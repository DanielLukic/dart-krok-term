import 'dart:async';
import 'dart:convert';

import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:rxdart/rxdart.dart' hide Notification;

enum BotType {
  autoTrader,
  dipper,
  simpleTrader,
}

typedef BotUserref = int;
typedef Bots = List<BotData>;

class BotData extends BaseModel {
  final BotType type;
  final BotUserref userref;
  final JsonObject data;

  BotData(this.type, this.userref, this.data);

  BotData.from(List<dynamic> json) : this(toBotType(json[0]), json[1], json[2]);

  @override
  List get fields => [type, userref, data];

  String toJson() => jsonEncode([type.name, userref, data]);

  static BotType toBotType(String name) =>
      BotType.values.singleWhere((e) => e.name == name);
}

class BotsRepo {
  BotsRepo(this._storage) {
    _running = _events.asyncMap((e) => _handle(e.$1, e.$2)).listen((e) {});
  }

  late final StreamSubscription _running;

  final _events = BehaviorSubject<(String, dynamic)>.seeded(('restore', null));
  final _data = BehaviorSubject<Bots>();

  final Storage _storage;

  Stream<Bots> subscribe() => _data;

  void add(BotData bot) => _events.add(('append', bot));

  void update(BotData bot) => _events.add(('update', bot));

  void remove(BotData bot) => _events.add(('remove', bot));

  Future close() async {
    _events.add(('close', null));
    await _running.asFuture();
  }

  Future<String> _handle(String event, dynamic argument) async {
    if (event == 'close') _onClose();

    if (event == 'append') await _onAppend(argument);
    if (event == 'remove') await _onRemove(argument);
    if (event == 'restore') await _onRestore();
    if (event == 'update') await _onUpdate(argument);

    return event;
  }

  void _onClose() {
    _data.close();
    _events.close();
  }

  Future<void> _onAppend(BotData argument) async {
    final json = argument.toJson();
    await _storage.append('Bots', '$json\n');
    _data.value = _data.value + [argument];
  }

  Future<void> _onRemove(BotData it) async {
    final current = _data.value;
    current.removeWhere((e) => e.userref == it.userref);
    await _updateAll(current);
  }

  Future<void> _onRestore() async {
    final lines = await _storage.lines('Bots');
    final maps = lines.map((e) => jsonDecode(e));
    _data.value = maps.map((e) => BotData.from(e)).toList();
  }

  Future<void> _onUpdate(BotData it) async {
    final current = _data.value;
    current.removeWhere((e) => e.userref == it.userref);
    current.add(it);
    await _updateAll(current);
  }

  Future<void> _updateAll(Bots current) async {
    final json = current.map((e) => e.toJson());
    await _storage.saveList('Bots', json);
    _data.value = current;
  }
}
