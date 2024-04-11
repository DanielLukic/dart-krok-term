import 'dart:async';
import 'dart:math';

import 'package:dart_consul/dart_consul.dart';
import 'package:rxdart/rxdart.dart' hide SwitchMapExtension, ScanExtension;
import 'package:stream_transform/stream_transform.dart';

import '../common/window.dart';
import '../core/krok_core.dart';
import '../repository/asset_pairs_repo.dart';
import '../repository/krok_repos.dart';
import '../repository/ohlc_repo.dart';
import 'chart/chart_snapshot.dart';

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
      action: () => _scroll.byDelta(10));
  _window.onKey('<S-l>',
      description: 'Jump right', action: () => _scroll.byDelta(-10));
  _window.onKey('h', //
      description: 'Scroll left',
      action: () => _scroll.byDelta(1));
  _window.onKey('l', //
      description: 'Scroll right',
      action: () => _scroll.byDelta(-1));

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

  _window.chainOnMouseEvent(
      (e) => e.isDown ? _DragChartAction(_window, e, _scroll.current) : null);

  Stream<_PairDataInterval> retrieve(AssetPairData s, OhlcInterval i) =>
      ohlc(s, i).map((list) => (s, list, i));

  final chartData = combine([selectedAssetPair, _interval])
      .distinctUntilChanged()
      .switchMap((e) => retrieve(e[0], e[1]))
      .doOnData((e) => _scroll.setDataSize(e.$2.length));

  final withZoomAndScroll =
      combine([chartData, _interval, _zoom, _scroll.stream])
          .distinctUntilChanged()
          .map((e) => _renderChart(e[0], e[1], e[2], e[3]));

  _window.autoDispose("update",
      withZoomAndScroll.listenSafely((chart) => _window.update(() => chart)));
}

final _scroll = _MadScroll();
final _refresh = BehaviorSubject.seeded(DateTime.timestamp());
final _interval = BehaviorSubject.seeded(OhlcInterval.oneHour);
final _zoom = BehaviorSubject.seeded(1);
final _maxZoom = 10;

final _empty = OHLC(0, 0, 0, 0, 0);

void _reset() {
  _scroll.reset();
  _zoom.value = 1;
}

void _zoom_(int delta) {
  final scroll = _scroll.current * _zoom.value;
  if (delta == -1) _zoom.value = (_zoom.value - 1).clamp(1, _maxZoom);
  if (delta == 1) _zoom.value = (_zoom.value + 1).clamp(1, _maxZoom);
  if (delta == 0) _zoom.value = 1;
  _scroll.setScroll((scroll / _zoom.value).round());
}

void _interval_(int delta) {
  final now = _interval.value.index;
  final change = (now + delta).clamp(0, OhlcInterval.values.length - 1);
  _interval.value = OhlcInterval.values[change];
}

typedef _PairDataInterval = (AssetPairData, List<OHLC>, OhlcInterval);

String _renderChart(
  _PairDataInterval pdi,
  OhlcInterval interval,
  int zoom,
  int scroll,
) {
  final pair = pdi.$1;
  final data = pdi.$2;
  if (data.isEmpty) return "";

  final canvasWidth = (_window.width - 10) * 2;
  final canvasHeight = (_window.height - 3) * 4;

  final zoomed = _zoomed(data.reversedList(), zoom);
  final empty = List.filled(max(0, -scroll), _empty);
  final scrolled = empty + zoomed.skip(max(0, scroll)).toList();
  final snip = (scrolled).take(canvasWidth);
  final snapshot = ChartSnapshot.fromSnip(snip);

  final Buffer buffer = Buffer(_window.width, _window.height);
  buffer.fill(32);
  buffer.drawBuffer(0, 0, _renderIntervalSelection(interval));
  buffer.drawBuffer(0, 1, _renderCanvas(canvasWidth, canvasHeight, snapshot));
  buffer.drawBuffer(_window.width - 10, 0, _renderPrices(pair, snapshot));
  buffer.drawBuffer(0, _window.height - 2, _renderTimeline(snapshot));

  final sl = buffer.height - 3;
  final zl = buffer.height - 4;
  buffer.drawBuffer(0, sl, "scroll $scroll of ${_scroll.max}".gray());
  buffer.drawBuffer(0, zl, "zoom $zoom of $_maxZoom".gray());
  if (pdi.$3 != interval) buffer.drawBuffer(0, 1, "loading...");

  return buffer.frame();
}

