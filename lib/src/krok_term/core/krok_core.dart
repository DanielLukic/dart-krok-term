import 'dart:async';

import 'package:dart_consul/common.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:krok/krok.dart';
import 'package:krok_term/src/krok_term/common/extensions.dart';

export 'package:dart_consul/common.dart';
export 'package:krok/krok.dart';

export '../common/desktop.dart';
export '../common/extensions.dart';
export '../common/storage.dart';
export '../common/types.dart';

void initKrokCore() async {
  logInfo('init krok core');
  await for (final it in _queue.stream) {
    await _process(it);
  }
}

Stream<dynamic> retrieve(KrakenRequest request) {
  final it = QueuedRequest(request);
  _queue.add(it);
  return it.stream;
}

var _throttleTimestamp = DateTime.now().subtract(2.seconds);

final _queue = StreamController<QueuedRequest>();

final _api = KrakenApi.fromFile("~/.config/clikraken/kraken.key");

Future _process(QueuedRequest it) async {
  if (it.canceled) {
    logWarn('skip $it');
  } else {
    await _throttle(it);
    try {
      final response = await _api.retrieve(it._request);
      if (!it.canceled) it.complete(response);
    } catch (error) {
      logError('fail $it: $error');
      if (!it.canceled) it.completeError(error);
    }
  }
  return it;
}

Future _throttle(it) async {
  final now = DateTime.now();
  final seconds = now.difference(_throttleTimestamp).inSeconds;
  _throttleTimestamp = DateTime.now();
  if (seconds == 0) {
    logWarn('delay $it');
    await Future.delayed(1.seconds);
  }
}

class QueuedRequest {
  final KrakenRequest _request;

  late final StreamController<dynamic> _result;

  bool canceled = false;

  QueuedRequest(this._request) {
    _result = StreamController(onCancel: () => canceled = true);
  }

  Stream<dynamic> get stream => _result.stream;

  void complete(dynamic result) {
    if (_result.isClosed) {
      logWarn('queued request already closed: $this');
    } else {
      _result.add(result);
    }
  }

  void completeError(Object error) {
    if (_result.isClosed) {
      logWarn('queued request already closed: $this');
    } else {
      _result.addError(error);
    }
  }

  @override
  String toString() {
    final prefix = canceled ? "[CANCELED] " : "";
    return "$prefix${_request.path.toSnakeCase()}";
  }
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
