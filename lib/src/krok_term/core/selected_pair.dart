import 'krok_core.dart';

late final TimestampedStorage<Pair> _selectedPair;

Stream<Pair> get selectedPair => _selectedPair.stream;

selectPair(Pair wsname) {
  if (!wsname.contains("/")) {
    throw ArgumentError("must use wsname instead of $wsname", "wsname");
  }
  logEvent("select pair (wsname): $wsname");
  return _selectedPair.store(wsname);
}

initSelectedPair(Storage storage) {
  logEvent('init selected pair');
  _selectedPair = TimestampedStorage<Pair>(
    storage: storage,
    key: "selected_pair",
    restore: (e) => e,
    log: logEvent,
    restoreDefault: 'XBT/USD',
  );
  _selectedPair.restore();
}
