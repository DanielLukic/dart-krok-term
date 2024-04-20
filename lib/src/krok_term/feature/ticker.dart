import 'dart:math';

import 'package:dart_consul/dart_consul.dart';
import 'package:krok_term/src/krok_term/core/selected_pair.dart';
import 'package:stream_transform/stream_transform.dart';

import '../common/functions.dart';
import '../common/window.dart';
import '../core/krok_core.dart';
import '../core/selected_currency.dart';
import '../repository/asset_pairs_repo.dart';
import '../repository/krok_repos.dart';
import '../repository/ticker_repo.dart';

final _window = window("ticker", 41, 29) //
  ..name = "Ticker [$tKey]"
  ..position = AbsolutePosition(0, 0);

void openTicker() => autoWindow(_window, () => _create());

late final ScrolledContent _scrolled;
var _buffer = "";
Iterable<_TickerData> _gainers = [];
Iterable<_TickerData> _losers = [];

void _create() {
  _scrolled = scrolled(_window, () => _buffer, ellipsize: true);

  _window.onKey("u",
      description: "Update ticker data",
      action: () => tickersRepo.refresh(userRequest: true));

  _window.chainOnMouseEvent((e) {
    if (!e.isUp) return null;
    final y = e.y - 2 + _scrolled.scrollOffset;
    final left = e.x < _window.width ~/ 2;
    final pick = left ? _gainers : _losers;
    if (y < 0 || y >= pick.length) return null;
    final picked = pick.toList()[y];
    selectPair(picked.ap);
    return ConsumedMouseAction(_window);
  });

  _window.autoDispose(
    "update",
    tickersRepo
        .subscribe()
        .combineLatest(assetPairs, (p0, p1) => (p0, p1))
        .combineLatest(currency, (p0, p1) => (p0.$1, p0.$2, p1))
        .map((tac) => _filter(tac.$1, tac.$2, tac.$3))
        .listen(_updateResult),
  );
}

List<_TickerData> _filter(Tickers result, AssetPairs ap, Currency currency) {
  final List<_TickerData> data = [];
  for (final it in result.values) {
    final ap_ = ap[it.pair];
    if (ap_ == null) continue;
    if (ap_.quote != currency.z) continue;
    data.add(_TickerData(it, ap_.ap));
  }
  data.sort((a, b) => (b.percent.abs() - a.percent.abs()).sign.toInt());
  return data;
}

_updateResult(List<_TickerData> data) {
  _updateBuffer(data);
  _window.requestRedraw();
}

_updateBuffer(List<_TickerData> data) {
  _gainers = data.where((e) => e.percent > 0);
  _losers = data.where((e) => e.percent < 0);
  _updateHeaderMarketIndicator(data, _gainers, _losers);

  final g = _tickerColumn(_gainers);
  final l = _tickerColumn(_losers);
  final target = max(g.length, l.length);
  _ensureSameLength(g, target);
  _ensureSameLength(l, target);

  final columns = zip(g, l).map((e) => "${e.$1} │ ${e.$2}");
  _buffer = columns.join("\n");
}

void _updateHeaderMarketIndicator(
  List<_TickerData> data,
  Iterable<_TickerData> gainers,
  Iterable<_TickerData> losers,
) {
  // gainers MAR|KET losers
  final int all = data.length;
  final gg = "${gainers.length}/$all".green();
  final ll = "${losers.length}/$all".red();
  var m1 = "MAR";
  var m2 = "KET";
  if (gainers.length > data.length / 2) m1 = m1.green();
  if (gainers.length > data.length / 2 && losers.isEmpty) m2 = m2.green();
  if (losers.length > data.length / 2) m2 = m2.red();
  if (losers.length > data.length / 2 && gainers.isEmpty) m1 = m1.red();
  _scrolled.header = "$gg $m1│$m2 $ll".columns("L15|C11|R15");
}

void _ensureSameLength(List<String> g, int target) =>
    g.fillLength(target, "".padRight(_window.width ~/ 2 - 1));

List<String> _tickerColumn(Iterable<_TickerData> data) => data.map((e) {
      final it = e.toString().split(" ");
      final percent = it[1];
      final ap = it[0].ansiPadRight(
        _window.width ~/ 2 - percent.ansiLength - 1,
      );
      return "$ap$percent";
    }).toList();

class _TickerData {
  final AssetPair ap;
  late double percent;
  late String _string;

  _TickerData(TickerData data, this.ap) {
    final name = ap.wsname.highlightSuffix().fixDisplayPair();
    final percent = data.ansiPercent;
    _string = "$name $percent";

    this.percent = data.percent;
  }

  @override
  String toString() => _string;
}
