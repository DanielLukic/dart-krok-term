import 'package:dart_consul/dart_consul.dart';

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
