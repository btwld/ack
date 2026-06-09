import 'package:ack/ack.dart';

/// Reads the required field [key] from a decoded [map] as [T].
T readValue<T>(JsonMap map, String key) => map[key]! as T;

/// Reads the optional field [key] from a decoded [map] as [T].
T? readNullableValue<T>(JsonMap map, String key) => map[key] as T?;

/// Reads the required numeric field [key] from a decoded [map] as a `double`.
///
/// The schema has already validated the field, so the value is present and a
/// `num`; this centralizes the cast and `toDouble` conversion shared by
/// object-shaped codec decoders.
double readDouble(JsonMap map, String key) => (map[key]! as num).toDouble();

/// Reads the optional numeric field [key] from a decoded [map] as a `double`.
double? readNullableDouble(JsonMap map, String key) =>
    (map[key] as num?)?.toDouble();

/// Reads the required list field [key] from a decoded [map] as `List<T>`.
///
/// Not for numeric `T`: `cast<double>()` does not coerce JSON ints and would
/// throw on iteration. Use [readDoubleList] / [readNullableDoubleList] for
/// numeric lists.
List<T> readList<T>(JsonMap map, String key) =>
    (map[key]! as List).cast<T>().toList();

/// Reads the optional list field [key] from a decoded [map] as `List<T>`.
List<T>? readNullableList<T>(JsonMap map, String key) =>
    (map[key] as List?)?.cast<T>().toList();

/// Reads the required numeric list field [key] as `List<double>`.
///
/// Coerces JSON ints to doubles (unlike `readList<double>`, whose `cast` would
/// throw on a JSON int).
List<double> readDoubleList(JsonMap map, String key) =>
    (map[key]! as List).map((value) => (value as num).toDouble()).toList();

/// Reads the optional numeric list field [key] as `List<double>`.
List<double>? readNullableDoubleList(JsonMap map, String key) {
  final raw = map[key];
  if (raw == null) return null;

  return (raw as List).map((value) => (value as num).toDouble()).toList();
}
