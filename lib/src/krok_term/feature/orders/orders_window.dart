// ignore_for_file: unused_local_variable, non_constant_identifier_names

import 'dart:math';

import 'package:dart_consul/dart_consul.dart';
import 'package:krok_term/src/krok_term/repository/orders_repo.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../core/krok_core.dart';

class OrdersWindow {
  final Window _window;
  final Stream<Orders> _input;
  final int _topOff;
  final int _bottomOff;
  final Function() _refreshData;

  OrdersWindow(
      {required Window window,
      required Stream<Orders> input,
      required int topOff,
      required int bottomOff,
      required Function() refresh})
      : _window = window,
        _input = input,
        _topOff = topOff,
        _bottomOff = bottomOff,
        _refreshData = refresh;

  String _buffer = "";
  late final ScrolledContent _scrolled;

  final Set<OrderId> _open = {};
  final List<OrderData> _entries = [];

  final _refresh = BehaviorSubject.seeded(DateTime.timestamp());
  final _selected = BehaviorSubject.seeded("");

  bool get isEmpty => _entries.isEmpty;

  OrderData? get selected =>
      _entries.firstWhereOrNull((e) => e.id == _selected.value);

  void create() {
    _scrolled = scrolled(_window, () => _buffer, defaultShortcuts: false);

    _window.chainOnMouseEvent((e) {
      if (!e.isUp || e.y < 1) return null;
      return _clickSelect(e);
    });

    _window.onKey('k',
        description: 'Select previous order', action: () => _keySelect(-1));
    _window.onKey('j',
        description: 'Select next order', action: () => _keySelect(1));
    _window.onKey('<Return>',
        aliases: ['<Space>'],
        description: 'Toggle order expansion',
        action: () => _toggleSelected());

    _window.onKey("u",
        description: "Update orders now", action: () => _refreshData());

    _window.autoDispose(
      "update",
      _refresh
          .combineLatest(_input, (r, o) => o)
          .combineLatest(_selected, (e, s) => (e, s))
          .map((e) => _toEntries(e.$1, e.$2))
          .listenSafely((e) => _updateResult(e)),
    );
  }

  void _toggleSelected() {
    final s = _selected.value;
    if (s.isEmpty) return;
    if (_open.contains(s)) {
      _open.remove(s);
    } else {
      _open.add(s);
    }
    _keySelect(0);
    _refresh.value = DateTime.timestamp();
  }

  NopMouseAction _clickSelect(MouseEvent e) {
    final index = e.y - 1 + _scrolled.scrollOffset;
    if (index < 0 || index >= _entries.length) {
      return NopMouseAction(_window);
    }

    final it = _entries[index];
    _selected.value = it.id;
    _keySelect(0);

    if (_open.contains(it.id)) {
      _open.remove(it.id);
    } else {
      _open.add(it.id);
    }
    _refresh.value = DateTime.timestamp();

    return NopMouseAction(_window);
  }

  void _keySelect(int delta) {
    if (_entries.isEmpty) return;

    final ids = _entries.map((e) => e.id).unique().toList();
    final index = ids.indexWhere((e) => e == _selected.value);
    final target = index + delta;
    final valid = target.clamp(0, ids.length - 1);

    _selected.value = ids[valid];

    final so = _scrolled.scrollOffset;
    final si = _entries.indexWhere((e) => e.id == _selected.value);
    if (si < so + _topOff) {
      _scrolled.scrollOffset = si - _topOff;
    }
    if (si > so + _bottomOff) {
      _scrolled.scrollOffset = si - _bottomOff;
    }
  }

  List<String> _toEntries(Orders orders, OrderId? selected) {
    _entries.clear();

    final result = <String>[];
    for (final o in orders.values) {
      final id = o.id;

      final userref = o.i('userref');

      var status = o.s('status');
      if (status == "canceled") {
        status = status.bold().blue();
      } else {
        status = status.bold();
      }

      var reason = o.s_('reason');
      reason = reason != null ? " $reason".bold().blue() : "";

      final opentm = o.dt('opentm');
      final closetm = o.dt_('closetm');
      final starttm = o.dt('starttm');
      final expiretm = o.dt('expiretm');

      final times = [
        ("opentm", opentm),
        ("closetm", closetm),
        ("starttm", starttm),
        ("expiretm", expiretm),
      ].where((e) => e.$2 != null && e.$2!.millisecondsSinceEpoch > 0);

      final vol = o.d('vol');
      final vol_exec = o.d('vol_exec');
      final cost = o.d('cost');
      final fee = o.d('fee');
      final price = o.d('price');
      final stopprice = o.d('stopprice');
      final limitprice = o.d('limitprice');

      final pair = o.pair();
      final type = o.type();
      final ordertype = o.ordertype();
      final price1 = o.price();
      final price2 = o.price2();
      final leverage = o.leverage();
      var order = o.order();
      if (order.startsWith("buy ")) order = order.green();
      if (order.startsWith("sell ")) order = order.red();
      final close = o.close();

      if (_open.contains(o.id)) {
        final vp = vol_exec * 100 ~/ vol;
        final buffer = Buffer(80, max(4, 2 + times.length));

        var header = "▲ $order $status$reason";
        if (selected == o.id) header = header.inverse();
        buffer.drawBuffer(0, 0, header);

        for (final (i, t) in times.indexed) {
          final tm = t.$1;
          final dt = t.$2!.toLongStamp();
          final line = "$tm:|$dt".columns("L10|L20", '|');
          buffer.drawBuffer(2, 1 + i, line);
        }

        buffer.drawBuffer(33, 1, "vol: $vol_exec of $vol ($vp)");
        buffer.drawBuffer(33, 2, "userref: $userref id: $id");

        buffer.drawBuffer(0, buffer.height - 1, "".padRight(buffer.width, "┈"));

        result.add(buffer.frame());
        repeat(buffer.height, () => _entries.add(o));
      } else {
        var header = "▼ $order $status$reason";
        if (selected == o.id) header = header.inverse();
        result.add(header);
        _entries.add(o);
      }
    }

    return result;
  }

  void repeat(int count, void Function() what) {
    for (var i = 0; i < count; i++) {
      what();
    }
  }

  _updateResult(List<String> entries) {
    _buffer = entries.join("\n");
    _window.requestRedraw();
  }
}
