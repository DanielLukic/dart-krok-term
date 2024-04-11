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
  timeline.drawBuffer(0, 1, snapshot.oldestDate);
  timeline.drawBuffer(timeline.width - 11, 1, snapshot.newestDate);
  return timeline.frame();
}

String renderIntervalSelection(OhlcInterval interval) => OhlcInterval.values
    .map((e) => e == interval ? e.label.inverse() : e.label)
    .join(" ");

String renderCanvas(
  int canvasWidth,
  int canvasHeight,
  ChartSnapshot snapshot,
  OHLC latest,
) {
  final canvas = ColorCanvas(canvasWidth, canvasHeight);
  final invertX = canvasWidth - 1;
  final invertY = canvasHeight - 1;

  final line = snapshot.scaled(latest.close, canvasHeight);
  final trendColor = _trendColor(latest.open - latest.close);
  for (var x = 0; x < canvasWidth; x++) {
    canvas.set(invertX - x, invertY - line, trendColor);
  }

  final count = min(snapshot.length, canvas.width);
  for (var x = 0; x < count; x++) {
    final color = snapshot.trendColorAt(x);
    final yTop = snapshot.scaledHighAt(x, canvasHeight);
    final yBottom = snapshot.scaledLowAt(x, canvasHeight);
    for (var y = yBottom; y <= yTop; y++) {
      canvas.set(invertX - x, invertY - y.round(), color);
    }
  }
  return canvas.frame();
}

CanvasColor _trendColor(double delta) => switch (delta) {
      _ when delta > 0 => green,
      _ when delta < 0 => red,
      _ => (e) => e,
    };

extension on ChartSnapshot {
  CanvasColor trendColorAt(int index) => _trendColor(trendAt(index));

  double trendAt(int at) => closes[at] - opens[at];

  int scaled(double price, int height) =>
      ((price - minLow) * norm * height + 1).round();

  int scaledHighAt(int index, int height) => scaled(highs[index], height);

  int scaledLowAt(int index, int height) => scaled(lows[index], height);

  int scaledCloseAt(int index, int height) => scaled(closes[index], height);
}

String renderPrices(
  AssetPairData pair,
  ChartSnapshot snapshot,
  int height,
  OHLC last,
) {
  final latestColor = _trendColor(last.close - last.open);
  final latest = latestColor(pair.price(last.close));
  final latestY = snapshot.scaled(last.close, height - 3).clamp(1, height - 3);

  final currentColor = snapshot.trendColorAt(0);
  final current = currentColor(pair.price(snapshot.closes[0]));
  final currentY = snapshot.scaledCloseAt(0, height - 3).clamp(1, height - 3);

  final high = pair.price(snapshot.maxHigh);
  final low = pair.price(snapshot.minLow);

  final prices = Buffer(10, height);
  prices.fill(32);
  prices.drawBuffer(1, 0, high);
  prices.drawBuffer(1, height - 2 - currentY, current);
  prices.drawBuffer(1, height - 2 - latestY, latest);
  prices.drawBuffer(1, height - 2, low);
  prices.drawColumn(0, '┊');
  prices.set(0, height - 2, '┘');
  prices.set(0, height - 1, ' ');
  return prices.frame();
}
