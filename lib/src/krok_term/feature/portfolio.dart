import 'package:dart_consul/dart_consul.dart';
import 'package:krok_term/src/krok_term/repository/portfolio_repo.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_transform/stream_transform.dart';

import '../common/window.dart';
import '../core/krok_core.dart';
import '../repository/krok_repos.dart';

final _window = window("portfolio", 40, 1) //
  ..name = "Portfolio [$pKey]"
  ..position = AbsolutePosition(105, 0)
  ..size = WindowSize.min(Size(40, 2));

void openPortfolio() => autoWindow(_window, () => _create());

void _create() {
  _window.onKey("u",
      description: "Update data",
      action: () => portfolioRepo.refresh(userRequest: true));

  _window.chainOnMouseEvent((p0) {
    if (p0.isUp) {
      _expanded.value = !_expanded.value;
      _window.requestRedraw();
    }
    return null;
  });

  _window.autoDispose(
      "update",
      portfolio
          .combineLatest(_expanded, (p, e) => (p, e))
          .listenSafely((e) => _updateResult(e.$1, e.$2)));
}

final _expanded = BehaviorSubject.seeded(false);

_updateResult(PortfolioData data, bool expanded) {
  final size = expanded ? Size(40, 9) : Size(40, 1);
  desktop.sendMessage(("resize-window", _window, size));

  if (!expanded) {
    final header = "${data.eb}${"USD".gray()}| (click to open)";
    final buffer = Buffer(40, 1);
    buffer.fill(32);
    buffer.drawBuffer(0, 0, header.columns("R15|R25", "|"));
    _window.update(() => buffer.frame());
  } else {
    final header = "${data.eb}${"USD".gray()}| (click to close)";
    final buffer = Buffer(40, 9);
    buffer.fill(32);
    buffer.drawBuffer(0, 0, header.columns("R15|R25", "|"));

    final rows = [
      [data.tb, "tb"],
      [data.m, "margin open"],
      [data.n, "p/l open"],
      [data.c, "cost open"],
      [data.v, "float open"],
      [data.e, "equity"],
      [data.mf, "margin free"],
      [data.uv, "unfilled/partial"],
    ];
    for (final (i, r) in rows.indexed) {
      final row = "${r[0]}${"USD".gray()}| ${r[1]}";
      final aligned = row.columns("R15|L25", "|");
      buffer.drawBuffer(0, 1 + i, aligned);
    }
    _window.update(() => buffer.frame());
  }
}
