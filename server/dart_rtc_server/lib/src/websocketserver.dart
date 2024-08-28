part of rtc_server;

class WebSocketServer extends PacketHandler
    implements Server, ContainerContentsEventListener {
  /* The http server */
  late HttpServer _httpServer;

  /* Websocket handler */
  //WebSocketHandler _wsHandler;

  /* Container keeps track of users and rooms */
  late UserContainer _container;

  /* Ip address socket is going to be bind */
  late String _ip;

  /* path for websocket */
  late String _path;

  /* port to bind to */
  late int _port;

  /* 2 second session timeout */
  int _sessionTimeout = 2;

  // 1 minute
  static const int _timerTickInterval = 6000;

  /* Timer */
  late Timer _timer;

  late BinaryReader _reader;

  WebSocketServer() : super() {
    // Create the HttpServer and web socket
    //_httpServer = new HttpServer();
    //_httpServer.sessionTimeout = _sessionTimeout;
    //_wsHandler = new WebSocketHandler();
    _container = new UserContainer(this);
    _container.subscribe(this);
    _timer =
        new Timer.periodic(const Duration(milliseconds: 6000), onTimerTick);
    _reader = new BinaryReader();

    // Register handlers needed to handle on this low level
    registerHandler(PACKET_TYPE_HELO, handleIncomingHelo);
    registerHandler(PACKET_TYPE_BYE, handleIncomingBye);
    registerHandler(PACKET_TYPE_PONG, handleIncomingPong);
    registerHandler(PACKET_TYPE_DESC, handleIncomingDescription);
    registerHandler(PACKET_TYPE_ICE, handleIncomingIce);
    registerHandler(PACKET_TYPE_FILE, handleIncomingFile);
    registerHandler(PACKET_TYPE_CHANGENICK, handleIncomingNick);
  }

  /**
   * Stop the server
   * TODO: Find out howto catch ctrl+c
   */
  void stop() {
    _timer.cancel();
    //_httpServer.close();
  }

  /**
   * Start listening on port
   * @param ip the ip address bind to
   * @param port the port to bind to
   * @param path the path
   */
  void listen([String ip = "0.0.0.0", int port = 8234, String path = "/ws"]) {
    _ip = ip;
    _path = path;
    _port = port;

    HttpServer.bind(_ip, _port).then((HttpServer server) {
      _httpServer = server;

      server
          .transform(new WebSocketTransformer())
          .listen((WebSocket webSocket) {
        webSocket.listen((data) {
          Packet? p = getPacket(data);
          if (p == null) return;
          if (!executeHandlerFor(webSocket, p))
            print("No handler found for packet (${p.packetType})");
        }, onDone: () {
          User? u = _container.findUserByConn(webSocket);
          if (u != null) {
            u._onClose(webSocket.closeCode!, webSocket.closeReason!);
          }
        }, onError: (e) {
          /*
          User u = _container.findUserByConn(webSocket);
          if (u != null) {
            u._onClose(webSocket.closeCode, webSocket.closeReason);
            new Logger().Error("Error, removing user ${u.id}");
          }*/
        });
      });
    });
  }

  Packet? getPacket(Object m) {
    Packet? p = null;
    String readFrom = '';

    if (m is String) {
      readFrom = m;
    } else {
      _reader.readChunk(m as Uint8List);
      readFrom = _reader.getCompleted()!;
    }
    print(json.decode(readFrom));

    p = PacketFactory.getPacketFromString(readFrom);
    return p;
  }

  void onCountChanged(BaseContainer bc) {
    if (bc is UserContainer) print("Users: ${bc.count}");
  }

  void displayStatus() {}

  void onTimerTick(Timer t) {
    try {
      doAliveChecks();
      //displayStatus();
    } catch (e) {
      print("onTimerTick: $e");
    }
  }

  /**
   * PingPongKill
   */
  void doAliveChecks() {
    int currentTime = new DateTime.now().millisecondsSinceEpoch;
    List<User> users = _container.getUsers();

    for (int i = 0; i < users.length; i++) {
      User u = users[i];

      if (u.needsPing(currentTime)) {
        sendPacket(u.connection, new PingPacket.With(u.id));
      } else if (u.needsKill(currentTime)) {
        try {
          print("Closing dead socket");
          u.connection.close(1000, "Closing dead socket");
        } catch (e) {
          print("Closing dead socket threw $e");
        }
      }
    }
  }

  /**
   * Sends a packet to the WebSocketConnection
   * @param c WebSocketConnection
   * @param p Packet to send
   */
  void sendPacket(WebSocket c, Packet p) {
    sendToClient(c, PacketFactory.get(p));
  }

  /**
   * Send a stringified json to receiving web socket connection
   * @param c WebSocketConnection
   * @param p Packet to send
   */
  void sendToClient(WebSocket c, String p) {
    new Timer(const Duration(milliseconds: 500), () {
      try {
        c.add(p);
      } catch (e) {}
    });
    /*try {
      //new Timer.run(() {
        c.add(p);
      //});
    } catch(e, s) {
      logger.Debug("Socket Dead? removing connection.");
      try {
        User u = _container.findUserByConn(c);
        if (u != null) {
          logger.Debug("removing dead user ${u.id}");
          _container.removeUser(u);
          //u.channel.leave(u);
          u = null;
        } else {
          logger.Debug("user is null");
        }
        c.close(1000, "Assuming dead");
      } catch (e, s) {
        logger.Debug("Last catch, sendToClient $e, $s");
      }
    }*/
  }

  void handleIncomingHelo(HeloPacket p, WebSocket c) {
    User? u = _container.findUserByConn(c);
    if (u == null) return;
    c.close(1003, "Already HELO'd");
    print("User exists, disconnecting");

    if (!p.id.isEmpty)
      u = _container.createUserFromId(p.id, c);
    else
      u = _container.createUser(c);

    sendPacket(c, new ConnectionSuccessPacket.With(u.id));
  }

  void handleIncomingNick(ChangeNickCommand p, WebSocket c) {
    User? u = _container.findUserByConn(c);
    if (u == null) return;

    u.lastActivity = new DateTime.now().millisecondsSinceEpoch;

    if (!_container.nickExists(p.newId)) {
      u.id = p.newId;
      sendPacket(u.connection, p);
      // TODO: Notify talkers
    }
  }

  void handleIncomingBye(ByePacket p, WebSocket c) {
    User? u = _container.findUserByConn(c);
    if (u == null) return;
    u.terminate();
  }

  /**
   * Handle the incoming sdp description
   */
  void handleIncomingDescription(DescriptionPacket p, WebSocket c) {
    try {
      User? sender = _container.findUserByConn(c);
      User? receiver = _container.findUserById(p.id);

      if (receiver == null || sender == null) {
        print("Sender or Receiver not found");
        return;
      }
      sender.lastActivity = new DateTime.now().millisecondsSinceEpoch;

      if (sender == receiver) {
        print("Sending to self, abort");
        return;
      }
      receiver.lastActivity = new DateTime.now().millisecondsSinceEpoch;

      sender.talkTo(receiver);

      sendPacket(receiver.connection,
          new DescriptionPacket.With(p.sdp, p.type, sender.id, ""));
    } catch (e) {
      print("handleIncomingDescription: $e");
    }
  }

  /**
   * Handle incoming ice packets
   */
  void handleIncomingIce(IcePacket ice, WebSocket c) {
    try {
      User? sender = _container.findUserByConn(c);
      User? receiver = _container.findUserById(ice.id);

      if (receiver == null || sender == null) {
        print("Sender or Receiver not found");
        return;
      }
      sender.lastActivity = new DateTime.now().millisecondsSinceEpoch;

      if (sender == receiver) {
        print("Sending to self, abort");
        return;
      }
      receiver.lastActivity = new DateTime.now().millisecondsSinceEpoch;

      sendPacket(
          receiver.connection,
          new IcePacket.With(
              ice.candidate, ice.sdpMid, ice.sdpMLineIndex, sender.id));
    } catch (e) {
      print("handleIncomingIce: $e");
    }
  }

  /**
   * handle incoming pong replies
   */
  void handleIncomingPong(PongPacket p, WebSocket c) {
    try {
      print("Handling pong");
      User? sender = _container.findUserByConn(c);
      if (sender == null) return;

      sender.lastActivity = new DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      print("handleIncomingPong: $e");
    }
  }

  void handleIncomingFile(FilePacket p, WebSocket c) {
    try {
      print("Handling File packet");

      User? sender = _container.findUserByConn(c);
      User? receiver = _container.findUserById(p.id);

      if (receiver == null || sender == null) {
        print("Sender or Receiver not found");
        return;
      }

      sender.lastActivity = new DateTime.now().millisecondsSinceEpoch;
      receiver.lastActivity = new DateTime.now().millisecondsSinceEpoch;

      p.id = sender.id;
      sendPacket(receiver.connection, p);
    } catch (e) {
      print("handleIncomingPong: $e");
    }
  }
}
