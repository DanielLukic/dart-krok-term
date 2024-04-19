part of '../types.dart';

class OrderData extends BaseModel {
  final OrderId id;
  final JsonObject data;

  @override
  List get fields => [data];

  OrderData(this.id, this.data);

  dynamic operator [](String key) => data[key];

  String pair() => data['descr']['pair'];

  String type() => data['descr']['type'];

  OrderType ordertype() {
    final name = data['descr']['ordertype'];
    return OrderType.values.singleWhere((e) => e.name == name);
  }

  // TODO handle trailingStop here?

  KrakenPrice price() =>
      KrakenPrice.fromString(data['descr']['price'], trailingStop: false);

  KrakenPrice price2() =>
      KrakenPrice.fromString(data['descr']['price2'], trailingStop: false);

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
