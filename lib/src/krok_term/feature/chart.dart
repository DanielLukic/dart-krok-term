import 'dart:async';
import 'dart:math';

import 'package:dart_consul/dart_consul.dart';
import 'package:rxdart/rxdart.dart' hide SwitchMapExtension, ScanExtension;
import 'package:stream_transform/stream_transform.dart';

import '../common/window.dart';
import '../core/krok_core.dart';
import '../repository/asset_pairs_repo.dart';
import '../repository/krok_repos.dart';
import 'chart/chart_projection.dart';
import 'chart/chart_rendering.dart';
import 'chart/chart_snapshot.dart';

part 'chart/chart_keys.dart';
part 'chart/chart_mouse.dart';
part 'chart/chart_sampling.dart';

final _window = window('chart', 61, 25) //
  ..name = "Chart [$cKey] [1-9]"
  ..position = AbsolutePosition(43, 4);

void openChart() => autoWindow(_window, () => _create());

void _triggerRefresh() => _refresh.value = DateTime.timestamp();

void _create() {
  _window.setupKeys();
  _window.setupMouse();

  Stream<_ChartData> retrieve(AssetPairData s, OhlcInterval i, DateTime r) =>
      ohlc(s, i).map((list) => (s, list, i, r));

  final refreshOnSelect = selectedAssetPair.doOnData((_) => _triggerRefresh());

  final chartData = combine([refreshOnSelect, _interval, _refresh])
      .distinctUntilChanged()
      .switchMap((e) => retrieve(e[0], e[1], e[2]))
      .doOnData((e) => _projection.setDataSize(e.$2.length));

  final zoom = _projection.zoom;
  final scroll = _projection.scroll;
  final withZoomAndScroll =
      combine([chartData, _interval, zoom, scroll, _refresh])
          .distinctUntilChanged()
          .map((e) => _renderChart(e[0], e[1], e[2], e[3], e[4]));

  _window.autoDispose("update",
      withZoomAndScroll.listenSafely((chart) => _window.update(() => chart)));
}

final _projection = ChartProjection(_window.width ~/ 2);
final _refresh = BehaviorSubject.seeded(DateTime.timestamp());
final _interval = BehaviorSubject.seeded(OhlcInterval.oneHour);

typedef _ChartData = (AssetPairData, List<OHLC>, OhlcInterval, DateTime);

String _renderChart(
  _ChartData input,
  OhlcInterval interval,
  int zoom,
  int scroll,
  DateTime refresh,
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

  final Buffer buffer = Buffer(width, height);
  buffer.fill(32);
  buffer.drawBuffer(0, 0, renderIntervalSelection(interval));
  buffer.drawBuffer(width - 20, 0, _zoomInfo(zoom));
  buffer.drawBuffer(0, 1, renderCanvas(chartWidth, chartHeight, snap, last));
  buffer.drawBuffer(0, height - 3, _loading(input, interval, refresh));
  buffer.drawBuffer(split, 0, renderPrices(pair, snap, height, last));
  buffer.drawBuffer(0, height - 2, renderTimeline(snap, width));

  return buffer.frame();
}

String _loading(_ChartData pdi, OhlcInterval i, DateTime refresh) {
  final intervalChange = pdi.$3 != i;
  final refreshOngoing = pdi.$4 != refresh;
  return intervalChange || refreshOngoing ? "loading..".blue() : "";
}

String _zoomInfo(int zoom) => "zoom $zoom/${_projection.maxZoom}".gray();
