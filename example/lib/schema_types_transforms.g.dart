// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'schema_types_transforms.dart';

List<T> _$ackListCast<T>(Object? value) => (value as List).cast<T>();

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

  Color toJson() => _value;
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

  Map<String, Object?> toJson() => _data;

  Uri get homepage => _data['homepage'] as Uri;

  DateTime get birthday => _data['birthday'] as DateTime;

  DateTime get lastLogin => _data['lastLogin'] as DateTime;

  Duration get timeout => _data['timeout'] as Duration;

  List<Uri> get links => _$ackListCast<Uri>(_data['links']);

  Color get favoriteColor => _data['favoriteColor'] as Color;

  String get slug => _data['slug'] as String;

  ColorType get accent => ColorType(_data['accent'] as Color);

  List<ColorType> get colors =>
      (_data['colors'] as List).map((e) => ColorType(e as Color)).toList();

  List<Color> get customColors => _$ackListCast<Color>(_data['customColors']);

  TagList get tagList => _data['tagList'] as TagList;
}
