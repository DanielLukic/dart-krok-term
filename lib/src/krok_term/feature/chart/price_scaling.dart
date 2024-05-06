part of 'chart.dart';

final _scaling = PriceScaling();

class PriceScaling {
  List<double>? fixedScale;

  void step(int delta) {
    if (fixedScale == null) _initFixed();
    fixedScale?.let((f) {
      final step = _selection.priceStep;
      if (step == null) return;
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
}
