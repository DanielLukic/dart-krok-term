import '../core/krok_core.dart';
import '../core/selected_pair.dart';
import 'auto_repo.dart';

typedef AssetPairs = Map<Pair, AssetPairData>;

class AssetPairData extends BaseModel {
  final Pair pair;
  final String altname;
  final String wsname;
  final String base;
  final String quote;
  final int cost_decimals;
  final int pair_decimals;
  final int lot_decimals;
  final double ordermin;
  final double costmin;

  @override
  List get fields => [
        pair, altname, wsname, base, quote, cost_decimals, pair_decimals, //
        lot_decimals, ordermin, costmin
      ];

  AssetPairData(JsonObject json)
      : pair = json['pair'],
        altname = json['altname'],
        wsname = json['wsname'],
        base = json['base'],
        quote = json['quote'],
        cost_decimals = json['cost_decimals'],
        pair_decimals = json['pair_decimals'],
        lot_decimals = json['lot_decimals'],
        ordermin = double.parse(json['ordermin']),
        costmin = double.parse(json['costmin']);

  AssetPair get ap => AssetPair.fromWsName(wsname);

  String price(double price) => price.toStringAsFixed(pair_decimals);
}

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
      .map((k, v) => MapEntry(k, (v as Map<String, dynamic>) + {'pair': k}));

  static AssetPairs _restore(JsonObject result) =>
      result.map((k, v) => MapEntry(k, AssetPairData(v)));
}
