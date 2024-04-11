import 'dart:math';

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

  int get length => opens.length;

  String get oldest => times.last.toKrakenDateTime().toTimestamp();

  String get newest => times.first.toKrakenDateTime().toTimestamp();

  ChartSnapshot(this.times, this.opens, this.highs, this.lows, this.closes,
      this.maxHigh, this.minLow);

  factory ChartSnapshot.fromSnip(Iterable<OHLC> snip) {
    if (snip.isEmpty) throw ArgumentError("no data");

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
