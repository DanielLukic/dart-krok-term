import 'package:dart_consul/dart_consul.dart';

final bKey = 'gb';
final cKey = 'gc';
final lKey = 'gl';
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
