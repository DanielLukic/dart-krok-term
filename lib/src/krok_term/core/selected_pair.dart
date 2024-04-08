import 'krok_core.dart';

late final TimestampedStorage<Pair> _selectedPair;

Stream<Pair> get selectedPair => _selectedPair.stream;

selectPair(Pair it) {
  logEvent("select pair: $it");
  return _selectedPair.store(it);
}

initSelectedPair(Storage storage) {
  logEvent('init selected pair');
  _selectedPair = TimestampedStorage<Pair>(
    storage: storage,
    key: "selected_pair",
    restore: (e) => e,
    log: logEvent,
    restoreDefault: 'XXBTZUSD',
  );
  _selectedPair.restore();
}
