import 'krok_core.dart';

typedef Currency = String;

final knownCurrencies = ['AUD', 'CAD', 'EUR', 'GBP', 'USD', 'JPY'];

late final TimestampedStorage<Currency> _currency;

Stream<Currency> get currency => _currency.stream.map((e) => "Z$e");

initCurrency(Storage storage) {
  logEvent('init krok currency');
  _currency = TimestampedStorage<Currency>(
    storage: storage,
    key: "selected_currency",
    restore: (e) => e,
    log: logEvent,
    restoreDefault: 'USD',
  );
  _currency.restore();
}
