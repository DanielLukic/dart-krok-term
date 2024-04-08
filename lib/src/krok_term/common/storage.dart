import 'dart:convert';
import 'dart:io';

import 'package:rxdart/rxdart.dart';

import 'functions.dart';
import 'types.dart';

class Storage {
  final Directory _directory;

  Storage({required String path}) : _directory = Directory(path);

  Future<JsonObject?> load(String key) async {
    final exists = await _directory.exists();
    if (!exists) return null;

    final file = File(joinPath([_directory.path, key]));
    if (!await file.exists()) return null;

    return jsonDecode(await file.readAsString());
  }

  Future save(String key, JsonObject json) async {
    final exists = await _directory.exists();
    if (!exists) await _directory.create();

    final file = File(joinPath([_directory.path, key]));
    if (await file.exists()) {
      await file.rename("${file.path}.bak");
    }

    await file.writeAsString(jsonEncode(json));
  }
}

class TimestampedStorage<T> {
  final Storage _storage;
  final String _key;
  final T Function(dynamic) _restore;
  final void Function(dynamic) _log;
  final T? _restoreDefault;

  TimestampedStorage({
    required Storage storage,
    required String key,
    required T Function(dynamic) restore,
    void Function(dynamic) log = print,
    T? restoreDefault,
  })  : _storage = storage,
        _key = key,
        _restore = restore,
        _log = log,
        _restoreDefault = restoreDefault;

  final BehaviorSubject<_Cached<T>> _cache = BehaviorSubject();

  Stream<T> get stream => _cache.stream.map((e) => e.value);

  restore() async {
    final loaded = await _storage.load(_key);
    if (loaded == null) {
      if (_restoreDefault != null && _cache.valueOrNull == null) {
        _log("$_key default");
        store(_restoreDefault);
        return;
      }
      _log("$_key not found");
      return;
    }
    final current = _cache.valueOrNull;
    final timestamp = loaded['timestamp'];
    if (current == null || current.timestamp < timestamp) {
      try {
        final data = loaded['data'];
        _cache.value = _Cached(timestamp, _restore(data));
        _log('$_key restored');
      } catch (it) {
        _log("$_key restore failed: $it");
      }
    } else {
      _log('$_key outdated');
    }
  }

  store(dynamic json) {
    final timestamp = _now;
    final data = <String, dynamic>{};
    data['timestamp'] = timestamp;
    data['data'] = json;
    _storage.save(_key, data);
    _cache.value = _Cached(timestamp, _restore(json));
  }

  int get _now => DateTime.timestamp().millisecondsSinceEpoch;
}

class _Cached<T> {
  final int timestamp;
  final T value;

  _Cached(this.timestamp, this.value);
}
