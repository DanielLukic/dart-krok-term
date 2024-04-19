import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:krok_term/src/krok_term/repository/krok_repos.dart';
import 'package:rxdart/rxdart.dart' hide Notification;

import '../common/desktop.dart';
import '../common/types.dart';
import '../common/window.dart';

/// The idea is to have a dedicated log for all important notifications.
/// Triggered alerts, triggered orders and completed orders. Canceled orders,
/// potentially, if not canceled by user. This class has to be fed notifications
/// as events. It will then generate desktop notifications and log everything.

void onNotification(NotificationData it) => notificationsRepo.add(it);

final _window = window("notifications", 129, 10) //
  ..name = "Notifications [$nKey]"
  ..position = AbsolutePosition(56, 31);

void openNotifications() => autoWindow(_window, _create);

final initial =
    notifications.take(1).flatMap((value) => Stream.fromIterable(value));

final updates = notificationsRepo.notifications;

void _create() {
  scrolled(_window, () => _buffer);
  _window.autoDispose("update",
      ConcatStream([initial, updates]).listen((e) => _updateResult(e)));
  _window.autoDispose("notifications", updates.listen((e) => _show(e)));
}

List<NotificationData> _list = [];
String _buffer = "";

_updateResult(NotificationData it) {
  _list.insert(0, it);
  _buffer = _list.map((e) => e.toLogString()).join('\n');
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
