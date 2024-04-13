import 'package:dart_consul/common.dart';
import 'package:dart_consul/dart_consul.dart';
import 'package:dart_minilog/dart_minilog.dart';

import '../common/desktop.dart';

final _toastDuration = Duration(milliseconds: 600);

void toast(msg) => desktop.toast(msg, duration: _toastDuration);

final krokLog = DebugLog(redraw: () => desktop.redraw(), maxSize: 512);
final krokTermLog = DebugLog(redraw: () => desktop.redraw(), maxSize: 512);
final activityLog = DebugLog(redraw: () => desktop.redraw(), maxSize: 512);

final switchLog = _SwitchLog();

class _SwitchLog implements LogView {
  DebugLog target = krokTermLog;

  @override
  get entries => target.entries;

  void clear() => target.clear();

  void next() {
    if (target == activityLog) {
      toast("Debug Log");
      target = krokTermLog;
    } else if (target == krokTermLog) {
      toast("Krok API Log");
      target = krokLog;
    } else if (target == krokLog) {
      toast("Activity Log");
      target = activityLog;
    }
    desktop.redraw();
  }
}

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
    log: switchLog,
    name: "Log [$lKey] [v,d,i,w,e] [t] [x]",
    position: AbsolutePosition(56, 31),
    size: Size(129, 10),
    filter: filterLogEntry,
  );
  w.flags = {
    WindowFlag.minimizable,
    WindowFlag.resizable,
    WindowFlag.maximizable
  };

  void set(int l) {
    _level = l;
    toast(LogLevel.values[l]);
    w.requestRedraw();
  }

  w.onKey("v", description: "Show verbose level", action: () => set(0));
  w.onKey("d", description: "Show debug level", action: () => set(1));
  w.onKey("i", description: "Show info level", action: () => set(2));
  w.onKey("w", description: "Show warning level", action: () => set(3));
  w.onKey("e", description: "Show error level", action: () => set(4));

  w.onKey("t", description: "Switch log source", action: switchLog.next);

  w.onKey("x", description: "Clear log", action: () {
    switchLog.clear();
    w.requestRedraw();
  });
}

var _level = 1;
final _levels = ['V', 'D', 'I', 'W', 'E'];
final _matcher = RegExp(r"^\d\d:\d\d:\d\d \[(.)]");

bool filterLogEntry(String msg) => msg.toLogLevel() >= _level;

extension StringToLogLevel on String {
  int toLogLevel() {
    final m = _matcher.matchAsPrefix(ansiStripped(this));
    final l = m?.group(1) ?? 'I';
    return _levels.indexOf(l);
  }
}
