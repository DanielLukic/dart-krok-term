import 'package:dart_consul/dart_consul.dart';
import 'package:krok_term/src/krok_term/core/selected_pair.dart';
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
  ..name = "Balances [$bKey]"
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

  _window.chainOnMouseEvent((e) {
    if (!e.isUp || e.y <= 1) return null;
    final index = e.y - 2;
    if (index < 0 || index >= _entries.length) return null;
    selectPair(_entries[index].ap);
    return null;
  });

  _window.onKey("u",
      description: "Update balances now",
      action: () => balancesRepo.refresh(userRequest: true));

  _window.autoDispose(
    "update",
    CombineLatestStream.list<dynamic>(
            [assets, assetPairs, balances, currency, tickers])
        .map((e) => _toEntries(e[0], e[1], e[2], e[3], e[4]))
        .listen((e) => _updateResult(e)),
  );
}

List<AssetPairData> _entries = [];

List<String> _toEntries(
  Assets assets,
  AssetPairs assetPairs,
  Balances balances,
  Currency currency,
  Tickers tickers,
) {
  _entries.clear();

  final result = <String>[];
  for (var b in balances.values) {
    final ap = assetPairs.values
        .where((e) => e.base == b.asset && e.quote == currency.z)
        .singleOrNull;
    if (ap == null) continue;

    final pair = ap.altname;
    final td = tickers[pair];
    if (td == null) continue;

    final a = b.asset;
    final bid = td.last;
    final p = td.ansiPercent;
    final d = _assetDecimalsByName(assets, a);
    final bal = b.volume.toStringAsFixed(d);
    final volume = bid * b.volume;
    if (volume < 1) continue;
    final v = volume.toStringAsFixed(2);
    final bi = bid.toStringAsFixed(ap.pair_decimals);

    result.add("$a $bi $p $bal $v".columns(_columns));

    _entries.add(ap);
  }
  result.sort();
  return result;
}

int _assetDecimalsByName(Assets assets, Asset a) =>
    _assetByName(assets, a)?.display ?? 0;

AssetData? _assetByName(Assets assets, Asset a) =>
    assets.values.where((e) => e.name == a).singleOrNull;

_updateResult(List<String> entries) {
  _buffer = entries.join("\n");
  _window.requestRedraw();
}
