import 'dart:ui' as ui show Locale, Shadow;

import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show
        Color,
        FontStyle,
        FontWeight,
        TextBaseline,
        TextDecoration,
        TextDecorationStyle,
        TextLeadingDistribution,
        TextOverflow,
        TextStyle;

import 'enums.dart'
    show
        fontStyleCodec,
        textBaselineCodec,
        textDecorationStyleCodec,
        textLeadingDistributionCodec,
        textOverflowCodec;
import 'primitives/color.dart' show colorCodec;
import 'primitives/font_weight.dart' show fontWeightCodec;
import 'primitives/locale.dart' show localeCodec;
import 'primitives/text_decoration.dart' show textDecorationCodec;
import 'shadows.dart' show shadowCodec;

/// Codec for [TextStyle].
///
/// Supported fields are the JSON-safe constructor parameters: colors,
/// typography scalars, enum fields, [FontWeight], [ui.Locale], shadows,
/// [TextDecoration], font families, package, and overflow.
///
/// Unsupported fields are intentionally omitted:
/// * `foreground` and `background` are `Paint?`, which is not JSON-safe.
/// * `debugLabel` is debug metadata and is excluded from [TextStyle] equality.
/// * `fontFeatures` and `fontVariations` are niche typography fields reserved
///   for a focused follow-up.
final textStyleCodec = Ack.object({
  'inherit': Ack.boolean().withDefault(true),
  'color': colorCodec.nullable().optional(),
  'backgroundColor': colorCodec.nullable().optional(),
  'fontSize': Ack.number().nullable().optional(),
  'fontWeight': fontWeightCodec.nullable().optional(),
  'fontStyle': fontStyleCodec.nullable().optional(),
  'letterSpacing': Ack.number().nullable().optional(),
  'wordSpacing': Ack.number().nullable().optional(),
  'textBaseline': textBaselineCodec.nullable().optional(),
  'height': Ack.number().nullable().optional(),
  'leadingDistribution': textLeadingDistributionCodec.nullable().optional(),
  'locale': localeCodec.nullable().optional(),
  'shadows': Ack.list(shadowCodec).nullable().optional(),
  'decoration': textDecorationCodec.nullable().optional(),
  'decorationColor': colorCodec.nullable().optional(),
  'decorationStyle': textDecorationStyleCodec.nullable().optional(),
  'decorationThickness': Ack.number().nullable().optional(),
  'fontFamily': Ack.string().nullable().optional(),
  'fontFamilyFallback': Ack.list(Ack.string()).nullable().optional(),
  'package': Ack.string().nullable().optional(),
  'overflow': textOverflowCodec.nullable().optional(),
}).codec<TextStyle>(decode: _decodeTextStyle, encode: _encodeTextStyle);

TextStyle _decodeTextStyle(JsonMap data) {
  return TextStyle(
    inherit: data['inherit']! as bool,
    color: data['color'] as Color?,
    backgroundColor: data['backgroundColor'] as Color?,
    fontSize: _readNullableDouble(data, 'fontSize'),
    fontWeight: data['fontWeight'] as FontWeight?,
    fontStyle: data['fontStyle'] as FontStyle?,
    letterSpacing: _readNullableDouble(data, 'letterSpacing'),
    wordSpacing: _readNullableDouble(data, 'wordSpacing'),
    textBaseline: data['textBaseline'] as TextBaseline?,
    height: _readNullableDouble(data, 'height'),
    leadingDistribution:
        data['leadingDistribution'] as TextLeadingDistribution?,
    locale: data['locale'] as ui.Locale?,
    shadows: _readNullableList<ui.Shadow>(data, 'shadows'),
    decoration: data['decoration'] as TextDecoration?,
    decorationColor: data['decorationColor'] as Color?,
    decorationStyle: data['decorationStyle'] as TextDecorationStyle?,
    decorationThickness: _readNullableDouble(data, 'decorationThickness'),
    fontFamily: data['fontFamily'] as String?,
    fontFamilyFallback: _readNullableList<String>(data, 'fontFamilyFallback'),
    package: data['package'] as String?,
    overflow: data['overflow'] as TextOverflow?,
  );
}

JsonMap _encodeTextStyle(TextStyle value) {
  final fontFamilyFields = _encodeFontFamilyFields(value);

  return {
    'inherit': value.inherit,
    'color': value.color,
    'backgroundColor': value.backgroundColor,
    'fontSize': value.fontSize,
    'fontWeight': value.fontWeight,
    'fontStyle': value.fontStyle,
    'letterSpacing': value.letterSpacing,
    'wordSpacing': value.wordSpacing,
    'textBaseline': value.textBaseline,
    'height': value.height,
    'leadingDistribution': value.leadingDistribution,
    'locale': value.locale,
    'shadows': value.shadows,
    'decoration': value.decoration,
    'decorationColor': value.decorationColor,
    'decorationStyle': value.decorationStyle,
    'decorationThickness': value.decorationThickness,
    'fontFamily': fontFamilyFields.family,
    'fontFamilyFallback': fontFamilyFields.fallback,
    'package': fontFamilyFields.packageName,
    'overflow': value.overflow,
  };
}

double? _readNullableDouble(JsonMap map, String key) {
  final value = map[key];
  if (value == null) return null;

  return (value as num).toDouble();
}

List<T>? _readNullableList<T>(JsonMap data, String key) {
  final value = data[key];
  if (value == null) return null;

  return (value as List).cast<T>().toList();
}

({String? family, List<String>? fallback, String? packageName})
_encodeFontFamilyFields(TextStyle value) {
  final fontFamily = value.fontFamily;
  final fontFamilyFallback = value.fontFamilyFallback;
  final packageName = _inferPackageName(fontFamily, fontFamilyFallback);
  if (packageName == null) {
    return (
      family: fontFamily,
      fallback: fontFamilyFallback,
      packageName: null,
    );
  }

  return (
    family: fontFamily == null
        ? null
        : _stripPackagePrefix(fontFamily, packageName),
    fallback: fontFamilyFallback
        ?.map((family) => _stripPackagePrefix(family, packageName))
        .toList(),
    packageName: packageName,
  );
}

String? _inferPackageName(String? fontFamily, List<String>? fallback) {
  final families = [
    if (fontFamily != null) fontFamily,
    if (fallback != null) ...fallback,
  ];
  if (families.isEmpty) return null;

  final packageName = _packageNameFromPrefixedFamily(families.first);
  if (packageName == null) return null;

  for (final family in families.skip(1)) {
    if (_packageNameFromPrefixedFamily(family) != packageName) return null;
  }

  return packageName;
}

String? _packageNameFromPrefixedFamily(String fontFamily) {
  const packagesPrefix = 'packages/';
  if (!fontFamily.startsWith(packagesPrefix)) return null;

  final packageAndFamily = fontFamily.substring(packagesPrefix.length);
  final separator = packageAndFamily.indexOf('/');
  if (separator <= 0 || separator == packageAndFamily.length - 1) return null;

  return packageAndFamily.substring(0, separator);
}

String _stripPackagePrefix(String fontFamily, String packageName) {
  final prefix = 'packages/$packageName/';
  if (!fontFamily.startsWith(prefix)) return fontFamily;

  return fontFamily.substring(prefix.length);
}
