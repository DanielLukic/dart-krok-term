import 'package:dart_minilog/dart_minilog.dart';
import 'package:krok/extensions.dart';
import 'package:krok_term/src/krok_term/repository/notifications_repo.dart';
import 'package:rxdart/subjects.dart';
import 'package:rxdart/transformers.dart';

import '../core/krok_core.dart';
import 'asset_pairs_repo.dart';

class AlertTriggered extends BaseModel {
  final AlertData alert;
  final Price trigger;

  AlertTriggered(this.alert, this.trigger);

  @override
  List get fields => [alert, trigger];

  Notification asNotification() => Notification.now(
        alert.pair,
        "price ${alert.mode} ${alert.price}: "
        "$trigger",
        ('select-pair', alert.pair),
      );
}

class AlertAdd extends BaseModel {
  final AssetPairData pair;
  double selectedPrice;
  double lastPrice;
  double refPrice = 0;
  String? presetPrice;
  String label = 'unknown';

  AlertAdd(this.pair, this.selectedPrice, this.lastPrice) {
    final sp = selectedPrice.takeIf(selectedPrice > 0);
    if (sp != null) {
      refPrice = sp;
      label = 'selected';
      presetPrice = sp.let((it) => pair.price(it));
      return;
    }

    final lp = lastPrice.takeIf(lastPrice > 0);
    if (lp != null) {
      refPrice = lp;
      label = "last";
      presetPrice = presetPrice ?? lp.let((it) => pair.price(it));
      return;
    }
  }

  @override
  List get fields => [pair, selectedPrice, lastPrice, presetPrice];
}

typedef Alerts = Map<Asset, List<AlertData>>;

class AlertData extends BaseModel {
  final Asset pair;
  final double price;
  final String mode;

  AlertData(this.pair, this.price, this.mode)
      : assert(!pair.contains('/'), 'pair expected instead of wsname: $pair');

  @override
  List get fields => [pair, price, mode];
}

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
        'remove' => _remove(alerts, command.$2),
        _ => alerts,
      };

  Stream<Alerts> subscribe() => _cache;

  void add(AlertData alert) => _events.add(('add', alert));

  void remove(AlertData alert) => _events.add(('remove', alert));

  void addAlert(Asset pair, double price, String mode) =>
      add(AlertData(pair, price, mode));

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
        list.mapList((ad) => AlertData(ad[0], ad[1], ad[2]));
    return json.mapValues((list) => fromJson(list));
  }
}

extension<E> on List<E>? {
  List<E> clone() => List<E>.from(this ?? []);
}

extension<K, V> on Map<K, V> {
  void put(K k, V v) => this[k] = v;
}
