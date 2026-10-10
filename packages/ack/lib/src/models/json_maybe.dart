import 'package:meta/meta.dart';

import '../utils/collection_utils.dart';

/// Represents an optional, nullable JSON object property with three distinct
/// states:
///
/// * [JsonAbsent] (`const JsonMaybe.absent()`): the key is omitted from the
///   JSON map.
/// * [JsonValue] (`const JsonMaybe.value(null)`): the key is present in the
///   JSON map with a `null` value.
/// * [JsonValue] (`const JsonMaybe.value(value)`): the key is present in the
///   JSON map with [value].
///
/// Use `JsonMaybe<T>` on a `@Schemable()` class field when you need to
/// distinguish an omitted JSON property from an explicit `null` on both parse
/// and encode.
@immutable
sealed class JsonMaybe<T> {
  const JsonMaybe();

  /// An omitted JSON property.
  const factory JsonMaybe.absent() = JsonAbsent<T>;

  /// A present JSON property with [value] (which may be `null`).
  const factory JsonMaybe.value(T? value) = JsonValue<T>;

  /// A present JSON property with an explicit `null` value.
  const factory JsonMaybe.nullValue() = JsonValue<T>.nullValue;

  /// Whether the key was present in the JSON map.
  bool get isPresent;

  /// Whether the key was omitted from the JSON map.
  bool get isAbsent => !isPresent;

  /// Whether the key was present with a `null` value.
  bool get isNull;

  /// The property value when present, or `null` when absent or `null`.
  T? get valueOrNull;
}

/// An omitted JSON property.
@immutable
final class JsonAbsent<T> extends JsonMaybe<T> {
  /// Creates an omitted JSON property marker.
  const JsonAbsent();

  @override
  bool get isPresent => false;

  @override
  bool get isNull => false;

  @override
  T? get valueOrNull => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is JsonAbsent<Object?>;

  @override
  int get hashCode => (JsonAbsent).hashCode;

  @override
  String toString() => 'JsonMaybe.absent()';
}

/// A present JSON property with [value] (which may be `null`).
@immutable
final class JsonValue<T> extends JsonMaybe<T> {
  /// Creates a present JSON property with [value].
  const JsonValue(this.value);

  /// Creates a present JSON property with a `null` value.
  const JsonValue.nullValue() : value = null;

  /// The present property value, or `null` when explicitly set to `null`.
  final T? value;

  @override
  bool get isPresent => true;

  @override
  bool get isNull => value == null;

  @override
  T? get valueOrNull => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JsonValue<Object?> && deepEquals(value, other.value));

  @override
  int get hashCode => Object.hash(JsonValue, deepHashCode(value));

  @override
  String toString() => 'JsonMaybe.value($value)';
}
