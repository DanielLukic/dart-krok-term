import 'package:dart_minilog/dart_minilog.dart';
import 'package:rxdart/transformers.dart';

import '../core/krok_core.dart';
import 'asset_pairs_repo.dart';

class OHLC extends BaseModel {
  static final empty = OHLC(timestamp: 0, open: 0, high: 0, low: 0, close: 0);

  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;

  @override
  List get fields => [timestamp, open, high, low, close];

  OHLC({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory OHLC.parse(List<dynamic> data) {
    final timestamp = data[0] as int;
    final open = double.parse(data[1]);
    final high = double.parse(data[2]);
    final low = double.parse(data[3]);
    final close = double.parse(data[4]);
    return OHLC(
      timestamp: timestamp,
      open: open,
      high: high,
      low: low,
      close: close,
    );
  }
}

Stream<List<OHLC>> ohlc(AssetPairData ap, OhlcInterval interval) =>
    retrieve(KrakenRequest.ohlc(
      pair: ap.pair,
      interval: interval,
      since: _toKrakenTime(interval),
    ))
        .doOnData((e) => logVerbose("o_h_l_c retrieved"))
        .map((json) => json[ap.pair] as List<dynamic>)
        .map((list) => list.mapList((e) => OHLC.parse(e)));

KrakenTime _toKrakenTime(OhlcInterval interval) =>
    _strToKt("${interval.minutes * 720}m");

KrakenTime _strToKt(String spec) =>
    KrakenTime.fromString(spec, since: true, allowShortForm: false);
