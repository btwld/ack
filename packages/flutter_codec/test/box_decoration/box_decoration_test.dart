import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

const _redBlueHex = ['#FF0000', '#0000FF'];
const _redBlue = [Color(0xFFFF0000), Color(0xFF0000FF)];

void main() {
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
}
