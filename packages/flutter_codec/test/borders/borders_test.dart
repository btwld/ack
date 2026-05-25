import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('strokeAlignCodec decode', () {
    const namedCases = [
      ('inside', BorderSide.strokeAlignInside),
      ('center', BorderSide.strokeAlignCenter),
      ('outside', BorderSide.strokeAlignOutside),
    ];

    for (final (input, expected) in namedCases) {
      test('decodes "$input"', () {
        expect(strokeAlignCodec.parse(input), expected);
      });
    }

    test('decodes a double as itself', () {
      expect(strokeAlignCodec.parse(0.5), 0.5);
    });

    test('decodes an int as a double', () {
      expect(strokeAlignCodec.parse(2), 2.0);
    });

    test('decodes values beyond the named range', () {
      expect(strokeAlignCodec.parse(-3.5), -3.5);
    });
  });

  group('strokeAlignCodec encode', () {
    test('canonicalizes named offsets to aliases', () {
      for (final (offset, alias) in const [
        (BorderSide.strokeAlignInside, 'inside'),
        (BorderSide.strokeAlignCenter, 'center'),
        (BorderSide.strokeAlignOutside, 'outside'),
      ]) {
        final encoded = strokeAlignCodec.encode(offset);
        expect(encoded, alias);
        expectJsonSafe(encoded);
      }
    });

    test('encodes other finite values as numbers', () {
      final encoded = strokeAlignCodec.encode(0.5);
      expect(encoded, 0.5);
      expectJsonSafe(encoded);
    });
  });

  group('strokeAlignCodec rejects invalid input', () {
    test('rejects unknown strings', () {
      expect(strokeAlignCodec.safeParse('diagonal').isFail, isTrue);
    });

    test('rejects non-finite numbers', () {
      expect(strokeAlignCodec.safeParse(double.infinity).isFail, isTrue);
      expect(strokeAlignCodec.safeParse(double.nan).isFail, isTrue);
    });
  });

  group('borderSideCodec decode', () {
    test('parses an empty object as the default BorderSide', () {
      expect(borderSideCodec.parse({}), const BorderSide());
    });

    test('applies defaults to a partial object, decoding nested color', () {
      expect(
        borderSideCodec.parse({'color': '#2196F3'}),
        const BorderSide(color: Color(0xFF2196F3)),
      );
    });

    test('parses a full object', () {
      expect(
        borderSideCodec.parse({
          'color': '#FF0000',
          'width': 2.0,
          'style': 'none',
          'strokeAlign': 'outside',
        }),
        const BorderSide(
          color: Color(0xFFFF0000),
          width: 2,
          style: BorderStyle.none,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      );
    });
  });

  group('borderSideCodec encode', () {
    test('emits a full canonical object including defaults', () {
      final encoded = borderSideCodec.encode(const BorderSide());
      expect(encoded, {
        'color': '#000000',
        'width': 1.0,
        'style': 'solid',
        'strokeAlign': 'inside',
      });
      expectJsonSafe(encoded);
    });

    test('encodes a customized BorderSide', () {
      final encoded = borderSideCodec.encode(
        const BorderSide(
          color: Color(0xFFFF0000),
          width: 2,
          style: BorderStyle.none,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      );
      expect(encoded, {
        'color': '#FF0000',
        'width': 2.0,
        'style': 'none',
        'strokeAlign': 'center',
      });
      expectJsonSafe(encoded);
    });
  });

  group('borderSideCodec rejects invalid input', () {
    const invalidCases = <String, Object>{
      'invalid color': {'color': 'not-a-color'},
      'negative width': {'width': -1},
      'non-finite width': {'width': double.infinity},
      'invalid style': {'style': 'dotted'},
      'invalid strokeAlign': {'strokeAlign': 'diagonal'},
      'extra property': {'unexpected': true},
    };

    invalidCases.forEach((name, input) {
      test('rejects $name', () {
        expect(borderSideCodec.safeParse(input).isFail, isTrue);
      });
    });
  });
}
