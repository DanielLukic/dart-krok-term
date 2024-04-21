part of '../types.dart';

class PlaceOrder extends BaseModel {
  final AssetPairData pair;
  final double price;
  final OrderDirection dir;
  final OrderType type;

  double get limit => dir == OrderDirection.buy ? price * 1.025 : price * 0.975;

  PlaceOrder(
    this.pair,
    this.price, {
    OrderDirection? dir,
    OrderType? type,
  })  : dir = dir ?? OrderDirection.buy,
        type = type ?? OrderType.market;

  @override
  List get fields => [pair, price, dir, type];
}
