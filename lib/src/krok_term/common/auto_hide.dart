import 'desktop.dart';
import 'settings.dart';

extension AutoHideWindow on Window {
  void onAutoHide(String id, void Function(bool?) func) {
    settings.b('$id-auto-hide').then(func);
  }

  void addAutoHide(String key, String id, {bool hideByDefault = true}) {
    final it = '$id-auto-hide';
    onKey(
      key,
      description: 'Toggle auto-hide window',
      action: () => settings.b(it).then((v) {
        final value = !(v ?? hideByDefault);
        if (value) {
          desktop.toast('Auto hide on');
        } else {
          desktop.toast('Auto hide off');
        }
        settings.setSynced(it, value);
      }),
    );

    var wasFocused = false;
    onStateChanged.add(() {
      if (wasFocused && !isFocused) {
        settings.b(it).then((e) {
          e = e ?? hideByDefault;
          if (e != false) desktop.minimizeWindow(this);
        });
      }
      wasFocused = isFocused;
    });
  }
}
