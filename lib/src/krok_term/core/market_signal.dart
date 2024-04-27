import 'package:signals_core/signals_core.dart';

enum MarketSignal {
  buy,
  buyBuy,
  sell,
  sellSell,
  unavailable,
  undecided,
}

final marketSignal = signal(MarketSignal.unavailable);
