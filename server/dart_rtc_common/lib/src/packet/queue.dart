part of rtc_common;

class QueuePacket extends Packet {
  QueuePacket(this.id, this.channelId, this.position);
  QueuePacket.With(this.id, this.channelId, this.position);

  String packetType = PACKET_TYPE_QUEUE;
  String id;
  String channelId;
  String position;

  Map toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'position': position,
      'packetType': packetType
    };
  }

  static QueuePacket fromMap(Map m) {
    return new QueuePacket.With(m['id'], m['channelId'], m['position']);
  }
}

class NextPacket extends Packet {
  NextPacket(this.id, this.channelId);
  NextPacket.With(this.id, this.channelId);

  String packetType = PACKET_TYPE_NEXT;
  String id;
  String channelId;

  Map toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'packetType': packetType
    };
  }

  static NextPacket fromMap(Map m) {
    return new NextPacket.With(m['id'], m['channelId']);
  }
}


