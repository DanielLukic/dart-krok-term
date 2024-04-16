import 'dart:io';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:rxdart/rxdart.dart';

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

  List toJson() => fields;

  factory OHLC.fromJson(List<dynamic> data) {
    final timestamp = data[0] as int;
    final open = _toDouble(data[1]);
    final high = _toDouble(data[2]);
    final low = _toDouble(data[3]);
    final close = _toDouble(data[4]);
    return OHLC(
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

class OhlcRepo {
  final Storage _storage;

  OhlcRepo(this._storage);

  Stream<List<OHLC>> retrieve(
    AssetPairData ap,
    OhlcInterval interval, {
    bool forceFresh = false,
  }) {
    final key = 'ohlc_${ap.wsname.replaceFirst('/', '_')}_${interval.minutes}';
    final lm = _storage.lastModified(key);
    final Stream<List<OHLC>> pre;
    if (!forceFresh && lm != null && lm.age.inMinutes < interval.minutes) {
      final restored = Stream.fromFuture(_storage.load(key));
      final data = restored.whereNotNull().map((e) => e['ohlc'] as List);
      pre = data
          .map((e) => e.mapList((e) => OHLC.fromJson(e)))
          .doOnData((e) => logVerbose('restored ${e.length} values for $key'));
    } else {
      pre = Stream.empty();
    }
    final fresh = ohlc(ap, interval).asyncMap((e) async {
      try {
        logVerbose('save $key: ${e.length} values');
        await _storage.save(key, {'ohlc': e});
      } catch (it) {
        logError('failed saving ohlc data for $key - ignored: $it');
      }
      return e;
    }).doOnCancel(() => logVerbose('fresh canceled'));

    final clean = Stream.fromFuture(_cleanUpFiles())
        .flatMap((_) => Stream<List<OHLC>>.empty());

    return ConcatStream([pre, fresh, clean])
        .doOnData((e) => logVerbose('provide ${e.length} values for $key'));
  }

  Future _cleanUpFiles() async {
    final stream = Directory('krok')
        .list()
        .where((e) => e.path.contains('ohlc_'))
        .asyncMap((e) async => (e, await e.stat()));
    await for (final (e, stat) in stream) {
      if (stat.modified.age.inMinutes < 60) continue;
      logVerbose('delete outdated ${e.path}');
      await e.delete();
    }
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
        .map((list) => list.mapList((e) => OHLC.fromJson(e)));

KrakenTime _toKrakenTime(OhlcInterval interval) =>
    _strToKt("${interval.minutes * 720}m");

KrakenTime _strToKt(String spec) =>
    KrakenTime.fromString(spec, since: true, allowShortForm: false);
