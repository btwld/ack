// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'schema_types_transforms.dart';

List<T> _$ackListCast<T>(Object? value) => (value as List).cast<T>();

/// Extension type for Color
extension type ColorType(String _value) implements String {
  static ColorType parse(Object? data) {
    return colorSchema.parseRepresentationAs(
      data,
      (validated) => ColorType(validated as String),
    );
  }

  static SchemaResult<ColorType> safeParse(Object? data) {
    return colorSchema.safeParseRepresentationAs(
      data,
      (validated) => ColorType(validated as String),
    );
  }

  String toJson() => _value;

  Color get parsed => colorSchema.parse(_value)!;
}

/// Extension type for Profile
extension type ProfileType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static ProfileType parse(Object? data) {
    return profileSchema.parseRepresentationAs(
      data,
      (validated) => ProfileType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<ProfileType> safeParse(Object? data) {
    return profileSchema.safeParseRepresentationAs(
      data,
      (validated) => ProfileType(validated as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => _data;

  String get homepage => _data['homepage'] as String;

  Uri get homepageParsed =>
      profileSchema.properties['homepage']!.parse(_data['homepage']) as Uri;

  String get birthday => _data['birthday'] as String;

  DateTime get birthdayParsed =>
      profileSchema.properties['birthday']!.parse(_data['birthday'])
          as DateTime;

  String get lastLogin => _data['lastLogin'] as String;

  DateTime get lastLoginParsed =>
      profileSchema.properties['lastLogin']!.parse(_data['lastLogin'])
          as DateTime;

  int get timeout => _data['timeout'] as int;

  Duration get timeoutParsed =>
      profileSchema.properties['timeout']!.parse(_data['timeout']) as Duration;

  List<String> get links => _$ackListCast<String>(_data['links']);

  String get favoriteColor => _data['favoriteColor'] as String;

  Color get favoriteColorParsed =>
      profileSchema.properties['favoriteColor']!.parse(_data['favoriteColor'])
          as Color;

  String get slug => _data['slug'] as String;

  ColorType get accent => ColorType(_data['accent'] as String);

  Color get accentParsed => accent.parsed;

  List<ColorType> get colors =>
      (_data['colors'] as List).map((e) => ColorType(e as String)).toList();

  List<Color> get colorsParsed => colors.map((e) => e.parsed).toList();

  List<String> get customColors => _$ackListCast<String>(_data['customColors']);

  List<String> get tagList => _$ackListCast<String>(_data['tagList']);

  TagList get tagListParsed =>
      profileSchema.properties['tagList']!.parse(_data['tagList']) as TagList;

  ProfileType copyWith({
    String? homepage,
    String? birthday,
    String? lastLogin,
    int? timeout,
    List<String>? links,
    String? favoriteColor,
    String? slug,
    ColorType? accent,
    List<ColorType>? colors,
    List<String>? customColors,
    List<String>? tagList,
  }) {
    return ProfileType.parse({
      'homepage': homepage ?? _data['homepage'],
      'birthday': birthday ?? _data['birthday'],
      'lastLogin': lastLogin ?? _data['lastLogin'],
      'timeout': timeout ?? _data['timeout'],
      'links': links ?? _data['links'],
      'favoriteColor': favoriteColor ?? _data['favoriteColor'],
      'slug': slug ?? _data['slug'],
      'accent': accent?.toJson() ?? _data['accent'],
      'colors': colors?.map((e) => e.toJson()).toList() ?? _data['colors'],
      'customColors': customColors ?? _data['customColors'],
      'tagList': tagList ?? _data['tagList'],
    });
  }
}
