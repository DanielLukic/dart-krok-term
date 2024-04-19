part of '../types.dart';

class BalanceData extends BaseModel {
  final Asset asset;
  final double volume;

  @override
  List get fields => [asset, volume];

  BalanceData(this.asset, this.volume);
}
