part of rtc_common;

class DescriptionPacket extends Packet {
  DescriptionPacket(this.sdp, this.type, this.id, this.channelId);
  DescriptionPacket.With(this.sdp, this.type, this.id, this.channelId);

  String packetType = PACKET_TYPE_DESC;
  String sdp;
  String id;
  String channelId;
  String type;

  Map toJson() {
    return {
      'sdp':sdp,
      'type': type,
      'id':id,
      'packetType':packetType,
      'channelId':channelId
    };
  }

  static DescriptionPacket fromMap(Map m) {
    return new DescriptionPacket.With(m['sdp'], m['type'], m['id'], m['channelId']);
  }
}