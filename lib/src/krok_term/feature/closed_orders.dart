import '../common/window.dart';
import '../core/krok_core.dart';
import '../repository/krok_repos.dart';
import 'orders/orders_window.dart';

final _window = window("closed-orders", 80, 14) //
  ..flags = {
    WindowFlag.maximizable,
    WindowFlag.minimizable,
    WindowFlag.resizable
  }
  ..name = "Closed Orders [$ocKey]"
  ..position = AbsolutePosition(105, 15);

final _closedOrders = OrdersWindow(
    window: _window,
    input: closedOrders,
    topOff: 3,
    bottomOff: 8,
    refresh: () => closedOrdersRepo.refresh(userRequest: true));

void openClosedOrders() {
  autoWindow(_window, _closedOrders.create);
  desktop.stream().listen((e) {
    if (e case ('select-order', String id)) {
      _closedOrders.selectById(id);
    }
  });
}
