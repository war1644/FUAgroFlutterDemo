part of rtc_server;

class QueueServer extends WebSocketServer
    implements ContainerContentsEventListener {
  late QueueContainer _queueContainer;

  QueueServer() {
    registerHandler(PACKET_TYPE_PEERCREATED, handlePeerCreated);
    registerHandler(PACKET_TYPE_USERMESSAGE, handleUserMessage);
    registerHandler(PACKET_TYPE_NEXT, handleNextUser);
    registerHandler(PACKET_TYPE_REMOVEUSER, handleRemoveUserCommand);

    _queueContainer = new QueueContainer(this);
    _queueContainer.subscribe(this);
  }

  void onCountChanged(BaseContainer bc) {
    print("Container count changed ${bc.count}");
    displayStatus();
  }

  void displayStatus() {
    print(
        "Users: ${_container.userCount} Channels: ${_queueContainer.channelCount}");
  }

  // Override
  void handleIncomingHelo(HeloPacket hp, WebSocket c) {
    super.handleIncomingHelo(hp, c);
    try {
      if (hp.channelId.isEmpty) {
        c.close(1003, "Specify channel id");
        return;
      }

      User? u = _container.findUserByConn(c);
      if (u == null) return;

      Channel? chan = _queueContainer.findChannel(hp.channelId);
      if (chan == null)
        chan = _queueContainer.createChannelWithId(hp.channelId);
      chan!.join(u);
    } catch (e, s) {
      print(e);
      print(s);
    }
  }

  void handlePeerCreated(PeerCreatedPacket pcp, WebSocket c) {
    User? user = _container.findUserByConn(c);
    User? other = _container.findUserById(pcp.id);

    if (user != null && other != null) user.talkTo(other);
  }

  void handleRemoveUserCommand(RemoveUserCommand p, WebSocket c) {
    try {
      User? user = _container.findUserByConn(c);
      User? other = _container.findUserById(p.id);

      if (user == null || other == null) {
        print("(channelserver.dart) User was not found");
        return;
      }

      Channel? channel = _queueContainer.findChannel(p.channelId);
      if (channel == null) return;
      if (user == channel.owner) channel.leave(other);
    } catch (e) {
      print("Error: $e");
    }
  }

  void handleNextUser(NextPacket p, WebSocket c) {
    try {
      User? user = _container.findUserByConn(c);
      User? other = _container.findUserById(p.id);

      if (user == null || other == null) {
        print("(channelserver.dart) User was not found");
        return;
      }

      Channel? channel = _queueContainer.findChannel(p.channelId);
      if (channel == null) return;
      if (user == channel.owner) (channel as QueueChannel).next();
    } catch (e) {
      print("Error: $e");
    }
  }

  void handleUserMessage(UserMessage um, WebSocket c) {
    try {
      if (um.id.isEmpty) {
        print("id was null or empty");
        return;
      }
      User? user = _container.findUserByConn(c);
      User? other = _container.findUserById(um.id);

      if (user == null || other == null) {
        print("(channelserver.dart) User was not found");
        return;
      }

      um.id = user.id;

      sendToClient(other.connection, PacketFactory.get(um));
    } on NoSuchMethodError catch (e) {
      print("Error: $e");
    } catch (e) {
      print("Error: $e");
    }
  }
}
