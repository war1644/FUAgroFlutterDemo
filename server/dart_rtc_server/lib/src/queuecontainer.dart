part of rtc_server;

class QueueContainer extends ChannelContainer implements ChannelQueueEventListener {
  QueueContainer(Server s) : super(s) {
    _channelLimit = 2;
  }
  
  void onEnterQueue(Channel c, User u, int count, int position) {
    String positionToDisplay = (position + 1).toString();
    _server.sendPacket(u.connection, new QueuePacket.With(u.id, c.id, positionToDisplay));
    print("test1");
    _server.sendPacket(c.owner!.connection, new QueuePacket.With(u.id, c.id, positionToDisplay));
  }
  
  void onMoveInQueue(Channel c, User u, int count, int position) {
    String positionToDisplay = (position + 1).toString();
    _server.sendPacket(u.connection, new QueuePacket.With(u.id, c.id, positionToDisplay));
    print("test2");
    _server.sendPacket(c.owner!.connection, new QueuePacket.With(u.id, c.id, positionToDisplay));
  }
  
  void onLeaveQueue(Channel c, User u) {
    _server.sendPacket(u.connection, new QueuePacket.With(u.id, c.id, "0"));
    print("test3");
    _server.sendPacket(c.owner!.connection, new QueuePacket.With(u.id, c.id, "0"));
  }
  
  /**
   * Create channel with specified id
   */
  Channel? createChannelWithId(String id) {
    if (channelExists(id))
      return findChannel(id);
    
    Channel c = new QueueChannel.With(this, id);
    c.subscribe(this);
    add(c);
    return c;
  }
}

