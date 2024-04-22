part of 'ordering.dart';

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
        'z' => true,
        'price' => true,
        'limit' => true,
        _ => false,
      };

  String get focusedId => DuiLayout.focusedId(this);

  set focusedId(String id) => DuiLayout.setFocused(this, id);

  OrderDirection get dir => this['dir'];

  OrderType get type => this['type'];

  String get descType => type.name.replaceAll('-', ' ');

  bool get isBuy => dir == OrderDirection.buy;

  bool get isMarket => type == OrderType.market;

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

  (double?, String?) get zAck =>
      evalValueInput(this['z'], zMax_, min: ap.costmin, max: zMax_);

  double get zAvail => this['z_ref'] ?? 0;

  double get priceEst {
    if (isMarket) return isBuy ? ask : bid;
    return evalValueInput(this['price'], priceRef).$1 ?? 0;
  }

  AssetPairData get ap => this['pair'] as AssetPairData;

  double get volMax_ {
    if (isBuy) {
      if (zAvail > 0 && priceEst > 0) {
        return zAvail / priceEst;
      } else {
        return 0;
      }
    } else {
      return volumeRef;
    }
  }

  String get volMax {
    final vm = volMax_;
    if (vm > 0) return ap.volume(vm);
    return isBuy ? '...' : 'loading'.gray();
  }

  String get volMin => '${ap.ordermin}';

  double get zMax_ {
    if (isBuy) return zAvail;

    final double vr = volumeRef;
    final double pr = priceRef;
    final double price = isMarket ? pr : priceEst;
    return (vr * price);
  }

  String get zMax => zMax_ == 0 ? '...' : zMax_.toStringAsFixed(2);

  String get zMin => '${ap.costmin}';

  void updateForTrailing() {
    final p = (this['price'] as String);
    if (p.startsWith('-')) this['price'] = p.replaceFirst('-', '+');
    if (p.startsWith('#')) this['price'] = p.replaceFirst('-', '+');
    if (!p.startsWith('+')) this['price'] = '+';

    final limit = (this['limit'] as String);
    if (limit.startsWith('+')) return;
    if (limit.startsWith('-')) return;
    this['limit'] = '';
  }

  void updateZFromVolume(String v) {
    if (v.isEmpty || v.endsWith('%')) {
      this['z'] = v;
    } else {
      final va = volumeAck.$1;
      if (va != null) {
        this['z'] = (va * priceEst).toStringAsFixed(2);
      } else {
        this['z'] = '';
      }
    }
  }

  void updateVolumeFromZ(String z) {
    if (z.isEmpty || z.endsWith('%')) {
      this['volume'] = z;
    } else {
      final za = zAck.$1;
      if (za != null) {
        this['volume'] = ap.volume(za / priceEst);
      } else {
        this['volume'] = '';
      }
    }
  }

  String get description {
    final va = volumeAck.$1 ?? '<vol>'.red();
    var d = '${dir.name} $va ${ap.pair} @ $descType';
    if (isMarket) return d;

    final limited = d.endsWith(' limit') && !(type == OrderType.limit);
    if (limited) d = d.dropLast(6);

    final pa = priceAck.$1 != null ? this['price'] : '<price>'.red();
    d += " $pa";
    if (!limited) return d;

    final la = limitAck.$1 != null ? this['limit'] : '<limit>'.red();
    d += " -> limit $la";
    return d;
  }

  List<String> get help {
    final List<String> help;
    if (focusedId == 'volume' || focusedId == 'z') {
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
