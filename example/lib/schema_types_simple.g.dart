// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema_types_simple.dart';

/// Extension type for User
extension type UserType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static UserType parse(Object? data) {
    final validated = userSchema.parse(data);
    return UserType(validated as Map<String, Object?>);
  }

  static SchemaResult<UserType> safeParse(Object? data) {
    final result = userSchema.safeParse(data);
    return result.match(
      onOk: (validated) =>
          SchemaResult.ok(UserType(validated as Map<String, Object?>)),
      onFail: (error) => SchemaResult.fail(error),
    );
  }

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
