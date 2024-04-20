part of '../chart.dart';

extension on Window {
  void setupMouse() {
    chainOnMouseEvent(_changeInterval);
    onWheelDown(() => _projection.zoomBy(1));
    onWheelUp(() => _projection.zoomBy(-1));

    chainOnMouseEvent((e) => _isChartClick(e)
        ? _DragChartAction(_window, e, _projection.currentScroll)
        : null);
  }

  bool _isChartClick(MouseEvent e) =>
      e.isDown && e.x < width - 10 && e.y > 1 && e.y < height - 2;
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

  _DragChartAction(super.window, super.event, this._startScroll) {
    sendMessage(("raise-window", _window));
  }

  @override
  void onMouseEvent(MouseEvent event) {
    if (event.isUp) done = true;

    final dx = event.x - this.event.x;
    _projection.setScroll(_startScroll + dx * 2);
    // the 2 is for the canvas pixel duplication ☝
  }
}
