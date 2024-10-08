part of rtc_server;

class Channel extends GenericEventTarget<ChannelEventListener>
    implements UserConnectionEventListener {
  /* Parent container */
  ChannelContainer _container;

  /* Room id */
  String _id;

  /* max amount of users in room */
  int _limit;

  /* Owner of the channel */
  User? _owner;

  /* users */
  List<User> _users = [];

  /**
   * Returns users in channel
   */
  List<User> get users => _users;

  /**
   * Returns true if users length is less than limit
   */
  bool get canJoin => _users.length < _limit;

  /**
   * Limit of users in channel
   */
  int get channelLimit => _limit;
  set channelLimit(int i) => setChannelLimit(i);
  /**
   * Current usercount
   */
  int get userCount => _users.length;

  User? get owner => _owner;
  /**
   * Channel id
   */
  String get id => _id;

  Channel.With(this._container, this._id, this._limit);

  /**
   * Implements UserConnectionEventListener
   */
  void onClose(User u, int status, String reason) {
    leave(u);
  }

  /**
   * Sets the channel user limit and notifies all users in channel.
   */
  void setChannelLimit(int l) {
    _limit = l;
    _users.forEach((User u) {
      _container.getServer().sendPacket(u.connection,
          new ChannelPacket.With(u.id, id, u == owner, userCount, _limit));
    });
  }

  /**
   * Joins the room
   */
  bool join(User u) {
    if (!_addUser(u)) return false;

    u.subscribe(this);
    _notifyUserJoined(u);
    _sendJoinPackets(u);

    return true;
  }

  void _sendJoinPackets(User user) {
    Server server = _container.getServer();

    // Create a join packet to notify existing users in room
    Packet jp = new JoinPacket.With(_id, user.id);

    // Iterate trough all the users in this room
    _users.forEach((User u) {
      // If the newUser is not the current user in container
      if (u != user) {
        // Create a Id packet for newUser notifying all existing users in channel
        Packet ip = new IdPacket.With(u.id, _id);

        server.sendPacket(u.connection, jp);
        server.sendPacket(user.connection, ip);
      }
    });
    server.sendPacket(user.connection,
        new ChannelPacket.With(user.id, id, user == owner, userCount, _limit));
  }

  /**
   * Remove user from channel
   * Notify everyone else in channel
   * Notify listeners
   */
  void leave(User u) {
    if (u == _owner) _owner = null;
    _notifyUserLeft(u);

    sendToAll(new ByePacket.With(u.id));
  }

  /**
   * Force all users to leave the channel
   */
  void killAll() {
    for (int i = 0; i < _users.length; i++) {
      User u = _users[i];
      leave(u);
    }
  }

  /*
   * Adds a user to channel if user does not exist already
   */
  bool _addUser(User u) {
    if (!_users.contains(u) && canJoin) {
      if (_users.length == 0) _owner = u;
      _users.add(u);
      return true;
    }
    return false;
  }

  /*
   * Removes user from channel
   */
  User? _removeUser(User u) {
    int index = _users.indexOf(u);

    if (index > -1) {
      return _users.removeAt(index);
    }
    return null;
  }

  bool isInChannel(User u) {
    return _users.contains(u);
  }

  /*
   * Notify listeners about the user leaving
   */
  void _notifyUserLeft(User u) {
    listeners.where((l) => l is ChannelConnectionEventListener).forEach((l) {
      (l as ChannelConnectionEventListener).onLeaveChannel(this, u);
    });
  }

  /*
   * Notify listeners about the user joining
   */
  void _notifyUserJoined(User u) {
    listeners.where((l) => l is ChannelConnectionEventListener).forEach((l) {
      (l as ChannelConnectionEventListener).onEnterChannel(this, u);
    });
  }

  /**
   * Send packet to everyone in channel
   */
  void sendToAll(Packet p) {
    _users.forEach((User u) {
      if (u.isDead) print("WARN: user ${u.id} is dead");

      _container.getServer().sendPacket(u.connection, p);
    });
  }

  /**
   * Send packet to everyone in channel except the sender
   */
  void sendToAllExceptSender(User sender, Packet p) {
    _users.forEach((User u) {
      if (sender != u) {
        _container.getServer().sendPacket(u.connection, p);
      }
    });
  }

  /**
   * Equality operator ==
   * Check that id strings match
   **/
  operator ==(Object other) {
    if (!(other is Channel)) {
      return false;
    }
    return _id == (other)._id;
  }
}
