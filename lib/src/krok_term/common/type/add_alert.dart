part of '../types.dart';

class AddAlert extends BaseModel {
  final AssetPairData pair;
  double selectedPrice;
  double lastPrice;
  double refPrice = 0;
  String? presetPrice;
  String label = 'unknown';

  AddAlert(this.pair, this.selectedPrice, this.lastPrice) {
    final sp = selectedPrice.takeIf(selectedPrice > 0);
    if (sp != null) {
      refPrice = sp;
      label = 'selected';
      presetPrice = sp.let((it) => pair.price(it));
      return;
    }

    final lp = lastPrice.takeIf(lastPrice > 0);
    if (lp != null) {
      refPrice = lp;
      label = "last";
      presetPrice = presetPrice ?? lp.let((it) => pair.price(it));
      return;
    }
  }

  @override
  List get fields => [pair, selectedPrice, lastPrice, presetPrice];
}
