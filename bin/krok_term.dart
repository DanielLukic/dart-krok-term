import 'dart:io';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:krok_term/src/krok_term/core/selected_currency.dart';
import 'package:krok_term/src/krok_term/core/selected_pair.dart';
import 'package:krok_term/src/krok_term/feature/alerting.dart';
import 'package:krok_term/src/krok_term/feature/alerts.dart';
import 'package:krok_term/src/krok_term/feature/asset_pair.dart';
import 'package:krok_term/src/krok_term/feature/balances.dart';
import 'package:krok_term/src/krok_term/feature/chart.dart';
import 'package:krok_term/src/krok_term/feature/closed_orders.dart';
import 'package:krok_term/src/krok_term/feature/debug_log.dart';
import 'package:krok_term/src/krok_term/feature/open_orders.dart';
import 'package:krok_term/src/krok_term/feature/portfolio.dart';
import 'package:krok_term/src/krok_term/feature/select_pair.dart';
import 'package:krok_term/src/krok_term/feature/status.dart';
import 'package:krok_term/src/krok_term/feature/ticker.dart';
import 'package:krok_term/src/krok_term/repository/alerts_repo.dart';
import 'package:krok_term/src/krok_term/repository/krok_repos.dart';
import 'package:rxdart/transformers.dart';

void main(List<String> args) async {
  final conIO = MadConIO();
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
      position: RelativePosition.fromBottomRight(),
    );

_initLog() {
  final logfile = fileSink('krok.log', truncate: true);
  sink = (e) {
    final filter = e.toString();
    if (filter.contains("package:krok/")) {
      krokLog.add(e);
    } else if (filter.contains("[!]")) {
      activityLog.add(e);
    } else {
      krokTermLog.add(e);
    }
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
  desktop.onKey(cKey, description: "Go to chart", action: openChart);
  desktop.onKey(lKey, description: "Go to log", action: openLog);
  desktop.onKey("g<S-c>",
      description: "Go to closed orders", action: openClosedOrders);
  desktop.onKey("g<S-o>",
      description: "Go to open orders", action: openOpenOrders);
  desktop.onKey(pKey, description: "Go to profile", action: openPortfolio);
  desktop.onKey(sKey, description: "Go to status", action: openStatus);
  desktop.onKey(tKey, description: "Go to ticker", action: openTicker);

  openAlerts();
  openAssetPair();
  openBalances();
  openChart();
  openLog();
  openClosedOrders();
  openOpenOrders();
  openPortfolio();
  openStatus();
  openTicker();

  desktop.focusById('chart');

  final alerting = Alerting(tickersRepo);

  desktop.stream().whereType<AlertAdd>().listen((event) {
    logInfo('alert add ${event.presetPrice}');
    alerting.onAdd(event);
  });
}
