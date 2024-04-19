import '../core/krok_core.dart';
import 'auto_repo.dart';

final class OpenOrdersRepo extends KrokAutoRepo<Orders> {
  OpenOrdersRepo(Storage storage)
      : super(
          storage,
          "open_orders",
          request: () => KrakenRequest.openOrders(),
          preform: (e) => e['open'],
          restore: (e) => _restore(e),
          duration: 1.minutes,
        );

  static Orders _restore(JsonObject result) =>
      result.map((k, v) => MapEntry(k, OrderData(k, v)));
}

final class ClosedOrdersRepo extends KrokAutoRepo<Orders> {
  ClosedOrdersRepo(Storage storage)
      : super(
          storage,
          "closed_orders",
          request: () => KrakenRequest.closedOrders(),
          preform: (e) => e['closed'],
          restore: (e) => _restore(e),
          duration: 1.minutes,
        );

  static Orders _restore(JsonObject result) =>
      result.map((k, v) => MapEntry(k, OrderData(k, v)));
}
