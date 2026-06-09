import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

const _redBlue = [Color(0xFFFF0000), Color(0xFF0000FF)];
const _redBlueHex = ['#FF0000', '#0000FF'];

void main() {
  group('linearGradientCodec decode', () {
    test('parses a minimal input with defaults', () {
      expect(
        linearGradientCodec.parse({'type': 'linear', 'colors': _redBlueHex}),
        const LinearGradient(colors: _redBlue),
      );
    });

    test('parses a full input', () {
      expect(
        linearGradientCodec.parse({
          'type': 'linear',
          'begin': 'topLeft',
          'end': 'bottomRight',
          'colors': _redBlueHex,
          'stops': [0.0, 1.0],
          'tileMode': 'mirror',
        }),
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _redBlue,
          stops: [0.0, 1.0],
          tileMode: TileMode.mirror,
        ),
      );
    });
  });

  group('linearGradientCodec encode', () {
    test('emits a full canonical object with discriminator', () {
      final encoded = linearGradientCodec.encode(
        const LinearGradient(colors: _redBlue),
      );
      expect(encoded, {
        'type': 'linear',
        'begin': 'centerLeft',
        'end': 'centerRight',
        'colors': _redBlueHex,
        'stops': null,
        'tileMode': 'clamp',
      });
      expectJsonSafe(encoded);
    });

    test('encodes stops when provided', () {
      final encoded =
          linearGradientCodec.encode(
                const LinearGradient(colors: _redBlue, stops: [0.0, 1.0]),
              )
              as Map;
      expect(encoded['stops'], [0.0, 1.0]);
      expectJsonSafe(encoded);
    });
  });

  group('linearGradientCodec rejects invalid input', () {
    const invalidCases = <String, Object>{
      'wrong discriminator': {'type': 'radial', 'colors': _redBlueHex},
      'single-color list': {
        'type': 'linear',
        'colors': ['#FF0000'],
      },
      'missing colors': {'type': 'linear'},
      'extra property': {'type': 'linear', 'colors': _redBlueHex, 'foo': 1},
    };

    invalidCases.forEach((name, input) {
      test('rejects $name', () {
        expect(linearGradientCodec.safeParse(input).isFail, isTrue);
      });
    });
  });

  group('radialGradientCodec decode', () {
    test('parses a minimal input with defaults', () {
      expect(
        radialGradientCodec.parse({'type': 'radial', 'colors': _redBlueHex}),
        const RadialGradient(colors: _redBlue),
      );
    });

    test('parses focal and focalRadius', () {
      expect(
        radialGradientCodec.parse({
          'type': 'radial',
          'colors': _redBlueHex,
          'focal': 'topLeft',
          'focalRadius': 0.25,
        }),
        const RadialGradient(
          colors: _redBlue,
          focal: Alignment.topLeft,
          focalRadius: 0.25,
        ),
      );
    });
  });

  group('radialGradientCodec encode', () {
    test('emits null optional fields (stops, focal) explicitly', () {
      final encoded = radialGradientCodec.encode(
        const RadialGradient(colors: _redBlue),
      );
      expect(encoded, {
        'type': 'radial',
        'center': 'center',
        'radius': 0.5,
        'colors': _redBlueHex,
        'stops': null,
        'tileMode': 'clamp',
        'focal': null,
        'focalRadius': 0.0,
      });
      expectJsonSafe(encoded);
    });

    test('round-trips focal when present', () {
      const original = RadialGradient(
        colors: _redBlue,
        focal: Alignment.topLeft,
        focalRadius: 0.25,
      );
      final encoded = radialGradientCodec.encode(original) as Map;
      expect(encoded['focal'], 'topLeft');
      expect(radialGradientCodec.parse(encoded), original);
      expectJsonSafe(encoded);
    });
  });

  group('radialGradientCodec rejects invalid input', () {
    test('rejects negative radius', () {
      expect(
        radialGradientCodec.safeParse({
          'type': 'radial',
          'colors': _redBlueHex,
          'radius': -1,
        }).isFail,
        isTrue,
      );
    });

    test('rejects negative focalRadius', () {
      expect(
        radialGradientCodec.safeParse({
          'type': 'radial',
          'colors': _redBlueHex,
          'focalRadius': -0.1,
        }).isFail,
        isTrue,
      );
    });
  });

  group('sweepGradientCodec decode', () {
    test('parses a minimal input with defaults', () {
      expect(
        sweepGradientCodec.parse({'type': 'sweep', 'colors': _redBlueHex}),
        const SweepGradient(colors: _redBlue),
      );
    });

    test('parses startAngle/endAngle', () {
      expect(
        sweepGradientCodec.parse({
          'type': 'sweep',
          'colors': _redBlueHex,
          'startAngle': 1.0,
          'endAngle': 2.0,
        }),
        const SweepGradient(colors: _redBlue, startAngle: 1, endAngle: 2),
      );
    });
  });

  group('sweepGradientCodec encode', () {
    test('default endAngle is math.pi * 2', () {
      final encoded =
          sweepGradientCodec.encode(const SweepGradient(colors: _redBlue))
              as Map;
      expect(encoded['startAngle'], 0.0);
      expect(encoded['endAngle'], closeTo(math.pi * 2, 1e-9));
      expect(encoded['type'], 'sweep');
      expectJsonSafe(encoded);
    });
  });

  group('gradientCodec', () {
    test('parses {type: linear, ...} as a LinearGradient', () {
      final parsed = gradientCodec.parse({
        'type': 'linear',
        'colors': _redBlueHex,
      });
      expect(parsed, isA<LinearGradient>());
      expect(parsed, const LinearGradient(colors: _redBlue));
    });

    test('parses {type: radial, ...} as a RadialGradient', () {
      final parsed = gradientCodec.parse({
        'type': 'radial',
        'colors': _redBlueHex,
      });
      expect(parsed, isA<RadialGradient>());
      expect(parsed, const RadialGradient(colors: _redBlue));
    });

    test('parses {type: sweep, ...} as a SweepGradient', () {
      final parsed = gradientCodec.parse({
        'type': 'sweep',
        'colors': _redBlueHex,
      });
      expect(parsed, isA<SweepGradient>());
      expect(parsed, const SweepGradient(colors: _redBlue));
    });

    test('rejects an unknown discriminator', () {
      expect(
        gradientCodec.safeParse({
          'type': 'spiral',
          'colors': _redBlueHex,
        }).isFail,
        isTrue,
      );
    });

    test('rejects a missing discriminator', () {
      expect(gradientCodec.safeParse({'colors': _redBlueHex}).isFail, isTrue);
    });

    test('encode dispatches by runtime type', () {
      final linear =
          gradientCodec.encode(const LinearGradient(colors: _redBlue)) as Map;
      expect(linear['type'], 'linear');

      final radial =
          gradientCodec.encode(const RadialGradient(colors: _redBlue)) as Map;
      expect(radial['type'], 'radial');

      final sweep =
          gradientCodec.encode(const SweepGradient(colors: _redBlue)) as Map;
      expect(sweep['type'], 'sweep');

      expectJsonSafe(linear);
      expectJsonSafe(radial);
      expectJsonSafe(sweep);
    });
  });

  group('gradientCodec JSON Schema', () {
    test('discriminator branches and numeric constraints flow through', () {
      final schema = jsonEncode(gradientCodec.toJsonSchema());
      // Each branch's Ack.literal still emits "const":"<value>" in the inner
      // object schema.
      expect(schema, contains('"const":"linear"'));
      expect(schema, contains('"const":"radial"'));
      expect(schema, contains('"const":"sweep"'));
      // radius / focalRadius non-negativity propagates from Ack.number().min(0).
      expect(schema, contains('"minimum":0'));
    });
  });

  group('gradient transform is rejected on encode', () {
    final transform = GradientRotation(math.pi / 4);

    test('linearGradientCodec fails on a transformed gradient', () {
      final gradient = LinearGradient(colors: _redBlue, transform: transform);
      expect(linearGradientCodec.safeEncode(gradient).isFail, isTrue);
    });

    test('radialGradientCodec fails on a transformed gradient', () {
      final gradient = RadialGradient(colors: _redBlue, transform: transform);
      expect(radialGradientCodec.safeEncode(gradient).isFail, isTrue);
    });

    test('sweepGradientCodec fails on a transformed gradient', () {
      final gradient = SweepGradient(colors: _redBlue, transform: transform);
      expect(sweepGradientCodec.safeEncode(gradient).isFail, isTrue);
    });

    test('gradientCodec fails on a transformed gradient', () {
      final gradient = LinearGradient(colors: _redBlue, transform: transform);
      expect(gradientCodec.safeEncode(gradient).isFail, isTrue);
    });
  });
}
