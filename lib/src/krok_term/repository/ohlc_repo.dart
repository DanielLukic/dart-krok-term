import '../core/krok_core.dart';
import 'asset_pairs_repo.dart';

class OHLC extends BaseModel {
  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;

  @override
  List get fields => [timestamp, open, high, low, close];

  OHLC(this.timestamp, this.open, this.high, this.low, this.close);

  factory OHLC.parse(List<dynamic> data) {
    final timestamp = data[0] as int;
    final open = double.parse(data[1]);
    final high = double.parse(data[2]);
    final low = double.parse(data[3]);
    final close = double.parse(data[4]);
    return OHLC(timestamp, open, high, low, close);
  }
}

Stream<List<OHLC>> ohlc(AssetPairData ap, OhlcInterval interval) =>
    retrieve(KrakenRequest.ohlc(pair: ap.pair, interval: interval))
        .map((json) => json[ap.pair] as List<dynamic>)
        .map((list) => list.mapList((e) => OHLC.parse(e)));
