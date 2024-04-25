import 'package:ansi/ansi.dart';
import 'package:collection/collection.dart';
import 'package:dart_consul/common.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:krok/extensions.dart';
import 'package:krok/krok.dart';
import 'package:krok_term/src/krok_term/common/extensions.dart';

part 'type/alert.dart';
part 'type/add_alert.dart';
part 'type/alert_triggered.dart';
part 'type/asset.dart';
part 'type/asset_pair.dart';
part 'type/balance.dart';
part 'type/notification.dart';
part 'type/ohlc.dart';
part 'type/order.dart';
part 'type/place_order.dart';
part 'type/portfolio.dart';
part 'type/ticker.dart';

typedef Alerts = Map<Asset, List<AlertData>>;
typedef Assets = Map<Asset, AssetData>;
typedef AssetPairs = Map<Pair, AssetPairData>;
typedef Balances = Map<Asset, BalanceData>;
typedef Notifications = List<NotificationData>;
typedef OrderId = String;
typedef Orders = Map<OrderId, OrderData>;
typedef Tickers = Map<Pair, TickerData>;

/// Simplified type for JSON list. Mostly to document intent.
typedef JsonList = List<dynamic>;

/// Simplified type for JSON objects/maps. Mostly to document intent.
typedef JsonObject = Map<String, dynamic>;

/// Attempt at simplifying the pair vs pair name vs wsname handling. Consider
/// this a first step in the right(?) direction.
extension type AssetPair._(String _wsname) {
  AssetPair.fromWsName(String wsname)
      : assert(wsname.contains("/")),
        _wsname = wsname;

  String get wsname => _wsname;
}

/// To handle "proper" equality checks on all models, this base class
/// requires each model to provide all data [fields]. It implements
/// [hashCode], [==] and [toString] using [DeepCollectionEquality] on the
/// this list of [fields].
abstract class BaseModel {
  List<dynamic> get fields;

  @override
  int get hashCode => Object.hashAll(fields);

  @override
  bool operator ==(Object other) {
    if (other is! BaseModel) return false;
    return DeepCollectionEquality().equals(fields, other.fields);
  }

  @override
  String toString() => fields.toString();
}
