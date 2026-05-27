import 'dart:convert';
import 'dart:ui';

import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('fontFeatureCodec decode', () {
    test('decodes a feature tag with an explicit value', () {
      expect(
        fontFeatureCodec.parse({'feature': 'smcp', 'value': 1}),
        const FontFeature('smcp', 1),
      );
    });

    test('defaults missing value to 1 (the enable convention)', () {
      expect(
        fontFeatureCodec.parse({'feature': 'liga'}),
        const FontFeature('liga'),
      );
    });

    test('accepts non-default integer values', () {
      expect(
        fontFeatureCodec.parse({'feature': 'cv01', 'value': 3}),
        const FontFeature('cv01', 3),
      );
    });
  });

  group('fontFeatureCodec encode', () {
    test('emits the feature tag and value', () {
      final encoded = fontFeatureCodec.encode(const FontFeature('smcp', 1));
      expect(encoded, {'feature': 'smcp', 'value': 1});
      expectJsonSafe(encoded);
    });

    test('round-trips named convenience constructors as (feature, value)', () {
      final encoded = fontFeatureCodec.encode(FontFeature.alternative(2));
      expect(fontFeatureCodec.parse(encoded), FontFeature.alternative(2));
    });
  });

  group('fontFeatureCodec rejects invalid input', () {
    test('rejects a feature tag shorter than four characters', () {
      expect(
        fontFeatureCodec.safeParse({'feature': 'lig', 'value': 1}).isFail,
        isTrue,
      );
    });

    test('rejects a feature tag longer than four characters', () {
      expect(
        fontFeatureCodec.safeParse({'feature': 'ligas', 'value': 1}).isFail,
        isTrue,
      );
    });

    test('rejects negative values', () {
      expect(
        fontFeatureCodec.safeParse({'feature': 'smcp', 'value': -1}).isFail,
        isTrue,
      );
    });

    test('rejects unknown keys', () {
      expect(
        fontFeatureCodec.safeParse({
          'feature': 'smcp',
          'value': 1,
          'extra': true,
        }).isFail,
        isTrue,
      );
    });
  });

  group('fontFeatureCodec JSON Schema', () {
    test('reflects the 4-character pattern and default value', () {
      final schema = jsonEncode(fontFeatureCodec.toJsonSchema());
      expect(schema, contains(r'[\\x20-\\x7E]{4}'));
      expect(schema, contains('"default":1'));
    });
  });
}
