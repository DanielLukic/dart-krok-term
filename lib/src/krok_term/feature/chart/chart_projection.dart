import 'package:rxdart/rxdart.dart';
import 'package:stream_transform/stream_transform.dart';

class ChartProjection {
  ChartProjection(this._overscroll, this._zoom);

  final int _overscroll;
  final Stream<int> _zoom;

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

  int get max => _currentMaxScroll.value;

  int get current => _currentScroll.value;

  void setDataSize(int count) => _dataSize.value = count;

  void setScroll(int absolute) => _setScroll.value = absolute;

  void scrollBy(int d) => _setScroll.value = _currentScroll.value + d;

  void reset() => _setScroll.value = 0;
}
