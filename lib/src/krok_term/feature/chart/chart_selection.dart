part of '../chart.dart';

final _selection = ChartSelection();

class ChartSelection {
  final _selectedPrice = BehaviorSubject.seeded(0.0);

  double min = 0;
  double max = 0;
  double last = 0;
  int rows = 0;

  Stream<double> get selectedPrice => _selectedPrice;

  void _setPriceTo(double price) => _selectedPrice.value = price;

  double get currentPrice => _selectedPrice.value;

  void useChartInfo(double min, double max, double last, int rows) {
    if (this.min == min && this.max == max && this.last == last) {
      return;
    }
    this.last = last;
    if (min >= max) {
      this.min = 0;
      this.max = 0;
      return;
    }
    this.min = min;
    this.max = max;
    this.rows = rows;

    // no selection, keep it like that:
    if (currentPrice == 0) return;

    // otherwise clamp it to new min/max:
    _setPriceTo(currentPrice.clamp(min, max));
  }

  void reset() => _selectedPrice.value = 0;

  void change(int delta) {
    if (min == 0 || max == 0 || min >= max || rows == 0) return;
    if (currentPrice == 0) {
      if (min <= last && last <= max) {
        _setPriceTo(last);
      } else {
        _setPriceTo((max + min) / 2);
      }
    } else {
      final step = (max - min) / rows;
      final changed = currentPrice + step * delta;
      _setPriceTo(changed.clamp(min, max));
    }
  }
}
