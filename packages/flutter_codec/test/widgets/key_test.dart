import 'package:ack/ack.dart' show SchemaNestedError;
import 'package:flutter/widgets.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('keyCodec', () {
    test('round-trips supported ValueKey scalar types', () {
      final cases = <Key>[
        const ValueKey<String>('foo'),
        const ValueKey<int>(1),
        const ValueKey<double>(1.5),
        const ValueKey<bool>(true),
      ];

      for (final key in cases) {
        final encoded = keyCodec.encode(key);

        expect(keyCodec.parse(encoded), key);
        expectJsonSafe(encoded);
      }
    });

    test('encodes Key(String) sugar as a string ValueKey', () {
      final encoded = keyCodec.encode(const Key('foo'));

      expect(encoded, {'type': 'value', 'valueType': 'string', 'value': 'foo'});
      expect(keyCodec.parse(encoded), const ValueKey<String>('foo'));
      expectJsonSafe(encoded);
    });

    test('keeps int and double keys distinct', () {
      final intKey = keyCodec.parse({
        'type': 'value',
        'valueType': 'int',
        'value': 1,
      });
      final doubleKey = keyCodec.parse({
        'type': 'value',
        'valueType': 'double',
        'value': 1,
      });

      expect(intKey, const ValueKey<int>(1));
      expect(doubleKey, const ValueKey<double>(1));
      expect(intKey, isNot(doubleKey));
    });

    test('rejects identity-based key subtypes on encode', () {
      final cases = <Key>[const ObjectKey('x'), UniqueKey(), GlobalKey()];

      for (final key in cases) {
        _expectEncodeFailureContains(key, key.runtimeType.toString());
        _expectEncodeFailureContains(key, 'cannot be serialized');
      }
    });

    test('rejects unsupported ValueKey value types on encode', () {
      final cases = <Key>[
        const ValueKey<num>(1),
        const ValueKey<Object>('foo'),
        const ValueKey<List<int>>([1]),
      ];

      for (final key in cases) {
        _expectEncodeFailureContains(key, key.runtimeType.toString());
        _expectEncodeFailureContains(key, 'no portable JSON shape');
      }
    });

    test('rejects invalid value-key payloads', () {
      final invalidCases = <String, Object>{
        'unknown valueType': {
          'type': 'value',
          'valueType': 'date',
          'value': '2026-05-27',
        },
        'generic number valueType': {
          'type': 'value',
          'valueType': 'number',
          'value': 1,
        },
        'missing value': {'type': 'value', 'valueType': 'string'},
        'int type mismatch': {
          'type': 'value',
          'valueType': 'int',
          'value': 'oops',
        },
        'string type mismatch': {
          'type': 'value',
          'valueType': 'string',
          'value': 1,
        },
      };

      invalidCases.forEach((name, input) {
        expect(keyCodec.safeParse(input).isFail, isTrue, reason: name);
      });
    });
  });
}

void _expectEncodeFailureContains(Key key, String fragment) {
  final result = keyCodec.safeEncode(key);

  expect(result.isFail, isTrue);
  final error = result.getError();
  expect(error, isA<SchemaNestedError>());
  expect(
    (error as SchemaNestedError).errors.single.toString(),
    contains(fragment),
  );
}
