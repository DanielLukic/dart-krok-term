import 'package:dart_consul/dart_consul.dart';
import 'package:rxdart/streams.dart';

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

  _window.autoDispose(
    "update",
    CombineLatestStream.list<dynamic>(
            [assets, assetPairs, balances, currency, tickers])
        .map((e) => _toEntries(e[0], e[1], e[2], e[3], e[4]))
        .listen((e) => _updateResult(e)),
  );
}

List<String> _toEntries(
  Assets assets,
  AssetPairs assetPairs,
  Balances balances,
  Currency currency,
  Tickers tickers,
) {
  final result = <String>[];
  for (var b in balances.values) {
    final ap = assetPairs.values
        .where((e) => e.base == b.asset && e.quote == currency.z)
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
