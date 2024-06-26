import 'dart:io';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:krok_term/src/krok_term/core/selected_currency.dart';
import 'package:krok_term/src/krok_term/core/selected_pair.dart';
import 'package:krok_term/src/krok_term/feature/alerting.dart';
import 'package:krok_term/src/krok_term/feature/alerts.dart';
import 'package:krok_term/src/krok_term/feature/asset_pair.dart';
import 'package:krok_term/src/krok_term/feature/balances.dart';
import 'package:krok_term/src/krok_term/feature/bots.dart';
import 'package:krok_term/src/krok_term/feature/chart/chart.dart';
import 'package:krok_term/src/krok_term/feature/debug_log.dart';
import 'package:krok_term/src/krok_term/feature/logic/alert_tracking.dart';
import 'package:krok_term/src/krok_term/feature/logic/order_tracking.dart';
import 'package:krok_term/src/krok_term/feature/notifications.dart';
import 'package:krok_term/src/krok_term/feature/orders/closed_orders.dart';
import 'package:krok_term/src/krok_term/feature/orders/editing.dart';
import 'package:krok_term/src/krok_term/feature/orders/open_orders.dart';
import 'package:krok_term/src/krok_term/feature/orders/ordering.dart';
import 'package:krok_term/src/krok_term/feature/portfolio.dart';
import 'package:krok_term/src/krok_term/feature/select_pair.dart';
import 'package:krok_term/src/krok_term/feature/status.dart';
import 'package:krok_term/src/krok_term/feature/ticker.dart';
import 'package:krok_term/src/krok_term/repository/krok_repos.dart';

void main(List<String> args) async {
  final conIO = TermLibConIO();
  try {
    desktop = Desktop(conIO: conIO);
    desktop.setDefaultKeys();
    desktop.onKey("q", description: "Quit", action: desktop.exit);
    _addAutoHelp();
    _initLog();
    _initKrokTerm();
    await desktop.run();
  } finally {
    conIO.close();
  }
  exit(0); // to force exit with timers etc running
}

_addAutoHelp() => addAutoHelp(
      desktop,
      key: "gh",
      aliases: ['<C-?>'],
      position: RelativePosition.fromBottomRight(),
    );

_initLog() {
  final logfile = fileSink('krok.log', truncate: true);
  sink = (e) {
    final filter = e.toString();
    if (!filter.contains("package:krok/")) krokTermLog.add(e);
    logfile(e);
  };
  logLevel = LogLevel.verbose;
}

_initKrokTerm() async {
  logVerbose('init krok storage');
  final storage = Storage(path: 'krok');

  initCurrency(storage);
  initSelectedPair(storage);
  initKrokRepos(storage);
  initKrokCore();

  desktop.onKey("/", description: "Select asset pair", action: selectAssetPair);
  desktop.onKey(aKey, description: "Go to alerts", action: openAlerts);
  desktop.onKey(bKey, description: "Go to balances", action: openBalances);
  desktop.onKey('g<S-b>', description: "Go to bots", action: openBots);
  desktop.onKey(cKey, description: "Go to chart", action: openChart);
  desktop.onKey(lKey, description: "Go to log", action: openLog);
  desktop.onKey("g<S-c>",
      description: "Go to closed orders", action: openClosedOrders);
  desktop.onKey("g<S-o>",
      description: "Go to open orders", action: openOpenOrders);
  desktop.onKey(nKey,
      description: "Go to notifications", action: openNotifications);
  desktop.onKey(pKey, description: "Go to profile", action: openPortfolio);
  desktop.onKey(sKey, description: "Go to status", action: openStatus);
  desktop.onKey(tKey, description: "Go to ticker", action: openTicker);

  openAlerts();
  openAssetPair();
  openBalances();
  openBots();
  openChart();
  openLog();
  openClosedOrders();
  openNotifications();
  openOpenOrders();
  openPortfolio();
  openStatus();
  openTicker();

  desktop.focusById('log');
  desktop.focusById('chart');
  desktop.focusById('bots');

  desktop.stream().listen((it) {
    if (it is AddAlert) onAddAlert(it);
    if (it is EditOrder) onEditOrder(it);
    if (it is PlaceOrder) onPlaceOrder(it);

    if (it is AlertTriggered) onNotification(it.asNotification());

    if (it case ('select-pair', String wsname)) {
      selectPair(AssetPair.fromWsName(wsname));
    }
  });

  startAlertTracking();
  startOrderTracking();

  final kind = [('b', OrderDirection.buy), ('s', OrderDirection.sell)];
  for (final (k, d) in kind) {
    final n = d.name;
    desktop.onKey('${k}m',
        description: 'Place $n market order',
        action: () => _placeOrder(dir: d, type: OrderType.market));
    desktop.onKey('${k}l',
        description: 'Place $n limit order',
        action: () => _placeOrder(dir: d, type: OrderType.limit));
    desktop.onKey('${k}p',
        description: 'Place $n take profit order',
        action: () => _placeOrder(dir: d, type: OrderType.takeProfit));
    desktop.onKey('$k<S-p>',
        description: 'Place $n take profit limit order',
        action: () => _placeOrder(dir: d, type: OrderType.takeProfitLimit));
    desktop.onKey('${k}sl',
        description: 'Place $n stop loss order',
        action: () => _placeOrder(dir: d, type: OrderType.stopLoss));
    desktop.onKey('${k}ss',
        description: 'Place $n stop loss limit order',
        action: () => _placeOrder(dir: d, type: OrderType.stopLossLimit));
    desktop.onKey('${k}ts',
        description: 'Place $n trailing stop order',
        action: () => _placeOrder(dir: d, type: OrderType.trailingStop));
    desktop.onKey('${k}tt',
        description: 'Place $n trailing stop limit order',
        action: () => _placeOrder(dir: d, type: OrderType.trailingStopLimit));
  }
}

void _placeOrder({required OrderDirection dir, required OrderType type}) {
  desktop.sendMessage(('place-order', dir, type));
}
