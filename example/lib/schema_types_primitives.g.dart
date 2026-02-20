// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'schema_types_primitives.dart';

/// Extension type for Password
extension type PasswordType(String _value) implements String {
  static PasswordType parse(Object? data) {
    return passwordSchema.parseAs(
      data,
      (validated) => PasswordType(validated as String),
    );
  }

  static SchemaResult<PasswordType> safeParse(Object? data) {
    return passwordSchema.safeParseAs(
      data,
      (validated) => PasswordType(validated as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for Age
extension type AgeType(int _value) implements int {
  static AgeType parse(Object? data) {
    return ageSchema.parseAs(data, (validated) => AgeType(validated as int));
  }

  static SchemaResult<AgeType> safeParse(Object? data) {
    return ageSchema.safeParseAs(
      data,
      (validated) => AgeType(validated as int),
    );
  }

  int toJson() => _value;
}

/// Extension type for Price
extension type PriceType(double _value) implements double {
  static PriceType parse(Object? data) {
    return priceSchema.parseAs(
      data,
      (validated) => PriceType(validated as double),
    );
  }

  static SchemaResult<PriceType> safeParse(Object? data) {
    return priceSchema.safeParseAs(
      data,
      (validated) => PriceType(validated as double),
    );
  }

  double toJson() => _value;
}

/// Extension type for Active
extension type ActiveType(bool _value) implements bool {
  static ActiveType parse(Object? data) {
    return activeSchema.parseAs(
      data,
      (validated) => ActiveType(validated as bool),
    );
  }

  static SchemaResult<ActiveType> safeParse(Object? data) {
    return activeSchema.safeParseAs(
      data,
      (validated) => ActiveType(validated as bool),
    );
  }

  bool toJson() => _value;
}

/// Extension type for Tags
extension type TagsType(List<String> _value) implements List<String> {
  static TagsType parse(Object? data) {
    return tagsSchema.parseAs(
      data,
      (validated) => TagsType(validated as List<String>),
    );
  }

  static SchemaResult<TagsType> safeParse(Object? data) {
    return tagsSchema.safeParseAs(
      data,
      (validated) => TagsType(validated as List<String>),
    );
  }

  List<String> toJson() => _value;
}

/// Extension type for Scores
extension type ScoresType(List<int> _value) implements List<int> {
  static ScoresType parse(Object? data) {
    return scoresSchema.parseAs(
      data,
      (validated) => ScoresType(validated as List<int>),
    );
  }

  static SchemaResult<ScoresType> safeParse(Object? data) {
    return scoresSchema.safeParseAs(
      data,
      (validated) => ScoresType(validated as List<int>),
    );
  }

  List<int> toJson() => _value;
}

/// Extension type for Status
extension type StatusType(String _value) implements String {
  static StatusType parse(Object? data) {
    return statusSchema.parseAs(
      data,
      (validated) => StatusType(validated as String),
    );
  }

  static SchemaResult<StatusType> safeParse(Object? data) {
    return statusSchema.safeParseAs(
      data,
      (validated) => StatusType(validated as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for Role
extension type RoleType(String _value) implements String {
  static RoleType parse(Object? data) {
    return roleSchema.parseAs(
      data,
      (validated) => RoleType(validated as String),
    );
  }

  static SchemaResult<RoleType> safeParse(Object? data) {
    return roleSchema.safeParseAs(
      data,
      (validated) => RoleType(validated as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for UserRole
extension type UserRoleType(UserRole _value) implements UserRole {
  static UserRoleType parse(Object? data) {
    return userRoleSchema.parseAs(
      data,
      (validated) => UserRoleType(validated as UserRole),
    );
  }

  static SchemaResult<UserRoleType> safeParse(Object? data) {
    return userRoleSchema.safeParseAs(
      data,
      (validated) => UserRoleType(validated as UserRole),
    );
  }

  UserRole toJson() => _value;
}

/// Extension type for StatusEnum
extension type StatusEnumType(Status _value) implements Status {
  static StatusEnumType parse(Object? data) {
    return statusEnumSchema.parseAs(
      data,
      (validated) => StatusEnumType(validated as Status),
    );
  }

  static SchemaResult<StatusEnumType> safeParse(Object? data) {
    return statusEnumSchema.safeParseAs(
      data,
      (validated) => StatusEnumType(validated as Status),
    );
  }

  Status toJson() => _value;
}

/// Extension type for OptionalStatus
extension type OptionalStatusType(String _value) implements String {
  static OptionalStatusType parse(Object? data) {
    return optionalStatusSchema.parseAs(
      data,
      (validated) => OptionalStatusType(validated as String),
    );
  }

  static SchemaResult<OptionalStatusType> safeParse(Object? data) {
    return optionalStatusSchema.safeParseAs(
      data,
      (validated) => OptionalStatusType(validated as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for DefaultedEnum
extension type DefaultedEnumType(UserRole _value) implements UserRole {
  static DefaultedEnumType parse(Object? data) {
    return defaultedEnumSchema.parseAs(
      data,
      (validated) => DefaultedEnumType(validated as UserRole),
    );
  }

  static SchemaResult<DefaultedEnumType> safeParse(Object? data) {
    return defaultedEnumSchema.safeParseAs(
      data,
      (validated) => DefaultedEnumType(validated as UserRole),
    );
  }

  UserRole toJson() => _value;
}

/// Extension type for ChainedEnumString
extension type ChainedEnumStringType(String _value) implements String {
  static ChainedEnumStringType parse(Object? data) {
    return chainedEnumStringSchema.parseAs(
      data,
      (validated) => ChainedEnumStringType(validated as String),
    );
  }

  static SchemaResult<ChainedEnumStringType> safeParse(Object? data) {
    return chainedEnumStringSchema.safeParseAs(
      data,
      (validated) => ChainedEnumStringType(validated as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for RefinedAge
extension type RefinedAgeType(int _value) implements int {
  static RefinedAgeType parse(Object? data) {
    return refinedAgeSchema.parseAs(
      data,
      (validated) => RefinedAgeType(validated as int),
    );
  }

  static SchemaResult<RefinedAgeType> safeParse(Object? data) {
    return refinedAgeSchema.safeParseAs(
      data,
      (validated) => RefinedAgeType(validated as int),
    );
  }

  int toJson() => _value;
}
