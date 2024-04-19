part of '../types.dart';

/// Data structure to capture the various notifications like triggered alerts
/// and triggered orders. For example:
/// ```
/// +--------------------------+
/// | WIF/USD         10:55:12 |
/// | Price below 2.0:     1.9 |
/// +--------------------------+
/// +--------------------------+
/// | Order executed  10:55:12 |
/// | SELL 10 WIF/USD @ 2.5    |
/// | TRAILING STOP 3%         |
/// +--------------------------+
/// ```
class Notification extends BaseModel {
  final int timestamp;

  /// WSNAME for alerts, 'Order executed' or 'Order canceled' for orders:
  final String header;

  /// "Price [below/above] <price>: <price>" for alerts, "BUY ..." for orders:
  final String description;

  /// Message to be sent when notification is clicked.
  /// ("select-pair", "WIF/USD") for alerts.
  /// ("select-order", "ORDER-ID-XXX") for orders.
  final (String, String) onClickMsg;

  Notification(this.timestamp, this.header, this.description, this.onClickMsg);

  Notification.now(this.header, this.description, this.onClickMsg)
      : timestamp = DateTime.timestamp().millisecondsSinceEpoch;

  Notification.from(List<dynamic> json)
      : this(json[0], json[1], json[2], (json[3], json[4]));

  @override
  List get fields =>
      [timestamp, header, description, onClickMsg.$1, onClickMsg.$2];

  String toLogString() {
    final ts = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
    return "${ts.toLocal().toLongStamp()} $header $description";
  }
}
