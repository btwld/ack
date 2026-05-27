import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show FontStyle, FontWeight, StrutStyle, TextLeadingDistribution;

import 'enums.dart' show fontStyleCodec, textLeadingDistributionCodec;
import 'font_family_packing.dart' show unpackFontFamily;
import 'json_readers.dart';
import 'primitives/font_weight.dart' show fontWeightCodec;

/// Codec for [StrutStyle].
///
/// Supported fields are the JSON-safe constructor parameters: `fontFamily`,
/// `fontFamilyFallback`, `package`, `fontSize` (positive when non-null),
/// `height`, `leadingDistribution` ([textLeadingDistributionCodec]),
/// `leading` (non-negative when non-null), `fontWeight`
/// ([fontWeightCodec]), `fontStyle` ([fontStyleCodec]), and
/// `forceStrutHeight`.
///
/// Encoding unfolds Flutter's internal `packages/<pkg>/<family>` storage
/// back to a `(fontFamily, fontFamilyFallback, package)` triple when all
/// referenced families share the same prefix (matching [textStyleCodec]).
/// When the prefix is missing or inconsistent, `package` is emitted as
/// `null` and the stored (prefixed) `fontFamily` is preserved verbatim.
///
/// [StrutStyle.debugLabel] is excluded — it's debug metadata, ignored by
/// [StrutStyle] equality.
final strutStyleCodec = Ack.object({
  'fontFamily': Ack.string().nullable().optional(),
  'fontFamilyFallback': Ack.list(Ack.string()).nullable().optional(),
  'package': Ack.string().nullable().optional(),
  'fontSize': Ack.number().positive().nullable().optional(),
  'height': Ack.number().nullable().optional(),
  'leadingDistribution': textLeadingDistributionCodec.nullable().optional(),
  'leading': Ack.number().min(0).nullable().optional(),
  'fontWeight': fontWeightCodec.nullable().optional(),
  'fontStyle': fontStyleCodec.nullable().optional(),
  'forceStrutHeight': Ack.boolean().nullable().optional(),
}).codec<StrutStyle>(decode: _decodeStrutStyle, encode: _encodeStrutStyle);

StrutStyle _decodeStrutStyle(JsonMap data) {
  return StrutStyle(
    fontFamily: readNullableValue<String>(data, 'fontFamily'),
    fontFamilyFallback: readNullableList<String>(data, 'fontFamilyFallback'),
    package: readNullableValue<String>(data, 'package'),
    fontSize: readNullableDouble(data, 'fontSize'),
    height: readNullableDouble(data, 'height'),
    leadingDistribution: readNullableValue<TextLeadingDistribution>(
      data,
      'leadingDistribution',
    ),
    leading: readNullableDouble(data, 'leading'),
    fontWeight: readNullableValue<FontWeight>(data, 'fontWeight'),
    fontStyle: readNullableValue<FontStyle>(data, 'fontStyle'),
    forceStrutHeight: readNullableValue<bool>(data, 'forceStrutHeight'),
  );
}

JsonMap _encodeStrutStyle(StrutStyle value) {
  final fontFamilyFields = unpackFontFamily(
    value.fontFamily,
    value.fontFamilyFallback,
  );

  return {
    'fontFamily': fontFamilyFields.family,
    'fontFamilyFallback': fontFamilyFields.fallback,
    'package': fontFamilyFields.packageName,
    'fontSize': value.fontSize,
    'height': value.height,
    'leadingDistribution': value.leadingDistribution,
    'leading': value.leading,
    'fontWeight': value.fontWeight,
    'fontStyle': value.fontStyle,
    'forceStrutHeight': value.forceStrutHeight,
  };
}
