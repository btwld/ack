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
import 'json_readers.dart';
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
    inherit: readValue<bool>(data, 'inherit'),
    color: readNullableValue<Color>(data, 'color'),
    backgroundColor: readNullableValue<Color>(data, 'backgroundColor'),
    fontSize: readNullableDouble(data, 'fontSize'),
    fontWeight: readNullableValue<FontWeight>(data, 'fontWeight'),
    fontStyle: readNullableValue<FontStyle>(data, 'fontStyle'),
    letterSpacing: readNullableDouble(data, 'letterSpacing'),
    wordSpacing: readNullableDouble(data, 'wordSpacing'),
    textBaseline: readNullableValue<TextBaseline>(data, 'textBaseline'),
    height: readNullableDouble(data, 'height'),
    leadingDistribution: readNullableValue<TextLeadingDistribution>(
      data,
      'leadingDistribution',
    ),
    locale: readNullableValue<ui.Locale>(data, 'locale'),
    shadows: readNullableList<ui.Shadow>(data, 'shadows'),
    decoration: readNullableValue<TextDecoration>(data, 'decoration'),
    decorationColor: readNullableValue<Color>(data, 'decorationColor'),
    decorationStyle: readNullableValue<TextDecorationStyle>(
      data,
      'decorationStyle',
    ),
    decorationThickness: readNullableDouble(data, 'decorationThickness'),
    fontFamily: readNullableValue<String>(data, 'fontFamily'),
    fontFamilyFallback: readNullableList<String>(data, 'fontFamilyFallback'),
    package: readNullableValue<String>(data, 'package'),
    overflow: readNullableValue<TextOverflow>(data, 'overflow'),
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

/// Unfolds Flutter's internal `packages/<pkg>/<family>` storage back to the
/// user-supplied `(fontFamily, fontFamilyFallback, package)` triple, when all
/// referenced families share the same package prefix. Falls back to the
/// stored (prefixed) form if the prefix is missing or inconsistent.
({String? family, List<String>? fallback, String? packageName})
_encodeFontFamilyFields(TextStyle value) {
  final family = value.fontFamily;
  final fallback = value.fontFamilyFallback;
  final pkg = _sharedPackagePrefix([if (family != null) family, ...?fallback]);
  if (pkg == null) {
    return (family: family, fallback: fallback, packageName: null);
  }

  final prefix = 'packages/$pkg/';
  String strip(String f) =>
      f.startsWith(prefix) ? f.substring(prefix.length) : f;
  return (
    family: family == null ? null : strip(family),
    fallback: fallback?.map(strip).toList(),
    packageName: pkg,
  );
}

/// Returns the package name shared by every `packages/<name>/<family>` entry
/// in [families], or null if any entry lacks the prefix or disagrees.
String? _sharedPackagePrefix(List<String> families) {
  const prefix = 'packages/';
  String? shared;
  for (final family in families) {
    if (!family.startsWith(prefix)) return null;

    final rest = family.substring(prefix.length);
    final separator = rest.indexOf('/');
    if (separator <= 0 || separator == rest.length - 1) return null;

    final name = rest.substring(0, separator);
    if (shared == null) {
      shared = name;
    } else if (shared != name) {
      return null;
    }
  }
  return shared;
}
