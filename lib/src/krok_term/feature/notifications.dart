import 'package:krok_term/src/krok_term/common/auto_hide.dart';
import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:krok_term/src/krok_term/repository/krok_repos.dart';
import 'package:rxdart/rxdart.dart' hide Notification;

import '../common/window.dart';

/// The idea is to have a dedicated log for all important notifications.
/// Triggered alerts, triggered orders and completed orders. Canceled orders,
/// potentially, if not canceled by user. This class has to be fed notifications
/// as events. It will then generate desktop notifications and log everything.

void onNotification(NotificationData it) => notificationsRepo.add(it);

final _window = window("notifications", 129, 7) //
  ..name = "Notifications [$nKey]"
  ..position = AbsolutePosition(56, 31);

void openNotifications() => autoWindow(_window, _create);

final initial =
    notifications.take(1).flatMap((value) => Stream.fromIterable(value));

final updates = notificationsRepo.notifications;

void _create() {
  _listed = ListWindow(
    window: _window,
    topOff: 2,
    bottomOff: 2,
    onSelect: (e) => _onSelect(e),
  );

  _window.addAutoHide('a', 'notifications', hideByDefault: false);

  _window.autoDispose("update",
      ConcatStream([initial, updates]).listen((e) => _updateResult(e)));

  _window.autoDispose("notifications", updates.listen((e) => _show(e)));
}

void _onSelect(int index) {
  if (index < 0 || index >= _list.length) return;
  desktop.sendMessage(_list[index].onClickMsg);
}

late final ListWindow _listed;
List<NotificationData> _list = [];

_updateResult(NotificationData it) {
  _list.insert(0, it);
  _listed.updateEntries(_list.mapList((e) => e.toLogString()));
  _window.requestRedraw();
}

_show(NotificationData it) {
  desktop.notify(it.toDesktopNotification());
}

extension on NotificationData {
  DesktopNotification toDesktopNotification() {
    final ts = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
    final tag = ts.toLocal().toAutoStamp();
    return DesktopNotification(header, tag, description, onClickMsg);
  }
}
