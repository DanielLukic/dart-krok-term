import 'package:dart_minilog/dart_minilog.dart';
import 'package:krok_term/src/krok_term/repository/notifications_repo.dart';
import 'package:krok_term/src/krok_term/repository/orders_repo.dart';
import 'package:stream_transform/stream_transform.dart';

import '../common/storage.dart';
import '../core/selected_pair.dart';
import 'alerts_repo.dart';
import 'asset_pairs_repo.dart';
import 'assets_repo.dart';
import 'balances_repo.dart';
import 'ohlc_repo.dart';
import 'portfolio_repo.dart';
import 'ticker_repo.dart';

late AlertsRepo alertsRepo;
late AssetsRepo assetsRepo;
late AssetPairsRepo assetPairsRepo;
late BalancesRepo balancesRepo;
late ClosedOrdersRepo closedOrdersRepo;
late NotificationsRepo notificationsRepo;
late OhlcRepo ohlcRepo;
late OpenOrdersRepo openOrdersRepo;
late PortfolioRepo portfolioRepo;
late TickersRepo tickersRepo;

Stream<Alerts> get alerts => alertsRepo.subscribe();

Stream<Assets> get assets => assetsRepo.subscribe();

Stream<AssetPairs> get assetPairs => assetPairsRepo.subscribe();

Stream<Balances> get balances => balancesRepo.subscribe();

Stream<Notifications> get notifications => notificationsRepo.subscribe();

Stream<Orders> get closedOrders => closedOrdersRepo.subscribe();

Stream<Orders> get openOrders => openOrdersRepo.subscribe();

Stream<Portfolio> get portfolio => portfolioRepo.subscribe();

Stream<Tickers> get tickers => tickersRepo.subscribe();

Stream<AssetPairData> get selectedAssetPair =>
    selectedPair.combineLatest(assetPairs, _pickAssetPair);

AssetPairData _pickAssetPair(AssetPair it, AssetPairs ap) {
  final match = ap.values.where((e) => e.wsname == it.wsname).singleOrNull;
  if (match == null) {
    throw ArgumentError("selected asset pair not found in $ap", it.wsname);
  }
  return match;
}

initKrokRepos(Storage storage) {
  logVerbose('init krok repos');
  alertsRepo = AlertsRepo(storage);
  assetsRepo = AssetsRepo(storage);
  assetPairsRepo = AssetPairsRepo(storage);
  balancesRepo = BalancesRepo(storage);
  closedOrdersRepo = ClosedOrdersRepo(storage);
  notificationsRepo = NotificationsRepo(storage);
  ohlcRepo = OhlcRepo(storage);
  openOrdersRepo = OpenOrdersRepo(storage);
  portfolioRepo = PortfolioRepo(storage);
  tickersRepo = TickersRepo(storage);
}
