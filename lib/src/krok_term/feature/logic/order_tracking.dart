import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:krok_term/src/krok_term/repository/krok_repos.dart';
import 'package:rxdart/rxdart.dart';

import '../notifications.dart';

startOrderTracking() {
  var seenOpen = <OrderData>[];
  combine([openOrders, closedOrders]).debounceTime(100.millis).listen((e) {
    final Orders closed = e[1];
    final gotClosed = seenOpen.where((e) => closed.keys.contains(e.id));
    for (final o in gotClosed.unique()) {
      final c = closed[o.id];
      if (c != null) _notifyOrder(c);
    }
    final Orders open = e[0];
    seenOpen = List.from(open.values);
  });
}

void _notifyOrder(OrderData o) {
  var status = o.status();
  if (status == "closed") status = "executed";
  final header = "Order $status";
  final description = o.order();
  onNotification(
      NotificationData.now(header, description, ('select-order', o.id)));
}
