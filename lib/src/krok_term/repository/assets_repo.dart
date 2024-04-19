import '../core/krok_core.dart';
import 'auto_repo.dart';

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
