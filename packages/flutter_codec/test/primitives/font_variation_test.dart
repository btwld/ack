import 'dart:convert';
import 'dart:ui';

import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('fontVariationCodec decode', () {
    test('decodes an axis tag and value', () {
      expect(
        fontVariationCodec.parse({'axis': 'wght', 'value': 600}),
        const FontVariation('wght', 600),
      );
    });

    test('coerces integer JSON values to double on the value field', () {
      // JSON sources emit `100` as int; FontVariation.value is double, and
      // the codec must round-trip through the double constructor.
      expect(
        fontVariationCodec.parse({'axis': 'wdth', 'value': 100}),
        const FontVariation('wdth', 100.0),
      );
    });
  });

  group('fontVariationCodec encode', () {
    test('emits the axis tag and value', () {
      final encoded = fontVariationCodec.encode(
        const FontVariation('wght', 600),
      );
      expect(encoded, {'axis': 'wght', 'value': 600.0});
      expectJsonSafe(encoded);
    });

    test('round-trips named convenience constructors as (axis, value)', () {
      final encoded = fontVariationCodec.encode(FontVariation.weight(500));
      expect(fontVariationCodec.parse(encoded), FontVariation.weight(500));
    });
  });

  group('fontVariationCodec rejects invalid input', () {
    test('rejects an axis tag shorter than four characters', () {
      expect(
        fontVariationCodec.safeParse({'axis': 'wgt', 'value': 600}).isFail,
        isTrue,
      );
    });

    test('rejects an axis tag longer than four characters', () {
      expect(
        fontVariationCodec.safeParse({'axis': 'wghtx', 'value': 600}).isFail,
        isTrue,
      );
    });

    test('rejects unknown keys', () {
      expect(
        fontVariationCodec.safeParse({
          'axis': 'wght',
          'value': 600,
          'extra': true,
        }).isFail,
        isTrue,
      );
    });

    test('rejects a missing value', () {
      expect(fontVariationCodec.safeParse({'axis': 'wght'}).isFail, isTrue);
    });
  });

  group('fontVariationCodec JSON Schema', () {
    test('reflects the 4-character pattern on axis', () {
      final schema = jsonEncode(fontVariationCodec.toJsonSchema());
      expect(schema, contains(r'[\\x20-\\x7E]{4}'));
    });
  });
}
