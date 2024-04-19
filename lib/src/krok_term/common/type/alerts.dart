part of '../types.dart';

class AlertData extends BaseModel {
  final Asset pair;
  final String wsname;
  final double price;
  final String mode;

  AlertData(this.pair, this.wsname, this.price, this.mode)
      : assert(!pair.contains('/'), 'pair expected instead of wsname: $pair');

  @override
  List get fields => [pair, wsname, price, mode];
}

class AlertTriggered extends BaseModel {
  final AlertData alert;
  final Price trigger;

  AlertTriggered(this.alert, this.trigger);

  @override
  List get fields => [alert, trigger];

  Notification asNotification() => Notification.now(
        alert.pair,
        "price ${alert.mode} ${alert.price}: "
        "$trigger",
        ('select-pair', alert.pair),
      );
}

class AlertAdd extends BaseModel {
  final AssetPairData pair;
  double selectedPrice;
  double lastPrice;
  double refPrice = 0;
  String? presetPrice;
  String label = 'unknown';

  AlertAdd(this.pair, this.selectedPrice, this.lastPrice) {
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
