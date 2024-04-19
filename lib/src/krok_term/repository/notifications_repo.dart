import 'dart:async';
import 'dart:convert';

import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:rxdart/rxdart.dart' hide Notification;

class NotificationsRepo {
  NotificationsRepo(this._storage) {
    _running = _events.asyncMap((e) => _handle(e.$1, e.$2)).listen((e) {});
  }

  late final StreamSubscription _running;

  final _events = BehaviorSubject<(String, dynamic)>.seeded(('restore', null));
  final _data = BehaviorSubject<Notifications>();
  final _notifications = BehaviorSubject<Notification>();

  final Storage _storage;

  /// Stream of occurring notifications.
  Stream<Notification> get notifications => _notifications;

  /// Always latest list of all notifications.
  Stream<Notifications> subscribe() => _data;

  /// Persist a new notification, triggering a new event via [notifications].
  void add(Notification notification) {
    _notifications.add(notification);
    _events.add(('append', notification));
  }

  /// Used for testing only: Close down processing.
  Future close() async {
    _events.add(('close', null));
    await _running.asFuture();
  }

  Future<String> _handle(String event, dynamic argument) async {
    if (event == 'append') await _onAppend(argument);
    if (event == 'close') _onClose();
    if (event == 'restore') await _onRestore();
    return event;
  }

  Future<void> _onAppend(Notification argument) async {
    final json = jsonEncode(argument.fields);
    await _storage.append('notifications', '$json\n');
    _data.value = _data.value + [argument];
  }

  void _onClose() {
    _data.close();
    _notifications.close();
    _events.close();
  }

  Future<void> _onRestore() async {
    final lines = await _storage.lines('notifications');
    final maps = lines.map((e) => jsonDecode(e));
    final notifications = maps.map((e) => Notification.from(e));
    _data.value = notifications.toList();
  }
}
