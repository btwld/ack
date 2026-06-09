import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('edgeInsetsCodec decode', () {
    test('decodes a number as all sides', () {
      expect(edgeInsetsCodec.parse(16), const EdgeInsets.all(16));
    });

    test('decodes a full {left, top, right, bottom} object', () {
      expect(
        edgeInsetsCodec.parse({'left': 1, 'top': 2, 'right': 3, 'bottom': 4}),
        const EdgeInsets.fromLTRB(1, 2, 3, 4),
      );
    });

    test('applies per-side defaults to a partial object', () {
      expect(
        edgeInsetsCodec.parse({'left': 8}),
        const EdgeInsets.only(left: 8),
      );
    });

    test('decodes an empty object as EdgeInsets.zero', () {
      expect(edgeInsetsCodec.parse({}), EdgeInsets.zero);
    });
  });

  group('edgeInsetsCodec encode', () {
    test('collapses a uniform inset to a scalar', () {
      final encoded = edgeInsetsCodec.encode(const EdgeInsets.all(16));
      expect(encoded, 16.0);
      expectJsonSafe(encoded);
    });

    test('encodes EdgeInsets.zero as 0', () {
      final encoded = edgeInsetsCodec.encode(EdgeInsets.zero);
      expect(encoded, 0.0);
      expectJsonSafe(encoded);
    });

    test('emits the full object when sides differ', () {
      final encoded = edgeInsetsCodec.encode(
        const EdgeInsets.only(left: 8, top: 4),
      );
      expect(encoded, {'left': 8.0, 'top': 4.0, 'right': 0.0, 'bottom': 0.0});
      expectJsonSafe(encoded);
    });
  });

  group('edgeInsetsCodec rejects invalid input', () {
    const invalidCases = <String, Object>{
      'directional shape': {'start': 8, 'top': 0, 'end': 0, 'bottom': 0},
      'unknown key': {'left': 8, 'z': 1},
      'non-finite scalar': double.infinity,
      'non-finite side': {'left': double.infinity},
    };

    invalidCases.forEach((name, input) {
      test('rejects $name', () {
        expect(edgeInsetsCodec.safeParse(input).isFail, isTrue);
      });
    });
  });

  group('edgeInsetsDirectionalCodec', () {
    test('decodes a full {start, top, end, bottom} object', () {
      expect(
        edgeInsetsDirectionalCodec.parse({
          'start': 1,
          'top': 2,
          'end': 3,
          'bottom': 4,
        }),
        const EdgeInsetsDirectional.fromSTEB(1, 2, 3, 4),
      );
    });

    test('applies per-side defaults to a partial object', () {
      expect(
        edgeInsetsDirectionalCodec.parse({'start': 8}),
        const EdgeInsetsDirectional.only(start: 8),
      );
    });

    test('decodes an empty object as EdgeInsetsDirectional.zero', () {
      expect(edgeInsetsDirectionalCodec.parse({}), EdgeInsetsDirectional.zero);
    });

    test('always encodes to the full object, even when uniform', () {
      final encoded = edgeInsetsDirectionalCodec.encode(
        const EdgeInsetsDirectional.all(8),
      );
      expect(encoded, {'start': 8.0, 'top': 8.0, 'end': 8.0, 'bottom': 8.0});
      expectJsonSafe(encoded);
    });

    group('rejects invalid input', () {
      const invalidCases = <String, Object>{
        'a scalar': 8,
        'non-directional shape': {'left': 8, 'top': 0, 'right': 0, 'bottom': 0},
        'non-finite side': {'start': double.infinity},
      };

      invalidCases.forEach((name, input) {
        test('rejects $name', () {
          expect(edgeInsetsDirectionalCodec.safeParse(input).isFail, isTrue);
        });
      });
    });
  });

  group('edgeInsetsGeometryCodec', () {
    test('decodes scalar / {left,...} / {} to EdgeInsets', () {
      expect(edgeInsetsGeometryCodec.parse(16), isA<EdgeInsets>());
      expect(edgeInsetsGeometryCodec.parse(16), const EdgeInsets.all(16));

      final fromObject = edgeInsetsGeometryCodec.parse({'left': 8});
      expect(fromObject, isA<EdgeInsets>());
      expect(fromObject, const EdgeInsets.only(left: 8));

      expect(edgeInsetsGeometryCodec.parse({}), isA<EdgeInsets>());
    });

    test('decodes {start,...} to EdgeInsetsDirectional', () {
      final value = edgeInsetsGeometryCodec.parse({'start': 8});
      expect(value, isA<EdgeInsetsDirectional>());
      expect(value, const EdgeInsetsDirectional.only(start: 8));
    });

    test('encodes EdgeInsets back to scalar/object', () {
      expect(edgeInsetsGeometryCodec.encode(const EdgeInsets.all(16)), 16.0);
      final encoded = edgeInsetsGeometryCodec.encode(
        const EdgeInsets.only(left: 8, top: 4),
      );
      expect(encoded, {'left': 8.0, 'top': 4.0, 'right': 0.0, 'bottom': 0.0});
      expectJsonSafe(encoded);
    });

    test('encodes EdgeInsetsDirectional back to its object', () {
      final encoded = edgeInsetsGeometryCodec.encode(
        const EdgeInsetsDirectional.only(start: 8),
      );
      expect(encoded, {'start': 8.0, 'top': 0.0, 'end': 0.0, 'bottom': 0.0});
      expectJsonSafe(encoded);
    });

    test('directional zero round-trips as EdgeInsetsDirectional', () {
      // EdgeInsets.zero == EdgeInsetsDirectional.zero, so assert the type.
      final encoded = edgeInsetsGeometryCodec.encode(
        EdgeInsetsDirectional.zero,
      );
      expect(encoded, {'start': 0.0, 'top': 0.0, 'end': 0.0, 'bottom': 0.0});
      expect(
        edgeInsetsGeometryCodec.parse(encoded),
        isA<EdgeInsetsDirectional>(),
      );
    });

    test('rejects encoding a mixed geometry', () {
      // Combining EdgeInsets with EdgeInsetsDirectional yields a private
      // _MixedEdgeInsets that matches neither branch, so encode fails loudly
      // rather than coercing it.
      final mixed = const EdgeInsets.only(
        left: 8,
      ).add(const EdgeInsetsDirectional.only(start: 4));
      expect(edgeInsetsGeometryCodec.safeEncode(mixed).isFail, isTrue);
    });

    group('rejects invalid input', () {
      const invalidCases = <String, Object>{
        'mixed keys': {'left': 8, 'start': 8},
        'unknown key': {'z': 1},
      };

      invalidCases.forEach((name, input) {
        test('rejects $name', () {
          expect(edgeInsetsGeometryCodec.safeParse(input).isFail, isTrue);
        });
      });
    });
  });
}
