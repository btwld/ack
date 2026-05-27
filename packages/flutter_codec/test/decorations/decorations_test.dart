import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

const _redBlueHex = ['#FF0000', '#0000FF'];
const _redBlue = [Color(0xFFFF0000), Color(0xFF0000FF)];

void main() {
  // --- boxDecorationCodec ----------------------------------------------------

  group('boxDecorationCodec decode', () {
    test('decodes an empty object as the default BoxDecoration', () {
      expect(boxDecorationCodec.parse({}), const BoxDecoration());
    });

    test('decodes a full real-world BoxDecoration without image', () {
      expect(
        boxDecorationCodec.parse({
          'color': '#2196F3',
          'border': {'color': '#FF0000', 'width': 2},
          'borderRadius': 8,
          'boxShadow': [
            {
              'color': '#55000000',
              'offset': {'x': 1, 'y': 2},
              'blurRadius': 3,
              'spreadRadius': 4,
              'blurStyle': 'outer',
            },
          ],
          'gradient': {
            'type': 'linear',
            'begin': 'topLeft',
            'end': 'bottomRight',
            'colors': _redBlueHex,
            'stops': [0, 1],
            'tileMode': 'mirror',
          },
          'backgroundBlendMode': 'multiply',
          'shape': 'circle',
        }),
        BoxDecoration(
          color: const Color(0xFF2196F3),
          border: Border.all(color: const Color(0xFFFF0000), width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              offset: Offset(1, 2),
              blurRadius: 3,
              spreadRadius: 4,
              blurStyle: BlurStyle.outer,
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _redBlue,
            stops: [0, 1],
            tileMode: TileMode.mirror,
          ),
          backgroundBlendMode: BlendMode.multiply,
          shape: BoxShape.circle,
        ),
      );
    });

    test('decodes partial inputs', () {
      expect(
        boxDecorationCodec.parse({'color': '#00FF00'}),
        const BoxDecoration(color: Color(0xFF00FF00)),
      );
      expect(
        boxDecorationCodec.parse({'shape': 'circle'}),
        const BoxDecoration(shape: BoxShape.circle),
      );
    });
  });

  group('boxDecorationCodec encode', () {
    test('emits a full canonical map with explicit nulls for defaults', () {
      final encoded = boxDecorationCodec.encode(const BoxDecoration());

      expect(encoded, {
        'color': null,
        'image': null,
        'border': null,
        'borderRadius': null,
        'boxShadow': null,
        'gradient': null,
        'backgroundBlendMode': null,
        'shape': 'rectangle',
      });
      expectJsonSafe(encoded);
    });

    test('round-trips a full BoxDecoration without image', () {
      final original = BoxDecoration(
        color: const Color(0xFF2196F3),
        border: Border.all(color: const Color(0xFFFF0000), width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            offset: Offset(1, 2),
            blurRadius: 3,
            spreadRadius: 4,
            blurStyle: BlurStyle.outer,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _redBlue,
          stops: [0, 1],
          tileMode: TileMode.mirror,
        ),
        backgroundBlendMode: BlendMode.multiply,
      );

      final encoded = boxDecorationCodec.encode(original);

      expect(boxDecorationCodec.parse(encoded), original);
      expectJsonSafe(encoded);
    });
  });

  group('boxDecorationCodec image integration', () {
    test('decodes an image field via decorationImageCodec', () {
      final parsed = boxDecorationCodec.parse({
        'image': {
          'image': {'type': 'network', 'url': 'https://example.com/foo.png'},
          'fit': 'cover',
        },
      });
      expect(parsed!.image, isA<DecorationImage>());
      expect(parsed.image!.image, isA<NetworkImage>());
      expect(parsed.image!.fit, BoxFit.cover);
    });

    test('accepts an explicit null image', () {
      expect(boxDecorationCodec.parse({'image': null}), const BoxDecoration());
    });

    test('round-trips a BoxDecoration with an image', () {
      final original = BoxDecoration(
        image: DecorationImage(
          image: const NetworkImage('https://example.com/foo.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topLeft,
        ),
      );

      final encoded = boxDecorationCodec.encode(original);
      expect(boxDecorationCodec.parse(encoded), original);
      expectJsonSafe(encoded);
    });
  });

  group('boxDecorationCodec rejects invalid input', () {
    const invalidCases = <String, Object>{
      'unknown keys': {'foo': 1},
      'invalid color': {'color': 'not-a-color'},
      'mismatched border keys': {
        'border': {'top': 'none', 'right': 'none', 'start': 'none'},
      },
      'invalid gradient discriminator': {
        'gradient': {'type': 'spiral', 'colors': _redBlueHex},
      },
      'invalid nested image provider': {
        'image': {
          'image': {'type': 'spiral', 'url': 'https://example.com/x.png'},
        },
      },
    };

    invalidCases.forEach((name, input) {
      test('rejects $name', () {
        expect(boxDecorationCodec.safeParse(input).isFail, isTrue);
      });
    });
  });

  group('boxDecorationCodec JSON Schema', () {
    test('dependent codec schemas flow through composition', () {
      final schema = jsonEncode(boxDecorationCodec.toJsonSchema());

      expect(schema, contains('"circle"'));
      expect(schema, contains('"const":"linear"'));
      expect(schema, contains(r'^#[0-9A-Fa-f]{6}$'));
    });
  });

  // --- shapeDecorationCodec --------------------------------------------------

  group('shapeDecorationCodec decode', () {
    test('decodes a minimal ShapeDecoration with just a shape', () {
      expect(
        shapeDecorationCodec.parse({
          'shape': {'type': 'circle'},
        }),
        const ShapeDecoration(shape: CircleBorder()),
      );
    });

    test('decodes a full ShapeDecoration', () {
      // ShapeDecoration asserts color XOR gradient — exercise the gradient
      // branch here; color-only is exercised by the encode round-trip below.
      final decoded = shapeDecorationCodec.parse({
        'gradient': {'type': 'linear', 'colors': _redBlueHex},
        'shadows': [
          {
            'color': '#55000000',
            'offset': {'x': 1, 'y': 2},
            'blurRadius': 3,
          },
        ],
        'shape': {'type': 'roundedRectangle', 'borderRadius': 8},
      });

      expect(
        decoded,
        ShapeDecoration(
          gradient: const LinearGradient(colors: _redBlue),
          shadows: const [
            BoxShadow(
              color: Color(0x55000000),
              offset: Offset(1, 2),
              blurRadius: 3,
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  });

  group('shapeDecorationCodec encode', () {
    test('emits a canonical map with explicit nulls for unset fields', () {
      final encoded = shapeDecorationCodec.encode(
        const ShapeDecoration(shape: CircleBorder()),
      );

      expect(encoded, {
        'color': null,
        'image': null,
        'gradient': null,
        'shadows': null,
        // Nested codecs re-encode to JSON, so the shape arrives as its
        // canonical map form (including the discriminator), not as the
        // runtime CircleBorder instance.
        'shape': {'type': 'circle', 'side': 'none', 'eccentricity': 0.0},
      });
      expectJsonSafe(encoded);
    });

    test('round-trips a populated ShapeDecoration', () {
      final original = ShapeDecoration(
        color: const Color(0xFF2196F3),
        shadows: const [
          BoxShadow(
            color: Color(0x55000000),
            offset: Offset(1, 2),
            blurRadius: 3,
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );

      final encoded = shapeDecorationCodec.encode(original);
      expect(shapeDecorationCodec.parse(encoded), original);
      expectJsonSafe(encoded);
    });
  });

  group('shapeDecorationCodec rejects invalid input', () {
    test('rejects a missing required shape', () {
      expect(shapeDecorationCodec.safeParse({}).isFail, isTrue);
    });

    test('rejects an unknown shape discriminator', () {
      expect(
        shapeDecorationCodec.safeParse({
          'shape': {'type': 'oval'},
        }).isFail,
        isTrue,
      );
    });

    test('rejects unknown keys', () {
      expect(
        shapeDecorationCodec.safeParse({
          'shape': {'type': 'circle'},
          'foo': true,
        }).isFail,
        isTrue,
      );
    });
  });

  // --- decorationCodec (union) ----------------------------------------------

  group('decorationCodec decode', () {
    test('parses {type: box, ...} as a BoxDecoration', () {
      final decoded = decorationCodec.parse({
        'type': 'box',
        'color': '#2196F3',
      });
      expect(decoded, isA<BoxDecoration>());
      expect((decoded as BoxDecoration).color, const Color(0xFF2196F3));
    });

    test('parses {type: shape, ...} as a ShapeDecoration', () {
      final decoded = decorationCodec.parse({
        'type': 'shape',
        'shape': {'type': 'circle'},
      });
      expect(decoded, isA<ShapeDecoration>());
      expect((decoded as ShapeDecoration).shape, const CircleBorder());
    });
  });

  group('decorationCodec encode', () {
    test('emits {type: box, ...} for a BoxDecoration', () {
      final encoded =
          decorationCodec.encode(const BoxDecoration()) as Map<String, Object?>;
      expect(encoded['type'], 'box');
      expect(encoded.containsKey('color'), isTrue);
      expect(encoded.containsKey('shape'), isTrue);
      expectJsonSafe(encoded);
    });

    test('emits {type: shape, ...} for a ShapeDecoration', () {
      final encoded =
          decorationCodec.encode(const ShapeDecoration(shape: CircleBorder()))
              as Map<String, Object?>;
      expect(encoded['type'], 'shape');
      expect(encoded['shape'], {
        'type': 'circle',
        'side': 'none',
        'eccentricity': 0.0,
      });
      expectJsonSafe(encoded);
    });

    test('round-trips a BoxDecoration through the union', () {
      final original = const BoxDecoration(
        color: Color(0xFF2196F3),
        shape: BoxShape.circle,
      );
      expect(decorationCodec.parse(decorationCodec.encode(original)), original);
    });

    test('round-trips a ShapeDecoration through the union', () {
      final original = ShapeDecoration(
        color: const Color(0xFF2196F3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
      expect(decorationCodec.parse(decorationCodec.encode(original)), original);
    });
  });

  group('decorationCodec rejects invalid input', () {
    test('rejects an unknown discriminator', () {
      expect(
        decorationCodec.safeParse({'type': 'flutter-logo'}).isFail,
        isTrue,
      );
    });

    test('rejects a missing discriminator', () {
      expect(decorationCodec.safeParse({}).isFail, isTrue);
    });
  });

  group('decorationCodec JSON Schema', () {
    test('surfaces both discriminator branches', () {
      final schema = jsonEncode(decorationCodec.toJsonSchema());
      expect(schema, contains('"box"'));
      expect(schema, contains('"shape"'));
    });
  });
}
