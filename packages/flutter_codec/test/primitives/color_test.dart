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
}
