import 'dart:async';

import 'package:dart_consul/dart_consul.dart';

import '../common/window.dart';
import '../core/krok_core.dart';
import '../core/selected_currency.dart';
import '../repository/asset_pairs_repo.dart';
import '../repository/assets_repo.dart';
import '../repository/balances_repo.dart';
import '../repository/krok_repos.dart';
import '../repository/ticker_repo.dart';

final _window = window("balances", 55, 10) //
  ..name = "Balances [gb]"
  ..position = AbsolutePosition(0, 31);

void openBalances() => autoWindow(_window, _create);

String _buffer = "";

final _columns = "L6|R10|R9|R15|R15";

void _create() {
  scrolled(
    _window,
    () => _buffer,
    header: "Coin Price 24H Balance EST.VALUE".columns(_columns),
  );

  _window.onKey("u",
      description: "Update balances now", action: balancesRepo.refresh);

  // TODO Seems rxdart is broken. Have not investigated much.
  // final b = balancesRepo.subscribe();
  // final c = currency.startWith("USD");
  // final a = assetsRepo.subscribe().startWith({});
  // final ap = assetPairsRepo.subscribe().startWith({});
  // final t = tickersRepo.subscribe().startWith({});
  // final s = b.withLatestFrom4(c, a, ap, t, _toEntries);
  // _window.autoDispose("update", s.listen(_updateResult));

  // TODO This works as expected:
  _window.autoDispose("update", _combined());
}

Disposable _combined() {
  final dispose = CompositeDisposable();
  Assets? a;
  AssetPairs? ap;
  Balances? b;
  Currency? c;
  Tickers? t;

  update<T>(Stream<T> stream, Function(T) update) {
    dispose.wrap(stream.listen((it) {
      update(it);
      if (a == null) return;
      if (ap == null) return;
      if (b == null) return;
      if (c == null) return;
      if (t == null) return;
      _updateResult(_toEntries(b!, c!, a!, ap!, t!));
    }));
  }

  update(assetsRepo.subscribe(), (it) => a = it);
  update(assetPairsRepo.subscribe(), (it) => ap = it);
  update(balancesRepo.subscribe(), (it) => b = it);
  update(currency, (it) => c = it);
  update(tickersRepo.subscribe(), (it) => t = it);

  return dispose;
}

List<String> _toEntries(
  Balances balances,
  Currency currency,
  Assets assets,
  AssetPairs assetPairs,
  Tickers tickers,
) {
  final result = <String>[];
  for (var b in balances.values) {
    final ap = assetPairs.values
        .where((e) => e.base == b.asset && e.quote == currency)
        .singleOrNull;
    final pair = ap?.altname;
    final td = tickers[pair];
    if (td == null) continue;

    final a = b.asset;

    final pd = ap?.pair_decimals ?? 0;
    int d = assets.values.where((e) => e.name == a).singleOrNull?.display ?? 0;

    final bid = td.last;
    final p = td.ansiPercent;
    final bal = b.volume.toStringAsFixed(d);
    final volume = bid * b.volume;
    if (volume < 0.01) continue;
    final v = volume.toStringAsFixed(2);
    final bi = bid.toStringAsFixed(pd);

    result.add("$a $bi $p $bal $v".columns(_columns));
  }
  result.sort();
  return result;
}

_updateResult(List<String> entries) {
  _buffer = entries.join("\n");
  _window.requestRedraw();
}
