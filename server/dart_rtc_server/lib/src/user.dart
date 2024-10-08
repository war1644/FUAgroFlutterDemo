part of rtc_server;

class _User extends GenericEventTarget<UserEventListener>
    implements Comparable<_User> {
  /* talking to */
  late List<User> _talkingTo;

  /* name (id) of the user */
  String _id;

  /* millisecond timestamp when last activity was registered*/
  late int _lastActivity;

  /* millisecond timestamp when last connection to another user was done */
  late int _timeSinceLastConnection;

  bool _isDead = false;

  bool get isDead => _isDead;
  /** millisecond timestamp when last activity was registered */
  int get lastActivity => _lastActivity;

  /** millisecond timestamp when last connection to another user was done */
  int get timeSinceLastConnection => _timeSinceLastConnection;

  /** Is the user talking to another user */
  bool get isTalking => _talkingTo.length > 0;

  /** Users this user it talking with */
  List<User> get talkers => _talkingTo;

  /** Getter for user id */
  String get id => _id;

  /** Setter for user id */
  set id(String value) => _id = value;

  /** Set the timestamp for last activity */
  set lastActivity(int value) => _lastActivity = value;

  /** Set the timestamp for last connection */
  set timeSinceLastConnection(int value) => _timeSinceLastConnection = value;

  UserContainer? _container;

  _User(String id) : this.With(null, id);
  _User.With(this._container, this._id) {
    _talkingTo = [];

    var t = new DateTime.now().millisecondsSinceEpoch;
    _lastActivity = t;
    _timeSinceLastConnection = t;
  }

  /*
   * Called when websocket connection closes
   */
  void _onClose(int status, String reason) {
    _isDead = true;
    //_container.removeUser(this);
    _talkingTo.forEach((User u) => u.hangup(this as User));

    listeners.where((l) => l is UserConnectionEventListener).forEach((l) {
      final l1 = l as UserConnectionEventListener;
      l1.onClose(this as User, status, reason);
    });
  }

  /**
   * Hangup with other users
   */
  void hangup(User u) {
    if (_talkingTo.contains(u)) _talkingTo.removeAt(_talkingTo.indexOf(u));
  }

  /**
   * Talk to other user
   */
  void talkTo(User u) {
    if (!_talkingTo.contains(u)) {
      _talkingTo.add(u);
    }
  }

  /**
   * Checks if the user needs to be pinged
   */
  bool needsPing(int currentTime) {
    return currentTime >= lastActivity + DEAD_SOCKET_CHECK &&
        currentTime < lastActivity + DEAD_SOCKET_KILL;
  }

  /**
   * Checks if the user needs to be killed
   * User has not responded to ping with pong
   */
  bool needsKill(int currentTime) {
    return currentTime >= lastActivity + DEAD_SOCKET_KILL;
  }

  /**
   * Implements Comparable
   */
  @override
  int compareTo(_User other) {
    if (!(other is User))
      throw new ArgumentError("Cannot compare to anything else but User");

    int toReturn;

    _User otherUser = other as _User;
    if (_timeSinceLastConnection < otherUser.timeSinceLastConnection)
      toReturn = -1;
    else if (_timeSinceLastConnection > otherUser.timeSinceLastConnection)
      toReturn = 1;
    else
      toReturn = 0;

    return toReturn;
  }

  operator >(User other) {
    return _timeSinceLastConnection > other.timeSinceLastConnection;
  }

  operator >=(User other) {
    return _timeSinceLastConnection >= other.timeSinceLastConnection;
  }
}

/**
 * User class
 */
class User extends _User {
  /* WebSocketConnection */
  WebSocket _conn;

  /** Getter for the connection */
  WebSocket get connection => _conn;

  User(String id, WebSocket c) : this.With(null, id, c);
  User.With(UserContainer? container, String id, this._conn)
      : super.With(container, id) {
    //_conn.onClosed = _onClose;
    /*_conn.listen((event) {
      if (event is CloseEvent) {
        CloseEvent cevent = event;
        _onClose(cevent.code, cevent.reason);
      }
    });*/
  }

  /**
   * Kill the user
   */
  void terminate() {
    try {
      _conn.close(1000, "Leaving");
    } on Exception catch (e) {
    } catch (e) {}
  }

  /**
   * Equality operator ==
   */
  operator ==(Object o) {
    if (!(o is User)) return false;

    User u = o;
    if (u._conn != this._conn || u._id != this._id) {
      return false;
    }

    return true;
  }
}
