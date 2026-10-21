// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema_types_primitives.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

/// Immutable value model generated from `passwordSchema`.
final class Password {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Password(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Password.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Password.fromJson(String json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final String value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => passwordSchema,
    fromRuntime: Password._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Password] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Password> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  String toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<String> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $PasswordCopyWith<Password> get copyWith => _$PasswordCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Password &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'Password(value: $value)';

  static Password _fromAckRuntime(String value) => Password(value);

  String _toAckRuntime() => value;
}

/// Creates copies of [Password] with selected fields replaced.
abstract interface class $PasswordCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? value});
}

final class _$PasswordCopyWith implements $PasswordCopyWith<Password> {
  const _$PasswordCopyWith(this._source);

  final Password _source;

  @override
  Password call({String? value}) => Password(value ?? _source.value);
}

/// Immutable value model generated from `ageSchema`.
final class Age {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Age(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Age.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Age.fromJson(int json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final int value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => ageSchema,
    fromRuntime: Age._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Age] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Age> safeParse(Object? input) => $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  int toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<int> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $AgeCopyWith<Age> get copyWith => _$AgeCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Age &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'Age(value: $value)';

  static Age _fromAckRuntime(int value) => Age(value);

  int _toAckRuntime() => value;
}

/// Creates copies of [Age] with selected fields replaced.
abstract interface class $AgeCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({int? value});
}

final class _$AgeCopyWith implements $AgeCopyWith<Age> {
  const _$AgeCopyWith(this._source);

  final Age _source;

  @override
  Age call({int? value}) => Age(value ?? _source.value);
}

/// Immutable value model generated from `priceSchema`.
final class Price {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Price(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Price.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Price.fromJson(double json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final double value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => priceSchema,
    fromRuntime: Price._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Price] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Price> safeParse(Object? input) => $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  double toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<double> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $PriceCopyWith<Price> get copyWith => _$PriceCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Price &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'Price(value: $value)';

  static Price _fromAckRuntime(double value) => Price(value);

  double _toAckRuntime() => value;
}

/// Creates copies of [Price] with selected fields replaced.
abstract interface class $PriceCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({double? value});
}

final class _$PriceCopyWith implements $PriceCopyWith<Price> {
  const _$PriceCopyWith(this._source);

  final Price _source;

  @override
  Price call({double? value}) => Price(value ?? _source.value);
}

/// Immutable value model generated from `activeSchema`.
final class Active {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Active(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Active.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Active.fromJson(bool json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final bool value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => activeSchema,
    fromRuntime: Active._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Active] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Active> safeParse(Object? input) => $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  bool toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<bool> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $ActiveCopyWith<Active> get copyWith => _$ActiveCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Active &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'Active(value: $value)';

  static Active _fromAckRuntime(bool value) => Active(value);

  bool _toAckRuntime() => value;
}

/// Creates copies of [Active] with selected fields replaced.
abstract interface class $ActiveCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({bool? value});
}

final class _$ActiveCopyWith implements $ActiveCopyWith<Active> {
  const _$ActiveCopyWith(this._source);

  final Active _source;

  @override
  Active call({bool? value}) => Active(value ?? _source.value);
}

/// Immutable value model generated from `tagsSchema`.
final class Tags {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Tags(List<String> value)
    : value = List<String>.unmodifiable(value.map((item) => item));

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Tags.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Tags.fromJson(List<String> json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final List<String> value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => tagsSchema,
    fromRuntime: Tags._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Tags] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Tags> safeParse(Object? input) => $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  List<String> toJson() => List<String>.of($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<List<String>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $TagsCopyWith<Tags> get copyWith => _$TagsCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tags &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'Tags(value: $value)';

  static Tags _fromAckRuntime(List<String> value) => Tags(value);

  List<String> _toAckRuntime() =>
      value.map((item) => item).toList(growable: false);
}

/// Creates copies of [Tags] with selected fields replaced.
abstract interface class $TagsCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({List<String>? value});
}

final class _$TagsCopyWith implements $TagsCopyWith<Tags> {
  const _$TagsCopyWith(this._source);

  final Tags _source;

  @override
  Tags call({List<String>? value}) => Tags(value ?? _source.value);
}

