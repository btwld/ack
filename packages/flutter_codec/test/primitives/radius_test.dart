import 'dart:ui';

import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('radiusCodec decode', () {
    test('decodes a number as a circular radius', () {
      expect(radiusCodec.parse(8), const Radius.circular(8));
    });

    test('decodes x and y as an elliptical radius', () {
      expect(
        radiusCodec.parse({'x': 8, 'y': 12.5}),
        const Radius.elliptical(8, 12.5),
      );
    });
  });

  group('radiusCodec encode', () {
    test('canonicalizes circular radii to a number', () {
      final encoded = radiusCodec.encode(const Radius.circular(8));
      expect(encoded, 8.0);
      expectJsonSafe(encoded);
    });

    test('encodes elliptical radii as x and y', () {
      final encoded = radiusCodec.encode(const Radius.elliptical(8, 12.5));
      expect(encoded, {'x': 8.0, 'y': 12.5});
      expectJsonSafe(encoded);
    });
  });

  group('radiusCodec rejects invalid input', () {
    test('rejects negative circular radii', () {
      expect(radiusCodec.safeParse(-1).isFail, isTrue);
    });

    test('rejects negative elliptical coordinates', () {
      expect(radiusCodec.safeParse({'x': 1, 'y': -1}).isFail, isTrue);
    });

    test('rejects non-finite radii', () {
      expect(radiusCodec.safeParse(double.infinity).isFail, isTrue);
      expect(
        radiusCodec.safeParse({'x': double.infinity, 'y': 1}).isFail,
        isTrue,
      );
    });
  });
}
