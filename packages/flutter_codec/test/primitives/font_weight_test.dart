import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('fontWeightCodec decode', () {
    const weights = <String, FontWeight>{
      'w100': FontWeight.w100,
      'w200': FontWeight.w200,
      'w300': FontWeight.w300,
      'w400': FontWeight.w400,
      'w500': FontWeight.w500,
      'w600': FontWeight.w600,
      'w700': FontWeight.w700,
      'w800': FontWeight.w800,
      'w900': FontWeight.w900,
    };

    weights.forEach((name, value) {
      test('decodes "$name"', () {
        expect(fontWeightCodec.parse(name), value);
      });
    });

    test('decodes conventional aliases', () {
      expect(fontWeightCodec.parse('normal'), FontWeight.normal);
      expect(fontWeightCodec.parse('bold'), FontWeight.bold);
    });

    test('decodes an integer variable-font weight', () {
      expect(fontWeightCodec.parse(550), const FontWeight(550));
      expect(fontWeightCodec.parse(1), const FontWeight(1));
      expect(fontWeightCodec.parse(1000), const FontWeight(1000));
    });

    test('decodes a canonical integer weight to the standard instance', () {
      expect(fontWeightCodec.parse(400), FontWeight.w400);
    });
  });

  group('fontWeightCodec encode', () {
    const weights = [
      (FontWeight.w100, 'w100'),
      (FontWeight.w200, 'w200'),
      (FontWeight.w300, 'w300'),
      (FontWeight.w400, 'w400'),
      (FontWeight.w500, 'w500'),
      (FontWeight.w600, 'w600'),
      (FontWeight.w700, 'w700'),
      (FontWeight.w800, 'w800'),
      (FontWeight.w900, 'w900'),
    ];

    for (final (value, name) in weights) {
      test('encodes $value as "$name"', () {
        final encoded = fontWeightCodec.encode(value);
        expect(encoded, name);
        expectJsonSafe(encoded);
      });
    }

    test('canonicalizes conventional aliases', () {
      expect(fontWeightCodec.encode(FontWeight.normal), 'w400');
      expect(fontWeightCodec.encode(FontWeight.bold), 'w700');
    });

    test('encodes a non-canonical variable-font weight as an integer', () {
      final encoded = fontWeightCodec.encode(const FontWeight(550));
      expect(encoded, 550);
      expectJsonSafe(encoded);
    });

    test('round-trips a variable-font weight', () {
      const weight = FontWeight(550);
      expect(fontWeightCodec.parse(fontWeightCodec.encode(weight)), weight);
    });
  });

  group('fontWeightCodec rejects invalid input', () {
    // Out-of-range integers (the constructor asserts [1, 1000]) and
    // non-weight values are rejected; in-range integers are now accepted.
    for (final input in ['heavy', 0, 1001, null]) {
      test('rejects $input', () {
        expect(fontWeightCodec.safeParse(input).isFail, isTrue);
      });
    }
  });
}
