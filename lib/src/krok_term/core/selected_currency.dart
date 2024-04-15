import 'package:dart_minilog/dart_minilog.dart';

import 'krok_core.dart';

extension type Currency(String _plain) {
  Currency.fromPlain(String currency)
      : assert(!currency.startsWith("Z")),
        _plain = currency;

  Currency.fromZ(String currency)
      : assert(currency.startsWith("Z")),
        _plain = currency;

  String get quote => z;

  String get plain => _plain;

  String get z => "Z$plain";
}

final knownCurrencies = ['AUD', 'CAD', 'EUR', 'GBP', 'USD', 'JPY'];

late final TimestampedStorage<Currency> _currency;

Stream<Currency> get currency => _currency.stream;

initCurrency(Storage storage) {
  logVerbose('init krok currency');
  _currency = TimestampedStorage<Currency>(
    storage: storage,
    key: "selected_currency",
    restore: (e) => e,
    log: logVerbose,
    restoreDefault: Currency.fromPlain('USD'),
  );
  _currency.restore();
}
