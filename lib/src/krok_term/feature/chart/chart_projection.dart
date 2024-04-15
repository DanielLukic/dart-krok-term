import 'package:rxdart/rxdart.dart';
import 'package:stream_transform/stream_transform.dart';

class ChartProjection {
  ChartProjection(this._overscroll);

  final int _overscroll;

  final _zoom = BehaviorSubject.seeded(1);

  final _dataSize = BehaviorSubject.seeded(0);
  final _setScroll = BehaviorSubject.seeded(0);
  final _currentMaxScroll = BehaviorSubject.seeded(0);
  final _currentScroll = BehaviorSubject.seeded(0);

  late final _maxScroll = _dataSize
      .combineLatest(_zoom, (m, z) => (m / z).round() - _overscroll)
      .doOnData((e) => _currentMaxScroll.value = e);

  late final scroll = _setScroll
      .combineLatest(_maxScroll, (s, m) => s.clamp(-_overscroll, m))
      .doOnData((e) => _currentScroll.value = e);

  Stream<int> get zoom => _zoom;

  int get maxZoom => 7;

  int get maxScroll => _currentMaxScroll.value;

  int get currentScroll => _currentScroll.value;

  void zoomBy(int delta) {
    final scroll = currentScroll * _zoom.value;
    if (delta == -1) _zoom.value = (_zoom.value - 1).clamp(1, maxZoom);
    if (delta == 1) _zoom.value = (_zoom.value + 1).clamp(1, maxZoom);
    if (delta == 0) _zoom.value = 1;
    setScroll((scroll / _zoom.value).round());
  }

  void setDataSize(int count) => _dataSize.value = count;

  void setScroll(int absolute) => _setScroll.value = absolute;

  void scrollBy(int d) => _setScroll.value = _currentScroll.value + d;

  void reset() {
    _setScroll.value = 0;
    _zoom.value = 1;
  }
}
