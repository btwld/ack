import 'package:flutter/rendering.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('boxConstraintsCodec decode', () {
    test('decodes an empty object as default constraints', () {
      expect(boxConstraintsCodec.parse({}), const BoxConstraints());
    });

    test('decodes explicit null max bounds as unbounded', () {
      expect(
        boxConstraintsCodec.parse({
          'minWidth': 0,
          'maxWidth': null,
          'minHeight': 0,
          'maxHeight': null,
        }),
        const BoxConstraints(),
      );
    });

    test('decodes explicit null min bounds as infinite', () {
      expect(
        boxConstraintsCodec.parse({
          'minWidth': null,
          'maxWidth': null,
          'minHeight': null,
          'maxHeight': null,
        }),
        const BoxConstraints.expand(),
      );
    });
  });

  group('boxConstraintsCodec encode', () {
    test('emits a full canonical map with nulls for infinite bounds', () {
      final encoded = boxConstraintsCodec.encode(const BoxConstraints());

      expect(encoded, {
        'minWidth': 0.0,
        'maxWidth': null,
        'minHeight': 0.0,
        'maxHeight': null,
      });
      expectJsonSafe(encoded);
    });

    test('round-trips fully populated finite constraints', () {
      const constraints = BoxConstraints(
        minWidth: 1,
        maxWidth: 10,
        minHeight: 2,
        maxHeight: 20,
      );

      final encoded = boxConstraintsCodec.encode(constraints);

      expect(boxConstraintsCodec.parse(encoded), constraints);
      expectJsonSafe(encoded);
    });

    test('round-trips tightFor constraints', () {
      final constraints = BoxConstraints.tightFor(width: 12, height: 34);

      expect(
        boxConstraintsCodec.parse(boxConstraintsCodec.encode(constraints)!),
        constraints,
      );
    });

    test('round-trips expand constraints', () {
      const constraints = BoxConstraints.expand();

      expect(
        boxConstraintsCodec.parse(boxConstraintsCodec.encode(constraints)!),
        constraints,
      );
    });
  });

  group('constraintsCodec', () {
    test('parses a box constraints branch', () {
      final parsed = constraintsCodec.parse({
        'type': 'box',
        'minWidth': 1,
        'maxWidth': 10,
        'minHeight': 2,
        'maxHeight': 20,
      });

      expect(
        parsed,
        const BoxConstraints(
          minWidth: 1,
          maxWidth: 10,
          minHeight: 2,
          maxHeight: 20,
        ),
      );
      expect(parsed, isA<BoxConstraints>());
    });

    test('encodes BoxConstraints with a discriminator', () {
      const constraints = BoxConstraints(
        minWidth: 1,
        maxWidth: 10,
        minHeight: 2,
        maxHeight: 20,
      );

      final encoded = constraintsCodec.encode(constraints);

      expect(encoded, {
        'type': 'box',
        'minWidth': 1.0,
        'maxWidth': 10.0,
        'minHeight': 2.0,
        'maxHeight': 20.0,
      });
      expect(constraintsCodec.parse(encoded), constraints);
      expectJsonSafe(encoded);
    });

    test('rejects an unknown constraints discriminator', () {
      expect(constraintsCodec.safeParse({'type': 'sliver'}).isFail, isTrue);
    });
  });
}
