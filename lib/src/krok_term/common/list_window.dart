// ignore_for_file: unused_local_variable, non_constant_identifier_names

import 'dart:math';

import 'package:dart_consul/dart_consul.dart';
import 'package:rxdart/rxdart.dart';

class ListWindow {
  final Window _window;
  final int _topOff;
  final int _bottomOff;
  String Function(String) asSelected;
  Function(int)? onSelect;

  final _selected = BehaviorSubject.seeded(-1);
  late final ScrolledContent _scrolled;
  String _buffer = "";
  List<String> _entries = [];
  List<int> _indexes = [];

  int get selected => _selected.value;

  bool get isEmpty => _entries.isEmpty;

  ListWindow({
    required Window window,
    required int topOff,
    required int bottomOff,
    bool extendName = true,
    String? header,
    this.asSelected = inverse,
    this.onSelect,
  })  : _window = window,
        _topOff = topOff,
        _bottomOff = bottomOff {
    //
    _scrolled = scrolled(
      _window,
      () => _buffer,
      header: header,
      extendName: extendName,
      defaultShortcuts: false,
    );

    _window.chainOnMouseEvent((e) {
      if (!e.isUp || e.y < 1) return null;
      return _clickSelect(e);
    });

    final jump = max(3, _window.height - 4);
    _window.onKey('k',
        description: 'Select previous entry', action: () => _keySelect(-1));
    _window.onKey('j',
        description: 'Select next entry', action: () => _keySelect(1));
    _window.onKey('<S-k>',
        description: 'Select previous entry', action: () => _keySelect(-jump));
    _window.onKey('<S-j>',
        description: 'Select next entry', action: () => _keySelect(jump));

    _window.onKey('<Return>',
        aliases: ['<Space>'],
        description: 'Toggle entry action',
        action: () => _toggleAction());
  }

  void updateEntries(List<String> entries) {
    _entries = entries;
    _refresh();
  }

  void _refresh() {
    _indexes = [];

    final output = <String>[];
    for (final (i, e) in _entries.indexed) {
      final lines = e.split('\n');
      for (final l in lines) {
        _indexes.add(i);
        if (i == _selected.value) {
          output.add(asSelected(l));
        } else {
          output.add(l);
        }
      }
    }
    _buffer = output.join('\n');

    _window.requestRedraw();
  }

  void _toggleAction() {
    final s = _selected.value;
    if (s == -1) return;
    final os = onSelect;
    if (os == null) return;
    os(s);
    _keySelect(0);
  }

  NopMouseAction _clickSelect(MouseEvent e) {
    final index = e.y - 1 + _scrolled.scrollOffset;
    if (index < 0 || index >= _entries.length) {
      return NopMouseAction(_window);
    }

    final it = _indexes[index];
    _selected.value = it;
    _toggleAction();

    return NopMouseAction(_window);
  }

  void _keySelect(int delta) {
    if (_entries.isEmpty) return;

    final target = _selected.value + delta;
    final newIndex = target.clamp(0, _entries.length - 1);
    _selected.value = newIndex;

    final so = _scrolled.scrollOffset;
    final si = _indexes.indexWhere((e) => e == newIndex);
    if (si < so + _topOff) {
      _scrolled.scrollOffset = si - _topOff;
    }
    if (si > so + _bottomOff) {
      _scrolled.scrollOffset = si - _bottomOff;
    }

    _refresh();
  }
}
