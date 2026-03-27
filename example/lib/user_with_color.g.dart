// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'user_with_color.dart';

/// Extension type for Color
extension type ColorType(Color _value) implements Color {
  static ColorType parse(Object? data) {
    return colorSchema.parseAs(
      data,
      (validated) => ColorType(validated as Color),
    );
  }

  static SchemaResult<ColorType> safeParse(Object? data) {
    return colorSchema.safeParseAs(
      data,
      (validated) => ColorType(validated as Color),
    );
  }
}

/// Extension type for Profile
extension type ProfileType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ProfileType parse(Object? data) {
    return profileSchema.parseAs(
      data,
      (validated) => ProfileType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<ProfileType> safeParse(Object? data) {
    return profileSchema.safeParseAs(
      data,
      (validated) => ProfileType(validated as Map<String, Object?>),
    );
  }

  String get bio => _data['bio'] as String;

  Uri? get website => _data['website'] as Uri?;
}

/// Extension type for UserWithColor
extension type UserWithColorType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static UserWithColorType parse(Object? data) {
    return userWithColorSchema.parseAs(
      data,
      (validated) => UserWithColorType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<UserWithColorType> safeParse(Object? data) {
    return userWithColorSchema.safeParseAs(
      data,
      (validated) => UserWithColorType(validated as Map<String, Object?>),
    );
  }

  String get firstName => _data['firstName'] as String;

  String get lastName => _data['lastName'] as String;

  int get age => _data['age'] as int;

  ProfileType get profile =>
      ProfileType(_data['profile'] as Map<String, Object?>);

  ColorType get color => ColorType(_data['color'] as Color);

  ColorType? get favoriteColor => _data['favoriteColor'] != null
      ? ColorType(_data['favoriteColor'] as Color)
      : null;

  PetType get pet => PetType(_data['pet'] as Map<String, Object?>);

  List<PetType> get pets => (_data['pets'] as List)
      .map((e) => PetType(e as Map<String, Object?>))
      .toList();
}
