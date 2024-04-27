import 'package:krok_term/src/krok_term/core/selected_pair.dart';
import 'package:rxdart/rxdart.dart';

import '../common/list_window.dart';
import '../common/settings.dart';
import '../common/window.dart';
import '../core/krok_core.dart';
import '../repository/krok_repos.dart';

final _window = window("alerts", 22, 25) //
  ..name = "Alerts [$aKey]"
  ..position = AbsolutePosition(19, 4);

void openAlerts() => autoWindow(_window, _create);

late ListWindow _list;

void _create() {
  minimize() => desktop.minimizeWindow(_window);

  _list = ListWindow(
    window: _window,
    topOff: 2,
    bottomOff: 2,
    header: "Asset Pair|Price".columns(_columns, '|'),
    extendName: false,
    escapeToClear: false,
    onSelect: (index) {
      if (index < 0 || index >= _entries.length) return null;
      selectPair(_entries[index].$2.ap);
      minimize();
    },
  );

  _window.onKey('<Escape>',
      description: 'Hide alerts window', action: minimize);

  _window.onKey(
    't',
    description: 'Toggle show alerts for selected pair only',
    action: () => settings
        .b('alerts-selected-only')
        .then((v) => settings.setSynced('alerts-selected-only', !(v ?? false))),
  );

  _window.onKey('<S-d>',
      description: 'Delete all listed alerts',
      action: () => alertsRepo.clear());

  _window.onKey('d', description: 'Delete selected alert', action: () {
    final s = _list.selected;
    if (s < 0 || s >= _entries.length) return;
    final alert = _entries[s].$1;
    alertsRepo.remove(alert);
  });

  var wasFocused = false;
  _window.onStateChanged.add(() {
    if (wasFocused && !_window.isFocused) minimize();
    wasFocused = _window.isFocused;
  });

  final selected = settings
      .stream('alerts-selected-only')
      .switchMap((t) => (t ?? false) ? selectedPair : Stream.value(null));

  _window.autoDispose(
    "update",
    combine([alerts, assetPairs, selected])
        .map((e) => _toEntries(e[0], e[1], e[2]))
        .listen((e) => _list.updateEntries(e)),
  );
}

final _columns = "L10|R12";

List<(AlertData, AssetPairData)> _entries = [];

List<String> _toEntries(
  Alerts alerts,
  AssetPairs assetPairs,
  AssetPair? selected,
) {
  _entries.clear();

  final result = <String>[];
  for (final byPair in alerts.values) {
    final sorted = List<AlertData>.from(byPair);
    sorted.sort((a, b) => (a.price - b.price).sign.toInt());
    for (final a in sorted) {
      final ap = assetPairs[a.pair];
      if (ap == null) continue;
      if (selected != null && ap.wsname != selected.wsname) continue;
      _entries.add((a, ap));
      final p = ap.price(a.price);
      result.add("${ap.wsname}|$p".columns(_columns, '|'));
    }
  }

  _list.header = switch (result) {
    _ when result.isEmpty && alerts.isNotEmpty => 'Show all [t]',
    _ when result.isEmpty => 'No alerts',
    _ => "Asset Pair|Price".columns(_columns, '|'),
  };

  return result;
}
