import 'package:dart_minilog/dart_minilog.dart';
import 'package:krok/extensions.dart';
import 'package:rxdart/subjects.dart';
import 'package:rxdart/transformers.dart';

import '../core/krok_core.dart';

final class AlertsRepo {
  final Storage _storage;

  AlertsRepo(this._storage);

  late final _events =
      BehaviorSubject<(String, dynamic)>.seeded(('restore', Alerts()));

  late final _cache = _events
      .asyncMap((e) async => await _asyncRestore(e))
      .scan(_update, Alerts())
      .asyncMap((e) async => await _asyncSave(e));

  Alerts _update(Alerts alerts, (String, dynamic) command, int _) =>
      switch (command.$1) {
        'restore' => command.$2,
        'add' => _add(alerts, command.$2),
        'clear' => Alerts.from({}),
        'remove' => _remove(alerts, command.$2),
        _ => alerts,
      };

  Stream<Alerts> subscribe() => _cache;

  void add(AlertData alert) => _events.add(('add', alert));

  void clear() => _events.add(('clear', null));

  void remove(AlertData alert) => _events.add(('remove', alert));

  Alerts _add(Alerts alerts, AlertData alert) {
    final entries = alerts[alert.pair].clone();
    if (!entries.contains(alert)) entries.add(alert);
    return Alerts.from(alerts)..put(alert.pair, entries);
  }

  Alerts _remove(Alerts alerts, AlertData alert) {
    final entries = alerts[alert.pair].clone();
    if (entries.contains(alert)) entries.remove(alert);
    return Alerts.from(alerts)..put(alert.pair, entries);
  }

  Future<(String, dynamic)> _asyncRestore(e) async => switch (e.$1) {
        'restore' => ('restore', await _restore(_storage.load('alerts'))),
        _ => e,
      };

  Future<Alerts> _asyncSave(Alerts e) async {
    await _storage.save('alerts', _toJson(e));
    return e;
  }

  Map<Asset, dynamic> _toJson(Alerts alerts) {
    List toJson(AlertData ad) => ad.fields;
    return alerts.mapValues((list) => list.mapList((alert) => toJson(alert)));
  }

  Future<JsonObject> _restore(Future<JsonObject?> data) async {
    try {
      return _fromJson(await data ?? {});
    } catch (e) {
      logError('failed restoring alerts - ignored: $e');
      return Alerts();
    }
  }

  Alerts _fromJson(JsonObject json) {
    fromJson(List<dynamic> list) =>
        list.mapList((ad) => AlertData(ad[0], ad[1], ad[2], ad[3]));
    return json.mapValues((list) => fromJson(list));
  }
}

extension<E> on List<E>? {
  List<E> clone() => List<E>.from(this ?? []);
}

extension<K, V> on Map<K, V> {
  void put(K k, V v) => this[k] = v;
}
