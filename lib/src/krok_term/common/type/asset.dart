part of '../types.dart';

class AssetData extends BaseModel {
  final String name;
  final String altname;
  final int decimals;
  final int display;

  @override
  List get fields => [name, altname, decimals, display];

  AssetData(JsonObject json)
      : name = json['name'],
        altname = json['altname'],
        decimals = json['decimals'],
        display = json['display_decimals'];

  AssetData.from(this.name, this.altname, this.decimals, this.display);
}
