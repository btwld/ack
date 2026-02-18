// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'schema_types_primitives.dart';

T _$ackParse<T extends Object>(
  dynamic schema,
  Object? data,
  T Function(Object?) wrap,
) {
  final validated = schema.parse(data);
  return wrap(validated);
}

SchemaResult<T> _$ackSafeParse<T extends Object>(
  dynamic schema,
  Object? data,
  T Function(Object?) wrap,
) {
  final result = schema.safeParse(data);
  return result.match(
    onOk: (validated) => SchemaResult.ok(wrap(validated)),
    onFail: (error) => SchemaResult.fail(error),
  );
}

/// Extension type for Password
extension type PasswordType(String _value) implements String {
  static PasswordType parse(Object? data) {
    return _$ackParse<PasswordType>(
      passwordSchema,
      data,
      (validated) => PasswordType(validated as String),
    );
  }

  static SchemaResult<PasswordType> safeParse(Object? data) {
    return _$ackSafeParse<PasswordType>(
      passwordSchema,
      data,
      (validated) => PasswordType(validated as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for Age
extension type AgeType(int _value) implements int {
  static AgeType parse(Object? data) {
    return _$ackParse<AgeType>(
      ageSchema,
      data,
      (validated) => AgeType(validated as int),
    );
  }

  static SchemaResult<AgeType> safeParse(Object? data) {
    return _$ackSafeParse<AgeType>(
      ageSchema,
      data,
      (validated) => AgeType(validated as int),
    );
  }

  int toJson() => _value;
}

/// Extension type for Price
extension type PriceType(double _value) implements double {
  static PriceType parse(Object? data) {
    return _$ackParse<PriceType>(
      priceSchema,
      data,
      (validated) => PriceType(validated as double),
    );
  }

  static SchemaResult<PriceType> safeParse(Object? data) {
    return _$ackSafeParse<PriceType>(
      priceSchema,
      data,
      (validated) => PriceType(validated as double),
    );
  }

  double toJson() => _value;
}

/// Extension type for Active
extension type ActiveType(bool _value) implements bool {
  static ActiveType parse(Object? data) {
    return _$ackParse<ActiveType>(
      activeSchema,
      data,
      (validated) => ActiveType(validated as bool),
    );
  }

  static SchemaResult<ActiveType> safeParse(Object? data) {
    return _$ackSafeParse<ActiveType>(
      activeSchema,
      data,
      (validated) => ActiveType(validated as bool),
    );
  }

  bool toJson() => _value;
}

/// Extension type for Tags
extension type TagsType(List<String> _value) implements List<String> {
  static TagsType parse(Object? data) {
    return _$ackParse<TagsType>(
      tagsSchema,
      data,
      (validated) => TagsType(validated as List<String>),
    );
  }

  static SchemaResult<TagsType> safeParse(Object? data) {
    return _$ackSafeParse<TagsType>(
      tagsSchema,
      data,
      (validated) => TagsType(validated as List<String>),
    );
  }

  List<String> toJson() => _value;
}

/// Extension type for Scores
extension type ScoresType(List<int> _value) implements List<int> {
  static ScoresType parse(Object? data) {
    return _$ackParse<ScoresType>(
      scoresSchema,
      data,
      (validated) => ScoresType(validated as List<int>),
    );
  }

  static SchemaResult<ScoresType> safeParse(Object? data) {
    return _$ackSafeParse<ScoresType>(
      scoresSchema,
      data,
      (validated) => ScoresType(validated as List<int>),
    );
  }

  List<int> toJson() => _value;
}

/// Extension type for Status
extension type StatusType(String _value) implements String {
  static StatusType parse(Object? data) {
    return _$ackParse<StatusType>(
      statusSchema,
      data,
      (validated) => StatusType(validated as String),
    );
  }

  static SchemaResult<StatusType> safeParse(Object? data) {
    return _$ackSafeParse<StatusType>(
      statusSchema,
      data,
      (validated) => StatusType(validated as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for Role
extension type RoleType(String _value) implements String {
  static RoleType parse(Object? data) {
    return _$ackParse<RoleType>(
      roleSchema,
      data,
      (validated) => RoleType(validated as String),
    );
  }

  static SchemaResult<RoleType> safeParse(Object? data) {
    return _$ackSafeParse<RoleType>(
      roleSchema,
      data,
      (validated) => RoleType(validated as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for UserRole
extension type UserRoleType(UserRole _value) implements UserRole {
  static UserRoleType parse(Object? data) {
    return _$ackParse<UserRoleType>(
      userRoleSchema,
      data,
      (validated) => UserRoleType(validated as UserRole),
    );
  }

  static SchemaResult<UserRoleType> safeParse(Object? data) {
    return _$ackSafeParse<UserRoleType>(
      userRoleSchema,
      data,
      (validated) => UserRoleType(validated as UserRole),
    );
  }

  UserRole toJson() => _value;
}

/// Extension type for StatusEnum
extension type StatusEnumType(Status _value) implements Status {
  static StatusEnumType parse(Object? data) {
    return _$ackParse<StatusEnumType>(
      statusEnumSchema,
      data,
      (validated) => StatusEnumType(validated as Status),
    );
  }

  static SchemaResult<StatusEnumType> safeParse(Object? data) {
    return _$ackSafeParse<StatusEnumType>(
      statusEnumSchema,
      data,
      (validated) => StatusEnumType(validated as Status),
    );
  }

  Status toJson() => _value;
}

/// Extension type for OptionalStatus
extension type OptionalStatusType(String _value) implements String {
  static OptionalStatusType parse(Object? data) {
    return _$ackParse<OptionalStatusType>(
      optionalStatusSchema,
      data,
      (validated) => OptionalStatusType(validated as String),
    );
  }

  static SchemaResult<OptionalStatusType> safeParse(Object? data) {
    return _$ackSafeParse<OptionalStatusType>(
      optionalStatusSchema,
      data,
      (validated) => OptionalStatusType(validated as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for DefaultedEnum
extension type DefaultedEnumType(UserRole _value) implements UserRole {
  static DefaultedEnumType parse(Object? data) {
    return _$ackParse<DefaultedEnumType>(
      defaultedEnumSchema,
      data,
      (validated) => DefaultedEnumType(validated as UserRole),
    );
  }

  static SchemaResult<DefaultedEnumType> safeParse(Object? data) {
    return _$ackSafeParse<DefaultedEnumType>(
      defaultedEnumSchema,
      data,
      (validated) => DefaultedEnumType(validated as UserRole),
    );
  }

  UserRole toJson() => _value;
}

/// Extension type for ChainedEnumString
extension type ChainedEnumStringType(String _value) implements String {
  static ChainedEnumStringType parse(Object? data) {
    return _$ackParse<ChainedEnumStringType>(
      chainedEnumStringSchema,
      data,
      (validated) => ChainedEnumStringType(validated as String),
    );
  }

  static SchemaResult<ChainedEnumStringType> safeParse(Object? data) {
    return _$ackSafeParse<ChainedEnumStringType>(
      chainedEnumStringSchema,
      data,
      (validated) => ChainedEnumStringType(validated as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for RefinedAge
extension type RefinedAgeType(int _value) implements int {
  static RefinedAgeType parse(Object? data) {
    return _$ackParse<RefinedAgeType>(
      refinedAgeSchema,
      data,
      (validated) => RefinedAgeType(validated as int),
    );
  }

  static SchemaResult<RefinedAgeType> safeParse(Object? data) {
    return _$ackSafeParse<RefinedAgeType>(
      refinedAgeSchema,
      data,
      (validated) => RefinedAgeType(validated as int),
    );
  }

  int toJson() => _value;
}
