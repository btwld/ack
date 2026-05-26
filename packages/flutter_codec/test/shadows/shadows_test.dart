import 'dart:ui' as ui show Shadow;

import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('shadowCodec decode', () {
    test('parses {} as the default ui.Shadow', () {
      expect(shadowCodec.parse({}), const ui.Shadow());
    });

    test('applies defaults to a partial object', () {
      expect(
        shadowCodec.parse({'color': '#FF0000'}),
        const ui.Shadow(color: Color(0xFFFF0000)),
      );
    });

    test('parses a full object', () {
      expect(
        shadowCodec.parse({
          'color': '#FF0000',
          'offset': {'x': 2, 'y': 4},
          'blurRadius': 6,
        }),
        const ui.Shadow(
          color: Color(0xFFFF0000),
          offset: Offset(2, 4),
          blurRadius: 6,
        ),
      );
    });
  });

  group('shadowCodec encode', () {
    test('emits a full canonical object including defaults', () {
      final encoded = shadowCodec.encode(const ui.Shadow());
      expect(encoded, {
        'color': '#000000',
        'offset': {'x': 0.0, 'y': 0.0},
        'blurRadius': 0.0,
      });
      expectJsonSafe(encoded);
    });

    test('encodes a customized Shadow', () {
      final encoded = shadowCodec.encode(
        const ui.Shadow(
          color: Color(0xFFFF0000),
          offset: Offset(2, 4),
          blurRadius: 6,
        ),
      );
      expect(encoded, {
        'color': '#FF0000',
        'offset': {'x': 2.0, 'y': 4.0},
        'blurRadius': 6.0,
      });
      expectJsonSafe(encoded);
    });
  });

  group('shadowCodec rejects invalid input', () {
    const invalidCases = <String, Object>{
      'negative blurRadius': {'blurRadius': -1},
      'non-finite blurRadius': {'blurRadius': double.infinity},
      'invalid color': {'color': 'not-a-color'},
      'extra property': {'unexpected': true},
    };

    invalidCases.forEach((name, input) {
      test('rejects $name', () {
        expect(shadowCodec.safeParse(input).isFail, isTrue);
      });
    });
  });

  group('boxShadowCodec decode', () {
    test('parses {} as the default BoxShadow', () {
      expect(boxShadowCodec.parse({}), const BoxShadow());
    });

    test('parses a full object including spreadRadius + blurStyle', () {
      expect(
        boxShadowCodec.parse({
          'color': '#FF0000',
          'offset': {'x': 2, 'y': 4},
          'blurRadius': 6,
          'spreadRadius': 1,
          'blurStyle': 'outer',
        }),
        const BoxShadow(
          color: Color(0xFFFF0000),
          offset: Offset(2, 4),
          blurRadius: 6,
          spreadRadius: 1,
          blurStyle: BlurStyle.outer,
        ),
      );
    });

    test('accepts negative spreadRadius (Flutter allows shrinking)', () {
      expect(
        boxShadowCodec.parse({'spreadRadius': -2}),
        const BoxShadow(spreadRadius: -2),
      );
    });
  });

  group('boxShadowCodec encode', () {
    test('emits a full canonical object including defaults', () {
      final encoded = boxShadowCodec.encode(const BoxShadow());
      expect(encoded, {
        'color': '#000000',
        'offset': {'x': 0.0, 'y': 0.0},
        'blurRadius': 0.0,
        'spreadRadius': 0.0,
        'blurStyle': 'normal',
      });
      expectJsonSafe(encoded);
    });

    test('encodes a customized BoxShadow', () {
      final encoded = boxShadowCodec.encode(
        const BoxShadow(
          color: Color(0xFFFF0000),
          offset: Offset(2, 4),
          blurRadius: 6,
          spreadRadius: 1,
          blurStyle: BlurStyle.outer,
        ),
      );
      expect(encoded, {
        'color': '#FF0000',
        'offset': {'x': 2.0, 'y': 4.0},
        'blurRadius': 6.0,
        'spreadRadius': 1.0,
        'blurStyle': 'outer',
      });
      expectJsonSafe(encoded);
    });
  });

  group('boxShadowCodec rejects invalid input', () {
    const invalidCases = <String, Object>{
      'negative blurRadius': {'blurRadius': -1},
      'invalid blurStyle': {'blurStyle': 'fuzzy'},
      'extra property': {'unexpected': true},
    };

    invalidCases.forEach((name, input) {
      test('rejects $name', () {
        expect(boxShadowCodec.safeParse(input).isFail, isTrue);
      });
    });
  });
}
