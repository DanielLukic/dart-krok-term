import 'package:dart_consul/dart_consul.dart';
import 'package:krok_term/src/krok_term/feature/chart.dart';
import 'package:rxdart/rxdart.dart';

import '../common/window.dart';
import '../core/krok_core.dart';
import '../core/selected_currency.dart';
import '../core/selected_pair.dart';
import '../repository/asset_pairs_repo.dart';
import '../repository/krok_repos.dart';
import '../repository/ticker_repo.dart';

final _window = window("select-pair", 61, 25) //
  ..name = "Select Pair"
  ..position = AbsolutePosition(43, 4);

void selectAssetPair() {
  autoWindow(_window, () => _create());
  _scrolled.scrollOffset = 0;
  _scrolled.header = "Start typing to filter...".italic();
  _filter.value = "";
}

late ScrolledContent _scrolled;

List<AssetPairData> _data = [];

String _buffer = "";
final _filter = BehaviorSubject.seeded("");
final _selection = BehaviorSubject<(int?, AssetPairData?)>.seeded((null, null));

(int?, AssetPairData?) _resolveSelection({
  required (int?, AssetPairData?) selection,
  required List<AssetPairData> data,
}) {
  final it = _selection.value;
  if (data.isEmpty) {
    return (null, null);
  } else if (it.$1 == null) {
    return (0, data.first);
  } else {
    final found = data.indexed.where((e) => e.$2 == it.$2).singleOrNull;
    if (found != null) {
      return (found.$1, it.$2);
    } else {
      return (0, data.first);
    }
  }
}

void _navigate(int delta) {
  final selection = _resolveSelection(selection: _selection.value, data: _data);
  final currentIndex = selection.$1;
  if (currentIndex == null) return;
  final target = currentIndex + delta;
  if (target < 0 || target >= _data.length) return;
  _selection.value = (target, _data[target]);
  _window.requestRedraw();
}

void _stolen(KeyEvent it) {
  if (it.printable == "<C-u>") {
    _filter.value = "";
  } else if (it.printable == "<C-k>") {
    _navigate(-1);
  } else if (it.printable == "<Enter>" /*<C-j>*/) {
    _navigate(1);
  } else if (it is InputKey) {
    _filter.value = _filter.value + it.char;
  } else if (it.printable == "<Backspace>" || it.printable == "<C-h>") {
    _filter.value = _filter.value.dropLast(1);
  } else if (it.printable == "<C-u>") {
    _filter.value = "";
  } else if (it is ControlKey && it.printable == "<Escape>") {
    desktop.minimizeWindow(_window);
  } else if (it is ControlKey && it.printable == "<Up>") {
    _navigate(-1);
  } else if (it is ControlKey && it.printable == "<Down>") {
    _navigate(1);
  } else if (it is ControlKey && it.printable == "<Return>") {
    final selection =
        _resolveSelection(selection: _selection.value, data: _data);
    final selected = selection.$2;
    if (selected != null) _select(selected);
  } else {
    desktop.handleStolen(it);
  }
  final filter = _filter.value;
  if (filter.isEmpty) {
    _scrolled.header = "Start typing to filter...".italic();
  } else {
    _scrolled.header = filter.inverse();
  }
  _window.requestRedraw();
}

void _create() {
  _scrolled =
      scrolled(_window, () => _buffer, nameExtension: " ≡ ▼/▲ <C-j>/<C-k>");

  _window.onFocusChanged.add(() {
    if (_window.isFocused) {
      _window.autoDispose("stealKeys", desktop.stealKeys((it) => _stolen(it)));
      return;
    } else {
      _window.dispose("stealKeys");
      desktop.minimizeWindow(_window);
    }
  });

  var maybeTrigger = false;

  _window.chainOnMouseEvent((e) {
    if (e.isDown) maybeTrigger = true;
    if (e.isUp && maybeTrigger) {
      final max = _data.length - 1;
      final index = (_scrolled.scrollOffset + e.y - 2).clamp(0, max);
      _select(_data[index]);
      maybeTrigger = false;
    }
    return null;
  });

  _window.autoDispose(
    "update",
    CombineLatestStream.list<dynamic>(
            [currency, assetPairs, tickers, _filter, _selection])
        .map((e) => _toEntries(e[0], e[1], e[2], e[3], e[4]))
        .listen((e) => _updateResult(e)),
  );
}

_select(AssetPairData it) {
  desktop.minimizeWindow(_window);
  openChart();
  selectPair(it.ap);
}

(List<(AssetPairData, String)>, int?) _toEntries(
  Currency c,
  AssetPairs ap,
  Tickers t,
  String filter,
  (int?, AssetPairData?) selection,
) {
  filter = filter.toUpperCase();

  final currencyMatched = ap.values.where(
    (e) => e.quote == c.z,
  );

  final startMatched = currencyMatched.where(
    (e) => filter.length > 1
        ? e.wsname.split("/").first.fixDisplayPair().contains(filter)
        : false ||
            e.wsname.fixDisplayPair().startsWith(filter) ||
            e.pair.startsWith(filter) ||
            e.altname.startsWith(filter) ||
            e.wsname.startsWith(filter),
  );
  final containsMatched = currencyMatched.where(
    (e) => e.toString().contains(filter),
  );
  final allMatched = ap.values.where((e) => e.toString().contains(filter));

  final matches = switch (filter) {
    _ when startMatched.isNotEmpty => startMatched,
    _ when containsMatched.isNotEmpty => containsMatched,
    _ => allMatched,
  };

  final result = matches.map((e) {
    final ansiPair = e.wsname.highlightSuffix().fixDisplayPair();
    final price = t[e.pair]?.last.toString();
    final currency = c.plain.gray();
    final ansiPercent = t[e.pair]?.ansiPercent ?? "";
    return (e, "$ansiPair $price$currency $ansiPercent");
  }).toList();

  result.sort((a, b) {
    final aa = a.$1.wsname.fixDisplayPair();
    final bb = b.$1.wsname.fixDisplayPair();
    final order = aa.compareTo(bb);
    if (order == 0) return aa.length - bb.length;
    return order;
  });

  final it = _resolveSelection(
      selection: selection, data: result.mapList((e) => e.$1));

  return (result, it.$1);
}

_updateResult((List<(AssetPairData, String)>, int?) it) {
  final entries = it.$1;
  final selectedIndex = it.$2;

  _data = entries.mapList((e) => e.$1);

  final rows = entries
      .map((e) => e.$2.columns("L15|R15|R15").ansiPadRight(_window.width))
      .toList();
  if (selectedIndex != null) {
    rows[selectedIndex] = rows[selectedIndex].inverse();
  }
  _buffer = rows.join("\n");

  _window.requestRedraw();
}
