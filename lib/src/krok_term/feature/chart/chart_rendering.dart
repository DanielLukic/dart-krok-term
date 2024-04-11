import 'dart:math';

import 'package:dart_consul/dart_consul.dart';
import 'package:krok/krok.dart';
import 'package:krok_term/src/krok_term/common/extensions.dart';

import '../../common/color_canvas.dart';
import '../../repository/asset_pairs_repo.dart';
import 'chart_snapshot.dart';

String renderTimeline(ChartSnapshot snapshot, int width) {
  final timeline = Buffer(width - 10, 2);
  timeline.drawBuffer(0, 0, "".padRight(timeline.width, "┈"));
  timeline.drawBuffer(0, 1, "".padRight(timeline.width, " "));
  timeline.drawBuffer(0, 1, snapshot.oldest);
  timeline.drawBuffer(timeline.width - 11, 1, snapshot.newest);
  return timeline.frame();
}

String renderIntervalSelection(OhlcInterval interval) => OhlcInterval.values
    .map((e) => e == interval ? e.label.inverse() : e.label)
    .join(" ");

String renderCanvas(
  int canvasWidth,
  int canvasHeight,
  ChartSnapshot snapshot,
) {
  final canvas = ColorCanvas(canvasWidth, canvasHeight);
  final normY = (1.0 / (snapshot.maxHigh - snapshot.minLow)) * canvas.height;
  final invertX = canvas.width - 1;
  final invertY = canvas.height - 1;
  final count = min(snapshot.length, canvas.width);
  for (var x = 0; x < count; x++) {
    final trend = snapshot.trend(x);
    final color = switch (trend) {
      1 => green,
      -1 => red,
      _ => null,
    };
    final yTop = (snapshot.highs[x] - snapshot.minLow) * normY;
    final yBottom = (snapshot.lows[x] - snapshot.minLow) * normY;
    for (var y = yBottom; y <= yTop; y++) {
      canvas.set(invertX - x, invertY - y.round(), color);
    }
  }
  return canvas.frame();
}

String renderPrices(AssetPairData pair, ChartSnapshot snapshot, int height) {
  final prices = Buffer(10, height);
  prices.fill(32);
  prices.drawBuffer(1, 1, pair.price(snapshot.maxHigh));
  prices.drawBuffer(1, prices.height - 3, pair.price(snapshot.minLow));
  prices.drawColumn(0, '┊');
  prices.set(0, prices.height - 2, '┘');
  prices.set(0, prices.height - 1, ' ');
  return prices.frame();
}
