import 'dart:async';

import 'package:dart_consul/dart_consul.dart';
import 'package:dart_minilog/dart_minilog.dart';

import '../core/krok_core.dart';

abstract base class KrokAutoRepo<T> with AutoDispose {
  late final String _key;
  late final Duration _duration;
  late final Duration _freshDuration;

  late final KrakenRequest Function() _request;
  late final dynamic Function(dynamic) _preform;
  late final T Function(dynamic) _restore;

  late final TimestampedStorage<T> _storage;

  KrokAutoRepo(
    Storage storage,
    String key, {
    /// Provide the [KrakenRequest] here.
    required KrakenRequest Function() request,

    /// Implement the inner transformer: turn incoming JSON from the
    /// [KrakenRequest] into JSON for storage. This resulting JSON will then be
    /// passed into [_restore] before passing it outward. Note that the incoming
    /// JSON can be a [Map], [List] or really anything the underlying API
    /// provides.
    dynamic Function(dynamic json)? preform,

    /// Implement the outward transformer: turn JSON from [Storage] into a [T].
    /// The JSON will be whatever [_preform] returned.
    T Function(dynamic json)? restore,

    /// Define the auto-refresh [Duration] here.
    Duration duration = const Duration(minutes: 10),

    /// Optional [Duration], less(!) than [duration] to use for checking data
    /// freshness. [refresh] calls will be ignored if data is no older than
    /// [freshDuration] (unless `userRequest` is true). Defaults to half the
    /// [duration].
    Duration? freshDuration,
  }) {
    _key = key;
    _duration = duration;
    _freshDuration = freshDuration ?? (duration ~/ 2);
    _request = request;
    _preform = preform ?? (e) => e;
    _restore = restore ?? (e) => e;
    _storage = TimestampedStorage(
      storage: storage,
      key: key,
      restore: (e) => _restore(e),
      log: logVerbose,
    );
    _storage.restore();
    refresh();
  }

  /// Refresh data from API. [refresh] calls will be ignored if data is no
  /// older than [freshDuration] (unless [userRequest] is true).
  void refresh({bool userRequest = false}) {
    if (!userRequest && _storage.stillFresh(_freshDuration)) {
      logVerbose('$_key still fresh');
      return;
    }
    logVerbose('$_key refresh');
    autoDispose("refresh", Timer(_duration, refresh));
    autoDispose("retrieve", retrieve(_request()).listenSafely(_update));
  }

  void _update(dynamic result) {
    logVerbose('$_key retrieved');
    _storage.store(_preform(result));
  }

  Stream<T> subscribe() => _storage.stream;
}

extension on Duration {
  Duration operator ~/(int div) =>
      Duration(milliseconds: inMilliseconds ~/ div);
}
