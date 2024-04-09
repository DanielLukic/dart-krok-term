import 'package:dart_consul/dart_consul.dart';

import '../common/desktop.dart';

void openLog() {
  final w = desktop.findWindow("log");
  if (w != null) {
    desktop.raiseWindow(w);
  } else {
    _openLog();
  }
}

_openLog() {
  final w = addDebugLog(
    desktop,
    name: "Log [gl] [v,i,w,e]",
    key: "",
    position: AbsolutePosition(56, 31),
    filter: filterLogEntry,
  );

  void set(int l) {
    _level = l;
    w.requestRedraw();
  }

  w.onKey("v", description: "Show verbose level", action: () => set(0));
  w.onKey("i", description: "Show info level", action: () => set(1));
  w.onKey("w", description: "Show warning level", action: () => set(2));
  w.onKey("e", description: "Show error level", action: () => set(3));
}

var _level = 1;
final _levels = ['V', 'I', 'W', 'E'];
final _matcher = RegExp(r"^\d\d:\d\d:\d\d \[(.)]");

bool filterLogEntry(String msg) => msg.toLogLevel() >= _level;

extension StringToLogLevel on String {
  int toLogLevel() {
    final m = _matcher.matchAsPrefix(this);
    final l = m?.group(1) ?? 'I';
    return _levels.indexOf(l);
  }
}
