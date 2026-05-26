import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('alignmentCodec', () {
    const named = <String, Alignment>{
      'topLeft': Alignment.topLeft,
      'topCenter': Alignment.topCenter,
      'topRight': Alignment.topRight,
      'centerLeft': Alignment.centerLeft,
      'center': Alignment.center,
      'centerRight': Alignment.centerRight,
      'bottomLeft': Alignment.bottomLeft,
      'bottomCenter': Alignment.bottomCenter,
      'bottomRight': Alignment.bottomRight,
    };

    named.forEach((name, value) {
      test('decodes/encodes named "$name"', () {
        expect(alignmentCodec.parse(name), value);
        final encoded = alignmentCodec.encode(value);
        expect(encoded, name);
        expectJsonSafe(encoded);
      });
    });

    test('decodes an arbitrary {x, y} object', () {
      expect(
        alignmentCodec.parse({'x': 0.25, 'y': -0.5}),
        const Alignment(0.25, -0.5),
      );
    });

    test('encodes an arbitrary Alignment as {x, y}', () {
      final encoded = alignmentCodec.encode(const Alignment(0.25, -0.5));
      expect(encoded, {'x': 0.25, 'y': -0.5});
      expectJsonSafe(encoded);
    });

    test('decodes an integer object coordinate as a double', () {
      expect(alignmentCodec.parse({'x': 1, 'y': 0}), const Alignment(1, 0));
    });

    group('rejects invalid input', () {
      const invalidCases = <String, Object>{
        'unknown name': 'middle',
        'missing y': {'x': 0.0},
        'extra key': {'x': 0.0, 'y': 0.0, 'z': 1.0},
        'directional shape': {'start': 0.0, 'y': 0.0},
        'non-finite x': {'x': double.infinity, 'y': 0.0},
      };

      invalidCases.forEach((name, input) {
        test('rejects $name', () {
          expect(alignmentCodec.safeParse(input).isFail, isTrue);
        });
      });
    });
  });

  group('alignmentDirectionalCodec', () {
    const named = <String, AlignmentDirectional>{
      'topStart': AlignmentDirectional.topStart,
      'topCenter': AlignmentDirectional.topCenter,
      'topEnd': AlignmentDirectional.topEnd,
      'centerStart': AlignmentDirectional.centerStart,
      'center': AlignmentDirectional.center,
      'centerEnd': AlignmentDirectional.centerEnd,
      'bottomStart': AlignmentDirectional.bottomStart,
      'bottomCenter': AlignmentDirectional.bottomCenter,
      'bottomEnd': AlignmentDirectional.bottomEnd,
    };

    named.forEach((name, value) {
      test('decodes/encodes named "$name"', () {
        expect(alignmentDirectionalCodec.parse(name), value);
        final encoded = alignmentDirectionalCodec.encode(value);
        expect(encoded, name);
        expectJsonSafe(encoded);
      });
    });

    test('decodes an arbitrary {start, y} object', () {
      expect(
        alignmentDirectionalCodec.parse({'start': 0.25, 'y': -0.5}),
        const AlignmentDirectional(0.25, -0.5),
      );
    });

    test('encodes an arbitrary AlignmentDirectional as {start, y}', () {
      final encoded = alignmentDirectionalCodec.encode(
        const AlignmentDirectional(0.25, -0.5),
      );
      expect(encoded, {'start': 0.25, 'y': -0.5});
      expectJsonSafe(encoded);
    });

    group('rejects invalid input', () {
      const invalidCases = <String, Object>{
        'unknown name': 'middle',
        'missing y': {'start': 0.0},
        'extra key': {'start': 0.0, 'y': 0.0, 'z': 1.0},
        'non-directional shape': {'x': 0.0, 'y': 0.0},
        'non-finite start': {'start': double.infinity, 'y': 0.0},
      };

      invalidCases.forEach((name, input) {
        test('rejects $name', () {
          expect(alignmentDirectionalCodec.safeParse(input).isFail, isTrue);
        });
      });
    });
  });

  group('alignmentGeometryCodec', () {
    test('decodes regular names and {x, y} to Alignment', () {
      expect(alignmentGeometryCodec.parse('topLeft'), Alignment.topLeft);
      expect(alignmentGeometryCodec.parse('topLeft'), isA<Alignment>());

      final fromObject = alignmentGeometryCodec.parse({'x': 0.25, 'y': -0.5});
      expect(fromObject, const Alignment(0.25, -0.5));
      expect(fromObject, isA<Alignment>());
    });

    test(
      'decodes directional names and {start, y} to AlignmentDirectional',
      () {
        expect(
          alignmentGeometryCodec.parse('topStart'),
          AlignmentDirectional.topStart,
        );
        expect(
          alignmentGeometryCodec.parse('topStart'),
          isA<AlignmentDirectional>(),
        );

        final fromObject = alignmentGeometryCodec.parse({
          'start': -1.0,
          'y': 0.0,
        });
        expect(fromObject, const AlignmentDirectional(-1, 0));
        expect(fromObject, isA<AlignmentDirectional>());
      },
    );

    test('resolves the shared "center" name to Alignment, not directional', () {
      // Alignment.center == AlignmentDirectional.center, so assert the type.
      expect(alignmentGeometryCodec.parse('center'), isA<Alignment>());
      expect(
        alignmentGeometryCodec.parse('center'),
        isNot(isA<AlignmentDirectional>()),
      );
    });

    test('round-trips preserve the runtime type', () {
      final alignment = alignmentGeometryCodec.parse({'x': 0.25, 'y': -0.5})!;
      expect(alignment, isA<Alignment>());
      expect(alignmentGeometryCodec.encode(alignment), {'x': 0.25, 'y': -0.5});

      final directional = alignmentGeometryCodec.parse({
        'start': 0.25,
        'y': -0.5,
      })!;
      expect(directional, isA<AlignmentDirectional>());
      expect(alignmentGeometryCodec.encode(directional), {
        'start': 0.25,
        'y': -0.5,
      });
    });

    test('encodes Alignment back to named/object', () {
      expect(alignmentGeometryCodec.encode(Alignment.center), 'center');
      final encoded = alignmentGeometryCodec.encode(
        const Alignment(0.25, -0.5),
      );
      expect(encoded, {'x': 0.25, 'y': -0.5});
      expectJsonSafe(encoded);
    });

    test('encodes AlignmentDirectional back to named/object', () {
      expect(
        alignmentGeometryCodec.encode(AlignmentDirectional.topStart),
        'topStart',
      );
      final encoded = alignmentGeometryCodec.encode(
        const AlignmentDirectional(0.25, -0.5),
      );
      expect(encoded, {'start': 0.25, 'y': -0.5});
      expectJsonSafe(encoded);
    });

    group('rejects invalid input', () {
      const invalidCases = <String, Object>{
        'unknown name': 'middle',
        'mixed keys': {'x': 0.0, 'y': 0.0, 'start': 0.0},
      };

      invalidCases.forEach((name, input) {
        test('rejects $name', () {
          expect(alignmentGeometryCodec.safeParse(input).isFail, isTrue);
        });
      });
    });
  });
}
