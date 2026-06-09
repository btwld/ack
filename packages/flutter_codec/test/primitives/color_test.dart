import 'dart:ui';

import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('colorCodec decode', () {
    const cases = [
      ('#2196F3', Color(0xFF2196F3)),
      ('#802196F3', Color(0x802196F3)),
      ('rgb(33, 150, 243)', Color(0xFF2196F3)),
      ('rgba(33, 150, 243, 0.5)', Color(0x802196F3)),
    ];

    for (final (input, expected) in cases) {
      test(input, () {
        expect(colorCodec.parse(input), expected);
      });
    }
  });

  group('colorCodec encode', () {
    test('canonicalizes opaque colors to #RRGGBB', () {
      final encoded = colorCodec.encode(const Color(0xFF2196F3));
      expect(encoded, '#2196F3');
      expectJsonSafe(encoded);
    });

    test('canonicalizes translucent colors to #AARRGGBB', () {
      final encoded = colorCodec.encode(const Color(0x802196F3));
      expect(encoded, '#802196F3');
      expectJsonSafe(encoded);
    });
  });

  group('colorCodec rejects invalid input', () {
    for (final input in [
      '#2196F',
      '#GG96F3',
      'rgb(256, 150, 243)',
      'rgba(33, 150, 243, 1.5)',
      'hsl(207, 90%, 54%)',
    ]) {
      test(input, () {
        expect(colorCodec.safeParse(input).isFail, isTrue);
      });
    }
  });

  // Characterization tests: the wire format is 8-bit sRGB hex, so float-channel
  // precision and non-sRGB color spaces are intentionally not preserved. These
  // pin the documented loss so it stays deliberate.
  group('colorCodec is 8-bit sRGB (documented lossy)', () {
    test('an integer-constructed sRGB color round-trips exactly', () {
      const color = Color(0xFF2196F3);
      expect(colorCodec.parse(colorCodec.encode(color)), color);
    });

    test('a float-channel color is quantized to 8 bits, not preserved', () {
      final color = const Color(0xFF000000).withValues(alpha: 0.3);
      final roundTripped = colorCodec.parse(colorCodec.encode(color))!;
      // The float alpha 0.3 cannot survive an 8-bit round-trip exactly...
      expect(roundTripped, isNot(color));
      // ...but the quantized value stays within one 8-bit step of 0.3.
      expect(roundTripped.a, closeTo(0.3, 1 / 255));
    });

    test('a wide-gamut color round-trips as sRGB', () {
      const wideGamut = Color.from(
        alpha: 1,
        red: 1,
        green: 0,
        blue: 0,
        colorSpace: ColorSpace.displayP3,
      );
      final roundTripped = colorCodec.parse(colorCodec.encode(wideGamut))!;
      expect(roundTripped.colorSpace, ColorSpace.sRGB);
    });
  });
}
