import 'dart:async';

import 'package:dart_consul/dart_consul.dart';
import 'package:dart_consul/src/util/common.dart';
import 'package:krok/krok.dart';

import '../common/desktop.dart';

export 'package:krok/krok.dart';

export '../common/desktop.dart';
export '../common/extensions.dart';
export '../common/storage.dart';
export '../common/types.dart';

void initKrokCore() async {
  logEvent('init krok core');
  await for (final it in _queue.stream) {
    await _process(it);
  }
}

Disposable retrieve(KrakenRequest request, Function(dynamic) onResult) {
  final it = QueuedRequest(request, onResult);
  _queue.add(it);
  return Disposable.wrap(it.cancel);
}

var _throttleTimestamp = DateTime.now().subtract(2.seconds);

final _queue = StreamController<QueuedRequest>();

final _api = KrakenApi.fromFile("~/.config/clikraken/kraken.key");

Future _process(QueuedRequest it) async {
  if (it.canceled) {
    logEvent("skip $it");
  } else {
    await _throttle(it);
    logEvent("process $it");
    try {
      final response = await _api.retrieve(it._request);
      it.complete(response);
    } catch (error) {
      if (!it.canceled) {
        it.completeError(error);
        logEvent("fail $it: $error");
      }
    }
  }
  return it;
}

Future _throttle(it) async {
  final now = DateTime.now();
  final seconds = now.difference(_throttleTimestamp).inSeconds;
  _throttleTimestamp = DateTime.now();
  if (seconds == 0) {
    logEvent("delay $it");
    await Future.delayed(1.seconds);
  }
}

class QueuedRequest {
  final KrakenRequest _request;

  final _result = Completer<Result>();

  late final StreamSubscription<Result> _subscription;

  bool canceled = false;

  QueuedRequest(this._request, void Function(dynamic) onResult) {
    _subscription = _result.future.asStream().listen(onResult);
  }

  void cancel() {
    canceled = true;
    _subscription.cancel();
  }

  void complete(Result result) {
    if (_result.isCompleted) throw StateError("already completed");
    _result.complete(result);
  }

  void completeError(Object error) => _result.completeError(error);

  @override
  String toString() {
    final prefix = canceled ? "[CANCELED] " : "";
    return "$prefix${_request.string}";
  }
}

extension on KrakenRequest {
  String get string => "${scope.name}/$path/$params";
}

extension SafeStreamExtension<T> on Stream<T> {
  StreamSubscription<T> listenSafely(Function(T) listener) {
    safely(t) {
      try {
        listener(t);
      } catch (it, trace) {
        logError(it, trace);
      }
    }

    return listen(safely, onError: logError);
  }
}
