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

void _create() {
  _window.setupKeys();
  _window.setupMouse();

  Stream<_PairDataInterval> retrieve(AssetPairData s, OhlcInterval i) =>
      ohlc(s, i).map((list) => (s, list, i));

  final chartData = combine([selectedAssetPair, _interval])
      .distinctUntilChanged()
      .switchMap((e) => retrieve(e[0], e[1]))
      .doOnData((e) => _projection.setDataSize(e.$2.length));

  final withZoomAndScroll =
      combine([chartData, _interval, _projection.zoom, _projection.scroll])
          .distinctUntilChanged()
          .map((e) => _renderChart(e[0], e[1], e[2], e[3]));

  _window.autoDispose("update",
      withZoomAndScroll.listenSafely((chart) => _window.update(() => chart)));
}

final _projection = ChartProjection(_window.width ~/ 2);
final _refresh = BehaviorSubject.seeded(DateTime.timestamp());
final _interval = BehaviorSubject.seeded(OhlcInterval.oneHour);

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

  final width = _window.width;
  final height = _window.height;

  final canvasWidth = (width - 10) * 2;
  final canvasHeight = (height - 3) * 4;

  final snapshot = _sample(data, zoom, scroll, canvasWidth);

  final Buffer buffer = Buffer(width, height);
  buffer.fill(32);
  buffer.drawBuffer(0, 0, renderIntervalSelection(interval));
  buffer.drawBuffer(0, 1, renderCanvas(canvasWidth, canvasHeight, snapshot));
  buffer.drawBuffer(width - 10, 0, renderPrices(pair, snapshot, height));
  buffer.drawBuffer(0, height - 2, renderTimeline(snapshot, width));

  final sl = buffer.height - 3;
  final zl = buffer.height - 4;
  buffer.drawBuffer(0, sl, "scroll $scroll of ${_projection.maxScroll}".gray());
  buffer.drawBuffer(0, zl, "zoom $zoom of ${_projection.maxZoom}".gray());
  if (pdi.$3 != interval) buffer.drawBuffer(0, 1, "loading...");

  return buffer.frame();
}
