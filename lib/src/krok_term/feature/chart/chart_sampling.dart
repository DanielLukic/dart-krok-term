part of '../chart.dart';

ChartSnapshot _sample(List<OHLC> data, int zoom, int scroll, int count) {
  final zoomed = _zoomed(data.reversedList(), zoom);
  final empty = List.filled(max(0, -scroll), OHLC.empty);
  final scrolled = empty + zoomed.skip(max(0, scroll)).toList();
  final snip = (scrolled).take(count);
  return ChartSnapshot.fromSnip(snip);
}

/// Simply get data windows defined by zoom (count) and average them into new
/// OHLCs. Averaging via [_merge] for timestamp, open and close. Min and max
/// for high and low.
Iterable<OHLC> _zoomed(Iterable<OHLC> data, int zoom) =>
    data.windowed(zoom).map((e) => e.reduce(_merged));

OHLC _merged(OHLC a, OHLC b) {
  if (a == OHLC.empty) return b;
  if (b == OHLC.empty) return a;
  return OHLC(
    timestamp: (a.timestamp + b.timestamp) ~/ 2,
    open: a.timestamp < b.timestamp ? a.open : b.open,
    high: max(a.high, b.high),
    low: min(a.low, b.low),
    close: a.timestamp > b.timestamp ? a.open : b.open,
  );
}
