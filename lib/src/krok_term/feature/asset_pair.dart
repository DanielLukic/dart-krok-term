import 'package:dart_consul/dart_consul.dart';
import 'package:stream_transform/stream_transform.dart';

import '../common/window.dart';
import '../core/krok_core.dart';
import '../core/selected_pair.dart';
import '../repository/asset_pairs_repo.dart';
import '../repository/krok_repos.dart';
import '../repository/ticker_repo.dart';
import 'select_pair.dart';

final _window = window("asset-pair", 61, 2) //
  ..name = "Asset Pair [/]"
  ..position = AbsolutePosition(43, 0);

void openAssetPair() => autoWindow(_window, () => _create());

void _create() {
  _window.onKey("u",
      description: "Update data", action: () => tickersRepo.refresh());

  var maybeTrigger = false;
  _window.chainOnMouseEvent((e) {
    if (e.x <= 10) {
      if (e.isDown) maybeTrigger = true;
      if (e.isUp && maybeTrigger) selectAssetPair();
    } else if (e.isDown || e.isUp) {
      maybeTrigger = false;
    }
    return null;
  });

  _window.autoDispose(
    "update",
    selectedPair
        .combineLatest(assetPairs, _pickAssetPair)
        .combineLatest(tickers, _pickTicker)
        .whereNotNull()
        .listenSafely(_updateResult),
  );
}

AssetPairData _pickAssetPair(Pair selected, AssetPairs ap) {
  final match = ap.values.where((e) => e.wsname == selected).singleOrNull;
  if (match == null) {
    throw ArgumentError("selected asset pair not found in $ap", selected);
  }
  return match;
}

(AssetPairData, TickerData) _pickTicker(AssetPairData ap, Tickers t) {
  final data = t[ap.pair];
  if (data == null) {
    throw ArgumentError("selected asset pair not found in $t", ap.pair);
  }
  return (ap, data);
}

_updateResult((AssetPairData, TickerData) data) {
  final ap = data.$1;
  final t = data.$2;
  final currency = ap.wsname.split("/").last;
  final name = ap.wsname.highlightSuffix().fixDisplayPair().bold();
  var last = t.last.toStringAsFixed(2);
  if (t.last < t.priceToday) last = last.red();
  if (t.last > t.priceToday) last = last.green();
  final p = t.ansiPercent;
  final vb = t.volumeLast24.formatLargeNumber();
  final d = (t.volumeLast24 * t.priceToday).formatLargeNumber();
  final vq = d + currency.gray();
  final spec = "L12|L15|L13|L22";
  final header = "Pair|Last Price|24H Change|24H Volume".columns(spec, "|");
  final values = "$name|$last|$p|$vb $vq".columns(spec, "|");
  _window.update(() => "$header\n$values\n");
}
