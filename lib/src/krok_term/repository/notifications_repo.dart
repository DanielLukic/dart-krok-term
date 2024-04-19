import 'dart:async';
import 'dart:convert';

import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:rxdart/rxdart.dart';

typedef Notifications = List<Notification>;

/*
  +--------------------------+
  | WIF/USD         10:55:12 |
  | Price below 2.0:     1.9 |
  +--------------------------+
  +--------------------------+
  | Order executed  10:55:12 |
  | SELL 10 WIF/USD @ 2.5    |
  | TRAILING STOP 3%         |
  +--------------------------+
 */

class Notification extends BaseModel {
  final int timestamp;

  /// WSNAME for alerts, 'Order executed' or 'Order canceled' for orders:
  final String header;

  /// "Price [below/above] <price>: <price>" for alerts, "BUY ..." for orders:
  final String description;

  /// Message to be sent when notification is clicked.
  /// ("select-pair", "WIF/USD") for alerts.
  /// ("select-order", "ORDER-ID-XXX") for orders.
  final (String, String) onClickMsg;

  Notification(this.timestamp, this.header, this.description, this.onClickMsg);

  Notification.now(this.header, this.description, this.onClickMsg)
      : timestamp = DateTime.timestamp().millisecondsSinceEpoch;

  Notification.from(List<dynamic> json)
      : this(json[0], json[1], json[2], (json[3], json[4]));

  @override
  List get fields =>
      [timestamp, header, description, onClickMsg.$1, onClickMsg.$2];

  String toLogString() {
    final ts = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
    return "${ts.toLocal().toLongStamp()} $header $description";
  }
}

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
