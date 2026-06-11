import 'dart:ui' show Locale;

import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show
        Color,
        StrutStyle,
        TextAlign,
        TextDirection,
        TextHeightBehavior,
        TextOverflow,
        TextStyle,
        TextWidthBasis;
import 'package:flutter/widgets.dart' show Key, Text;

import '../enums.dart'
    show
        textAlignCodec,
        textDirectionCodec,
        textOverflowCodec,
        textWidthBasisCodec;
import '../json_readers.dart';
import '../primitives/color.dart' show colorCodec;
import '../primitives/locale.dart' show localeCodec;
import '../primitives/text_height_behavior.dart' show textHeightBehaviorCodec;
import '../strut_style.dart' show strutStyleCodec;
import '../text_style.dart' show textStyleCodec;
import 'key.dart' show keyCodec;

/// Codec for plain [Text].
///
/// [Text.rich] is intentionally excluded until inline span trees have their own
/// codec. `textScaler` has no portable JSON shape (Flutter exposes no stable
/// public state for its concrete implementations); encoding a [Text] that sets
/// it throws [UnsupportedError] rather than dropping it silently. The
/// deprecated `textScaleFactor` constructor parameter is not encoded.
final CodecSchema<JsonMap, Text> textWidgetCodec = Ack.object({
  'key': keyCodec.nullable().optional(),
  'data': Ack.string(),
  'style': textStyleCodec.nullable().optional(),
  'strutStyle': strutStyleCodec.nullable().optional(),
  'textAlign': textAlignCodec.nullable().optional(),
  'textDirection': textDirectionCodec.nullable().optional(),
  'locale': localeCodec.nullable().optional(),
  'softWrap': Ack.boolean().nullable().optional(),
  'overflow': textOverflowCodec.nullable().optional(),
  'maxLines': Ack.integer().min(1).nullable().optional(),
  'semanticsLabel': Ack.string().nullable().optional(),
  'semanticsIdentifier': Ack.string().nullable().optional(),
  'textWidthBasis': textWidthBasisCodec.nullable().optional(),
  'textHeightBehavior': textHeightBehaviorCodec.nullable().optional(),
  'selectionColor': colorCodec.nullable().optional(),
}).codec<Text>(decode: _decodeText, encode: _encodeText);

Text _decodeText(JsonMap data) {
  return Text(
    readValue<String>(data, 'data'),
    key: readNullableValue<Key>(data, 'key'),
    style: readNullableValue<TextStyle>(data, 'style'),
    strutStyle: readNullableValue<StrutStyle>(data, 'strutStyle'),
    textAlign: readNullableValue<TextAlign>(data, 'textAlign'),
    textDirection: readNullableValue<TextDirection>(data, 'textDirection'),
    locale: readNullableValue<Locale>(data, 'locale'),
    softWrap: readNullableValue<bool>(data, 'softWrap'),
    overflow: readNullableValue<TextOverflow>(data, 'overflow'),
    maxLines: readNullableValue<int>(data, 'maxLines'),
    semanticsLabel: readNullableValue<String>(data, 'semanticsLabel'),
    semanticsIdentifier: readNullableValue<String>(data, 'semanticsIdentifier'),
    textWidthBasis: readNullableValue<TextWidthBasis>(data, 'textWidthBasis'),
    textHeightBehavior: readNullableValue<TextHeightBehavior>(
      data,
      'textHeightBehavior',
    ),
    selectionColor: readNullableValue<Color>(data, 'selectionColor'),
  );
}

JsonMap _encodeText(Text value) {
  // Flutter exposes no stable public state for a [TextScaler] implementation,
  // so it has no portable JSON shape. Fail loudly when one is set instead of
  // dropping it and decoding back an unscaled [Text].
  if (value.textScaler != null) {
    throw UnsupportedError(
      'Text.textScaler has no portable JSON shape and cannot be encoded. '
      'Resolve text scaling outside the codec, or omit textScaler.',
    );
  }

  return {
    'key': value.key,
    'data': value.data,
    'style': value.style,
    'strutStyle': value.strutStyle,
    'textAlign': value.textAlign,
    'textDirection': value.textDirection,
    'locale': value.locale,
    'softWrap': value.softWrap,
    'overflow': value.overflow,
    'maxLines': value.maxLines,
    'semanticsLabel': value.semanticsLabel,
    'semanticsIdentifier': value.semanticsIdentifier,
    'textWidthBasis': value.textWidthBasis,
    'textHeightBehavior': value.textHeightBehavior,
    'selectionColor': value.selectionColor,
  };
}
