import 'package:ansi/ansi.dart';
import 'package:dart_consul/common.dart';
import 'package:krok_term/src/krok_term/common/types.dart';

import 'extensions.dart';

String joinPath(List<String> elements) => elements.joinPath();

List<(A, B)> zip<A, B>(List<A> a, List<B> b) =>
    [for (int i = 0; i < a.length; i++) (a[i], b[i])];

/// Given a price or volume input, return the absolute price and/or and error
/// message. Will handle +/- prefix for relative values, as well as trailing
/// % for percentages. Including the combination. Special case: if [base] is
/// `null`, the error returned is "loading".
(double?, String?) evalValueInput(
  String input,
  double? base, {
  double? min,
  double? max,
}) {
  if (base == null) return (null, 'loading'.gray());

  final op = switch (input) {
    _ when input.startsWith('+') => (e) => base + e,
    _ when input.startsWith('-') => (e) => base - e,
    _ => null,
  };
  if (op != null) input = input.drop(1);

  final pre = switch (input) {
    _ when input.endsWith('%') => (e) => base * e / 100,
    _ => null,
  };
  if (pre != null) input = input.dropLast(1);

  final price = double.tryParse(input);
  if (price != null) {
    final abs = (pre ?? (e) => e)(price);
    final res = (op ?? (e) => e)(abs);
    if (min != null && price < min) return (res, 'too low'.red());
    if (max != null && price > max) return (res, 'too high'.red());
    return (res, null);
  } else if (input.isEmpty) {
    return (null, 'required'.gray());
  } else {
    return (null, 'invalid'.red());
  }
}

/// Format a price using the result of [evalValueInput], [ap] for decimals
/// formatting, and [label] for the "unit".
String makePrice(String input, (double?, String?) it, AssetPairData ap) {
  final b = StringBuffer();
  final v = it.$1;
  if (v != null) {
    final fp = ap.price(v);
    if (fp == input) {
      b.write(ap.quote);
    } else {
      b.write("$fp ${ap.quote}");
    }
  }

  final e = it.$2;
  if (e != null && b.isNotEmpty) b.write(' ');
  if (e != null) b.write(e);

  return b.toString();
}

/// Format a volume using the result of [evalValueInput], [ap] for decimals
/// formatting, and [label] for the "unit".
String makeVolume((double?, String?) it, AssetPairData ap) {
  final b = StringBuffer();
  final v = it.$1;
  if (v != null) b.write("${ap.volume(v)} ${ap.base}");

  final e = it.$2;
  if (e != null && b.isNotEmpty) b.write(' ');
  if (e != null) b.write(e);

  return b.toString();
}
