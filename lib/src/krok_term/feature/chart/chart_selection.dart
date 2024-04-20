part of '../chart.dart';

final _selection = ChartSelection();

class ChartSelection {
  final _selectedPrice = BehaviorSubject.seeded(0.0);

  List<double>? fixedScale;

  double _min = 0;
  double _max = 0;
  double last = 0;
  int _rows = 0;

  Stream<double> get selectedPrice => _selectedPrice;

  void _setPriceTo(double price) => _selectedPrice.value = price;

  double get currentPrice => _selectedPrice.value;

  void step(int delta) {
    if (fixedScale == null) _initFixed();
    fixedScale?.let((f) {
      final step = (_max - _min) / _rows;
      final change = step * delta;
      for (var i = 0; i < f.length; i++) {
        f[i] += change;
      }
    });
  }

  void resetFixed() => fixedScale = null;

  void _onScale(void Function(List<double>) scale) {
    if (fixedScale == null) _initFixed();
    fixedScale?.let(scale);
  }

  void _initFixed() {
    final max = _selection._max;
    final min = _selection._min;
    if (max != 0 && min != 0) fixedScale = [min, max, min, max];
  }

  void toggleFixed() {
    if (fixedScale != null) {
      fixedScale = null;
    } else {
      _initFixed();
    }
  }

  void scaleDown() => _onScale((f) {
        final center = (f[2] + f[3]) / 2;
        final span = (f[1] - f[0]) * 0.8;
        f[0] = center - span / 2;
        f[1] = center + span / 2;
      });

  void scaleUp() => _onScale((f) {
        final center = (f[2] + f[3]) / 2;
        final span = (f[1] - f[0]) * 1.2;
        f[0] = center - span / 2;
        f[1] = center + span / 2;
      });

  void useChartInfo(double min, double max, double last, int rows) {
    if (_min == min && _max == max && this.last == last) {
      return;
    }
    this.last = last;
    if (min >= max) {
      _min = 0;
      _max = 0;
      return;
    }
    _min = min;
    _max = max;
    _rows = rows;

    // no selection, keep it like that:
    if (currentPrice == 0) return;

    // otherwise clamp it to new min/max:
    _setPriceTo(currentPrice.clamp(min, max));
  }

  void invalidate() {
    _min = 0;
    _max = 0;
    last = 0;
    _rows = 0;
    reset();
  }

  void reset() => _selectedPrice.value = 0;

  void change(int delta) {
    if (_min == 0 || _max == 0 || _min >= _max || _rows == 0) return;
    if (currentPrice == 0) {
      if (_min <= last && last <= _max) {
        _setPriceTo(last);
      } else {
        _setPriceTo((_max + _min) / 2);
      }
    } else {
      final step = (_max - _min) / _rows;
      final changed = currentPrice + step * delta;
      _setPriceTo(changed.clamp(_min, _max));
    }
  }
}
