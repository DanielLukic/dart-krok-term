import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:krok_term/src/krok_term/common/extensions.dart';

import '../../repository/ohlc_repo.dart';

export '../../repository/ohlc_repo.dart';

class ChartSnapshot {
  final List<int> times;
  final List<double> opens;
  final List<double> highs;
  final List<double> lows;
  final List<double> closes;
  final double maxHigh;
  final double minLow;

  late final norm = (1.0 / (maxHigh - minLow));

  int get length => opens.length;

  String get oldestDate => times.last.toKrakenDateTime().toTimestamp();

  String get newestDate => times.first.toKrakenDateTime().toTimestamp();

  ChartSnapshot(this.times, this.opens, this.highs, this.lows, this.closes,
      this.maxHigh, this.minLow);

  factory ChartSnapshot.fromSnip(Iterable<OHLC> snip) {
    if (snip.isEmpty) {
      logWarn("no data");
      return ChartSnapshot.fromSnip([OHLC.empty]);
    }

    final times = snip.mapList((e) => e.timestamp);
    final opens = snip.mapList((e) => e.open);
    final highs = snip.mapList((e) => e.high);
    final lows = snip.mapList((e) => e.low);
    final closes = snip.mapList((e) => e.close);
    final validHighs = highs.where((e) => e != 0);
    final validLows = lows.where((e) => e != 0);
    final double maxHigh;
    final double minLow;
    if (validHighs.isEmpty) {
      maxHigh = highs[0];
      minLow = lows[0];
    } else {
      maxHigh = validHighs.reduce((a, b) => max(a, b));
      minLow = validLows.reduce((a, b) => min(a, b));
    }
    return ChartSnapshot(times, opens, highs, lows, closes, maxHigh, minLow);
  }
}
