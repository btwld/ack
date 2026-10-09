// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema_types_transforms.dart';

// **************************************************************************
// AckModelGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

/// Immutable value model generated from `colorSchema`.
final class ColorModel {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  ColorModel(this.value);

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory ColorModel.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory ColorModel.fromJson(String json) {
    return $ack.parse(json);
  }

  /// The wrapped value.
  final Color value;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => colorSchema,
    fromRuntime: ColorModel._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [ColorModel] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<ColorModel> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  String toJson() => $ack.encode(this);

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<String> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $ColorModelCopyWith<ColorModel> get copyWith => _$ColorModelCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ColorModel &&
          runtimeType == other.runtimeType &&
          deepEquals(value, other.value));

  @override
  int get hashCode => Object.hashAll([runtimeType, deepHashCode(value)]);

  @override
  String toString() => 'ColorModel(value: $value)';

  static ColorModel _fromAckRuntime(Color value) => ColorModel(value);

  Color _toAckRuntime() => value;
}

/// Creates copies of [ColorModel] with selected fields replaced.
abstract interface class $ColorModelCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({Color? value});
}

final class _$ColorModelCopyWith implements $ColorModelCopyWith<ColorModel> {
  const _$ColorModelCopyWith(this._source);

  final ColorModel _source;

  @override
  ColorModel call({Color? value}) => ColorModel(value ?? _source.value);
}

/// Immutable model generated from `profileSchema`.
final class Profile {
  /// Creates a model without validating it.
  ///
  /// Use `parse` or `fromJson` for untrusted input. `toJson` validates
  /// the model while encoding it.
  Profile({
    required this.homepage,
    required this.birthday,
    required this.lastLogin,
    required this.timeout,
    required List<Uri> links,
    required this.favoriteColor,
    required this.slug,
    required this.accent,
    required List<ColorModel> colors,
    required List<Color> customColors,
    required this.tagList,
  }) : links = List<Uri>.unmodifiable(links.map((item) => item)),
       colors = List<ColorModel>.unmodifiable(colors.map((item) => item)),
       customColors = List<Color>.unmodifiable(
         customColors.map((item) => item),
       );

