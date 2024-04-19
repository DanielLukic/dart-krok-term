import '../core/krok_core.dart';
import 'auto_repo.dart';

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
