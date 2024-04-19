import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:krok_term/src/krok_term/repository/krok_repos.dart';
import 'package:rxdart/rxdart.dart';

startAlertTracking() {
  combine([alerts, tickers]).debounceTime(1.seconds).listen((event) {
    final alerts = event[0] as Alerts;
    final tickers = event[1] as Tickers;

    final fired = <AlertData>[];
    for (final entry in alerts.entries) {
      final ticks = tickers[entry.key];
      if (ticks == null) continue;

      for (final alert in entry.value) {
        if (alert.mode == 'above' && ticks.last > alert.price) {
          desktop.sendMessage(AlertTriggered(alert, ticks.last));
          fired.add(alert);
        }
        if (alert.mode == 'below' && ticks.last < alert.price) {
          desktop.sendMessage(AlertTriggered(alert, ticks.last));
          fired.add(alert);
        }
      }
    }

    for (final it in fired) {
      alertsRepo.remove(it);
    }
  });
}
