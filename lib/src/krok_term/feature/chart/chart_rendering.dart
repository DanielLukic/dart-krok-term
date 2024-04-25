import 'dart:math';

import 'package:dart_consul/dart_consul.dart';
import 'package:krok/krok.dart';
import 'package:krok_term/src/krok_term/common/extensions.dart';
import 'package:termlib/termlib.dart';

import '../../common/types.dart';
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
  OhlcData latest,
  double selected,
  List<AlertData> alerts,
  (Orders, Orders) orders,
) {
  final canvas = ColorCanvas(canvasWidth, canvasHeight);
  final invertX = canvasWidth - 1;
  final invertY = canvasHeight - 1;

  drawPriceLine(double price, CanvasColor color) =>
      canvas.drawLine(snapshot.scaled(price, canvasHeight), color);

  for (final alert in alerts) {
    drawPriceLine(alert.price, gray);
  }
  drawPriceLine(latest.close, _trendColor(latest.open - latest.close));
  if (selected > 0) drawPriceLine(selected, blue);

  final count = min(snapshot.length, canvas.width);
  for (var x = 0; x < count; x++) {
    final color = snapshot.trendColorAt(x);
    final yTop = snapshot.scaledHighAt(x, canvasHeight);
    final yBottom = snapshot.scaledLowAt(x, canvasHeight);
    for (var y = yBottom; y <= yTop; y++) {
      canvas.set(invertX - x, invertY - y.round(), color);
    }
  }

  final closed = orders.$2.values;
  for (var x = 0; x < count; x++) {
    final co = closed.where((e) => snapshot.inTime(x, e.d('closetm')));
    for (final o in co.take(1)) {
      final p = o.d('price');
      final y = snapshot.scaled(p, canvasHeight);
      final color = o.type() == 'sell' ? _sellColor : _buyColor;
      for (var dx = 0; dx < 8; dx++) {
        canvas.set(invertX - x - dx, invertY - y.round(), color);
      }
    }
  }

  final open = orders.$1.values;
  for (final o in open) {
    final p1 = o.resolvePriceAgainst(latest.close);
    final p2 = o.resolvePrice2Against(latest.close);
    final p = p2 ?? p1;
    if (p == null) continue;
    final y = snapshot.scaled(p, canvasHeight);

    final color = o.type() == 'sell' ? _sellColor : _buyColor;
    for (var x = 0; x < 4; x++) {
      canvas.set(x, invertY - y.round(), color);
    }
  }

  return canvas.frame();
}

extension on ColorCanvas {
  drawLine(int y, CanvasColor color) {
    for (var x = 0; x < width; x++) {
      set(x, height - 1 - y, color);
    }
  }
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
      ((price - minLow) * norm * 0.95 * height + 1).round().clamp(-1, height);

  int scaledHighAt(int index, int height) => scaled(highs[index], height);

  int scaledLowAt(int index, int height) => scaled(lows[index], height);

  int scaledCloseAt(int index, int height) => scaled(closes[index], height);

  bool inTime(int index, double time) {
    if (index < 0 || index >= times.length) return false;
    if (index == times.length - 1) return false;
    final a = times[index];
    final b = times[index + 1];
    final delta = a - b;
    if ((time - a).abs() < delta / 3) return true;
    if ((time - b).abs() < delta / 3) return true;
    return a >= time && time >= b;
  }
}

String renderPrices(
  AssetPairData pair,
  ChartSnapshot snapshot,
  int height,
  OhlcData last,
  double sp,
  List<AlertData> alerts,
  bool fixed,
) {
  final scaleHeight = height - 3;

  // pure madness :-D

  final latestColor = _trendColor(last.close - last.open);
  final latest = latestColor(pair.price(last.close));
  final latestY = snapshot.scaled(last.close, scaleHeight);

  final currentColor = snapshot.trendColorAt(0);
  final current = currentColor(pair.price(snapshot.closes[0]));
  final currentY = snapshot.scaledCloseAt(0, scaleHeight);

  final selectedColor = blue;
  final selected = selectedColor(pair.price(sp));
  final selectedY = snapshot.scaled(sp, scaleHeight);

  var high = pair.price(snapshot.maxHigh);
  var low = pair.price(snapshot.minLow);
  final showCurrent = snapshot.closes[0] > 0;
  final showSelected = sp > 0;

  if (fixed) {
    high = high.inverse();
    low = low.inverse();
  }

  final prices = Buffer(10, height);
  prices.fill(32);
  prices.drawBuffer(1, 0, high);
  prices.drawBuffer(1, height - 2, low);

  for (final alert in alerts) {
    final ap = gray(pair.price(alert.price));
    final ay = snapshot.scaled(alert.price, scaleHeight);
    prices.drawBuffer(1, height - 2 - ay, ap);
  }

  if (showCurrent) prices.drawBuffer(1, height - 2 - currentY, current);
  prices.drawBuffer(1, height - 2 - latestY, latest);
  if (showSelected) prices.drawBuffer(1, height - 2 - selectedY, selected);
  prices.drawColumn(0, '┊');
  prices.set(0, height - 2, '┘');
  prices.set(0, height - 1, ' ');
  return prices.frame();
}

String _sellColor(e) {
  final s = Style(e, profile: ProfileEnum.trueColor)
    ..blink()
    ..fg(TrueColor(128, 0, 0));
  return s.toString();
}

String _buyColor(e) {
  final s = Style(e, profile: ProfileEnum.trueColor)
    ..blink()
    ..fg(TrueColor(0, 128, 0));
  return s.toString();
}
