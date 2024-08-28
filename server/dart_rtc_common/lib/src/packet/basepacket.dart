part of rtc_common;

/**
 * Base packet
 */
abstract class Packet {
  /**
   * The type of the Packet
   */
  late final String packetType;

  /**
   * The id of the sender
   */
  late final String id;

  /**
   * Returns the object as Map.
   * WebSocket sends only native objects and maps
   */
  Map toJson();

  /**
   * Calls JSON.stringify on Map returned by toJson
   */
  String toString() {
    return json.encode(toJson());
  }
}
