part of rtc_server;

class ChannelServer extends WebSocketServer implements ContainerContentsEventListener{
late  ChannelContainer _channelContainer;

  ChannelServer() : super() {
    registerHandler(PACKET_TYPE_PEERCREATED, handlePeerCreated);
    registerHandler(PACKET_TYPE_USERMESSAGE, handleUserMessage);
    registerHandler(PACKET_TYPE_CHANNELMESSAGE, handleChannelMessage);
    registerHandler(PACKET_TYPE_SETCHANNELVARS, handleChannelvars);
    registerHandler(PACKET_TYPE_CHANNELJOIN, handleChannelJoin);

    _channelContainer = new ChannelContainer(this);
    _channelContainer.subscribe(this);
  }

  void onCountChanged(BaseContainer bc) {
    print("Container count changed ${bc.count}");
    displayStatus();
  }

  void displayStatus() {
    print("Users: ${_container.userCount} Channels: ${_channelContainer.channelCount}");
  }

  void handleIncomingNick(ChangeNickCommand p, WebSocket c) {
    super.handleIncomingNick(p, c);

    User? user = _container.findUserByConn(c);
     if (user == null) return;
    List<Channel> channels = _channelContainer.getChannelsWhereUserIs(user);
    if (channels.length > 0) {
      channels.forEach((Channel c) {
        c.sendToAllExceptSender(user, p);
      });
    }
  }
  void handleChannelJoin(ChannelJoinCommand p, WebSocket c) {
    try {
      if (p.channelId.isEmpty) {
        return;
      }

      User? u = _container.findUserByConn(c);
      if (u == null) return;

      Channel? chan;
      chan = _channelContainer.findChannel(p.channelId);
      if (chan != null) {
        if (chan.canJoin) {
          chan.join(u);
        }
      } else {
        chan = _channelContainer.createChannelWithId(p.channelId);
        chan!.join(u);
      }
    } catch(e, s) {
     print(e);
      print(s);
    }
  }

  void handlePeerCreated(PeerCreatedPacket pcp, WebSocket c) {
    User? user = _container.findUserByConn(c);
    User? other = _container.findUserById(pcp.id);

    if (user != null && other != null)
      user.talkTo(other);
  }

  void handleChannelvars(SetChannelVarsCommand cm, WebSocket c) {
    if (cm.channelId.isEmpty)
      return;

    Channel? channel = _channelContainer.findChannel(cm.channelId);
    User? user = _container.findUserByConn(c);

    if (user == null) {
      print("(channelserver.dart) User was not found");
      return;
    }

    if (channel == null) {
      print("(channelserver.dart) Channel was not found");
      return;
    }

    if (user == channel.owner) {
      channel.channelLimit = cm.limit;
    }
  }
  void handleChannelMessage(ChannelMessage cm, WebSocket c) {
    print("Handling channel message to channel ${cm.channelId}");
    try {

      if (cm.channelId.isEmpty)
        return;

      User? user = _container.findUserByConn(c);

      if (user == null) {
        print("(channelserver.dart) User was not found");
        return;
      }

      Channel? channel = _channelContainer.findChannel(cm.channelId);
      if (channel == null) {
        return;
      }
      if (channel.isInChannel(user)) {
        print("Sending to all users in channel");
        channel.sendToAllExceptSender(user, cm);
      }

    } on NoSuchMethodError catch(e) {
     print("Error: $e");
    } catch(e) {
     print("Error: $e");
    }
  }
  void handleUserMessage(UserMessage um, WebSocket c) {
    try {
      if (um.id == null || um.id.isEmpty) {
        print ("id was null or empty");
        return;
      }
      User? user = _container.findUserByConn(c);
      User? other = _container.findUserById(um.id);

      if (user == null || other == null) {
        print("(channelserver.dart) User was not found");
        return;
      }

      List<Channel> channels = _channelContainer.getChannelsWhereUserIs(user);
      if (channels.length > 0) {
        channels.forEach((Channel c) {
          c.sendToAllExceptSender(user, um);
        });
      }
      //um.id = user.id;


      //sendToClient(other.connection, PacketFactory.get(um));

    } on NoSuchMethodError catch(e) {
     print("Error: $e");
    } catch(e) {
     print("Error: $e");
    }
  }
}
