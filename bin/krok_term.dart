import 'dart:io';

import 'package:dart_consul/dart_consul.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:krok_term/src/krok_term/core/selected_currency.dart';
import 'package:krok_term/src/krok_term/core/selected_pair.dart';
import 'package:krok_term/src/krok_term/feature/asset_pair.dart';
import 'package:krok_term/src/krok_term/feature/balances.dart';
import 'package:krok_term/src/krok_term/feature/chart.dart';
import 'package:krok_term/src/krok_term/feature/debug_log.dart';
import 'package:krok_term/src/krok_term/feature/select_pair.dart';
import 'package:krok_term/src/krok_term/feature/ticker.dart';
import 'package:krok_term/src/krok_term/repository/krok_repos.dart';

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
  final logfile = fileSink("krok.log");
  sink = (e) {
    eventDebugLog.add(e);
    logfile(e);
  };
  logLevel = LogLevel.verbose;
}

_initKrokTerm() async {
  logInfo('init krok storage');
  final storage = Storage(path: 'krok');

  initCurrency(storage);
  initSelectedPair(storage);
  initKrokRepos(storage);
  initKrokCore();

  selectPair() {
    openAssetPair();
    selectAssetPair();
  }

  desktop.onKey("/", description: "Select asset pair", action: selectPair);
  desktop.onKey("gb", description: "Go to balances", action: openBalances);
  desktop.onKey("gc", description: "Go to chart", action: openChart);
  desktop.onKey("gl", description: "Go to log", action: openLog);
  desktop.onKey("gt", description: "Go to ticker", action: openTicker);

  openAssetPair();
  openBalances();
  openChart();
  openLog();
  openTicker();
}
