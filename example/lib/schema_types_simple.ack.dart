// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'schema_types_simple.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

/// Immutable model generated from `userSchema`.
@AckInfer.jsonSerializable
final class User {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  User({required this.name, required this.age, required this.active});

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory User.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory User.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final String name;

  final int age;

  final bool active;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => userSchema,
    fromRuntime: User._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<User> safeParse(Object? input) => $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $UserCopyWith<User> get copyWith => _$UserCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          runtimeType == other.runtimeType &&
          deepEquals(name, other.name) &&
          deepEquals(age, other.age) &&
          deepEquals(active, other.active));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(name),
    deepHashCode(age),
    deepHashCode(active),
  ]);

  @override
  String toString() => 'User(name: $name, age: $age, active: $active)';

  static User _fromAckRuntime(Map<String, Object?> value) =>
      _$UserFromJson(Map<String, dynamic>.from(value));

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    ..._$UserToJson(this),
  };

  static String _ackFromRuntimeName(Object? value) => value as String;

  static Object? _ackToRuntimeName(String value) => value;

  static int _ackFromRuntimeAge(Object? value) => value as int;

  static Object? _ackToRuntimeAge(int value) => value;

  static bool _ackFromRuntimeActive(Object? value) => value as bool;

  static Object? _ackToRuntimeActive(bool value) => value;
}

/// Creates copies of [User] with selected fields replaced.
abstract interface class $UserCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? name, int? age, bool? active});
}

final class _$UserCopyWith implements $UserCopyWith<User> {
  const _$UserCopyWith(this._source);

  final User _source;

  @override
  User call({String? name, int? age, bool? active}) => User(
    name: name ?? _source.name,
    age: age ?? _source.age,
    active: active ?? _source.active,
  );
}
