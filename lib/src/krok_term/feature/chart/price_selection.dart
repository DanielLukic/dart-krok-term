part of 'chart.dart';

final _selection = PriceSelection();

class PriceSelection {
  final _selectedPrice = BehaviorSubject.seeded(0.0);

  double _min = 0;
  double _max = 0;
  double last = 0;
  int _rows = 0;

  double? get priceStep => _rows == 0 ? null : (_max - _min) / _rows;

  Stream<double> get selectedPrice => _selectedPrice;

  void _setPriceTo(double price) => _selectedPrice.value = price;

  double get currentPrice => _selectedPrice.value;

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
    resetSelectedPrice();
  }

  void resetSelectedPrice() => _selectedPrice.value = 0;

  void changeSelectedPrice(int delta) {
    if (_min == 0 || _max == 0 || _min >= _max || _rows == 0) return;
    if (currentPrice == 0) {
      if (_min <= last && last <= _max) {
        _setPriceTo(last);
      } else {
        _setPriceTo((_max + _min) / 2);
      }
    } else {
      final changed = currentPrice + priceStep! * delta;
      _setPriceTo(changed.clamp(_min, _max));
    }
  }

  void selectByRow(double row) {
    final step = priceStep;
    if (step == null) return;
    final changed = _max - row * (_max - _min);
    _setPriceTo(changed.clamp(_min, _max));
  }
}
