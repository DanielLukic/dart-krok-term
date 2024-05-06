part of '../types.dart';

class OrderData extends BaseModel {
  final OrderId id;
  final JsonObject data;

  @override
  List get fields => [data];

  OrderData(this.id, this.data);

  dynamic operator [](String key) => data[key];

  double? get volume => double.tryParse(data['vol']);

  String pair() => data['descr']['pair'];

  String status() => s('status');

  OrderDirection direction() {
    final dir = data['descr']['type'];
    return OrderDirection.values.singleWhere((e) => e.name == dir);
  }

  String type() => data['descr']['type'];

  OrderType ordertype() {
    final name = data['descr']['ordertype'];
    return OrderType.values.singleWhere((e) => e.name == name);
  }

  // TODO handle trailingStop here?

  String? get _price => data['descr']['price'];

  String? get _price2 => data['descr']['price2'];

  bool _isTrailingPrice(String? p) =>
      ordertype().name.startsWith('trailing') &&
      p?.startsWith(_trailingPrefixes) == true;

  final _trailingPrefixes = RegExp(r'[-+#]');

  KrakenPrice? price() {
    final String? price = _price;
    if (price == null || price == '0') return null;
    final trailing = _isTrailingPrice(price);
    try {
      return KrakenPrice.fromString(price, trailingStop: trailing);
    } catch (it, t) {
      logError('$price of $id (trailing? $trailing): $it', t);
      return null;
    }
  }

  KrakenPrice? price2() {
    final price2 = data['descr']['price2'];
    if (price2 == null || price2 == '0') return null;
    final trailing = _isTrailingPrice(price2);
    try {
      return KrakenPrice.fromString(price2, trailingStop: trailing);
    } catch (it, t) {
      logError('$price2 of $id: $it (trailing? $trailing)', t);
      return null;
    }
  }

  double? resolvePriceAgainst(double latest) =>
      resolve(direction(), price(), latest, price1: true);

  double? resolvePrice2Against(double? latest) =>
      resolve(direction(), price2(), latest, price1: false);

  static double? resolve(
    OrderDirection type,
    KrakenPrice? price,
    double? latest, {
    required bool price1,
  }) {
    if (price == null || latest == null || latest == 0) return null;

    final p = price;
    if (p.it == '0') return null;

    var dir = type == OrderDirection.sell ? -1 : 1;
    final percent = p.percentage;
    final v = percent ? latest * p.value / 100 : p.value;

    if (p.trailingStopPrice) {
      if (price1) {
        if (p.it.startsWith('+')) {
          return latest + v * dir;
        } else {
          throw ArgumentError('trailing stop price without +: ${p.it}');
        }
      } else if (p.it.startsWith('+')) {
        return latest + v;
      } else if (p.it.startsWith('-')) {
        return latest - v;
      } else {
        throw ArgumentError('trailing stop limit without + or -: ${p.it}');
      }
    } else if (p.it.startsWith('+')) {
      return latest + v;
    } else if (p.it.startsWith('-')) {
      return latest - v;
    } else if (p.it.startsWith('#')) {
      // TODO type
      return latest + v * dir;
    } else {
      return v;
    }
  }

  String leverage() => data['descr']['leverage'];

  String order() => data['descr']['order'];

  String close() => data['descr']['close'];

  double d(String key) {
    final i = data[key];
    if (i is double) return i;
    if (i is int) return i.toDouble();
    return double.parse(i.toString());
  }

  double? d_(String key) {
    final i = data[key];
    if (i == null) return null;
    if (i is double) return i;
    if (i is int) return i.toDouble();
    return double.parse(i.toString());
  }

  int i(String key) => data[key] as int;

  String s(String key) => data[key] as String;

  String? s_(String key) => data[key] != null ? data[key] as String : null;

  DateTime dt(String key) => d(key).toKrakenDateTime();

  DateTime? dt_(String key) => d_(key)?.toKrakenDateTime();
}
