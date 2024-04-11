part of '../chart.dart';

extension on Window {
  void setupKeys() {
    onKey("u",
        description: "Update data",
        action: () => _refresh.value = DateTime.timestamp());

    onKey('<S-h>', //
        aliases: ['<S-Left>'],
        description: 'Jump left',
        action: () => _projection.scrollBy(10));
    onKey('<S-l>',
        aliases: ['<S-Right>'],
        description: 'Jump right', action: () => _projection.scrollBy(-10));
    onKey('h', //
        aliases: ['<Left>'],
        description: 'Scroll left',
        action: () => _projection.scrollBy(2));
    onKey('l', //
        aliases: ['<Right>'],
        description: 'Scroll right',
        action: () => _projection.scrollBy(-2));

    changeInterval(int delta) {
      final now = _interval.value.index;
      final change = (now + delta).clamp(0, OhlcInterval.values.length - 1);
      _interval.value = OhlcInterval.values[change];
    }

    onKey('i',
        description: 'Smaller interval', action: () => changeInterval(-1));
    onKey('<S-i>',
        description: 'Bigger interval', action: () => changeInterval(1));

    onKey('+', description: 'Zoom out', action: () => _projection.zoomBy(-1));
    onKey('-', description: 'Zoom in', action: () => _projection.zoomBy(1));
    onKey('=', description: 'Reset zoom', action: () => _projection.zoomBy(0));
    onKey('r', description: 'Reset scroll and zoom', action: _projection.reset);

    for (final i in OhlcInterval.values) {
      onKey((i.index + 1).toString(),
          description: 'Switch to ${i.label}',
          action: () => _interval.value = i);
    }
  }
}
