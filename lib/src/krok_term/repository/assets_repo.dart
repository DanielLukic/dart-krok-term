import '../core/krok_core.dart';
import 'auto_repo.dart';

typedef Assets = Map<Asset, AssetData>;

class AssetData {
  final String name;
  final String altname;
  final int decimals;
  final int display;

  final JsonObject _json;

  AssetData(JsonObject json)
      : _json = json,
        name = json['name'],
        altname = json['altname'],
        decimals = json['decimals'],
        display = json['display_decimals'];

  @override
  String toString() => _json.toString();
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
      .map((k, v) => MapEntry(k, (v as Map<String, dynamic>) + {'name': k}));

  static Assets _restore(JsonObject result) =>
      result.map((k, v) => MapEntry(k, AssetData(v)));
}
