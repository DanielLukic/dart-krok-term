import 'package:collection/collection.dart';
import 'package:krok_term/src/krok_term/common/list_filter.dart';
import 'package:krok_term/src/krok_term/feature/orders/closed_orders.dart';
import 'package:rxdart/rxdart.dart';

import '../../common/window.dart';
import '../../core/krok_core.dart';
import '../../repository/krok_repos.dart';

final _window = window('pick_order', 61, 25) //
  ..name = 'Pick Order'
  ..position = AbsolutePosition(105, 4);

void pickOrder() {
  autoWindow(_window, () => _create());
  _scrolled.scrollOffset = 0;
  _scrolled.header = "Start typing to filter...".italic();
  _filter.reset();
}

late ScrolledContent _scrolled;
late ListFilter<OrderData> _filter;

final List<OrderData> _data = [];

String _buffer = "";
final _selection = BehaviorSubject<(int?, OrderData?)>.seeded((null, null));

(int?, OrderData?) _resolveSelection({
  required (int?, OrderData?) selection,
  required List<OrderData> data,
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
    CombineLatestStream.list<dynamic>([closedOrders, _filter.value, _selection])
        .map((e) => _toEntries(e[0], e[1], e[2]))
        .listen((e) => _updateResult(e)),
  );
}

_select(OrderData it) {
  desktop.minimizeWindow(_window);
  openClosedOrders();
  desktop.sendMessage(('select-order', it.id));
}

(List<(OrderData, String)>, int?) _toEntries(
  Orders orders,
  String filter,
  (int?, OrderData?) selection,
) {
  filter = filter.toUpperCase();

  final matched = orders.values.where((e) => e.id.contains(filter));
  matched.sorted((a, b) => a.id.compareTo(b.id));

  final fuzzy = orders.values.where((e) {
    final rx = StringBuffer();
    for (var i = 0; i < filter.length; i++) {
      final c = filter[i];
      rx.write(c);
      rx.write(r'.*');
    }
    return e.id.contains(RegExp(rx.toString()));
  });

  final all = matched + fuzzy;
  final result = all.unique().map((e) => (e, e.id)).toList();

  final it = _resolveSelection(
      selection: selection, data: result.mapList((e) => e.$1));

  return (result, it.$1);
}

_updateResult((List<(OrderData, String)>, int?) it) {
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
