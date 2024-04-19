import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_consul/common.dart';
import 'package:dart_consul/dart_consul.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:intl/intl.dart';
import 'package:krok/krok.dart';
import 'package:rxdart/rxdart.dart';

import 'functions.dart';

extension OhlcIntervalExtension on OhlcInterval {
  String get label => switch (this) {
        OhlcInterval.oneMinute => ' 1m',
        OhlcInterval.fiveMinutes => ' 5m',
        OhlcInterval.fifteenMinutes => '15m',
        OhlcInterval.thirtyMinutes => '30m',
        OhlcInterval.oneHour => ' 1h',
        OhlcInterval.fourHours => ' 4h',
        OhlcInterval.oneDay => ' 1d',
        OhlcInterval.oneWeek => ' 7d',
        OhlcInterval.fifteenDays => '15d',
      };
}

extension BufferExtensions on Buffer {
  drawColumn(int x, String char) {
    for (var y = 0; y < height; y++) {
      set(x, y, char);
    }
  }

  set(int x, int y, String char) {
    drawBuffer(x, y, char);
  }
}

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
  /// Add all entries from [other] to `this`.
  void merged(Map<K, V> other) => addAll(other);

  /// Add new map entry [k] [v] to `this`.
  void plus(K k, V v) => this[k] = v;

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

  String toLongStamp() => DateFormat('yyyy-MM-dd HH:mm:ss').format(this);

  Duration get age => DateTime.timestamp().difference(this);
}

extension UniqueIterable<E> on Iterable<E> {
  Iterable<E> unique() sync* {
    final seen = <E>{};
    for (final i in this) {
      if (seen.contains(i)) continue;
      seen.add(i);
      yield i;
    }
  }
}

extension PlusIterable<E> on Iterable<E> {
  Iterable<E> plus(Iterable<E> more) sync* {
    for (final i in this) {
      yield i;
    }
    for (final i in more) {
      yield i;
    }
  }
}

extension SafeStreamExtension<T> on Stream<T> {
  StreamSubscription<T> listenSafely(
    Function(T) listener, {
    void Function(dynamic)? onError,
  }) {
    final oe = onError ?? logError;

    safely(t) {
      try {
        listener(t);
      } catch (it, trace) {
        logError(it, trace);
      }
    }

    return listen(safely, onError: oe);
  }
}
