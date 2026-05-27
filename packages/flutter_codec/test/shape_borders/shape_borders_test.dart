import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('circleBorderCodec', () {
    test('decodes an empty object as the default CircleBorder', () {
      expect(circleBorderCodec.parse({}), const CircleBorder());
    });

    test('decodes side and eccentricity', () {
      expect(
        circleBorderCodec.parse({
          'side': {'color': '#FF0000', 'width': 2},
          'eccentricity': 0.5,
        }),
        CircleBorder(
          side: const BorderSide(color: Color(0xFFFF0000), width: 2),
          eccentricity: 0.5,
        ),
      );
    });

    test('encode emits the canonical map with both fields', () {
      final encoded = circleBorderCodec.encode(const CircleBorder());
      expect(encoded, {'side': 'none', 'eccentricity': 0.0});
      expectJsonSafe(encoded);
    });

    test('rejects eccentricity outside [0, 1]', () {
      expect(circleBorderCodec.safeParse({'eccentricity': 1.5}).isFail, isTrue);
      expect(
        circleBorderCodec.safeParse({'eccentricity': -0.1}).isFail,
        isTrue,
      );
    });
  });

  group('stadiumBorderCodec', () {
    test('decodes an empty object as the default StadiumBorder', () {
      expect(stadiumBorderCodec.parse({}), const StadiumBorder());
    });

    test('round-trips a sided StadiumBorder', () {
      final original = const StadiumBorder(
        side: BorderSide(color: Color(0xFFFF0000), width: 3),
      );
      expect(
        stadiumBorderCodec.parse(stadiumBorderCodec.encode(original)),
        original,
      );
    });
  });

  group('roundedRectangleBorderCodec', () {
    test('decodes an empty object as the default RoundedRectangleBorder', () {
      expect(
        roundedRectangleBorderCodec.parse({}),
        const RoundedRectangleBorder(),
      );
    });

    test('round-trips side and borderRadius', () {
      final original = RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFFF0000), width: 2),
        borderRadius: BorderRadius.circular(12),
      );
      expect(
        roundedRectangleBorderCodec.parse(
          roundedRectangleBorderCodec.encode(original),
        ),
        original,
      );
    });
  });

  group('beveledRectangleBorderCodec / continuousRectangleBorderCodec / '
      'roundedSuperellipseBorderCodec', () {
    test('each decodes its empty default and round-trips', () {
      expect(
        beveledRectangleBorderCodec.parse({}),
        const BeveledRectangleBorder(),
      );
      expect(
        continuousRectangleBorderCodec.parse({}),
        const ContinuousRectangleBorder(),
      );
      expect(
        roundedSuperellipseBorderCodec.parse({}),
        const RoundedSuperellipseBorder(),
      );

      final beveled = BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      );
      expect(
        beveledRectangleBorderCodec.parse(
          beveledRectangleBorderCodec.encode(beveled),
        ),
        beveled,
      );

      final continuous = ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      );
      expect(
        continuousRectangleBorderCodec.parse(
          continuousRectangleBorderCodec.encode(continuous),
        ),
        continuous,
      );

      final superellipse = RoundedSuperellipseBorder(
        side: const BorderSide(color: Color(0xFFFF0000), width: 2),
        borderRadius: BorderRadius.circular(8),
      );
      expect(
        roundedSuperellipseBorderCodec.parse(
          roundedSuperellipseBorderCodec.encode(superellipse),
        ),
        superellipse,
      );
    });
  });

  group('shapeBorderCodec', () {
    test('decodes each discriminator value to the matching ShapeBorder', () {
      expect(shapeBorderCodec.parse({'type': 'circle'}), const CircleBorder());
      expect(
        shapeBorderCodec.parse({'type': 'stadium'}),
        const StadiumBorder(),
      );
      expect(
        shapeBorderCodec.parse({'type': 'roundedRectangle'}),
        const RoundedRectangleBorder(),
      );
      expect(
        shapeBorderCodec.parse({'type': 'beveledRectangle'}),
        const BeveledRectangleBorder(),
      );
      expect(
        shapeBorderCodec.parse({'type': 'continuousRectangle'}),
        const ContinuousRectangleBorder(),
      );
      expect(
        shapeBorderCodec.parse({'type': 'roundedSuperellipse'}),
        const RoundedSuperellipseBorder(),
      );
    });

    test('encode dispatches by runtime ShapeBorder subtype', () {
      expect(shapeBorderCodec.encode(const CircleBorder()), {
        'type': 'circle',
        'side': 'none',
        'eccentricity': 0.0,
      });
      expect(shapeBorderCodec.encode(const StadiumBorder()), {
        'type': 'stadium',
        'side': 'none',
      });
      final rounded = shapeBorderCodec.encode(const RoundedRectangleBorder());
      expect(rounded, containsPair('type', 'roundedRectangle'));
      expect(rounded, containsPair('side', 'none'));
      final superellipse = shapeBorderCodec.encode(
        const RoundedSuperellipseBorder(),
      );
      expect(superellipse, containsPair('type', 'roundedSuperellipse'));
      expect(superellipse, containsPair('side', 'none'));
    });

    test('rejects an unknown discriminator', () {
      expect(shapeBorderCodec.safeParse({'type': 'oval'}).isFail, isTrue);
    });

    test('rejects a missing discriminator', () {
      expect(shapeBorderCodec.safeParse({}).isFail, isTrue);
    });

    test('JSON Schema surfaces all six discriminator branches', () {
      final schema = jsonEncode(shapeBorderCodec.toJsonSchema());
      for (final value in const [
        'circle',
        'stadium',
        'roundedRectangle',
        'beveledRectangle',
        'continuousRectangle',
        'roundedSuperellipse',
      ]) {
        expect(schema, contains('"$value"'));
      }
    });
  });
}
