import '../core/krok_core.dart';
import 'auto_repo.dart';

class Portfolio extends BaseModel {
  final JsonObject _json;

  double get eb => double.parse(_json['eb']);
  double get tb => double.parse(_json['tb']);
  double get m => double.parse(_json['m']);
  double get uv => double.parse(_json['uv']);
  double get n => double.parse(_json['n']);
  double get c => double.parse(_json['c']);
  double get v => double.parse(_json['v']);
  double get e => double.parse(_json['e']);
  double get mf => double.parse(_json['mf']);

  @override
  List get fields => [_json];

  Portfolio(this._json);
}

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
