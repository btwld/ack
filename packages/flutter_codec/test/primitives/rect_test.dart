import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('rectCodec decode', () {
    test('decodes a {left, top, right, bottom} object', () {
      expect(
        rectCodec.parse({'left': 1, 'top': 2, 'right': 30, 'bottom': 40}),
        const Rect.fromLTRB(1, 2, 30, 40),
      );
    });

    test('accepts integer coordinates as doubles', () {
      expect(
        rectCodec.parse({'left': 0, 'top': 0, 'right': 10, 'bottom': 10}),
        const Rect.fromLTRB(0, 0, 10, 10),
      );
    });
  });

  group('rectCodec encode', () {
    test('emits a canonical {left, top, right, bottom} map', () {
      final encoded = rectCodec.encode(const Rect.fromLTRB(1, 2, 30, 40));
      expect(encoded, {'left': 1.0, 'top': 2.0, 'right': 30.0, 'bottom': 40.0});
      expectJsonSafe(encoded);
    });

    test('round-trips an arbitrary rect', () {
      const rect = Rect.fromLTRB(-5.5, 12.25, 100, 0);
      expect(rectCodec.parse(rectCodec.encode(rect)!), rect);
    });
  });

  group('rectCodec rejects invalid input', () {
    const invalidCases = <String, Object>{
      'missing left': {'top': 0, 'right': 10, 'bottom': 10},
      'missing bottom': {'left': 0, 'top': 0, 'right': 10},
      'non-finite right': {
        'left': 0,
        'top': 0,
        'right': double.infinity,
        'bottom': 10,
      },
      'unknown key': {
        'left': 0,
        'top': 0,
        'right': 10,
        'bottom': 10,
        'width': 10,
      },
    };

    invalidCases.forEach((name, input) {
      test('rejects $name', () {
        expect(rectCodec.safeParse(input).isFail, isTrue);
      });
    });
  });
}