  /// Validates [input] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Profile.parse(Object? input) {
    return $ack.parse(input);
  }

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return $ack.parse(json);
  }

  final Uri homepage;

  final DateTime birthday;

  final DateTime lastLogin;

  final Duration timeout;

  final List<Uri> links;

  final Color favoriteColor;

  final String slug;

  final ColorModel accent;

  final List<ColorModel> colors;

  final List<Color> customColors;

  final TagList tagList;

  /// The Ack adapter that parses and encodes this model.
  static final $ack = AckModelAdapter(
    schema: () => profileSchema,
    fromRuntime: Profile._fromAckRuntime,
    toRuntime: (model) => model._toAckRuntime(),
  );

  /// The Ack schema that parses input into [Profile] and encodes it back.
  ///
  /// A shorthand for `$ack.modelSchema`, created once.
  static final schema = $ack.modelSchema;

  /// Validates [input] and returns the model or the validation failure.
  static SchemaResult<Profile> safeParse(Object? input) =>
      $ack.safeParse(input);

  /// Validates this model and encodes it for JSON.
  ///
  /// Throws an `AckException` when validation fails.
  Map<String, dynamic> toJson() => Map<String, dynamic>.from($ack.encode(this));

  /// Validates this model and encodes it for JSON, returning the validation
  /// failure instead of throwing.
  SchemaResult<Map<String, Object?>> safeToJson() => $ack.safeEncode(this);

  /// Creates a copy of this model with selected fields replaced.
  $ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWith(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          runtimeType == other.runtimeType &&
          deepEquals(homepage, other.homepage) &&
          deepEquals(birthday, other.birthday) &&
          deepEquals(lastLogin, other.lastLogin) &&
          deepEquals(timeout, other.timeout) &&
          deepEquals(links, other.links) &&
          deepEquals(favoriteColor, other.favoriteColor) &&
          deepEquals(slug, other.slug) &&
          deepEquals(accent, other.accent) &&
          deepEquals(colors, other.colors) &&
          deepEquals(customColors, other.customColors) &&
          deepEquals(tagList, other.tagList));

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    deepHashCode(homepage),
    deepHashCode(birthday),
    deepHashCode(lastLogin),
    deepHashCode(timeout),
    deepHashCode(links),
    deepHashCode(favoriteColor),
    deepHashCode(slug),
    deepHashCode(accent),
    deepHashCode(colors),
    deepHashCode(customColors),
    deepHashCode(tagList),
  ]);

  @override
  String toString() =>
      'Profile(homepage: $homepage, birthday: $birthday, lastLogin: $lastLogin, timeout: $timeout, links: $links, favoriteColor: $favoriteColor, slug: $slug, accent: $accent, colors: $colors, customColors: $customColors, tagList: $tagList)';

  static Profile _fromAckRuntime(Map<String, Object?> value) => Profile(
    homepage: value['homepage'] as Uri,
    birthday: value['birthday'] as DateTime,
    lastLogin: value['lastLogin'] as DateTime,
    timeout: value['timeout'] as Duration,
    links: (value['links'] as List).map((item) => item as Uri).toList(),
    favoriteColor: value['favoriteColor'] as Color,
    slug: value['slug'] as String,
    accent: ColorModel.$ack.fromRuntime(value['accent'] as Color),
    colors: (value['colors'] as List)
        .map((item) => ColorModel.$ack.fromRuntime(item as Color))
        .toList(),
    customColors: (value['customColors'] as List)
        .map((item) => item as Color)
        .toList(),
    tagList: value['tagList'] as TagList,
  );

  Map<String, Object?> _toAckRuntime() => <String, Object?>{
    'homepage': homepage,
    'birthday': birthday,
    'lastLogin': lastLogin,
    'timeout': timeout,
    'links': links.map((item) => item).toList(growable: false),
    'favoriteColor': favoriteColor,
    'slug': slug,
    'accent': ColorModel.$ack.toRuntime(accent),
    'colors': colors
        .map((item) => ColorModel.$ack.toRuntime(item))
        .toList(growable: false),
    'customColors': customColors.map((item) => item).toList(growable: false),
    'tagList': tagList,
  };
}

/// Creates copies of [Profile] with selected fields replaced.
abstract interface class $ProfileCopyWith<$Result> {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  $Result call({
    Uri? homepage,
    DateTime? birthday,
    DateTime? lastLogin,
    Duration? timeout,
    List<Uri>? links,
    Color? favoriteColor,
    String? slug,
    ColorModel? accent,
    List<ColorModel>? colors,
    List<Color>? customColors,
    TagList? tagList,
  });
}

final class _$ProfileCopyWith implements $ProfileCopyWith<Profile> {
  const _$ProfileCopyWith(this._source);

  final Profile _source;

  @override
  Profile call({
    Uri? homepage,
    DateTime? birthday,
    DateTime? lastLogin,
    Duration? timeout,
    List<Uri>? links,
    Color? favoriteColor,
    String? slug,
    ColorModel? accent,
    List<ColorModel>? colors,
    List<Color>? customColors,
    TagList? tagList,
  }) => Profile(
    homepage: homepage ?? _source.homepage,
    birthday: birthday ?? _source.birthday,
    lastLogin: lastLogin ?? _source.lastLogin,
    timeout: timeout ?? _source.timeout,
    links: links ?? _source.links,
    favoriteColor: favoriteColor ?? _source.favoriteColor,
    slug: slug ?? _source.slug,
    accent: accent ?? _source.accent,
    colors: colors ?? _source.colors,
    customColors: customColors ?? _source.customColors,
    tagList: tagList ?? _source.tagList,
  );
}
