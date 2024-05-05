import 'dart:async';
import 'dart:math';

import 'package:rxdart/rxdart.dart'
    hide SwitchMapExtension, ScanExtension, StartWithExtension;
import 'package:stream_transform/stream_transform.dart';

import '../../common/window.dart';
import '../../core/krok_core.dart';
import '../../repository/krok_repos.dart';
import 'chart_projection.dart';
import 'chart_rendering.dart';
import 'chart_snapshot.dart';

part 'chart_keys.dart';
part 'chart_mouse.dart';
part 'chart_sampling.dart';
part 'chart_selection.dart';

final _window = window('chart', 62, 25) //
  ..name = "Chart [$cKey] [1-9]"
  ..position = AbsolutePosition(42, 4);

void openChart() => autoWindow(_window, () => _create());

void _triggerRefresh() => _refresh.value = DateTime.timestamp();

void _triggerRedraw() => _redraw.value = DateTime.timestamp();

void _create() {
  _window.setupKeys();
  _window.setupMouse();

  Stream<_ChartData> retrieve(AssetPairData s, OhlcInterval i, DateTime r) =>
      ohlcRepo.retrieve(s, i).map((list) => (s, list, i, r));

  final autoRefreshPair = selectedAssetPair.doOnData((_) {
    _selection.invalidate();
    _selection.resetFixed();
    _projection.reset();
    _interval.value = OhlcInterval.oneHour;
    _triggerRefresh();
    // reset pair when switching. will be assigned after data arrived.
    _pair = null;
  });

  final refresh = _refresh.switchMap((e) =>
      Stream.periodic(1.minutes).map((_) => DateTime.timestamp()).startWith(e));

  final chartData = combine([autoRefreshPair, _interval, refresh])
      .distinctUntilChanged()
      .debounceTime(100.millis)
      .switchMap((e) => retrieve(e[0], e[1], e[2]))
      .doOnData((e) => _projection.setDataSize(e.$2.length));

  final pairAlerts = alerts.combineLatest(
      selectedAssetPair, (a, ap) => a[ap.pair] ?? <AlertData>[]);

  final orders =
      combine([selectedAssetPair, openOrders, closedOrders]).map(_orders);

  final zoom = _projection.zoom;
  final scroll = _projection.scroll;
  final withZoomAndScroll = combine([
    chartData,
    _interval,
    zoom,
    scroll,
    refresh,
    autoRefreshPair,
    _selection.selectedPrice,
    pairAlerts,
    orders,
    _redraw,
  ])
      .distinctUntilChanged()
      // assign pair, now that data is available/visible. pair is used for
      // placing alerts only for now.
      .doOnData((e) => _setPairWhenDataAvailable(e[0], e[5]))
      .map((e) =>
          _renderChart(e[0], e[1], e[2], e[3], e[4], e[5], e[6], e[7], e[8]));

  _window.autoDispose("update",
      withZoomAndScroll.listenSafely(_showChart, onError: _showError));
}

(Orders, Orders) _orders(List<dynamic> e) {
  final AssetPairData ap = e[0];
  final Orders open = e[1];
  final Orders closed = e[2];
  final o = open.where(
      (e) => e.value.pair() == ap.pair && e.value.status() != 'canceled');
  final c = closed.where(
      (e) => e.value.pair() == ap.pair && e.value.status() != 'canceled');
  return (o, c);
}

_setPairWhenDataAvailable(_ChartData data, AssetPairData pair) {
  _pair = data.$1 == pair ? pair : null;
}

_showChart(chart) => _window.update(() => chart);

_showError(e, trace) => _window.update(() {
      final error = e
          .toString()
          .split(':')
          .join('\n')
          .autoWrap(_window.width)
          .map((e) => e.red())
          .join('\n');
      return '$error\n\n$trace';
    });

/// Latest selected pair. Horrible. Used for placing alerts.
AssetPairData? _pair;

final _projection = ChartProjection(_window.width ~/ 2);
final _refresh = BehaviorSubject.seeded(DateTime.timestamp());
final _redraw = BehaviorSubject.seeded(DateTime.timestamp());
final _interval = BehaviorSubject.seeded(OhlcInterval.oneHour);

typedef _ChartData = (AssetPairData, List<OhlcData>, OhlcInterval, DateTime);

String _renderChart(
  _ChartData input,
  OhlcInterval interval,
  int zoom,
  int scroll,
  DateTime refresh,
  AssetPairData ap,
  double sp,
  List<AlertData> alerts,
  (Orders, Orders) orders,
) {
  final pair = input.$1;
  final data = input.$2;
  if (data.isEmpty) return "";

  final width = _window.width;
  final height = _window.height;

  final split = width - 10;
  final chartWidth = split * 2;
  final chartHeight = (height - 3) * 4;

  final last = data.last;
  final snap = _sample(data, zoom, scroll, chartWidth);

  final fixed = _selection.fixedScale;
  if (fixed != null) snap.override(fixed[0], fixed[1]);

  _selection.useChartInfo(snap.minLow, snap.maxHigh, last.close, chartHeight);

  final loading = _loading(input, interval, refresh);

  final Buffer buffer = Buffer(width, height);
  buffer.drawBuffer(0, 0, renderIntervalSelection(interval));
  buffer.drawBuffer(width - 20, 0, _zoomInfo(zoom));
  if (loading.isEmpty || input.$1 == ap) {
    final data =
        renderCanvas(chartWidth, chartHeight, snap, last, sp, alerts, orders);
    buffer.drawBuffer(0, 1, data);
    final prices =
        renderPrices(pair, snap, height, last, sp, alerts, fixed != null);
    buffer.drawBuffer(split, 0, prices);
    buffer.drawBuffer(0, height - 2, renderTimeline(snap, width));
  }
  buffer.drawBuffer(0, height - 3, loading);

  return buffer.frame();
}

String _loading(_ChartData pdi, OhlcInterval i, DateTime refresh) {
  final intervalChange = pdi.$3 != i;
  final refreshOngoing = pdi.$4 != refresh;
  return intervalChange || refreshOngoing ? "loading..".blue() : "";
}

String _zoomInfo(int zoom) => "zoom $zoom/${_projection.maxZoom}".gray();
