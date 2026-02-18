// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'schema_types_simple.dart';

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
  if (result.isOk) {
    return SchemaResult.ok(wrap(result.getOrNull()));
  }
  return SchemaResult.fail(result.getError()!);
}

/// Extension type for User
extension type UserType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static UserType parse(Object? data) {
    return _$ackParse<UserType>(
      userSchema,
      data,
      (validated) => UserType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<UserType> safeParse(Object? data) {
    return _$ackSafeParse<UserType>(
      userSchema,
      data,
      (validated) => UserType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get name => _data['name'] as String;

  int get age => _data['age'] as int;

  bool get active => _data['active'] as bool;

  UserType copyWith({String? name, int? age, bool? active}) {
    return UserType.parse({
      'name': name ?? this.name,
      'age': age ?? this.age,
      'active': active ?? this.active,
    });
  }
}
