import 'package:krok/krok.dart';
import 'package:krok_term/src/krok_term/common/types.dart';
import 'package:test/test.dart';

void main() {
  test('basic price', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('2', trailingStop: false);
    final actual = OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, equals(2.0));
  });

  test('+ price', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('+2', trailingStop: false);
    final actual = OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, equals(4.1));
  });

  test('- price', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('-2', trailingStop: false);
    final actual = OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, closeTo(0.1, 0.0001));
  });

  test('# sell', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('#2', trailingStop: false);
    final actual = OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, closeTo(0.1, 0.0001));
  });

  test('# buy', () {
    final dir = OrderDirection.buy;
    final price = KrakenPrice.fromString('#2', trailingStop: false);
    final actual = OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, equals(4.1));
  });

  test('percentage', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('10%', trailingStop: false);
    final actual = OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, equals(0.21));
  });

  test('+ percentage', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('+10%', trailingStop: false);
    final actual = OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, equals(2.31));
  });

  test('- percentage', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('-10%', trailingStop: false);
    final actual = OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, closeTo(1.89, 0.0001));
  });

  test('# percentage sell', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('#10%', trailingStop: false);
    final actual = OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, closeTo(1.89, 0.0001));
  });

  test('# percentage buy', () {
    final dir = OrderDirection.buy;
    final price = KrakenPrice.fromString('#10%', trailingStop: false);
    final actual = OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, equals(2.31));
  });

  test('+ trailing price', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('+2', trailingStop: true);
    final actual = OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, closeTo(0.1, 0.0001));
  });

  test('+ trailing percentage', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('+10%', trailingStop: true);
    final actual = OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, closeTo(1.89, 0.0001));
  });

  test('+ trailing percentage buy', () {
    final dir = OrderDirection.buy;
    final price = KrakenPrice.fromString('+10%', trailingStop: true);
    final actual = OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, equals(2.31));
  });

  test('+ trailing limit', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('+2', trailingStop: true);
    final actual = OrderData.resolve(dir, price, 2.1, price1: false);
    expect(actual, equals(4.1));
  });

  test('+ trailing limit percentage', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('+10%', trailingStop: true);
    final actual = OrderData.resolve(dir, price, 2.1, price1: false);
    expect(actual, equals(2.31));
  });

  test('- trailing limit', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('-2', trailingStop: true);
    final actual = OrderData.resolve(dir, price, 2.1, price1: false);
    expect(actual, closeTo(0.1, 0.0001));
  });

  test('- trailing limit percentage', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('-10%', trailingStop: true);
    final actual = OrderData.resolve(dir, price, 2.1, price1: false);
    expect(actual, closeTo(1.89, 0.0001));
  });

  test('- trailing price fails', () {
    final dir = OrderDirection.sell;
    final price = KrakenPrice.fromString('-2', trailingStop: true);
    actual() => OrderData.resolve(dir, price, 2.1, price1: true);
    expect(actual, throwsA(isA<ArgumentError>()));
  });
}
