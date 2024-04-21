import 'dart:io';

import 'package:krok_term/src/krok_term/common/settings.dart';
import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:test/test.dart';

File _testFile() => File('tmp/settings.json');

Future _deleteFile() async {
  if (!await _testFile().exists()) return;
  return await _testFile().delete();
}

void main() {
  late PersistentSettings sut;

  setUp(() => sut = PersistentSettings(path: 'tmp/settings.json'));

  setUp(() async => await _deleteFile());
  tearDown(() async => await _deleteFile());

  test('starts empty if notifications file is empty', () async {
    //when
    final actual = await sut.str('null');
    //then
    expect(actual, isNull);
  });

  test('restores existing data', () async {
    //given
    await _testFile().writeAsString('{"null":"not_null"}');
    //when
    final actual = await sut.str('null');
    //then
    expect(actual, equals('not_null'));
  });

  test('updates file when changed', () async {
    //given
    await sut.set('null', 'not_null');
    //when
    final actual = await _testFile().readAsString();
    //then
    expect(actual, equals('{"null":"not_null"}'));
  });

  test('provides changed data', () async {
    //given
    await sut.set('null', 'not_null');
    //when
    final actual = await sut.str('null');
    //then
    expect(actual, equals('not_null'));
  });

  test('provides changed data across restarts', () async {
    //given
    await PersistentSettings(path: _testFile().path).set('null', 'not_null');
    //when
    final actual = await sut.str('null');
    //then
    expect(actual, equals('not_null'));
  });

  test('streams existing value right away', () async {
    //given
    await _testFile().writeAsString('{"null":"not_null"}');
    //when
    final actual = await sut.stream('null').first;
    //then
    expect(actual, equals('not_null'));
  }, timeout: Timeout(100.millis));

  test('streams initial null value', () async {
    //when
    final actual = await sut.stream('null').first;
    //then
    expect(actual, isNull);
  }, timeout: Timeout(100.millis));

  test('streams latest update', () async {
    //given
    await sut.set('null', 'null');
    await sut.set('null', 'not_null');
    await sut.set('null', 'something');
    //when
    final actual = await sut.stream('null').first;
    //then
    expect(actual, equals('something'));
  }, timeout: Timeout(100.millis));

  test('streams updates', () async {
    //given
    final actual = sut.stream('null').take(4).toList();
    //when
    await sut.set('null', 'null');
    await sut.set('null', 'not_null');
    await sut.set('null', 'something');
    //then
    expect(
      await actual,
      containsAllInOrder([null, 'null', 'not_null', 'something']),
    );
  }, timeout: Timeout(100.millis));
}
