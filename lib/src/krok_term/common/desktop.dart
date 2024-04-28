import 'package:dart_consul/dart_consul.dart';

export 'package:dart_consul/dart_consul.dart';

final aKey = 'ga';
final bKey = 'gb';
final bbKey = 'gB';
final cKey = 'gc';
final lKey = 'gm';
final nKey = 'gn';
final ocKey = 'gC';
final ooKey = 'gO';
final pKey = 'gp';
final sKey = 'gs';
final tKey = 'gt';

late Desktop desktop;

void autoWindow(Window it, Function onCreate) {
  if (_created.contains(it)) {
    desktop.raiseWindow(it);
  } else {
    onCreate();
    desktop.openWindow(it);
    _created.add(it);
  }
}

final _created = <Window>{};