/// Simply get data windows defined by zoom (count) and average them into new
/// OHLCs. Averaging via [_merge] for timestamp, open and close. Min and max
/// for high and low.
Iterable<OHLC> _zoomed(Iterable<OHLC> data, int zoom) =>
    data.windowed(zoom).map((e) => e.reduce(_merged));

// ‾\_('')_/‾
OHLC _merged(OHLC a, OHLC b) {
  if (a == _empty) return b;
  if (b == _empty) return a;
  return OHLC((a.timestamp + b.timestamp) ~/ 2, (a.open + b.open) / 2,
      max(a.high, b.high), min(a.low, b.low), (a.close + b.close) / 2);
}

String _renderTimeline(ChartSnapshot snapshot) {
  final timeline = Buffer(_window.width - 10, 2);
  timeline.drawBuffer(0, 0, "".padRight(timeline.width, "┈"));
  timeline.drawBuffer(0, 1, "".padRight(timeline.width, " "));
  timeline.drawBuffer(0, 1, snapshot.oldest);
  timeline.drawBuffer(timeline.width - 11, 1, snapshot.newest);
  return timeline.frame();
}

String _renderIntervalSelection(OhlcInterval interval) => OhlcInterval.values
    .map((e) => e == interval ? e.label.inverse() : e.label)
    .join(" ");

String _renderCanvas(
  int canvasWidth,
  int canvasHeight,
  ChartSnapshot snapshot,
) {
  final canvas = DrawingCanvas(canvasWidth, canvasHeight);
  final normY = (1.0 / (snapshot.maxHigh - snapshot.minLow)) * canvas.height;
  final invertX = canvas.width - 1;
  final invertY = canvas.height - 1;
  final count = min(snapshot.length, canvas.width);
  for (var x = 0; x < count; x++) {
    final yTop = (snapshot.highs[x] - snapshot.minLow) * normY;
    final yBottom = (snapshot.lows[x] - snapshot.minLow) * normY;
    for (var y = yBottom; y <= yTop; y++) {
      canvas.set(invertX - x, invertY - y.round());
    }
  }
  return canvas.frame();
}

String _renderPrices(AssetPairData pair, ChartSnapshot snapshot) {
  final prices = Buffer(10, _window.height);
  prices.fill(32);
  prices.drawBuffer(1, 1, pair.price(snapshot.maxHigh));
  prices.drawBuffer(1, prices.height - 3, pair.price(snapshot.minLow));
  prices.drawColumn(0, '┊');
  prices.set(0, prices.height - 2, '┘');
  prices.set(0, prices.height - 1, ' ');
  return prices.frame();
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

class _MadScroll {
  final _dataSize = BehaviorSubject.seeded(0);
  final _setScroll = BehaviorSubject.seeded(0);
  final _currentMaxScroll = BehaviorSubject.seeded(0);
  final _currentScroll = BehaviorSubject.seeded(0);

  final _minScroll = -_window.width;

  late final _maxScroll = _dataSize
      .combineLatest(_zoom, (m, z) => (m / z).round() - _window.width)
      .doOnData((e) => _currentMaxScroll.value = e);

  late final stream = _setScroll
      .combineLatest(_maxScroll, (s, m) => s.clamp(_minScroll, m))
      .doOnData((e) => _currentScroll.value = e);

  int get max => _currentMaxScroll.value;

  int get current => _currentScroll.value;

  void setDataSize(int count) => _dataSize.value = count;

  void setScroll(int absolute) => _setScroll.value = absolute;

  void byDelta(int d) => _setScroll.value = _currentScroll.value + d;

  void reset() => _setScroll.value = 0;
}

class _DragChartAction extends BaseOngoingMouseAction {
  final int _startScroll;

  _DragChartAction(super.window, super.event, this._startScroll);

  @override
  void onMouseEvent(MouseEvent event) {
    if (event.isUp) done = true;

    final dx = event.x - this.event.x;
    _scroll.setScroll(_startScroll + dx * 2);
    // the 2 is for the canvas pixel duplication ☝
  }
}
