import 'dart:io';

import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:krok_term/src/krok_term/repository/notifications_repo.dart';
import 'package:test/test.dart';

File _testFile() => File('tmp/notifications');

Future _deleteFile() async {
  final f = _testFile();
  if (await f.exists()) await f.delete();
}

// only to have some async test...

void main() {
  final Storage storage = Storage(path: 'tmp');

  setUp(() async => await _deleteFile());
  tearDown(() async => await _deleteFile());

  test('starts empty if notifications file is empty', () async {
    //when
    final sut = NotificationsRepo(storage);
    final actual = await sut.subscribe().first;
    //then
    await sut.close();
    expect(actual, isEmpty);
  });

  test('appends json lines', () async {
    //given
    final sut = NotificationsRepo(storage);
    //when
    sut.add(Notification(1, '1', 'desc', ('msg', 'null')));
    sut.add(Notification(2, '2', 'desc', ('msg', 'null')));
    //then
    await sut.close();
    final actual = await _testFile().readAsLines();
    expect(
        actual,
        containsAllInOrder([
          '[1,"1","desc","msg","null"]',
          '[2,"2","desc","msg","null"]',
        ]));
  });

  test('restores notifications upon creation', () async {
    //given
    await storage.append('notifications', '[1,"1","desc","msg","null"]\n');
    await storage.append('notifications', '[2,"2","desc","msg","null"]\n');
    //when
    final sut = NotificationsRepo(storage);
    final actual = await sut.subscribe().first;
    //then
    await sut.close();
    expect(
        actual,
        containsAllInOrder([
          Notification(1, "1", "desc", ("msg", "null")),
          Notification(2, "2", "desc", ("msg", "null")),
        ]));
  });

  test('restores added notifications', () async {
    //given
    final pre = NotificationsRepo(storage);
    pre.add(Notification(1, '1', 'desc', ('msg', 'null')));
    pre.add(Notification(2, '2', 'desc', ('msg', 'null')));
    await pre.close();
    //when
    final sut = NotificationsRepo(storage);
    final actual = await sut.subscribe().first;
    //then
    await sut.close();
    expect(
        actual,
        containsAllInOrder([
          Notification(1, "1", "desc", ("msg", "null")),
          Notification(2, "2", "desc", ("msg", "null")),
        ]));
  });
}
