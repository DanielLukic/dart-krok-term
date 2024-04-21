import 'dart:convert';
import 'dart:io';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:rxdart/rxdart.dart';

class PersistentSettings {
  final File _file;

  PersistentSettings({required String path}) : _file = File(path);

  Map<String, dynamic>? _data;
  final _updates = PublishSubject<(DateTime, Map<String, dynamic>)>();

  Future<Map<String, dynamic>> _ensureLoaded() async {
    try {
      if (_data != null) return _data!;
      if (!await _file.exists()) return {};
      final String json = await _file.readAsString();
      final result = jsonDecode(json);
      _data = result;
      return result;
    } catch (it) {
      logWarn('failed reading settings - ignored: $it');
      return {};
    }
  }

  Stream<T?> stream<T>(String key) => _ensureLoaded()
      .asStream()
      .concatWith([_updates.map((d) => d.$2)]).map((m) => m[key]);

  Future set(String key, dynamic value) async {
    try {
      final d = await _ensureLoaded();
      d[key] = value;
      _updates.add((DateTime.timestamp(), d));
      await _file.writeAsString(jsonEncode(d));
    } catch (it) {
      logWarn('failed writing settings - ignored: $it');
    }
  }

  Future<String?> str(String key) async => (await _ensureLoaded())[key];

  Future<bool?> b(String key) async => (await _ensureLoaded())[key];

  Future<double?> d(String key) async => (await _ensureLoaded())[key];

  Future<int?> i(String key) async => (await _ensureLoaded())[key];

  Future<List?> l(String key) async => (await _ensureLoaded())[key];

  Future<Map?> m(String key) async => (await _ensureLoaded())[key];
}
