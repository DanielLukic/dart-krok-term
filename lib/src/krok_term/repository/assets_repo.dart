import '../core/krok_core.dart';
import 'auto_repo.dart';

typedef Assets = Map<Asset, AssetData>;

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

final class AssetsRepo extends KrokAutoRepo<Assets> {
  AssetsRepo(Storage storage)
      : super(
          storage,
          "assets",
          request: () => KrakenRequest.assets(),
          preform: (e) => _preform(e),
          restore: (e) => _restore(e),
        );

  static JsonObject _preform(JsonObject data) => data
      .map((k, v) => MapEntry(k, (v as Map<String, dynamic>)..plus('name', k)));

  static Assets _restore(JsonObject result) =>
      result.map((k, v) => MapEntry(k, AssetData(v)));
}
