import 'package:dart_minilog/dart_minilog.dart';

import 'krok_core.dart';

late final TimestampedStorage<AssetPair> _selectedPair;

Stream<AssetPair> get selectedPair => _selectedPair.stream;

selectPair(AssetPair pair) {
  logVerbose('select pair (wsname): $pair');
  _selectedPair.store(pair);
}

initSelectedPair(Storage storage) {
  logVerbose('init selected pair');
  _selectedPair = TimestampedStorage<AssetPair>(
    storage: storage,
    key: "selected_pair",
    restore: (e) => e,
    log: logVerbose,
    restoreDefault: AssetPair.fromWsName('XBT/USD'),
  );
  _selectedPair.restore();
}
