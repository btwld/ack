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

  group('starBorderCodec', () {
    test('decodes an empty object as the default StarBorder', () {
      expect(starBorderCodec.parse({}), const StarBorder());
    });

    test('decodes a fully-specified star', () {
      expect(
        starBorderCodec.parse({
          'side': {'color': '#FF0000', 'width': 2},
          'points': 6,
          'innerRadiusRatio': 0.5,
          'pointRounding': 0.1,
          'valleyRounding': 0.2,
          'rotation': 45,
          'squash': 0.3,
        }),
        const StarBorder(
          side: BorderSide(color: Color(0xFFFF0000), width: 2),
          points: 6,
          innerRadiusRatio: 0.5,
          pointRounding: 0.1,
          valleyRounding: 0.2,
          rotation: 45,
          squash: 0.3,
        ),
      );
    });

    test('round-trips a populated StarBorder', () {
      const original = StarBorder(points: 7, innerRadiusRatio: 0.3);
      expect(starBorderCodec.parse(starBorderCodec.encode(original)), original);
    });

    test('encodes StarBorder.polygon as the equivalent regular StarBorder', () {
      final polygon = StarBorder.polygon(sides: 6);
      final encoded = starBorderCodec.encode(polygon)!;
      expect(encoded['points'], 6);
      expect(encoded['valleyRounding'], 0.0);
      // innerRadiusRatio resolves to the polygon incircle (cos(pi/6)).
      expect(encoded['innerRadiusRatio'], closeTo(0.866, 0.001));
    });

    test('rejects fewer than two points', () {
      expect(starBorderCodec.safeParse({'points': 1}).isFail, isTrue);
    });

    test('rejects innerRadiusRatio outside [0, 1]', () {
      expect(
        starBorderCodec.safeParse({'innerRadiusRatio': 1.5}).isFail,
        isTrue,
      );
    });
  });

  group('linearBorderEdgeCodec', () {
    test('decodes an empty object as the default LinearBorderEdge', () {
      expect(linearBorderEdgeCodec.parse({}), const LinearBorderEdge());
    });

    test('round-trips a non-default edge', () {
      const original = LinearBorderEdge(size: 0.5, alignment: -0.25);
      expect(
        linearBorderEdgeCodec.parse(linearBorderEdgeCodec.encode(original)),
        original,
      );
    });

    test('rejects size outside [0, 1]', () {
      expect(linearBorderEdgeCodec.safeParse({'size': 1.5}).isFail, isTrue);
    });

    test('rejects alignment outside [-1, 1]', () {
      expect(
        linearBorderEdgeCodec.safeParse({'alignment': 1.5}).isFail,
        isTrue,
      );
    });
  });

  group('linearBorderCodec', () {
    test('decodes an empty object as the default LinearBorder', () {
      expect(linearBorderCodec.parse({}), const LinearBorder());
    });

    test('decodes a bottom-edge LinearBorder', () {
      expect(
        linearBorderCodec.parse({
          'bottom': {'size': 0.75, 'alignment': 0.5},
        }),
        const LinearBorder(
          bottom: LinearBorderEdge(size: 0.75, alignment: 0.5),
        ),
      );
    });

    test('round-trips a populated LinearBorder', () {
      const original = LinearBorder(
        side: BorderSide(color: Color(0xFFFF0000), width: 2),
        start: LinearBorderEdge(size: 0.5),
        top: LinearBorderEdge(alignment: -1),
      );
      expect(
        linearBorderCodec.parse(linearBorderCodec.encode(original)),
        original,
      );
    });

    test('LinearBorder.start round-trips through the regular constructor', () {
      final original = LinearBorder.start(size: 0.5, alignment: 0.25);
      expect(
        linearBorderCodec.parse(linearBorderCodec.encode(original))!.start,
        original.start,
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
      expect(shapeBorderCodec.parse({'type': 'star'}), const StarBorder());
      expect(shapeBorderCodec.parse({'type': 'linear'}), const LinearBorder());
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
      final star = shapeBorderCodec.encode(const StarBorder());
      expect(star, containsPair('type', 'star'));
      expect(star, containsPair('points', 5));
      final linear = shapeBorderCodec.encode(const LinearBorder());
      expect(linear, containsPair('type', 'linear'));
      expect(linear, containsPair('start', null));
    });

    test('rejects an unknown discriminator', () {
      expect(shapeBorderCodec.safeParse({'type': 'oval'}).isFail, isTrue);
    });

    test('rejects a missing discriminator', () {
      expect(shapeBorderCodec.safeParse({}).isFail, isTrue);
    });

    test('JSON Schema surfaces all eight discriminator branches', () {
      final schema = jsonEncode(shapeBorderCodec.toJsonSchema());
      for (final value in const [
        'circle',
        'stadium',
        'roundedRectangle',
        'beveledRectangle',
        'continuousRectangle',
        'roundedSuperellipse',
        'star',
        'linear',
      ]) {
        expect(schema, contains('"$value"'));
      }
    });
  });
}
