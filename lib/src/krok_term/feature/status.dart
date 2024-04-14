import 'package:dart_consul/dart_consul.dart';
import 'package:rxdart/rxdart.dart' hide SwitchMapExtension;
import 'package:stream_transform/stream_transform.dart' hide RateLimit;

import '../common/window.dart';
import '../core/krok_core.dart';

final _window = window("status", 39, 2) //
  ..name = "Status [$sKey]"
  ..position = AbsolutePosition(146, 0);

final _refresh = BehaviorSubject.seeded(DateTime.timestamp());

void openStatus() => autoWindow(_window, () => _create());

void _create() {
  _window.onKey("u",
      description: "Update status",
      action: () => _refresh.value = DateTime.timestamp());

  Stream<(String, dynamic)> request() => retrieve(KrakenRequest.systemStatus())
      .map((e) => (e['status'].toString(), ""))
      .onErrorReturnWith((error, stackTrace) => ('error', error.toString()));

  Stream<int> blink() => Stream.periodic(1.seconds, (i) => i);

  final refresh = _refresh
      .merge(Stream.periodic(1.minutes, (_) => DateTime.timestamp()))
      .throttleTime(1.seconds)
      .switchMap((dt) => request().map((s) => (dt, s.$1, s.$2)))
      .switchMap((e) => e.$2 == 'online'
          ? Stream.value((e.$1, e.$2, e.$3, 0))
          : blink().map((i) => (e.$1, e.$2, e.$3, i)));

  _window.autoDispose("update", refresh.listenSafely(_showStatus));
}

_showStatus(e) => _updateResult(e.$1, e.$2, e.$3, e.$4);

_updateResult(DateTime dt, String status, dynamic data, int blink) {
  final buffer = Buffer(39, 2);
  buffer.drawBuffer(0, 0, dt.toLongStamp());
  buffer.drawBuffer(0, 1, data.toString());

  switch (status) {
    case 'error':
      if (data.toString().startsWith('EService:Unavailable')) {
        buffer.drawBuffer(20, 0, _offline(blink, 'OFFLINE'));
      } else {
        buffer.drawBuffer(20, 0, _offline(blink, 'ERROR'));
      }
    case 'online':
      buffer.drawBuffer(20, 0, 'ONLINE'.inverse().green());
    default:
      buffer.drawBuffer(20, 0, _status(blink, status.toUpperCase()));
  }

  _window.update(() => buffer.frame());
}

String _offline(int blink, String it) =>
    blink.isOdd ? it.inverse().red() : it.red();

String _status(int blink, String it) =>
    blink.isOdd ? it.inverse().magenta() : it.magenta();
