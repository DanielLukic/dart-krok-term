import 'package:collection/collection.dart';
import 'package:krok_term/src/krok_term/common/list_filter.dart';
import 'package:rxdart/rxdart.dart';

import '../common/window.dart';
import '../core/krok_core.dart';
import '../core/selected_currency.dart';
import '../core/selected_pair.dart';
import '../repository/krok_repos.dart';

final _window = window("select-pair", 62, 25) //
  ..name = "Select Pair"
  ..position = AbsolutePosition(42, 4);

void selectAssetPair() {
  autoWindow(_window, () => _create());
  _scrolled.scrollOffset = 0;
  _scrolled.header = "Start typing to filter...".italic();
  _filter.reset();
}

late ScrolledContent _scrolled;
late ListFilter<AssetPairData> _filter;

final List<AssetPairData> _data = [];

String _buffer = "";
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

void _create() {
  _scrolled =
      scrolled(_window, () => _buffer, nameExtension: " ≡ ▼/▲ <C-j>/<C-k>");

  _filter = ListFilter(
    () => _resolveSelection(selection: _selection.value, data: _data),
    (e) => _selection.value = e,
    (e) => _select(e),
    _data,
    _scrolled,
    minimizeOnCancel: true,
  );

  _window.onFocusChanged.add(() {
    if (!_window.isFocused) desktop.minimizeWindow(_window);
  });

  _window.autoDispose(
    "update",
    CombineLatestStream.list<dynamic>(
            [currency, assetPairs, tickers, _filter.value, _selection])
        .map((e) => _toEntries(e[0], e[1], e[2], e[3], e[4]))
        .listen((e) => _updateResult(e)),
  );
}

_select(AssetPairData it) {
  desktop.minimizeWindow(_window);
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

  final startMatched =
      currencyMatched.where((e) => e.wsnStartsWith(filter)).sortedByWsn();

  final containsMatched =
      currencyMatched.where((e) => e.wsnContains(filter)).sortedByWsn();

  final allMatched = (startMatched.isEmpty && containsMatched.isEmpty
          ? ap.values.where((e) => e.contains(filter))
          : <AssetPairData>[])
      .sortedByWsn();

  final matches = startMatched.plus(containsMatched).plus(allMatched);
  final result = matches.unique().map((e) {
    final ansiPair = e.wsname.highlightSuffix().fixDisplayPair();
    final price = t[e.pair]?.last.toString();
    final currency = c.plain.gray();
    final ansiPercent = t[e.pair]?.ansiPercent ?? "";
    return (e, "$ansiPair $price$currency $ansiPercent");
  }).toList();

  final it = _resolveSelection(
      selection: selection, data: result.mapList((e) => e.$1));

  return (result, it.$1);
}

_updateResult((List<(AssetPairData, String)>, int?) it) {
  final entries = it.$1;
  final selectedIndex = it.$2;

  _data.clear();
  _data.addAll(entries.mapList((e) => e.$1));

  final rows = entries
      .map((e) => e.$2.columns("L15|R15|R15").ansiPadRight(_window.width))
      .toList();
  if (selectedIndex != null) {
    rows[selectedIndex] = rows[selectedIndex].inverse();
  }
  _buffer = rows.join("\n");

  _window.requestRedraw();
}

extension on AssetPairData {
  bool wsnStartsWith(String filter) =>
      wsname.fixDisplayPair().startsWith(filter) ||
      pair.startsWith(filter) ||
      altname.startsWith(filter) ||
      wsname.startsWith(filter);

  bool wsnContains(String filter) =>
      filter.length > 1 ? toString().contains(filter) : false;

  bool contains(String filter) => toString().contains(filter);
}

extension on Iterable<AssetPairData> {
  Iterable<AssetPairData> sortedByWsn() =>
      sorted((a, b) => a.wsname.length - b.wsname.length);
}
