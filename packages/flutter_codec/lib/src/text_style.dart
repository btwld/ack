import 'dart:ui' as ui show Locale, Shadow;

import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show
        Color,
        FontFeature,
        FontStyle,
        FontVariation,
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
import 'font_family_packing.dart' show unpackFontFamily;
import 'json_readers.dart';
import 'primitives/color.dart' show colorCodec;
import 'primitives/font_feature.dart' show fontFeatureCodec;
import 'primitives/font_variation.dart' show fontVariationCodec;
import 'primitives/font_weight.dart' show fontWeightCodec;
import 'primitives/locale.dart' show localeCodec;
import 'primitives/text_decoration.dart' show textDecorationCodec;
import 'shadows.dart' show shadowCodec;

/// Codec for [TextStyle].
///
/// Supported fields are the JSON-safe constructor parameters: colors,
/// typography scalars, enum fields, [FontWeight], [ui.Locale],
/// [TextStyle.shadows], [TextDecoration], [TextStyle.fontFamily],
/// [TextStyle.fontFamilyFallback], [TextStyle.package],
/// [TextStyle.overflow], [TextStyle.fontFeatures], and
/// [TextStyle.fontVariations].
///
/// Unsupported fields are intentionally omitted:
/// * [TextStyle.foreground] and [TextStyle.background] are nullable [Paint]
///   values, which are not JSON-safe.
/// * [TextStyle.debugLabel] is debug metadata and is excluded from
///   [TextStyle] equality.
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
  'fontFeatures': Ack.list(fontFeatureCodec).nullable().optional(),
  'fontVariations': Ack.list(fontVariationCodec).nullable().optional(),
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
    fontFeatures: readNullableList<FontFeature>(data, 'fontFeatures'),
    fontVariations: readNullableList<FontVariation>(data, 'fontVariations'),
  );
}

JsonMap _encodeTextStyle(TextStyle value) {
  final fontFamilyFields = unpackFontFamily(
    value.fontFamily,
    value.fontFamilyFallback,
  );

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
    'fontFeatures': value.fontFeatures,
    'fontVariations': value.fontVariations,
  };
}
