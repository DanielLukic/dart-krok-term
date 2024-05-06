part of '../types.dart';

class EditOrder extends BaseModel {
  final OrderData od;
  final AssetPairData ap;

  OrderDirection get dir => od.direction();

  OrderType get type => od.ordertype();

  String get txid => od.data['txid'] ?? '';

  int? get userref => od.data['userref'];

  double? get volume => od.volume;

  String get price => od.price()?.toString() ?? '';

  String get limit => od.price2()?.toString() ?? '';

  EditOrder(this.od, this.ap);

  @override
  List get fields => [od.id, od.data];
}
