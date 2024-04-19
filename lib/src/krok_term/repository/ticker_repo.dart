import '../core/krok_core.dart';
import 'auto_repo.dart';

final class TickersRepo extends KrokAutoRepo<Tickers> {
  TickersRepo(Storage storage)
      : super(
          storage,
          "tickers",
          request: () => KrakenRequest.ticker(),
          restore: (e) => _restore(e),
          duration: 1.minutes,
        );

  static Tickers _restore(JsonObject result) =>
      result.map((k, v) => MapEntry(k, TickerData(k, v)));
}
