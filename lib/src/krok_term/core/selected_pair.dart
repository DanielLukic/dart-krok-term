import 'krok_core.dart';

extension type AssetPair(String _wsname) {
  AssetPair.fromWsName(String wsname)
      : assert(wsname.contains("/")),
        _wsname = wsname;

  String get wsname => _wsname;
}

late final TimestampedStorage<AssetPair> _selectedPair;

Stream<AssetPair> get selectedPair => _selectedPair.stream;

selectPair(AssetPair pair) {
  logEvent("select pair (wsname): $pair");
  return _selectedPair.store(pair);
}

initSelectedPair(Storage storage) {
  logEvent('init selected pair');
  _selectedPair = TimestampedStorage<AssetPair>(
    storage: storage,
    key: "selected_pair",
    restore: (e) => e,
    log: logEvent,
    restoreDefault: AssetPair.fromWsName('XBT/USD'),
  );
  _selectedPair.restore();
}
