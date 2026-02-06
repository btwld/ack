// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'schema_types_primitives.dart';

/// Extension type for Password
extension type PasswordType(String _value) implements String {
  static PasswordType parse(Object? data) {
    final validated = passwordSchema.parse(data);
    return PasswordType(validated as String);
  }

  static SchemaResult<PasswordType> safeParse(Object? data) {
    final result = passwordSchema.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(PasswordType(validated as String)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String toJson() => _value;
}

/// Extension type for Age
extension type AgeType(int _value) implements int {
  static AgeType parse(Object? data) {
    final validated = ageSchema.parse(data);
    return AgeType(validated as int);
  }

  static SchemaResult<AgeType> safeParse(Object? data) {
    final result = ageSchema.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(AgeType(validated as int)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  int toJson() => _value;
}

/// Extension type for Price
extension type PriceType(double _value) implements double {
  static PriceType parse(Object? data) {
    final validated = priceSchema.parse(data);
    return PriceType(validated as double);
  }

  static SchemaResult<PriceType> safeParse(Object? data) {
    final result = priceSchema.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(PriceType(validated as double)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  double toJson() => _value;
}

/// Extension type for Active
extension type ActiveType(bool _value) implements bool {
  static ActiveType parse(Object? data) {
    final validated = activeSchema.parse(data);
    return ActiveType(validated as bool);
  }

  static SchemaResult<ActiveType> safeParse(Object? data) {
    final result = activeSchema.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(ActiveType(validated as bool)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  bool toJson() => _value;
}

/// Extension type for Tags
extension type TagsType(List<String> _value) implements List<String> {
  static TagsType parse(Object? data) {
    final validated = tagsSchema.parse(data);
    return TagsType(validated as List<String>);
  }

  static SchemaResult<TagsType> safeParse(Object? data) {
    final result = tagsSchema.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(TagsType(validated as List<String>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  List<String> toJson() => _value;
}

/// Extension type for Scores
extension type ScoresType(List<int> _value) implements List<int> {
  static ScoresType parse(Object? data) {
    final validated = scoresSchema.parse(data);
    return ScoresType(validated as List<int>);
  }

  static SchemaResult<ScoresType> safeParse(Object? data) {
    final result = scoresSchema.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(ScoresType(validated as List<int>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  List<int> toJson() => _value;
}

/// Extension type for Status
extension type StatusType(String _value) implements String {
  static StatusType parse(Object? data) {
    final validated = statusSchema.parse(data);
    return StatusType(validated as String);
  }

  static SchemaResult<StatusType> safeParse(Object? data) {
    final result = statusSchema.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(StatusType(validated as String)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String toJson() => _value;
}

/// Extension type for Role
extension type RoleType(String _value) implements String {
  static RoleType parse(Object? data) {
    final validated = roleSchema.parse(data);
    return RoleType(validated as String);
  }

  static SchemaResult<RoleType> safeParse(Object? data) {
    final result = roleSchema.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(RoleType(validated as String)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String toJson() => _value;
}

/// Extension type for UserRole
extension type UserRoleType(UserRole _value) implements UserRole {
  static UserRoleType parse(Object? data) {
    final validated = userRoleSchema.parse(data);
    return UserRoleType(validated as UserRole);
  }

  static SchemaResult<UserRoleType> safeParse(Object? data) {
    final result = userRoleSchema.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(UserRoleType(validated as UserRole)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  UserRole toJson() => _value;
}

/// Extension type for StatusEnum
extension type StatusEnumType(Status _value) implements Status {
  static StatusEnumType parse(Object? data) {
    final validated = statusEnumSchema.parse(data);
    return StatusEnumType(validated as Status);
  }

  static SchemaResult<StatusEnumType> safeParse(Object? data) {
    final result = statusEnumSchema.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(StatusEnumType(validated as Status)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  Status toJson() => _value;
}

/// Extension type for OptionalStatus
extension type OptionalStatusType(String _value) implements String {
  static OptionalStatusType parse(Object? data) {
    final validated = optionalStatusSchema.parse(data);
    return OptionalStatusType(validated as String);
  }

  static SchemaResult<OptionalStatusType> safeParse(Object? data) {
    final result = optionalStatusSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(OptionalStatusType(validated as String)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String toJson() => _value;
}

/// Extension type for DefaultedEnum
extension type DefaultedEnumType(UserRole _value) implements UserRole {
  static DefaultedEnumType parse(Object? data) {
    final validated = defaultedEnumSchema.parse(data);
    return DefaultedEnumType(validated as UserRole);
  }

  static SchemaResult<DefaultedEnumType> safeParse(Object? data) {
    final result = defaultedEnumSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(DefaultedEnumType(validated as UserRole)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  UserRole toJson() => _value;
}

/// Extension type for ChainedEnumString
extension type ChainedEnumStringType(String _value) implements String {
  static ChainedEnumStringType parse(Object? data) {
    final validated = chainedEnumStringSchema.parse(data);
    return ChainedEnumStringType(validated as String);
  }

  static SchemaResult<ChainedEnumStringType> safeParse(Object? data) {
    final result = chainedEnumStringSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(ChainedEnumStringType(validated as String)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  String toJson() => _value;
}

/// Extension type for RefinedAge
extension type RefinedAgeType(int _value) implements int {
  static RefinedAgeType parse(Object? data) {
    final validated = refinedAgeSchema.parse(data);
    return RefinedAgeType(validated as int);
  }

  static SchemaResult<RefinedAgeType> safeParse(Object? data) {
    final result = refinedAgeSchema.safeParse(data);
    return result.match(
      onOk: (validated) => SchemaResult.ok(RefinedAgeType(validated as int)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

  int toJson() => _value;
}
