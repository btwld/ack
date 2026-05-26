import 'dart:convert';

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
    test('parses "none" as BorderSide.none', () {
      expect(borderSideCodec.parse('none'), BorderSide.none);
    });

    test('parses an empty object as the default BorderSide', () {
      // Distinct from "none": `{}` falls through to the object branch and
      // produces a default-filled BorderSide (1px solid black), not
      // BorderSide.none (0px style:none).
      expect(borderSideCodec.parse({}), const BorderSide());
      expect(borderSideCodec.parse({}), isNot(BorderSide.none));
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
    test('canonicalizes BorderSide.none to "none"', () {
      final encoded = borderSideCodec.encode(BorderSide.none);
      expect(encoded, 'none');
      expectJsonSafe(encoded);
    });

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
      'unknown string alias': 'thin',
    };

    invalidCases.forEach((name, input) {
      test('rejects $name', () {
        expect(borderSideCodec.safeParse(input).isFail, isTrue);
      });
    });
  });

  group('borderCodec decode', () {
    test('decodes "none" as Border()', () {
      expect(borderCodec.parse('none'), const Border());
    });

    test('decodes a side shorthand as Border.all', () {
      expect(
        borderCodec.parse({'color': '#FF0000', 'width': 2}),
        Border.all(color: const Color(0xFFFF0000), width: 2),
      );
    });

    test('decodes a full per-side object', () {
      final parsed = borderCodec.parse({
        'top': {'color': '#FF0000', 'width': 2},
        'right': {'color': '#00FF00', 'width': 1},
        'bottom': {'color': '#0000FF', 'width': 3},
        'left': 'none',
      });
      expect(
        parsed,
        const Border(
          top: BorderSide(color: Color(0xFFFF0000), width: 2),
          right: BorderSide(color: Color(0xFF00FF00)),
          bottom: BorderSide(color: Color(0xFF0000FF), width: 3),
          left: BorderSide.none,
        ),
      );
    });

    test(
      'decodes a partial per-side object, defaulting omitted sides to none',
      () {
        expect(
          borderCodec.parse({
            'top': {'color': '#FF0000'},
          }),
          const Border(top: BorderSide(color: Color(0xFFFF0000))),
        );
      },
    );

    test('decodes {} via the side branch (NOT Border())', () {
      // Quirk lock-in: empty object falls through borderSideCodec to a default
      // BorderSide (1px solid black), then fan-outs to all four sides. The
      // canonical empty border is `"none"`, not `{}`.
      expect(borderCodec.parse({}), const Border.fromBorderSide(BorderSide()));
      expect(borderCodec.parse({}), isNot(const Border()));
    });
  });

  group('borderCodec encode', () {
    test('canonicalizes Border() to "none"', () {
      final encoded = borderCodec.encode(const Border());
      expect(encoded, 'none');
      expectJsonSafe(encoded);
    });

    test('canonicalizes uniform sides to the side shorthand', () {
      final encoded = borderCodec.encode(
        Border.all(color: const Color(0xFFFF0000), width: 2),
      );
      expect(encoded, {
        'color': '#FF0000',
        'width': 2.0,
        'style': 'solid',
        'strokeAlign': 'inside',
      });
      expectJsonSafe(encoded);
    });

    test('emits the full {top, right, bottom, left} map for mixed sides', () {
      final encoded = borderCodec.encode(
        const Border(
          top: BorderSide(color: Color(0xFFFF0000), width: 2),
          bottom: BorderSide(color: Color(0xFF0000FF), width: 3),
        ),
      );
      expect(encoded, {
        'top': {
          'color': '#FF0000',
          'width': 2.0,
          'style': 'solid',
          'strokeAlign': 'inside',
        },
        'right': 'none',
        'bottom': {
          'color': '#0000FF',
          'width': 3.0,
          'style': 'solid',
          'strokeAlign': 'inside',
        },
        'left': 'none',
      });
      expectJsonSafe(encoded);
    });
  });

  group('borderCodec rejects invalid input', () {
    test('rejects unknown keys', () {
      expect(borderCodec.safeParse({'foo': 1}).isFail, isTrue);
    });

    test('rejects mixed LTR + directional keys', () {
      expect(
        borderCodec.safeParse({
          'top': 'none',
          'right': 'none',
          'start': 'none',
        }).isFail,
        isTrue,
      );
    });
  });

  group('borderDirectionalCodec decode', () {
    test('parses {} as BorderDirectional()', () {
      expect(borderDirectionalCodec.parse({}), const BorderDirectional());
    });

    test('parses a full per-side object with "none" aliases', () {
      final parsed = borderDirectionalCodec.parse({
        'top': 'none',
        'start': {'color': '#FF0000', 'width': 2},
        'end': 'none',
        'bottom': 'none',
      });
      expect(
        parsed,
        const BorderDirectional(
          start: BorderSide(color: Color(0xFFFF0000), width: 2),
        ),
      );
    });

    test('rejects "none" at the top level (no scalar shorthand)', () {
      expect(borderDirectionalCodec.safeParse('none').isFail, isTrue);
    });
  });

  group('borderDirectionalCodec encode', () {
    test('always emits the full object form, never a side shorthand', () {
      final encoded = borderDirectionalCodec.encode(const BorderDirectional());
      expect(encoded, {
        'top': 'none',
        'start': 'none',
        'end': 'none',
        'bottom': 'none',
      });
      expectJsonSafe(encoded);
    });

    test('encodes mixed sides through borderSideCodec', () {
      final encoded = borderDirectionalCodec.encode(
        const BorderDirectional(
          start: BorderSide(color: Color(0xFFFF0000), width: 2),
        ),
      );
      expect(encoded, {
        'top': 'none',
        'start': {
          'color': '#FF0000',
          'width': 2.0,
          'style': 'solid',
          'strokeAlign': 'inside',
        },
        'end': 'none',
        'bottom': 'none',
      });
      expectJsonSafe(encoded);
    });
  });

  group('boxBorderCodec', () {
    test('decodes {top, right, bottom, left} as a Border', () {
      final parsed = boxBorderCodec.parse({
        'top': 'none',
        'right': {'color': '#FF0000'},
        'bottom': 'none',
        'left': 'none',
      });
      expect(parsed, isA<Border>());
      expect(parsed, const Border(right: BorderSide(color: Color(0xFFFF0000))));
    });

    test('decodes {top, start, end, bottom} as a BorderDirectional', () {
      final parsed = boxBorderCodec.parse({
        'top': 'none',
        'start': {'color': '#FF0000'},
        'end': 'none',
        'bottom': 'none',
      });
      expect(parsed, isA<BorderDirectional>());
      expect(
        parsed,
        const BorderDirectional(start: BorderSide(color: Color(0xFFFF0000))),
      );
    });

    test('decodes "none" as Border (LTR wins on shared alias)', () {
      final parsed = boxBorderCodec.parse('none');
      expect(parsed, isA<Border>());
      expect(parsed, const Border());
    });

    test('Border and BorderDirectional encode to their canonical shapes', () {
      final borderEncoded = boxBorderCodec.encode(const Border());
      expect(borderEncoded, 'none');
      expectJsonSafe(borderEncoded);

      final directionalEncoded = boxBorderCodec.encode(
        const BorderDirectional(),
      );
      expect(directionalEncoded, {
        'top': 'none',
        'start': 'none',
        'end': 'none',
        'bottom': 'none',
      });
      expectJsonSafe(directionalEncoded);
    });

    test('rejects mixed LTR + directional keys', () {
      expect(
        boxBorderCodec.safeParse({
          'top': 'none',
          'right': 'none',
          'start': 'none',
          'bottom': 'none',
        }).isFail,
        isTrue,
      );
    });
  });

  group('borderCodec JSON Schema', () {
    test('width non-negativity flows through composition', () {
      // Same pattern as radius_test.dart: ack's NumberSchema.min(0) emits
      // `"minimum": 0`, propagated through borderSideCodec into borderCodec's
      // anyOf composition.
      expect(jsonEncode(borderCodec.toJsonSchema()), contains('"minimum":0'));
    });
  });
}
