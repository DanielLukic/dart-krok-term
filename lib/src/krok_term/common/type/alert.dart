part of '../types.dart';

class AlertData extends BaseModel {
  final Asset pair;
  final String wsname;
  final double price;
  final String mode;

  AlertData(this.pair, this.wsname, this.price, this.mode)
      : assert(!pair.contains('/'), 'pair expected instead of wsname: $pair');

  @override
  List get fields => [pair, wsname, price, mode];
}
