import 'package:dart_consul/dart_consul.dart';
import 'package:krok_term/src/krok_term/core/krok_core.dart';
import 'package:test/test.dart';

void main() {
  test("adds highlighted suffix", () {
    //given
    final it = "XBT";
    //when
    final actual = it.highlightSuffix("USD");
    //then
    expect(actual, equals("XBT${"/USD".gray()}"));
  });

  test("highlights pair", () {
    //given
    final it = "XBTUSD";
    //when
    final actual = it.highlightSuffix("USD");
    //then
    expect(actual, equals("XBT${"/USD".gray()}"));
  });

  test("highlights separated pair", () {
    //given
    final it = "XBT/USD";
    //when
    final actual = it.highlightSuffix("USD");
    //then
    expect(actual, equals("XBT${"/USD".gray()}"));
  });
}