/// Immutable value model generated from `scoresSchema`.
final class Scores {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Scores(List<int> value)
    : value = List<int>.unmodifiable(value.map((item) => item));

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Scores.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Scores.fromJson(List<int> json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final List<int> value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => scoresSchema,
    fromRuntime: Scores._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Scores] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Scores> safeParse(Object? input) => $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  List<int> toJson() => List<int>.of($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<List<int>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $ScoresCopyWith<Scores> get copyWith => _$ScoresCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Scores &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'Scores(value: $value)';

  static Scores _fromAckRuntime(List<int> value) => Scores(value);

  List<int> _toAckRuntime() =>
      value.map((item) => item).toList(growable: false);
}

/// Creates copies of [Scores] with selected fields replaced.
abstract interface class $ScoresCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({List<int>? value});
}

final class _$ScoresCopyWith implements $ScoresCopyWith<Scores> {
  const _$ScoresCopyWith(this._source);

  final Scores _source;

  @override
  Scores call({List<int>? value}) => Scores(value ?? _source.value);
}

/// Immutable value model generated from `statusSchema`.
final class StatusLiteral {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  StatusLiteral(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory StatusLiteral.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory StatusLiteral.fromJson(String json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final String value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => statusSchema,
    fromRuntime: StatusLiteral._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [StatusLiteral] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<StatusLiteral> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  String toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<String> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $StatusLiteralCopyWith<StatusLiteral> get copyWith =>
      _$StatusLiteralCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StatusLiteral &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'StatusLiteral(value: $value)';

  static StatusLiteral _fromAckRuntime(String value) => StatusLiteral(value);

  String _toAckRuntime() => value;
}

/// Creates copies of [StatusLiteral] with selected fields replaced.
abstract interface class $StatusLiteralCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? value});
}

final class _$StatusLiteralCopyWith
    implements $StatusLiteralCopyWith<StatusLiteral> {
  const _$StatusLiteralCopyWith(this._source);

  final StatusLiteral _source;

  @override
  StatusLiteral call({String? value}) => StatusLiteral(value ?? _source.value);
}

/// Immutable value model generated from `roleSchema`.
final class Role {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Role(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Role.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Role.fromJson(String json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final String value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => roleSchema,
    fromRuntime: Role._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Role] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Role> safeParse(Object? input) => $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  String toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<String> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $RoleCopyWith<Role> get copyWith => _$RoleCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Role &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'Role(value: $value)';

  static Role _fromAckRuntime(String value) => Role(value);

  String _toAckRuntime() => value;
}

/// Creates copies of [Role] with selected fields replaced.
abstract interface class $RoleCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? value});
}

final class _$RoleCopyWith implements $RoleCopyWith<Role> {
  const _$RoleCopyWith(this._source);

  final Role _source;

  @override
  Role call({String? value}) => Role(value ?? _source.value);
}

/// Immutable value model generated from `userRoleSchema`.
final class UserRoleModel {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  UserRoleModel(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory UserRoleModel.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory UserRoleModel.fromJson(String json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final UserRole value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => userRoleSchema,
    fromRuntime: UserRoleModel._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [UserRoleModel] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<UserRoleModel> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  String toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<String> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $UserRoleModelCopyWith<UserRoleModel> get copyWith =>
      _$UserRoleModelCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRoleModel &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'UserRoleModel(value: $value)';

  static UserRoleModel _fromAckRuntime(UserRole value) => UserRoleModel(value);

  UserRole _toAckRuntime() => value;
}

/// Creates copies of [UserRoleModel] with selected fields replaced.
abstract interface class $UserRoleModelCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({UserRole? value});
}

final class _$UserRoleModelCopyWith
    implements $UserRoleModelCopyWith<UserRoleModel> {
  const _$UserRoleModelCopyWith(this._source);

  final UserRoleModel _source;

  @override
  UserRoleModel call({UserRole? value}) =>
      UserRoleModel(value ?? _source.value);
}

/// Immutable value model generated from `statusEnumSchema`.
final class StatusEnum {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  StatusEnum(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory StatusEnum.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory StatusEnum.fromJson(String json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final Status value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => statusEnumSchema,
    fromRuntime: StatusEnum._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [StatusEnum] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<StatusEnum> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  String toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<String> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $StatusEnumCopyWith<StatusEnum> get copyWith => _$StatusEnumCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StatusEnum &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'StatusEnum(value: $value)';

  static StatusEnum _fromAckRuntime(Status value) => StatusEnum(value);

  Status _toAckRuntime() => value;
}

/// Creates copies of [StatusEnum] with selected fields replaced.
abstract interface class $StatusEnumCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({Status? value});
}

final class _$StatusEnumCopyWith implements $StatusEnumCopyWith<StatusEnum> {
  const _$StatusEnumCopyWith(this._source);

  final StatusEnum _source;

