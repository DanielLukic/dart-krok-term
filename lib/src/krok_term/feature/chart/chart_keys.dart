part of 'chart.dart';

extension on Window {
  void setupKeys() {
    onKey("u", description: "Update data", action: () => _triggerRefresh());

    onKey('d', //
        description: 'Move chart down', action: () {
      _selection.step(1);
      _triggerRedraw();
    });
    onKey('e', //
        description: 'Move chart up', action: () {
      _selection.step(-1);
      _triggerRedraw();
    });

    onKey('<S-h>', //
        aliases: ['<S-Left>'],
        description: 'Jump left',
        action: () => _projection.scrollBy(-10));
    onKey('<S-l>',
        aliases: ['<S-Right>'],
        description: 'Jump right',
        action: () => _projection.scrollBy(10));
    onKey('h', //
        aliases: ['<Left>'],
        description: 'Scroll left',
        action: () => _projection.scrollBy(-2));
    onKey('l', //
        aliases: ['<Right>'],
        description: 'Scroll right',
        action: () => _projection.scrollBy(2));

    onKey('<Escape>', //
        description: 'Clear price selection',
        action: _selection.reset);
    onKey('j', //
        aliases: ['<Down>'],
        description: 'Price selection down',
        action: () => _selection.change(-1));
    onKey('<S-j>', //
        aliases: ['<S-Down>'],
        description: 'Price selection down 10 steps',
        action: () => _selection.change(-10));
    onKey('k', //
        aliases: ['<Up>'],
        description: 'Price selection up',
        action: () => _selection.change(1));
    onKey('<S-k>', //
        aliases: ['<S-Up>'],
        description: 'Price selection up 10 steps',
        action: () => _selection.change(10));

    onKey('<C-j>', //
        aliases: ['<C-Down>'],
        description: 'Scale price range up', action: () {
      _selection.scaleUp();
      _triggerRedraw();
    });
    onKey('<C-k>', //
        aliases: ['<C-Up>'],
        description: 'Scale price range down', action: () {
      _selection.scaleDown();
      _triggerRedraw();
    });

    onKey('a', description: 'Add alert', action: _addAlert);
    onKey('o', description: 'Place order', action: () => _placeOrder());

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
    onKey('<S-r>', description: 'Reset price scale, scroll and zoom',
        action: () {
      _projection.reset();
      _selection.resetFixed();
      _triggerRedraw();
    });

    for (final i in OhlcInterval.values) {
      onKey((i.index + 1).toString(),
          description: 'Switch to ${i.label}',
          action: () => _interval.value = i);
    }

    autoDispose(
        'order-shortcuts',
        desktop.stream().mapNotNull((e) {
          if (e case ('place-order', OrderDirection d, OrderType t)) {
            return ('place-order', d, t);
          } else {
            return null;
          }
        }).listenSafely((e) => _placeOrder(dir: e.$2, type: e.$3)));
  }
}

void _addAlert() {
  final pair = _pair;
  if (pair == null) return;
  desktop.sendMessage(
    AddAlert(pair, _selection.currentPrice, _selection.last),
  );
}

void _placeOrder({OrderDirection? dir, OrderType? type}) {
  final ap = _pair;
  if (ap == null) return;

  final c = _selection.currentPrice.takeIf_((c) => c > 0);
  final l = _selection.last;
  final p = c ?? l;

  desktop.sendMessage(PlaceOrder(ap, p, dir: dir, type: type));
}
