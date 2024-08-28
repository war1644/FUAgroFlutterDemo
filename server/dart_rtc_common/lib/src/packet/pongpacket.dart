part of rtc_common;

class PongPacket extends Packet {
  PongPacket(this.id, this.packetType);

  String packetType = PACKET_TYPE_PONG;
  String id;

  Map toJson() {
    return {'packetType': packetType};
  }

  static PongPacket fromMap(Map m) {
    return new PongPacket(m['id'], m['packetType']);
  }
}
