import '../common/desktop.dart';
import '../common/storage.dart';
import 'asset_pairs_repo.dart';
import 'assets_repo.dart';
import 'balances_repo.dart';
import 'ticker_repo.dart';

late AssetsRepo assetsRepo;
late AssetPairsRepo assetPairsRepo;
late BalancesRepo balancesRepo;
late TickersRepo tickersRepo;

Stream<Assets> get assets => assetsRepo.subscribe();

Stream<AssetPairs> get assetPairs => assetPairsRepo.subscribe();

Stream<Balances> get balances => balancesRepo.subscribe();

Stream<Tickers> get tickers => tickersRepo.subscribe();

initKrokRepos(Storage storage) {
  logEvent('init krok repos');
  assetsRepo = AssetsRepo(storage);
  assetPairsRepo = AssetPairsRepo(storage);
  balancesRepo = BalancesRepo(storage);
  tickersRepo = TickersRepo(storage);
}
