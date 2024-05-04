import 'package:krok_term/src/krok_term/common/settings.dart';
import 'package:krok_term/src/krok_term/feature/orders/pick_order.dart';
import 'package:rxdart/rxdart.dart';

import '../../common/window.dart';
import '../../core/krok_core.dart';
import '../../repository/krok_repos.dart';
import 'orders_window.dart';

final _window = window("closed-orders", 80, 14) //
  ..flags = {
    WindowFlag.maximizable,
    WindowFlag.minimizable,
    WindowFlag.resizable
  }
  ..name = "Closed Orders [$ocKey] [/]"
  ..position = AbsolutePosition(105, 15);

final _closedOrders = OrdersWindow(
    window: _window,
    input: _data(),
    topOff: 3,
    bottomOff: 8,
    refresh: () => closedOrdersRepo.refresh(userRequest: true));

Stream<Orders> _data() =>
    settings.stream('hide_orders_id').switchMap((id) => closedOrders.map((o) {
          if (id == null) return o;

          final result = <String, OrderData>{};
          final ids = o.entries;
          for (final e in ids) {
            if (e.key == id) break;
            result[e.key] = e.value;
          }
          return result;
        }));

void openClosedOrders() {
  autoWindow(_window, () {
    _window.onKey('/', description: 'Filter by order id', action: pickOrder);

    _window.onKey('r',
        description: 'Reset hidden orders to show all', action: _resetOrders);
    _window.onKey('h',
        description: 'Hide orders up until selection', action: _hideOrders);
    _window.onKey('<S-h>',
        description: 'Hide closed orders up until now', action: _hideAllOrders);

    desktop.stream().listen((e) {
      if (e case ('select-order', String id)) {
        _closedOrders.selectById(id);
      }
    });

    return _closedOrders.create();
  });
}

_resetOrders() => settings.setSynced('hide_orders_id', null);

_hideOrders() =>
    settings.setSynced('hide_orders_id', _closedOrders.selected?.id);

_hideAllOrders() =>
    settings.setSynced('hide_orders_id', _closedOrders.first?.id);
