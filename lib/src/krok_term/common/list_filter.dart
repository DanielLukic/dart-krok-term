import 'package:rxdart/rxdart.dart';

import '../core/krok_core.dart';

class ListFilter<T> {
  final (int?, T?) Function() _get;
  final Function((int?, T?)) _set;
  final Function(T) _select;
  final List _data;
  final ScrolledContent _scrolled;
  final bool _minimizeOnCancel;

  final value = BehaviorSubject.seeded("");

  late final _window = _scrolled.window;

  ListFilter(
    this._get,
    this._set,
    this._select,
    this._data,
    this._scrolled, {
    bool minimizeOnCancel = false,
  }) : _minimizeOnCancel = minimizeOnCancel {
    _window.onFocusChanged.add(() {
      if (_window.isFocused) {
        _window.autoDispose(
            "stealKeys", desktop.stealKeys((it) => _stolen(it)));
      } else {
        _window.dispose("stealKeys");
      }
    });

    var maybeTrigger = false;

    _window.chainOnMouseEvent((e) {
      if (e.isDown) maybeTrigger = true;
      if (e.isUp && maybeTrigger) {
        final max = _data.length - 1;
        final index = (_scrolled.scrollOffset + e.y - 2).clamp(0, max);
        _set(_data[index]);
        maybeTrigger = false;
      }
      return null;
    });
  }

  void reset() => value.value = '';

  void _navigate(int delta) {
    final selection = _get();
    final currentIndex = selection.$1;
    if (currentIndex == null) return;
    final target = currentIndex + delta;
    if (target < 0 || target >= _data.length) return;
    _set((target, _data[target]));
  }

  void _stolen(KeyEvent it) {
    if (it.printable == "<C-u>") {
      value.value = "";
    } else if (it.printable == "<C-k>") {
      _navigate(-1);
    } else if (it.printable == "<C-j>") {
      _navigate(1);
    } else if (it is InputKey) {
      value.value = value.value + it.char;
    } else if (it.printable == "<Backspace>" || it.printable == "<C-h>") {
      value.value = value.value.dropLast(1);
    } else if (it.printable == "<C-u>") {
      value.value = "";
    } else if (it is ControlKey && it.printable == "<Escape>") {
      value.value = '';
      if (_minimizeOnCancel) desktop.minimizeWindow(_window);
    } else if (it is ControlKey && it.printable == "<Up>") {
      _navigate(-1);
    } else if (it is ControlKey && it.printable == "<Down>") {
      _navigate(1);
    } else if (it is ControlKey && it.printable == "<Return>") {
      final selection = _get();
      final selected = selection.$2;
      if (selected != null) _select(selected);
    } else {
      desktop.handleStolen(it);
    }
    final currentFilter = value.value;
    if (currentFilter.isEmpty) {
      _scrolled.header = "Start typing to filter...".italic();
    } else {
      _scrolled.header = currentFilter.inverse();
    }
    _window.requestRedraw();
  }
}
