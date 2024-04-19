part of '../chart.dart';

ChartSnapshot _sample(List<OhlcData> data, int zoom, int scroll, int count) {
  final zoomed = _zoomed(data.reversedList(), zoom);
  final empty = List.filled(max(0, -scroll), OhlcData.empty);
  final scrolled = empty + zoomed.skip(max(0, scroll)).toList();
  final snip = (scrolled).take(count);
  return ChartSnapshot.fromSnip(snip);
}

/// Simply get data windows defined by zoom (count) and average them into new
/// OHLCs. Averaging via [_merge] for timestamp, open and close. Min and max
/// for high and low.
Iterable<OhlcData> _zoomed(Iterable<OhlcData> data, int zoom) =>
    data.windowed(zoom).map((e) => e.reduce(_merged));

OhlcData _merged(OhlcData a, OhlcData b) {
  if (a == OhlcData.empty) return b;
  if (b == OhlcData.empty) return a;
  return OhlcData(
    timestamp: (a.timestamp + b.timestamp) ~/ 2,
    open: a.timestamp < b.timestamp ? a.open : b.open,
    high: max(a.high, b.high),
    low: min(a.low, b.low),
    close: a.timestamp > b.timestamp ? a.open : b.open,
  );
}
