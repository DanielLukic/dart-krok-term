part of '../types.dart';

class OhlcData extends BaseModel {
  static final empty =
      OhlcData(timestamp: 0, open: 0, high: 0, low: 0, close: 0);

  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;

  @override
  List get fields => [timestamp, open, high, low, close];

  OhlcData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  List toJson() => fields;

  factory OhlcData.fromJson(List<dynamic> data) {
    final timestamp = data[0] as int;
    final open = _toDouble(data[1]);
    final high = _toDouble(data[2]);
    final low = _toDouble(data[3]);
    final close = _toDouble(data[4]);
    return OhlcData(
      timestamp: timestamp,
      open: open,
      high: high,
      low: low,
      close: close,
    );
  }

  static double _toDouble(dynamic it) => switch (it) {
        _ when it is double => it,
        _ => double.parse(it.toString()),
      };
}
