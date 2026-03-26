// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'schema_types_primitives.dart';

List<T> _$ackListCast<T>(Object? value) => (value as List).cast<T>();

/// Extension type for Password
extension type PasswordType(String _value) implements String {
  static PasswordType parse(Object? data) {
    return passwordSchema.parseRepresentationAs(
      data,
      (representation) => PasswordType(representation as String),
    );
  }

  static SchemaResult<PasswordType> safeParse(Object? data) {
    return passwordSchema.safeParseRepresentationAs(
      data,
      (representation) => PasswordType(representation as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for Age
extension type AgeType(int _value) implements int {
  static AgeType parse(Object? data) {
    return ageSchema.parseRepresentationAs(
      data,
      (representation) => AgeType(representation as int),
    );
  }

  static SchemaResult<AgeType> safeParse(Object? data) {
    return ageSchema.safeParseRepresentationAs(
      data,
      (representation) => AgeType(representation as int),
    );
  }

  int toJson() => _value;
}

/// Extension type for Price
extension type PriceType(double _value) implements double {
  static PriceType parse(Object? data) {
    return priceSchema.parseRepresentationAs(
      data,
      (representation) => PriceType(representation as double),
    );
  }

  static SchemaResult<PriceType> safeParse(Object? data) {
    return priceSchema.safeParseRepresentationAs(
      data,
      (representation) => PriceType(representation as double),
    );
  }

  double toJson() => _value;
}

/// Extension type for Active
extension type ActiveType(bool _value) implements bool {
  static ActiveType parse(Object? data) {
    return activeSchema.parseRepresentationAs(
      data,
      (representation) => ActiveType(representation as bool),
    );
  }

  static SchemaResult<ActiveType> safeParse(Object? data) {
    return activeSchema.safeParseRepresentationAs(
      data,
      (representation) => ActiveType(representation as bool),
    );
  }

  bool toJson() => _value;
}

/// Extension type for Tags
extension type TagsType(List<String> _value) implements List<String> {
  static TagsType parse(Object? data) {
    return tagsSchema.parseRepresentationAs(
      data,
      (representation) => TagsType(_$ackListCast<String>(representation)),
    );
  }

  static SchemaResult<TagsType> safeParse(Object? data) {
    return tagsSchema.safeParseRepresentationAs(
      data,
      (representation) => TagsType(_$ackListCast<String>(representation)),
    );
  }

  List<String> toJson() => _value;
}

/// Extension type for Scores
extension type ScoresType(List<int> _value) implements List<int> {
  static ScoresType parse(Object? data) {
    return scoresSchema.parseRepresentationAs(
      data,
      (representation) => ScoresType(_$ackListCast<int>(representation)),
    );
  }

  static SchemaResult<ScoresType> safeParse(Object? data) {
    return scoresSchema.safeParseRepresentationAs(
      data,
      (representation) => ScoresType(_$ackListCast<int>(representation)),
    );
  }

  List<int> toJson() => _value;
}

/// Extension type for Status
extension type StatusType(String _value) implements String {
  static StatusType parse(Object? data) {
    return statusSchema.parseRepresentationAs(
      data,
      (representation) => StatusType(representation as String),
    );
  }

  static SchemaResult<StatusType> safeParse(Object? data) {
    return statusSchema.safeParseRepresentationAs(
      data,
      (representation) => StatusType(representation as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for Role
extension type RoleType(String _value) implements String {
  static RoleType parse(Object? data) {
    return roleSchema.parseRepresentationAs(
      data,
      (representation) => RoleType(representation as String),
    );
  }

  static SchemaResult<RoleType> safeParse(Object? data) {
    return roleSchema.safeParseRepresentationAs(
      data,
      (representation) => RoleType(representation as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for UserRole
extension type UserRoleType(UserRole _value) implements UserRole {
  static UserRoleType parse(Object? data) {
    return userRoleSchema.parseRepresentationAs(
      data,
      (representation) => UserRoleType(representation as UserRole),
    );
  }

  static SchemaResult<UserRoleType> safeParse(Object? data) {
    return userRoleSchema.safeParseRepresentationAs(
      data,
      (representation) => UserRoleType(representation as UserRole),
    );
  }

  UserRole toJson() => _value;
}

/// Extension type for StatusEnum
extension type StatusEnumType(Status _value) implements Status {
  static StatusEnumType parse(Object? data) {
    return statusEnumSchema.parseRepresentationAs(
      data,
      (representation) => StatusEnumType(representation as Status),
    );
  }

  static SchemaResult<StatusEnumType> safeParse(Object? data) {
    return statusEnumSchema.safeParseRepresentationAs(
      data,
      (representation) => StatusEnumType(representation as Status),
    );
  }

  Status toJson() => _value;
}

/// Extension type for OptionalStatus
extension type OptionalStatusType(String _value) implements String {
  static OptionalStatusType parse(Object? data) {
    return optionalStatusSchema.parseRepresentationAs(
      data,
      (representation) => OptionalStatusType(representation as String),
    );
  }

  static SchemaResult<OptionalStatusType> safeParse(Object? data) {
    return optionalStatusSchema.safeParseRepresentationAs(
      data,
      (representation) => OptionalStatusType(representation as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for DefaultedEnum
extension type DefaultedEnumType(UserRole _value) implements UserRole {
  static DefaultedEnumType parse(Object? data) {
    return defaultedEnumSchema.parseRepresentationAs(
      data,
      (representation) => DefaultedEnumType(representation as UserRole),
    );
  }

  static SchemaResult<DefaultedEnumType> safeParse(Object? data) {
    return defaultedEnumSchema.safeParseRepresentationAs(
      data,
      (representation) => DefaultedEnumType(representation as UserRole),
    );
  }

  UserRole toJson() => _value;
}

/// Extension type for ChainedEnumString
extension type ChainedEnumStringType(String _value) implements String {
  static ChainedEnumStringType parse(Object? data) {
    return chainedEnumStringSchema.parseRepresentationAs(
      data,
      (representation) => ChainedEnumStringType(representation as String),
    );
  }

  static SchemaResult<ChainedEnumStringType> safeParse(Object? data) {
    return chainedEnumStringSchema.safeParseRepresentationAs(
      data,
      (representation) => ChainedEnumStringType(representation as String),
    );
  }

  String toJson() => _value;
}

/// Extension type for RefinedAge
extension type RefinedAgeType(int _value) implements int {
  static RefinedAgeType parse(Object? data) {
    return refinedAgeSchema.parseRepresentationAs(
      data,
      (representation) => RefinedAgeType(representation as int),
    );
  }

  static SchemaResult<RefinedAgeType> safeParse(Object? data) {
    return refinedAgeSchema.safeParseRepresentationAs(
      data,
      (representation) => RefinedAgeType(representation as int),
    );
  }

  int toJson() => _value;
}
