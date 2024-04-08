import 'dart:async';

import 'package:dart_consul/dart_consul.dart';

Window window(String id, int width, int height) => Window(
      id,
      id,
      size: WindowSize.fixed(Size(width, height)),
      flags: {WindowFlag.minimizable},
      redraw: () => "retrieving data...",
    );

extension KrokWindowExtensions on Window {
  bool get isVisible => !isInvisible;

  bool get isInvisible => isClosed || isMinimized;

  void update(OnRedraw redraw) {
    redrawBuffer = redraw;
    requestRedraw();
  }

  void periodic(Duration duration, Function function) {
    void periodic() {
      if (isVisible) {
        function();
        final tick = Timer.periodic(duration, (timer) => function());
        autoDispose("tick", tick);
      } else {
        dispose("tick");
      }
    }

    onStateChanged.add(periodic);
    autoDispose("periodic", () => onStateChanged.remove(periodic));

    periodic();
  }
}