  @override
  StatusEnum call({Status? value}) => StatusEnum(value ?? _source.value);
}

/// Immutable value model generated from `optionalStatusSchema`.
final class OptionalStatus {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  OptionalStatus(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory OptionalStatus.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory OptionalStatus.fromJson(String json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final String value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => optionalStatusSchema,
    fromRuntime: OptionalStatus._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [OptionalStatus] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<OptionalStatus> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  String toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<String> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $OptionalStatusCopyWith<OptionalStatus> get copyWith =>
      _$OptionalStatusCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OptionalStatus &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'OptionalStatus(value: $value)';

  static OptionalStatus _fromAckRuntime(String value) => OptionalStatus(value);

  String _toAckRuntime() => value;
}

/// Creates copies of [OptionalStatus] with selected fields replaced.
abstract interface class $OptionalStatusCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? value});
}

final class _$OptionalStatusCopyWith
    implements $OptionalStatusCopyWith<OptionalStatus> {
  const _$OptionalStatusCopyWith(this._source);

  final OptionalStatus _source;

  @override
  OptionalStatus call({String? value}) =>
      OptionalStatus(value ?? _source.value);
}

/// Immutable value model generated from `defaultedEnumSchema`.
final class DefaultedEnum {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  DefaultedEnum(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory DefaultedEnum.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory DefaultedEnum.fromJson(String json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final UserRole value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => defaultedEnumSchema,
    fromRuntime: DefaultedEnum._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [DefaultedEnum] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<DefaultedEnum> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  String toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<String> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $DefaultedEnumCopyWith<DefaultedEnum> get copyWith =>
      _$DefaultedEnumCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DefaultedEnum &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'DefaultedEnum(value: $value)';

  static DefaultedEnum _fromAckRuntime(UserRole value) => DefaultedEnum(value);

  UserRole _toAckRuntime() => value;
}

/// Creates copies of [DefaultedEnum] with selected fields replaced.
abstract interface class $DefaultedEnumCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({UserRole? value});
}

final class _$DefaultedEnumCopyWith
    implements $DefaultedEnumCopyWith<DefaultedEnum> {
  const _$DefaultedEnumCopyWith(this._source);

  final DefaultedEnum _source;

  @override
  DefaultedEnum call({UserRole? value}) =>
      DefaultedEnum(value ?? _source.value);
}

/// Immutable value model generated from `chainedEnumStringSchema`.
final class ChainedEnumString {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  ChainedEnumString(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory ChainedEnumString.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory ChainedEnumString.fromJson(String json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final String value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => chainedEnumStringSchema,
    fromRuntime: ChainedEnumString._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [ChainedEnumString] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<ChainedEnumString> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  String toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<String> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $ChainedEnumStringCopyWith<ChainedEnumString> get copyWith =>
      _$ChainedEnumStringCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChainedEnumString &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'ChainedEnumString(value: $value)';

  static ChainedEnumString _fromAckRuntime(String value) =>
      ChainedEnumString(value);

  String _toAckRuntime() => value;
}

/// Creates copies of [ChainedEnumString] with selected fields replaced.
abstract interface class $ChainedEnumStringCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({String? value});
}

final class _$ChainedEnumStringCopyWith
    implements $ChainedEnumStringCopyWith<ChainedEnumString> {
  const _$ChainedEnumStringCopyWith(this._source);

  final ChainedEnumString _source;

  @override
  ChainedEnumString call({String? value}) =>
      ChainedEnumString(value ?? _source.value);
}

/// Immutable value model generated from `refinedAgeSchema`.
final class RefinedAge {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  RefinedAge(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory RefinedAge.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory RefinedAge.fromJson(int json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final int value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => refinedAgeSchema,
    fromRuntime: RefinedAge._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [RefinedAge] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<RefinedAge> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  int toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<int> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $RefinedAgeCopyWith<RefinedAge> get copyWith => _$RefinedAgeCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RefinedAge &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'RefinedAge(value: $value)';

  static RefinedAge _fromAckRuntime(int value) => RefinedAge(value);

  int _toAckRuntime() => value;
}

/// Creates copies of [RefinedAge] with selected fields replaced.
abstract interface class $RefinedAgeCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({int? value});
}

final class _$RefinedAgeCopyWith implements $RefinedAgeCopyWith<RefinedAge> {
  const _$RefinedAgeCopyWith(this._source);

  final RefinedAge _source;

  @override
  RefinedAge call({int? value}) => RefinedAge(value ?? _source.value);
}
