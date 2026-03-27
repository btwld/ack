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

/// Extension type for Pet
extension type PetType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  String get type => _data['type'] as String;

  static PetType parse(Object? data) {
    return petSchema.parseAs(data, (validated) {
      final map = validated as Map<String, Object?>;
      return switch (map['type']) {
        'cat' => CatType(map),
        'dog' => DogType(map),
        _ => throw StateError('Unknown type: ${map['type']}'),
      };
    });
  }

  static SchemaResult<PetType> safeParse(Object? data) {
    return petSchema.safeParseAs(data, (validated) {
      final map = validated as Map<String, Object?>;
      return switch (map['type']) {
        'cat' => CatType(map),
        'dog' => DogType(map),
        _ => throw StateError('Unknown type: ${map['type']}'),
      };
    });
  }
}

/// Extension type for Cat
extension type CatType(Map<String, Object?> _data)
    implements PetType, Map<String, Object?> {
  String get type => _data['type'] as String;

  static CatType parse(Object? data) {
    return catSchema.parseAs(
      data,
      (validated) => CatType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<CatType> safeParse(Object? data) {
    return catSchema.safeParseAs(
      data,
      (validated) => CatType(validated as Map<String, Object?>),
    );
  }

  int get lives => _data['lives'] as int;
}

/// Extension type for Dog
extension type DogType(Map<String, Object?> _data)
    implements PetType, Map<String, Object?> {
  String get type => _data['type'] as String;

  static DogType parse(Object? data) {
    return dogSchema.parseAs(
      data,
      (validated) => DogType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<DogType> safeParse(Object? data) {
    return dogSchema.safeParseAs(
      data,
      (validated) => DogType(validated as Map<String, Object?>),
    );
  }

  String get breed => _data['breed'] as String;
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
