// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema_types_simple.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

/// Immutable model generated from `userSchema`.
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

  /// The Ack schema that parses input into [User] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

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

  static User _fromAckRuntime(Map<String, Object?> value) => User(
    name: value['name'] as String,
    age: value['age'] as int,
    active: value['active'] as bool,
  );

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    'name': name,
    'age': age,
    'active': active,
  };
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
