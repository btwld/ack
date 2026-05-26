import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('borderRadiusCodec decode', () {
    test('decodes a number as all circular corners', () {
      expect(borderRadiusCodec.parse(8), BorderRadius.circular(8));
    });

    test('decodes {x, y} as all elliptical corners', () {
      expect(
        borderRadiusCodec.parse({'x': 8, 'y': 4}),
        BorderRadius.all(const Radius.elliptical(8, 4)),
      );
    });

    test('decodes a full per-corner object', () {
      expect(
        borderRadiusCodec.parse({
          'topLeft': 1,
          'topRight': 2,
          'bottomLeft': 3,
          'bottomRight': 4,
        }),
        const BorderRadius.only(
          topLeft: Radius.circular(1),
          topRight: Radius.circular(2),
          bottomLeft: Radius.circular(3),
          bottomRight: Radius.circular(4),
        ),
      );
    });

    test('applies per-corner defaults to a partial object', () {
      expect(
        borderRadiusCodec.parse({'topLeft': 8}),
        const BorderRadius.only(topLeft: Radius.circular(8)),
      );
    });

    test('decodes an empty object as BorderRadius.zero', () {
      expect(borderRadiusCodec.parse({}), BorderRadius.zero);
    });
  });

  group('borderRadiusCodec encode', () {
    test('collapses uniform circular corners to a number', () {
      final encoded = borderRadiusCodec.encode(BorderRadius.circular(8));
      expect(encoded, 8.0);
      expectJsonSafe(encoded);
    });

    test('collapses uniform elliptical corners to {x, y}', () {
      final encoded = borderRadiusCodec.encode(
        BorderRadius.all(const Radius.elliptical(8, 4)),
      );
      expect(encoded, {'x': 8.0, 'y': 4.0});
      expectJsonSafe(encoded);
    });

    test('emits the full corner object when corners differ', () {
      final encoded = borderRadiusCodec.encode(
        const BorderRadius.only(topLeft: Radius.circular(8)),
      );
      expect(encoded, {
        'topLeft': 8.0,
        'topRight': 0.0,
        'bottomLeft': 0.0,
        'bottomRight': 0.0,
      });
      expectJsonSafe(encoded);
    });
  });

  group('borderRadiusCodec rejects invalid input', () {
    const invalidCases = <String, Object>{
      'directional shape': {
        'topStart': 8,
        'topEnd': 0,
        'bottomStart': 0,
        'bottomEnd': 0,
      },
      'unknown key': {'topLeft': 8, 'z': 1},
      'negative corner': {'topLeft': -1},
      'non-finite corner': {'topLeft': double.infinity},
    };

    invalidCases.forEach((name, input) {
      test('rejects $name', () {
        expect(borderRadiusCodec.safeParse(input).isFail, isTrue);
      });
    });
  });

  group('borderRadiusDirectionalCodec', () {
    test('decodes a full per-corner object', () {
      expect(
        borderRadiusDirectionalCodec.parse({
          'topStart': 1,
          'topEnd': 2,
          'bottomStart': 3,
          'bottomEnd': 4,
        }),
        const BorderRadiusDirectional.only(
          topStart: Radius.circular(1),
          topEnd: Radius.circular(2),
          bottomStart: Radius.circular(3),
          bottomEnd: Radius.circular(4),
        ),
      );
    });

    test('applies per-corner defaults to a partial object', () {
      expect(
        borderRadiusDirectionalCodec.parse({'topStart': 8}),
        const BorderRadiusDirectional.only(topStart: Radius.circular(8)),
      );
    });

    test('decodes an empty object as BorderRadiusDirectional.zero', () {
      expect(
        borderRadiusDirectionalCodec.parse({}),
        BorderRadiusDirectional.zero,
      );
    });

    test('always encodes to the full object, even when uniform', () {
      final encoded = borderRadiusDirectionalCodec.encode(
        BorderRadiusDirectional.all(const Radius.circular(8)),
      );
      expect(encoded, {
        'topStart': 8.0,
        'topEnd': 8.0,
        'bottomStart': 8.0,
        'bottomEnd': 8.0,
      });
      expectJsonSafe(encoded);
    });

    group('rejects invalid input', () {
      const invalidCases = <String, Object>{
        'a scalar': 8,
        'non-directional shape': {
          'topLeft': 8,
          'topRight': 0,
          'bottomLeft': 0,
          'bottomRight': 0,
        },
      };

      invalidCases.forEach((name, input) {
        test('rejects $name', () {
          expect(borderRadiusDirectionalCodec.safeParse(input).isFail, isTrue);
        });
      });
    });
  });

  group('borderRadiusGeometryCodec', () {
    test('decodes shorthand / {topLeft,...} / {} to BorderRadius', () {
      expect(borderRadiusGeometryCodec.parse(8), isA<BorderRadius>());
      expect(borderRadiusGeometryCodec.parse(8), BorderRadius.circular(8));

      final fromObject = borderRadiusGeometryCodec.parse({'topLeft': 8});
      expect(fromObject, isA<BorderRadius>());
      expect(fromObject, const BorderRadius.only(topLeft: Radius.circular(8)));

      expect(borderRadiusGeometryCodec.parse({}), isA<BorderRadius>());
    });

    test('decodes {topStart,...} to BorderRadiusDirectional', () {
      final value = borderRadiusGeometryCodec.parse({'topStart': 8});
      expect(value, isA<BorderRadiusDirectional>());
      expect(
        value,
        const BorderRadiusDirectional.only(topStart: Radius.circular(8)),
      );
    });

    test('encodes BorderRadius back to shorthand/object', () {
      expect(borderRadiusGeometryCodec.encode(BorderRadius.circular(8)), 8.0);
      final encoded = borderRadiusGeometryCodec.encode(
        const BorderRadius.only(topLeft: Radius.circular(8)),
      );
      expect(encoded, {
        'topLeft': 8.0,
        'topRight': 0.0,
        'bottomLeft': 0.0,
        'bottomRight': 0.0,
      });
      expectJsonSafe(encoded);
    });

    test('directional round-trips as BorderRadiusDirectional', () {
      final encoded = borderRadiusGeometryCodec.encode(
        BorderRadiusDirectional.all(const Radius.circular(8)),
      );
      expect(encoded, {
        'topStart': 8.0,
        'topEnd': 8.0,
        'bottomStart': 8.0,
        'bottomEnd': 8.0,
      });
      expect(
        borderRadiusGeometryCodec.parse(encoded),
        isA<BorderRadiusDirectional>(),
      );
    });

    group('rejects invalid input', () {
      const invalidCases = <String, Object>{
        'mixed keys': {'topLeft': 8, 'topStart': 8},
        'unknown key': {'z': 1},
      };

      invalidCases.forEach((name, input) {
        test('rejects $name', () {
          expect(borderRadiusGeometryCodec.safeParse(input).isFail, isTrue);
        });
      });
    });
  });
}
