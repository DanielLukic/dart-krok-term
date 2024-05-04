import 'package:krok_term/src/krok_term/common/list_window.dart';
import 'package:krok_term/src/krok_term/core/selected_pair.dart';
import 'package:rxdart/streams.dart';

import '../common/window.dart';
import '../core/krok_core.dart';
import '../core/selected_currency.dart';
import '../repository/krok_repos.dart';

final _window = window("balances", 55, 7) //
  ..name = "Balances [$bKey]"
  ..size = WindowSize.min(Size(55, 7))
  ..position = AbsolutePosition(0, 31);

void openBalances() => autoWindow(_window, _create);

final _columns = "L6|R10|R9|R15|R15";

late final ListWindow _list;

void _create() {
  _list = ListWindow(
    window: _window,
    topOff: 2,
    bottomOff: 3,
    header: "Coin Price 24H Balance EST.VALUE".columns(_columns),
    onSelect: (e) => selectPair(_entries[e].ap),
  );

  _window.onKey("u",
      description: "Update balances now",
      action: () => balancesRepo.refresh(force: true));

  _window.autoDispose(
    "update",
    CombineLatestStream.list<dynamic>(
            [assets, assetPairs, balances, currency, tickers])
        .map((e) => _toEntries(e[0], e[1], e[2], e[3], e[4]))
        .listen((e) => _updateResult(e)),
  );

  _window.autoDispose(
    'order-executed',
    desktop.subscribe(
      'order-executed',
      (e) => balancesRepo.refresh(force: true),
    ),
  );
}

final List<AssetPairData> _entries = [];

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

  final zs = knownCurrencies
      .map((e) => (e, balances[e.z]))
      .where((e) => e.$2 != null)
      .where((e) => e.$2!.volume >= 1);
  if (zs.isEmpty) return result;

  result.add('');
  result.add('Spot');
  for (final z in zs) {
    final v = z.$2?.volume;
    if (v == null || v < 1) continue;
    final a = z.$1.quote;
    final bal = v.toStringAsFixed(2);
    result.add("$a - - $bal $bal".columns(_columns));
  }

  return result;
}

int _assetDecimalsByName(Assets assets, Asset a) =>
    _assetByName(assets, a)?.display ?? 0;

AssetData? _assetByName(Assets assets, Asset a) =>
    assets.values.where((e) => e.name == a).singleOrNull;

_updateResult(List<String> entries) {
  _list.updateEntries(entries);
  _window.requestRedraw();
}
