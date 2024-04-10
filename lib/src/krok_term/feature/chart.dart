import 'dart:async';
import 'dart:math';

import 'package:dart_consul/dart_consul.dart';
import 'package:rxdart/rxdart.dart';

import '../common/window.dart';
import '../core/krok_core.dart';
import '../repository/asset_pairs_repo.dart';
import '../repository/krok_repos.dart';

final _window = window('chart', 61, 25) //
  ..name = "Chart [$cKey] [1-9]"
  ..position = AbsolutePosition(43, 4);

void openChart() => autoWindow(_window, () => _create());

final _interval = BehaviorSubject.seeded(OhlcInterval.oneHour);
final _zoom = BehaviorSubject.seeded(1.0);
final _scroll = BehaviorSubject.seeded(0);

Stream<List<dynamic>> combine(List<Stream<dynamic>> l) =>
    CombineLatestStream.list(l);

void _create() {
  // _window.onKey("u",
  //     description: "Update data", action: () => tickersRepo.refresh());

  _window.chainOnMouseEvent(_changeInterval);

  final chartData = combine([selectedAssetPair, _interval])
      .distinct((a, b) => a.toString() == b.toString()) // ‾\_('')_/‾
      .switchMap((e) => _retrieve(e[0], e[1]));

  final withZoomAndScroll = combine([chartData, _interval, _zoom, _scroll])
      .distinct((a, b) => a.toString() == b.toString()) // ‾\_('')_/‾
      .map((e) => _renderChart(e[0], e[1], e[2], e[3]));

  _window.autoDispose("update", withZoomAndScroll.listenSafely(_updateResult));
}

OngoingMouseAction? _changeInterval(MouseEvent event) {
  // TODO Not sure I'm OK with the decorated 1 instead of 0...
  if (event.y == 1) {
    final check = event.x % 4;
    if (check < 3) {
      final index = event.x ~/ 4;
      if (index < OhlcInterval.values.length) {
        _interval.value = OhlcInterval.values[index];
        return NopMouseAction(_window);
      }
    }
  }
  return null;
}

typedef _PairDataInterval = (AssetPairData, List, OhlcInterval);

Stream<_PairDataInterval> _retrieve(AssetPairData s, OhlcInterval i) =>
    retrieve(KrakenRequest.ohlc(pair: s.pair, interval: i))
        .map((json) => json[s.pair] as List)
        .map((list) => (s, list, i));

String _renderChart(
  _PairDataInterval pdi,
  OhlcInterval interval,
  double zoom,
  int scroll,
) {
  final pair = pdi.$1;
  final data = pdi.$2;
  if (data.isEmpty) return "";

  final Buffer buffer = Buffer(_window.width, _window.height);
  buffer.fill(32);

  final cw = (buffer.width - 10) * 2;
  final ch = (buffer.height - 3) * 4;
  final canvas = DrawingCanvas(cw, ch);

  final snip = data
      .takeLast(canvas.width)
      .reversed
      .map((e) => e as List<dynamic>)
      .toList();

  // final opens = snip.map((e) => double.parse(e[1]));
  final highs = snip.mapList((e) => double.parse(e[2]));
  final lows = snip.mapList((e) => double.parse(e[3]));
  // final closes = snip.map((e) => double.parse(e[4]));
  final max_ = highs.reduce((a, b) => max(a, b));
  final min_ = lows.reduce((a, b) => min(a, b));

  final normY = (1.0 / (max_ - min_)) * canvas.height;
  final invertX = canvas.width - 1;
  final invertY = canvas.height - 1;
  final count = min(snip.length, canvas.width);
  for (var x = 0; x < count; x++) {
    final yTop = (highs[x] - min_) * normY;
    final yBottom = (lows[x] - min_) * normY;
    for (var y = yBottom; y <= yTop; y++) {
      canvas.set(invertX - x, invertY - y.round());
    }
  }

  final prices = Buffer(10, _window.height);
  prices.fill(32);
  prices.drawBuffer(1, 1, pair.price(max_));
  prices.drawBuffer(1, prices.height - 3, pair.price(min_));
  prices.drawColumn(0, '┊');
  prices.set(0, prices.height - 2, '┘');
  prices.set(0, prices.height - 1, ' ');

  buffer.drawBuffer(0, 1, canvas.frame());
  buffer.drawBuffer(buffer.width - 10, 0, prices.frame());

  final divider = buffer.height - 2;
  final dividerLength = buffer.width - 10;
  buffer.drawBuffer(0, divider, "".padRight(dividerLength, "┈"));
  buffer.drawBuffer(0, buffer.height - 1, "".padRight(dividerLength, " "));

  final left = DateTime.fromMillisecondsSinceEpoch(snip.last[0] * 1000)
      .toIso8601String();
  buffer.drawBuffer(0, buffer.height - 1, left);

  final right = DateTime.fromMillisecondsSinceEpoch(snip.first[0] * 1000)
      .toIso8601String();
  buffer.drawBuffer(buffer.width - right.length, buffer.height - 1, right);

  final intervals = OhlcInterval.values
      .map((e) => e == interval ? e.label.inverse() : e.label);
  buffer.drawBuffer(0, 0, intervals.join(" "));

  if (pdi.$3 != interval) buffer.drawBuffer(0, 1, "loading...");

  return buffer.frame();
}

_updateResult(String chart) => _window.update(() => chart);

extension on Buffer {
  drawColumn(int x, String char) {
    for (var y = 0; y < height; y++) {
      set(x, y, char);
    }
  }

  set(int x, int y, String char) {
    drawBuffer(x, y, char);
  }
}

extension on OhlcInterval {
  String get label => switch (this) {
        OhlcInterval.oneMinute => ' 1m',
        OhlcInterval.fiveMinutes => ' 5m',
        OhlcInterval.fifteenMinutes => '15m',
        OhlcInterval.thirtyMinutes => '30m',
        OhlcInterval.oneHour => ' 1h',
        OhlcInterval.fourHours => ' 4h',
        OhlcInterval.oneDay => ' 1d',
        OhlcInterval.oneWeek => ' 7d',
        OhlcInterval.fifteenDays => '15d',
      };
}
