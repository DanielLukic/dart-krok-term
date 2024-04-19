import '../core/krok_core.dart';
import 'auto_repo.dart';

final class PortfolioRepo extends KrokAutoRepo<PortfolioData> {
  PortfolioRepo(Storage storage)
      : super(
          storage,
          "portfolio",
          request: () => KrakenRequest.tradeBalance(),
          restore: (e) => _restore(e),
          duration: 1.minutes,
        );

  static PortfolioData _restore(JsonObject result) => PortfolioData(result);
}
