import 'dart:convert';
import 'dart:io';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:rxdart/rxdart.dart';

import 'functions.dart';
import 'types.dart';

class Storage {
  final Directory _directory;

  Storage({required String path}) : _directory = Directory(path);

  File _file(String key) => File(joinPath([_directory.path, key]));

  DateTime? lastModified(String key) {
    final file = _file(key);
    if (!file.existsSync()) return null;
    return file.lastModifiedSync();
  }

  Future<List<String>> lines(key) async {
    final exists = await _directory.exists();
    if (!exists) await _directory.create();

    final file = _file(key);
    if (!await file.exists()) return [];

    return file.readAsLines();
  }

  Future<RandomAccessFile> randomAccess(key) async {
    final exists = await _directory.exists();
    if (!exists) await _directory.create();

    final file = _file(key);
    return file.open(mode: FileMode.append);
  }

  Future<JsonObject?> load(String key) async {
    final exists = await _directory.exists();
    if (!exists) return null;

    final file = _file(key);
    if (!await file.exists()) return null;

    return jsonDecode(await file.readAsString());
  }

  Future save(String key, JsonObject json) async {
    final exists = await _directory.exists();
    if (!exists) await _directory.create();

    final file = _file(key);
    if (await file.exists()) {
      await file.rename("${file.path}.bak");
    }

    await file.writeAsString(jsonEncode(json));
  }

  Future append(String key, String data) async {
    final exists = await _directory.exists();
    if (!exists) await _directory.create();

    final file = _file(key);
    await file.writeAsString(data, mode: FileMode.append);
  }
}

// TODO Switch to lastModified
class TimestampedStorage<T> {
  final Storage _storage;
  final String _key;
  final T Function(dynamic) _restore;
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
        _restoreDefault = restoreDefault;

  final BehaviorSubject<_Cached<T>> _cache = BehaviorSubject();

  bool stillFresh(Duration maxAge) {
    final limit = DateTime.timestamp().subtract(maxAge);
    final lastModified = _storage.lastModified(_key);
    if (lastModified == null) return false;
    return lastModified.isAfter(limit);
  }

  Stream<T> get stream => _cache.stream.map((e) => e.value);

  restore() async {
    final loaded = await _storage.load(_key);
    if (loaded == null) {
      if (_restoreDefault != null && _cache.valueOrNull == null) {
        logVerbose('$_key default');
        store(_restoreDefault);
        return;
      }
      logWarn('$_key not found');
      return;
    }
    final current = _cache.valueOrNull;
    final timestamp = loaded['timestamp'];
    if (current == null || current.timestamp < timestamp) {
      try {
        final data = loaded['data'];
        _cache.value = _Cached(timestamp, _restore(data));
        logVerbose('$_key restored');
      } catch (it, trace) {
        logError('$_key restore failed: $it', trace);
      }
    } else {
      logVerbose('$_key outdated');
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
