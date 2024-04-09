import 'dart:io';

import 'package:ansi/ansi.dart';
import 'package:dart_consul/src/util/common.dart';

import 'functions.dart';

extension StringListExtension on List<String> {
  String joinPath() => join(Platform.pathSeparator);
}

extension ListExtensions<E> on List<E> {
  void fillLength(int targetLength, E it) {
    while (length < targetLength) {
      add(it);
    }
  }

  List<R> mapList<R>(R Function(E) transform) => map(transform).toList();
}

extension MapExtension<K, V> on Map<K, V> {
  operator +(Map<K, V> other) {
    addAll(other);
    return this;
  }

  Map<K, V> plus(K k, V v) {
    this[k] = v;
    return this;
  }

  Map<K, V> where(bool Function(MapEntry<K, V>) pred) {
    final result = <K, V>{};
    entries.where(pred).forEach((e) => result[e.key] = e.value);
    return result;
  }
}

extension StringColumns on String {
  String columns(
    String spec, [
    String dataSplitter = " ",
    String specSplitter = "|",
  ]) {
    final data = split(dataSplitter);
    final columns = spec.split(specSplitter);
    return zip(data, columns).map((e) {
      final pad = switch (e.$2.take(1)) {
        "L" => (c) => e.$1.ansiPadRight(c),
        "C" => (c) => e.$1.ansiPad(c),
        "R" => (c) => e.$1.ansiPadLeft(c),
        _ => throw ArgumentError("invalid spec: $spec"),
      };
      final count = int.parse(e.$2.substring(1));
      return pad(count);
    }).join("");
  }
}

extension HighlightPairString on String {
  String highlightSuffix({String? suffix, String separator = '/'}) {
    var prefix = this;
    suffix ??= split(separator).last;
    if (endsWith(suffix)) prefix = prefix.dropLast(suffix.length);
    if (prefix.endsWith(separator)) prefix = prefix.dropLast(1);
    return prefix + "$separator$suffix".gray();
  }

  String fixDisplayPair() => replaceAll("XX", "X").replaceAll("XBT", "BTC");
}

extension LargeNumberFormat on double {
  String formatLargeNumber([int defaultDecimals = 4]) {
    if (this > 1000000) return "${(this / 1000000).toStringAsFixed(1)}M";
    if (this > 1000) return "${(this / 1000).toStringAsFixed(1)}K";
    return toStringAsFixed(defaultDecimals);
  }
}
