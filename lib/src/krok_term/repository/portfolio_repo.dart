import '../core/krok_core.dart';
import 'auto_repo.dart';

final class PortfolioRepo extends KrokAutoRepo<Portfolio> {
  PortfolioRepo(Storage storage)
      : super(
          storage,
          "portfolio",
          request: () => KrakenRequest.tradeBalance(),
          restore: (e) => _restore(e),
          duration: 1.minutes,
        );

  static Portfolio _restore(JsonObject result) => Portfolio(result);
}
