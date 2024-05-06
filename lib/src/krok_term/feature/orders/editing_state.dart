part of 'editing.dart';

extension on DuiState {
  BehaviorSubject<(DateTime, DuiState?)> get executor => this['execute'];

  void clearExecution() => executor.value = (DateTime.timestamp(), null);

  void triggerExecuteOrder() => executor.value = (DateTime.timestamp(), this);

  DuiTextInput makeInput(
    String key, {
    bool plusMinus = true,
    bool trailing = false,
  }) {
    final RegExp filter;
    if (plusMinus) {
      if (trailing) {
        filter = RegExp(r"[-+#][0-9]+\.?[0-9]*%?");
      } else {
        filter = RegExp(r"[-+#]?[0-9]+\.?[0-9]*%?");
      }
    } else {
      if (trailing) {
        filter = RegExp(r"\+[0-9]+\.?[0-9]*%?");
      } else {
        filter = RegExp(r"[0-9]+\.?[0-9]*%?");
      }
    }
    final it = DuiTextInput(
      id: key,
      limitLength: 12,
      preset: this[key],
      filter: filter,
    );
    return it..onChange = (e) => this[key] = e;
  }

  bool get inputFocused => switch (focusedId) {
        'volume' => true,
        'price' => true,
        'limit' => true,
        _ => false,
      };

  String get focusedId => DuiLayout.focusedId(this);

  set focusedId(String id) => DuiLayout.setFocused(this, id);

  OrderDirection get dir => this['dir'];

  OrderType get type => this['type'];

  bool get isBuy => dir == OrderDirection.buy;

  bool get isTrailing => type.name.startsWith('trailing');

  bool get needsPrice => type != OrderType.market;

  bool get needsLimit => switch (type) {
        OrderType.stopLossLimit => true,
        OrderType.takeProfitLimit => true,
        OrderType.trailingStopLimit => true,
        _ => false,
      };

  TickerData? get ticker => this['price_ticker'];

  double get ask => ticker?.ask ?? 0;

  double get bid => ticker?.bid ?? 0;

  double get priceRef => isBuy ? ask : bid;

  double get volumeRef => this['volume_ref'] ?? 0;

  (double?, String?) get priceAck => evalValueInput(this['price'], priceRef);

  (double?, String?) get limitAck => evalValueInput(this['limit'], priceRef);

  (double?, String?) get volumeAck =>
      evalValueInput(this['volume'], volMax_, min: ap.ordermin, max: volMax_);

  AssetPairData get ap => this['pair'] as AssetPairData;

  double get volMax_ => volumeRef;

  String get volMax {
    final vm = volMax_;
    if (vm > 0) return ap.volume(vm);
    return isBuy ? '...' : 'loading'.gray();
  }

  String get volMin => '${ap.ordermin}';

  List<String> get help {
    final List<String> help;
    if (focusedId == 'volume') {
      help = [
        'Volume:'.bold().italic(),
        '',
        'Specify values as absolute value or +/-.',
        'Optionally use % with either absolute or +/-.',
        'Use m to set max volume.',
      ];
    } else if (isTrailing && focusedId == 'price') {
      help = [
        'Trailing Stop Price:'.bold().italic(),
        '',
        'For trailing order, price has to start with +.',
        'It is auto mapped by the exchange onto + or -.',
        '',
        'Optionally use %.',
      ];
    } else if (isTrailing && focusedId == 'limit') {
      help = [
        'Trailing Stop Limit:'.bold().italic(),
        '',
        'For trailing order, limit has to use +/-.',
        '',
        'Optionally use %.',
      ];
    } else if (focusedId == 'price' || focusedId == 'limit') {
      help = [
        'Price and Limit:'.bold().italic(),
        '',
        'Specify values as absolute value or +/-.',
        'Or use # to have the exchange auto-choose.',
        '',
        'Optionally use % with either absolute or +/-/#.',
      ];
    } else if (focusedId == 'dir' || focusedId == 'type') {
      help = [
        'Direction and Type:'.bold().italic(),
        '',
        'Use j/k to step through available options.',
      ];
    } else if (focusedId == 'starttm' || focusedId == 'expiretm') {
      help = [
        'Start and expire time:'.bold().italic(),
        '',
        'Specify values as +<seconds>',
        'or as <count>[dhms].',
        'Optionally enter a unix timestamp',
        'or ISO8601 date or datetime.',
      ];
    } else {
      help = [];
    }

    help.addAll([
      if (inputFocused) '',
      if (inputFocused) 'Use x or <C-u> to clear input.',
      '',
      'Use <Escape> to cancel.',
      'Press <Return> to place order.',
    ]);

    return help;
  }
}
