part of 'chart.dart';

extension on Window {
  void setupMouse() {
    chainOnMouseEvent(_changeInterval);

    onWheel((e) {
      if (_isOnChart(e)) {
        if (e.kind.isDown) _projection.zoomBy(1);
        if (e.kind.isUp) _projection.zoomBy(-1);
      } else if (_isOnPrice(e)) {
        if (e.kind.isDown) _selection.scaleUp();
        if (e.kind.isUp) _selection.scaleDown();
        _triggerRedraw();
      }
    });

    final chartGestures = MouseGestures(this, desktop)
      ..onDoubleClick = ((_) => _reset())
      ..onDrag = (e) => _DragChartAction(_window, e, _projection.currentScroll);

    final priceGestures = MouseGestures(this, desktop)
      ..onDoubleClick = ((_) => _toggleFixed())
      ..onDrag = (e) => _DragPriceAction(_window, e);

    chainOnMouseEvent((e) {
      if (_isOnChart(e)) return chartGestures.process(e);
      if (_isOnPrice(e)) return priceGestures.process(e);
      return null;
    });
  }

  void _toggleFixed() {
    _selection.toggleFixed();
    _redraw.value = DateTime.timestamp();
  }

  void _reset() {
    _projection.reset();
    _selection.resetFixed();
  }

  bool _isOnChart(MouseEvent e) =>
      e.x < width - 10 && e.y > 1 && e.y < height - 2;

  bool _isOnPrice(MouseEvent e) =>
      e.x > width - 10 && e.y > 1 && e.y < height - 2;
}

OngoingMouseAction? _changeInterval(MouseEvent event) {
  // check we are in the first line. then check we are not on a third char.
  // because these are the spaces between intervals. then take the x/4 to get
  // the clicked interval. finally, make sure we allow only existing intervals.
  // TODO Not sure I'm OK with the decorated 1 instead of 0...

  if (event.y != 1) return null;

  final check = event.x % 4;
  if (check == 3) return null;

  final index = event.x ~/ 4;
  if (index >= OhlcInterval.values.length) return null;

  _interval.value = OhlcInterval.values[index];
  return ConsumedMouseAction(_window);
}

class _DragChartAction extends BaseOngoingMouseAction {
  final int _startScroll;

  _DragChartAction(super.window, super.event, this._startScroll);

  @override
  void onMouseEvent(MouseEvent event) {
    if (event.isUp) done = true;

    // the 2 and 4 are for the canvas pixels per char

    final dx = (event.x - this.event.x) * 2;
    _projection.setScroll(_startScroll + dx);

    // only apply vertical movement if price scale has been fixed. otherwise we would always auto-start fixed price
    // scale. which is confusing and not what we want.
    if (_selection.fixedScale != null) {
      final dy = (event.y - this.event.y) * 4;
      _selection.step(dy - stepped);
      stepped = dy;
    }

    _triggerRedraw();
  }

  var stepped = 0;
}

class _DragPriceAction extends BaseOngoingMouseAction {
  _DragPriceAction(super.window, super.event);

  @override
  void onMouseEvent(MouseEvent event) {
    if (event.isUp) done = true;

    final dy = event.y - this.event.y;
    final actual = dy - stepped;
    if (actual < 0) _selection.scaleDown();
    if (actual > 0) _selection.scaleUp();
    stepped = dy;

    _triggerRedraw();
  }

  var stepped = 0;
}
