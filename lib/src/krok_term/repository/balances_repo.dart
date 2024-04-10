import '../core/krok_core.dart';
import 'auto_repo.dart';

typedef Balances = Map<Asset, BalanceData>;

class BalanceData {
  final Asset asset;
  final double volume;

  BalanceData(this.asset, this.volume);

  @override
  int get hashCode => Object.hash(asset, volume);

  @override
  bool operator ==(Object other) {
    if (other is! BalanceData) return false;
    return asset == other.asset && volume == other.volume;
  }

  @override
  String toString() => "{asset: $asset, volume: $volume}";
}

final class BalancesRepo extends KrokAutoRepo<Balances> {
  BalancesRepo(Storage storage)
      : super(
          storage,
          "balances",
          request: () => KrakenRequest.balance(),
          restore: (e) => _restore(e),
          duration: 1.minutes,
        );

  static Balances _restore(JsonObject result) =>
      result.map((k, v) => MapEntry(k, BalanceData(k, double.parse(v))));
}
