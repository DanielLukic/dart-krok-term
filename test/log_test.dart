import 'package:dart_consul/dart_consul.dart';
import 'package:krok_term/src/krok_term/feature/debug_log.dart';
import 'package:test/test.dart';

void main() {
  check(String input, int expected) => expect(
        input.toLogLevel(),
        equals(expected),
        reason: "level of $input expected to be $expected",
      );

  test("check log levels", () {
    final checks = {
      "10:10:10 something": 1,
      "10:10:10 [I] something": 1,
      "10:10:10 [V] something": 0,
      "10:10:10 [W] something": 2,
      "10:10:10 [E] something": 3,
      "10:10:10 [E] something".red(): 3,
    };
    checks.forEach(check);
  });
}
