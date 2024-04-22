import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:krok_term/src/krok_term/repository/krok_repos.dart';
import 'package:rxdart/rxdart.dart';

import '../notifications.dart';

startOrderTracking() {
  OrderId seen = '';
  closedOrders.debounceTime(100.millis).listen((closed) {
    if (seen.isNotEmpty) {
      final todo = closed.keys.takeWhile((e) => e != seen);
      for (final o in todo) {
        closed[o]?.let(_notifyOrder);
      }
    }
    seen = closed.keys.firstOrNull ?? '';
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
