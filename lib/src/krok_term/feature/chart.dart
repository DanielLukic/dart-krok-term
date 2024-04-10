import 'dart:async';
import 'dart:math';

import 'package:dart_consul/dart_consul.dart';
import 'package:rxdart/rxdart.dart' hide SwitchMapExtension;
import 'package:stream_transform/stream_transform.dart';

import '../common/window.dart';
import '../core/krok_core.dart';
import '../repository/asset_pairs_repo.dart';
import '../repository/krok_repos.dart';
import '../repository/ohlc_repo.dart';

final _window = window('chart', 61, 25) //
  ..name = "Chart [$cKey] [1-9]"
  ..position = AbsolutePosition(43, 4);

void openChart() => autoWindow(_window, () => _create());

void _create() {
  _window.onKey("u",
      description: "Update data",
      action: () => _refresh.value = DateTime.timestamp());

  _window.onKey('<S-h>', //
      description: 'Jump left',
      action: () => _scroll_(10));
  _window.onKey('<S-l>',
      description: 'Jump right', action: () => _scroll_(-10));
  _window.onKey('h', //
      description: 'Scroll left',
      action: () => _scroll_(1));
  _window.onKey('l', //
      description: 'Scroll right',
      action: () => _scroll_(-1));

  _window.onKey('<Left>', //
      aliases: ['i'],
      description: 'Smaller interval',
      action: () => _interval_(-1));
  _window.onKey('<Right>', //
      aliases: ['<S-i>'],
      description: 'Bigger interval',
      action: () => _interval_(1));

  _window.onKey('-', description: 'Zoom out', action: () => _zoom_(-1));
  _window.onKey('+', description: 'Zoom in', action: () => _zoom_(1));
  _window.onKey('=', description: 'Reset zoom', action: () => _zoom_(0));
  _window.onKey('r', description: 'Reset scroll and zoom', action: _reset);

  for (final i in OhlcInterval.values) {
    _window.onKey((i.index + 1).toString(),
        description: 'Switch to ${i.label}', action: () => _interval.value = i);
  }

  _window.chainOnMouseEvent(_changeInterval);
  _window.onWheelDown(() => _zoom_(-1));
  _window.onWheelUp(() => _zoom_(1));

  _window.chainOnMouseEvent((e) {
    if (e.isDown) return _DragChartAction(_window, e, _scroll.value);
    return null;
  });

  Stream<_PairDataInterval> retrieve(AssetPairData s, OhlcInterval i) =>
      ohlc(s, i).map((list) => (s, list, i));

  final chartData = combine([selectedAssetPair, _interval])
      .distinctUntilChanged()
      .switchMap((e) => retrieve(e[0], e[1]))
      .doOnData((e) => _maxScroll.value = e.$2.length);

  final withZoomAndScroll = combine([chartData, _interval, _zoom, _validScroll])
      .distinctUntilChanged()
      .map((e) => _renderChart(e[0], e[1], e[2], e[3]));

  _window.autoDispose("update",
      withZoomAndScroll.listenSafely((chart) => _window.update(() => chart)));
}

final _refresh = BehaviorSubject.seeded(DateTime.timestamp());
final _interval = BehaviorSubject.seeded(OhlcInterval.oneHour);
final _zoom = BehaviorSubject.seeded(1);
final _maxZoom = 10;
final _scroll = BehaviorSubject.seeded(0);
final _maxScroll = BehaviorSubject.seeded(0);
final _validScroll = _scroll.combineLatest(_maxScroll, (s, m) => s.clamp(0, m));

void _scroll_(int d) {
  _scroll.value = (_scroll.value + d).clamp(0, _maxScroll.value);
}

void _reset() {
  _scroll.value = 0;
  _zoom.value = 1;
}

void _zoom_(int delta) {
  if (delta == -1) _zoom.value = (_zoom.value - 1).clamp(1, _maxZoom);
  if (delta == 1) _zoom.value = (_zoom.value + 1).clamp(1, _maxZoom);
  if (delta == 0) _zoom.value = 1;
}

void _interval_(int delta) {
  final now = _interval.value.index;
  final change = (now + delta).clamp(0, OhlcInterval.values.length - 1);
  _interval.value = OhlcInterval.values[change];
}

typedef _PairDataInterval = (AssetPairData, List<OHLC>, OhlcInterval);

// ‾\_('')_/‾
OHLC _merged(OHLC a, OHLC b) => OHLC(
    (a.timestamp + b.timestamp) ~/ 2,
    (a.open + b.open) / 2,
    max(a.high, b.high),
    min(a.low, b.low),
    (a.close + b.close) / 2);

String _renderChart(
  _PairDataInterval pdi,
  OhlcInterval interval,
  int zoom,
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

  final scrolled = data.reversedList().skip(scroll);

  final zoomed = scrolled.windowed(zoom).map((e) => e.reduce(_merged));

  final snip = zoomed.take(canvas.width);

  // final opens = snip.map((e) => double.parse(e[1]));
  final highs = snip.mapList((e) => e.high);
  final lows = snip.mapList((e) => e.low);
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

  final left = snip.last.timestamp.toKrakenDateTime().toTimestamp();
  buffer.drawBuffer(0, buffer.height - 1, left);

  final right = snip.first.timestamp.toKrakenDateTime().toTimestamp();
  buffer.drawBuffer(buffer.width - right.length - 10, buffer.height - 1, right);

  final intervals = OhlcInterval.values
      .map((e) => e == interval ? e.label.inverse() : e.label);
  buffer.drawBuffer(0, 0, intervals.join(" "));

  if (pdi.$3 != interval) buffer.drawBuffer(0, 1, "loading...");

  final sl = buffer.height - 3;
  final zl = buffer.height - 4;
  buffer.drawBuffer(0, sl, "scroll $scroll of ${_maxScroll.value}".gray());
  buffer.drawBuffer(0, zl, "zoom $zoom of $_maxZoom".gray());

  return buffer.frame();
}

OngoingMouseAction? _changeInterval(MouseEvent event) {
  // check we are in the first line. then check we are not on a third char.
  // because these are the spaces between intervals. then take the x/4 to get
  // the clicked interval. finally, make sure we allow only existing intervals.
  // TODO Not sure I'm OK with the decorated 1 instead of 0...

  if (event.y != 1) return null;

  final check = event.x % 4;
  if (check == 3) return null;

  final index = event.x ~/ 4;
  if (index >= OhlcInterval.values.length) return null;

  _interval.value = OhlcInterval.values[index];
  return NopMouseAction(_window);
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

class _DragChartAction extends BaseOngoingMouseAction {
  final int _startScroll;

  _DragChartAction(super.window, super.event, this._startScroll);

  @override
  void onMouseEvent(MouseEvent event) {
    if (event.isUp) done = true;

    final dx = event.x - this.event.x;
    _scroll.value = (_startScroll + dx * 2).clamp(0, _maxScroll.value);
  }
}
