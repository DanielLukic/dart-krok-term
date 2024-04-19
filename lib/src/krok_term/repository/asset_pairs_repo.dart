import '../core/krok_core.dart';
import 'auto_repo.dart';

final class AssetPairsRepo extends KrokAutoRepo<AssetPairs> {
  AssetPairsRepo(Storage storage)
      : super(
          storage,
          "asset_pairs",
          request: () => KrakenRequest.assetPairs(),
          preform: (e) => _preform(e),
          restore: (e) => _restore(e),
        );

  static JsonObject _preform(JsonObject data) => data
      .map((k, v) => MapEntry(k, (v as Map<String, dynamic>)..plus('pair', k)));

  static AssetPairs _restore(JsonObject result) =>
      result.map((k, v) => MapEntry(k, AssetPairData(v)));
}
