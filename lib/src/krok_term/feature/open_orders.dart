import 'package:dart_consul/dart_consul.dart';
import 'package:dart_minilog/dart_minilog.dart';

import '../common/window.dart';
import '../core/krok_core.dart';
import '../repository/krok_repos.dart';
import 'orders/orders_window.dart';

final _window = window("open-orders", 80, 9) //
  ..flags = {
    WindowFlag.maximizable,
    WindowFlag.minimizable,
    WindowFlag.resizable
  }
  ..name = "Open Orders [$ooKey]"
  ..position = AbsolutePosition(105, 4);

final _openOrders = OrdersWindow(
    window: _window,
    input: openOrders,
    topOff: 1,
    bottomOff: 4,
    refresh: () => openOrdersRepo.refresh(userRequest: true));

void openOpenOrders() => autoWindow(_window, () {
      _openOrders.create();
      _window.onKey('c',
          description: 'Cancel selected order', action: _cancelSelected);
      _window.onKey('<S-c>',
          description: 'Cancel all orders', action: _cancelAll);
    });

void _cancelSelected() {
  final o = _openOrders.selected;
  if (o == null) return;

  final msg = [
    'Please confirm order cancellation:',
    '',
    o.order(),
  ].join('\n');
  desktop.query(msg, (e) {
    if (e == QueryResult.positive) {
      logInfo("canceling ${o.id}");
      retrieve(KrakenRequest.cancelOrder(txid: o.id)).listenSafely((e) {
        closedOrdersRepo.refresh(userRequest: true);
        openOrdersRepo.refresh(userRequest: true);
      });
    }
  });
}

void _cancelAll() {
  if (_openOrders.isEmpty) return;

  final all = "ALL".bold().red();
  final msg = 'Please confirm cancellation of $all orders';
  desktop.query(msg, (e) {
    if (e == QueryResult.positive) {
      logInfo("canceling all orders");
      retrieve(KrakenRequest.cancelAll()).listenSafely((e) {
        closedOrdersRepo.refresh(userRequest: true);
        openOrdersRepo.refresh(userRequest: true);
      });
    }
  });
}
