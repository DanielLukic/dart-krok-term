import 'package:krok_term/src/krok_term/core/selected_pair.dart';
import 'package:krok_term/src/krok_term/repository/alerts_repo.dart';

import '../common/list_window.dart';
import '../common/window.dart';
import '../core/krok_core.dart';
import '../repository/asset_pairs_repo.dart';
import '../repository/krok_repos.dart';

final _window = window("alerts", 22, 25) //
  ..name = "Alerts [$aKey]"
  ..position = AbsolutePosition(19, 4);

void openAlerts() => autoWindow(_window, _create);

void _create() {
  minimize() => desktop.minimizeWindow(_window);

  final list = ListWindow(
    window: _window,
    topOff: 2,
    bottomOff: 2,
    header: "Asset Pair|Price".columns(_columns, '|'),
    extendName: false,
    onSelect: (index) {
      if (index < 0 || index >= _entries.length) return null;
      selectPair(_entries[index].$2.ap);
      minimize();
    },
  );

  _window.onKey('<Escape>',
      description: 'Hide alerts window', action: minimize);

  _window.onKey('d', description: 'Delete selected alert', action: () {
    final s = list.selected;
    if (s < 0 || s >= _entries.length) return;
    final alert = _entries[s].$1;
    alertsRepo.remove(alert);
  });

  var wasFocused = false;
  _window.onStateChanged.add(() {
    if (wasFocused && !_window.isFocused) minimize();
    wasFocused = _window.isFocused;
  });

  _window.autoDispose(
    "update",
    combine([alerts, assetPairs])
        .map((e) => _toEntries(e[0], e[1]))
        .listen((e) => list.updateEntries(e)),
  );
}

final _columns = "L10|R12";

List<(AlertData, AssetPairData)> _entries = [];

List<String> _toEntries(
  Alerts alerts,
  AssetPairs assetPairs,
) {
  _entries.clear();

  final result = <String>[];
  for (final byPair in alerts.values) {
    final sorted = List<AlertData>.from(byPair);
    sorted.sort((a, b) => (a.price - b.price).sign.toInt());
    for (final a in sorted) {
      final ap = assetPairs[a.pair];
      if (ap == null) continue;
      _entries.add((a, ap));
      result.add("${ap.wsname}|${a.price}".columns(_columns, '|'));
    }
  }
  return result;
}
