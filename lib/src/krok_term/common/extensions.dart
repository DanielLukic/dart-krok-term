import 'dart:io';

import 'package:ansi/ansi.dart';
import 'package:collection/collection.dart';
import 'package:dart_consul/common.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import 'functions.dart';

extension DistinctUntilChanged<E> on Stream<E> {
  Stream<E> distinctUntilChanged() => distinct(DeepCollectionEquality().equals);
}

Stream<List<dynamic>> combine(List<Stream<dynamic>> l) =>
    CombineLatestStream.list(l);

extension StringListExtension on List<String> {
  String joinPath() => join(Platform.pathSeparator);
}

extension IterableExtensions<E> on Iterable<E> {
  List<R> mapList<R>(R Function(E) mapper) => map(mapper).toList();

  Iterable<List<E>> windowed(int size) {
    final input = toList();
    final result = <List<E>>[];
    var current = <E>[];
    for (var i = 0; i < input.length; i++) {
      current.add(input[i]);
      if (current.length == size) {
        result.add(current);
        current = [];
      }
    }
    return result;
  }
}

extension ListExtensions<E> on List<E> {
  void fillLength(int targetLength, E it) {
    while (length < targetLength) {
      add(it);
    }
  }

  List<R> mapList<R>(R Function(E) transform) => map(transform).toList();

  List<E> reversedList() => reversed.toList();
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

extension SnakeCaseExtension on String {
  String toSnakeCase() {
    final result = StringBuffer();
    for (var i = 0; i < length; i++) {
      final c = this[i];
      if (c == c.toUpperCase()) {
        if (i > 0) result.write('_');
        result.write(c.toLowerCase());
      } else {
        result.write(c);
      }
    }
    return result.toString();
  }
}

extension AutoDateTimeFormatExtension on DateTime {
  String toTimestamp() => DateFormat('MM-dd HH:mm').format(this);
}

extension IntToKrakenDateTime on int {
  DateTime toKrakenDateTime() =>
      DateTime.fromMillisecondsSinceEpoch(this * 1000, isUtc: true);
}

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
