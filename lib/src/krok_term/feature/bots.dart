import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';

import '../common/list_window.dart';
import '../common/settings.dart';
import '../common/window.dart';
import '../core/krok_core.dart';
import '../repository/bots_repo.dart';
import '../repository/krok_repos.dart';

final _window = window('bots', 80, 25) //
  ..flags = {
    WindowFlag.maximizable,
    WindowFlag.minimizable,
    WindowFlag.resizable
  }
  ..name = "Bots [$bbKey]"
  ..position = AbsolutePosition(105, 4);

void openBots() => autoWindow(_window, _create);

void _create() {
  _listed = ListWindow(
    window: _window,
    topOff: 2,
    bottomOff: 2,
    header: _header,
    onSelect: (e) => _onSelect(e),
  );

  var wasFocused = false;
  _window.onStateChanged.add(() {
    if (wasFocused && !_window.isFocused) desktop.minimizeWindow(_window);
    wasFocused = _window.isFocused;
  });

  _window.autoDispose("update", bots.listen((e) => _updateResult(e)));

  _window.onKey('cd',
      description: 'Create dipper for currently selected pair',
      action: _createDipper);

  _window.onKey('cst',
      description: 'Create simple trader for currently selected pair',
      action: _createSimpleTrader);

  _window.onKey('d', description: 'Delete selected bot', action: _deleteBot);
}

void _onSelect(int index) {
  if (index < 0 || index >= _list.length) return;
  logInfo('bot wot?');
}

final _columns = "L25|L10|L15|L15";
final _header = "Bot Type|Id|Status|Turnover".columns(_columns, '|');

late final ListWindow _listed;
final List<BotData> _list = [];
final List<Bot> _bots = [];

_updateResult(List<BotData> it) {
  _list.clear();
  _list.addAll(it);

  final alive = <Bot>[];
  for (final bd in _list) {
    final it = _bots.where((e) => e.userref == bd.userref).singleOrNull;
    if (it != null) {
      alive.add(it);
    } else {
      alive.add(_createBot(bd));
    }
  }
  logInfo('keeping alive: $alive');

  final aliveRefs = alive.map((e) => e.userref);
  final dead = _bots.whereNot((e) => aliveRefs.contains(e.userref));
  logInfo('shutting down: $dead');
  for (final d in dead) {
    d.shutdown();
  }
  _bots.clear();
  _bots.addAll(alive);

  _listed.updateEntries(_bots.mapList((e) {
    return e.toString().columns(_columns, '|');
  }));
  _window.requestRedraw();
}

Bot _createBot(BotData bd) {
  return switch (bd.type) {
    BotType.dipper => Dipper.from(bd),
    BotType.simpleTrader => SimpleTrader.from(bd),
  };
}

Future _createDipper() async {
  final userref = await settings.i('bots::userref') ?? 0;
  final ap = await selectedAssetPair.first;
  botsRepo.add(BotData(BotType.dipper, userref, {'pair': ap.pair}));
  await settings.set('bots::userref', userref + 1);
}

_createSimpleTrader() async {
  final userref = await settings.i('bots::userref') ?? 0;
  final ap = await selectedAssetPair.first;
  botsRepo.add(BotData(BotType.simpleTrader, userref, {'pair': ap.pair}));
  await settings.set('bots::userref', userref + 1);
}

_deleteBot() {
  final i = _listed.selected;
  if (i < 0 || i >= _list.length) return;
  final it = _list[i];
  desktop.query('Please confirm deleting bot:\n$it', (e) {
    if (e is QueryPositive) botsRepo.remove(it);
  });
}

abstract interface class Bot {
  int get userref;

  Future shutdown();
}

class Dipper implements Bot {
  @override
  late final int userref;

  late final String _pair;

  Dipper.from(BotData bd) {
    userref = bd.userref;
    _pair = bd.data['pair'];
  }

  @override
  Future shutdown() async {
    logWarn("TODO shutdown");
  }

  @override
  String toString() => 'Dipper ${_pair.whiteBright()}|$userref|NOT READY|';
}

class SimpleTrader implements Bot {
  @override
  late final int userref;

  late final String _pair;

  SimpleTrader.from(BotData bd) {
    userref = bd.userref;
    _pair = bd.data['pair'];
  }

  @override
  Future shutdown() async {
    logWarn("TODO shutdown");
  }

  @override
  String toString() =>
      'SimpleTrader ${_pair.whiteBright()}|$userref|NOT READY|';
}

/// Bots need a simple interface for handling orders. This is it.
class BotOrders {
  (String?, String?) place(String descr) => (null, 'nyi');

  OrderData? find(String txid) => null;

  List<OrderData> gather(String userref) => [];
}
