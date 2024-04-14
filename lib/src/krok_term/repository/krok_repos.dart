import 'package:dart_minilog/dart_minilog.dart';
import 'package:krok_term/src/krok_term/repository/orders_repo.dart';
import 'package:stream_transform/stream_transform.dart';

import '../common/storage.dart';
import '../core/selected_pair.dart';
import 'asset_pairs_repo.dart';
import 'assets_repo.dart';
import 'balances_repo.dart';
import 'portfolio_repo.dart';
import 'ticker_repo.dart';

late AssetsRepo assetsRepo;
late AssetPairsRepo assetPairsRepo;
late BalancesRepo balancesRepo;
late ClosedOrdersRepo closedOrdersRepo;
late OpenOrdersRepo openOrdersRepo;
late PortfolioRepo portfolioRepo;
late TickersRepo tickersRepo;

Stream<Assets> get assets => assetsRepo.subscribe().distinct();

Stream<AssetPairs> get assetPairs => assetPairsRepo.subscribe().distinct();

Stream<Balances> get balances => balancesRepo.subscribe().distinct();

Stream<Orders> get closedOrders => closedOrdersRepo.subscribe().distinct();

Stream<Orders> get openOrders => openOrdersRepo.subscribe().distinct();

Stream<Portfolio> get portfolio => portfolioRepo.subscribe().distinct();

Stream<Tickers> get tickers => tickersRepo.subscribe().distinct();

Stream<AssetPairData> get selectedAssetPair =>
    selectedPair.combineLatest(assetPairs, _pickAssetPair).distinct();

AssetPairData _pickAssetPair(AssetPair it, AssetPairs ap) {
  final match = ap.values.where((e) => e.wsname == it.wsname).singleOrNull;
  if (match == null) {
    throw ArgumentError("selected asset pair not found in $ap", it.wsname);
  }
  return match;
}

initKrokRepos(Storage storage) {
  logInfo('init krok repos');
  assetsRepo = AssetsRepo(storage);
  assetPairsRepo = AssetPairsRepo(storage);
  balancesRepo = BalancesRepo(storage);
  closedOrdersRepo = ClosedOrdersRepo(storage);
  openOrdersRepo = OpenOrdersRepo(storage);
  portfolioRepo = PortfolioRepo(storage);
  tickersRepo = TickersRepo(storage);
}
