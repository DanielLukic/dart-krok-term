import 'package:dart_consul/dart_consul.dart';
import 'package:dart_consul/src/util/log.dart' as log;

late Desktop desktop;

void logEvent(msg) {
  eventDebugLog.add(msg);
  log.logInfo(msg);
}

void logError(Object error, [StackTrace? trace]) {
  eventDebugLog.add(error.toString().red());
  log.logError(error, trace);
}

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
