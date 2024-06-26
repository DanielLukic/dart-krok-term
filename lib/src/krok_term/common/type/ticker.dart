part of '../types.dart';

class TickerData extends BaseModel {
  final Pair pair;
  final Price ask;
  final Price bid;
  final Price last;
  final double volumeToday;
  final double volumeLast24;
  final Price priceToday;
  final Price priceLast24;
  final int tradesToday;
  final int tradesLast24;
  final Price lowToday;
  final Price lowLast24;
  final Price highToday;
  final Price highLast24;
  final Price opening;

  @override
  List get fields => [
        pair, ask, bid, last, volumeToday, volumeLast24, priceToday, //
        priceLast24, tradesToday, tradesLast24, lowToday, lowLast24, //
        highToday, highLast24, opening
      ];

  TickerData(this.pair, JsonObject json)
      : ask = double.parse(json['a'][0]),
        bid = double.parse(json['b'][0]),
        last = double.parse(json['c'][0]),
        volumeToday = double.parse(json['v'][0]),
        volumeLast24 = double.parse(json['v'][1]),
        priceToday = double.parse(json['p'][0]),
        priceLast24 = double.parse(json['p'][1]),
        tradesToday = json['t'][0],
        tradesLast24 = json['t'][0],
        lowToday = double.parse(json['l'][0]),
        lowLast24 = double.parse(json['l'][1]),
        highToday = double.parse(json['h'][0]),
        highLast24 = double.parse(json['h'][1]),
        opening = double.parse(json['o']);

  double get percent {
    final p = priceToday / priceLast24 * 100 - 100;
    if (p.isInfinite || p.isNaN) return 0;
    return p;
  }

  String get ansiPercent {
    final p = percent;
    final pp = "${p.toStringAsFixed(2)}%";
    return switch (p) {
      _ when p < 0 => pp.red(),
      _ when p > 0 => pp.green(),
      _ => pp,
    };
  }
}
