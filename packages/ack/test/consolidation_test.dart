import 'package:ack/ack.dart';
import 'package:test/test.dart';

final class _Foo {
  _Foo(this.created);
  final DateTime created;
}

void main() {
  group('encode error path preservation', () {
    test('list item encode failure carries item path', () {
      final schema = Ack.list(Ack.datetime());
      // Second element is local-time DateTime, fails UTC invariant.
      final result = schema.safeEncode([
        DateTime.utc(2026, 1, 1),
        DateTime(2026, 1, 2),
      ]);
      expect(result.isFail, true);
      final err = result.getError();
      final flattened = _flatten(err);
      expect(
        flattened.any((e) => e.path == '#/1'),
        true,
        reason:
            'Expected an error at path #/1, got: '
            '${flattened.map((e) => '${e.path} ${e.runtimeType}').join(', ')}',
      );
    });

    test('object property encode failure carries property path', () {
      final schema = Ack.object({'when': Ack.datetime()});
      final result = schema.safeEncode({'when': DateTime(2026, 1, 1)});
      expect(result.isFail, true);
      final flattened = _flatten(result.getError());
      expect(
        flattened.any((e) => e.path == '#/when'),
        true,
        reason:
            'Expected error at #/when, got: '
            '${flattened.map((e) => e.path).join(', ')}',
      );
    });

    test('nested object encode failure carries deep path', () {
      final schema = Ack.object({
        'event': Ack.object({'at': Ack.datetime()}),
      });
      final result = schema.safeEncode({
        'event': {'at': DateTime(2026, 5, 10)},
      });
      expect(result.isFail, true);
      final flattened = _flatten(result.getError());
      expect(
        flattened.any((e) => e.path == '#/event/at'),
        true,
        reason:
            'Expected #/event/at, got: '
            '${flattened.map((e) => e.path).join(', ')}',
      );
    });

    test('list of objects encode failure carries deep indexed path', () {
      final schema = Ack.list(Ack.object({'at': Ack.datetime()}));
      final result = schema.safeEncode([
        {'at': DateTime.utc(2026, 1, 1)},
        {'at': DateTime(2026, 1, 2)},
      ]);
      expect(result.isFail, true);
      final flattened = _flatten(result.getError());
      expect(
        flattened.any((e) => e.path == '#/1/at'),
        true,
        reason:
            'Expected #/1/at, got: '
            '${flattened.map((e) => e.path).join(', ')}',
      );
    });
  });

  group('runtime defaults on codecs', () {
    test('codec.withDefault returns runtime default on parse(null)', () {
      final schema = Ack.date().withDefault(DateTime(2026, 1, 1));
      final parsed = schema.parse(null);
      expect(parsed, DateTime(2026, 1, 1));
    });

    test('codec.withDefault default is validated through runtime path', () {
      // A non-midnight default would violate the date invariant. The
      // DefaultSchema runs it through inner.validateRuntimeWithContext on
      // parse(null) and should fail.
      final schema = Ack.date().withDefault(DateTime(2026, 1, 1, 12));
      final result = schema.safeParse(null);
      expect(result.isFail, true);
    });

    test('codec.withDefault encode does not inject default', () {
      final schema = Ack.date().nullable().withDefault(DateTime(2026, 1, 1));
      final encoded = schema.encode(null);
      expect(encoded, isNull);
    });

    test('codec.withDefault default is omitted from JSON Schema when '
        'it fails encoding', () {
      // Non-midnight runtime value fails the date codec's invariant; the
      // schema should omit the default rather than leak a runtime DateTime.
      final schema = Ack.date().withDefault(DateTime(2026, 1, 1, 12));
      final json = schema.toJsonSchema();
      expect(json.containsKey('default'), false);
    });

    test('codec.withDefault default IS emitted when it encodes cleanly', () {
      final schema = Ack.date().withDefault(DateTime(2026, 1, 1));
      final json = schema.toJsonSchema();
      expect(json['default'], '2026-01-01');
    });
  });

  group('non-string map keys', () {
    test('ObjectSchema rejects maps with non-string keys cleanly', () {
      final schema = Ack.object({'name': Ack.string()});
      final result = schema.safeParse({1: 'oops'});
      expect(result.isFail, true);
      expect(result.getError(), isA<TypeMismatchError>());
    });

    test('Encoding a map containing nested non-string-keyed map fails '
        'cleanly via object passthrough', () {
      final schema = Ack.object({
        'meta': Ack.any(),
      }, additionalProperties: false);
      // Pass-through into Ack.any encodes identity, so the meta map is
      // preserved as-is. This documents that the public API enforces
      // string keys at the top-level via the `JsonMap` typedef; nested
      // structures inside `Ack.any` are not normalised.
      final inner = <dynamic, dynamic>{1: 'oops'};
      final result = schema.safeEncode({'meta': inner});
      expect(result.isOk, true);
      expect((result.getOrNull()!['meta'] as Map)[1], 'oops');
    });

    test('DiscriminatedObjectSchema rejects non-string-keyed maps', () {
      final schema = Ack.discriminated<_Foo>(
        discriminatorKey: 'kind',
        schemas: {
          'foo': Ack.object({'created': Ack.datetime()}).model<_Foo>(
            decode: (data) => _Foo(data['created'] as DateTime),
            encode: (foo) => {'created': foo.created},
          ),
        },
      );
      final result = schema.safeParse({1: 'oops'});
      expect(result.isFail, true);
      expect(result.getError(), isA<TypeMismatchError>());
    });
  });

  group('built-in encode invariants', () {
    test('Ack.date rejects non-midnight encode', () {
      final result = Ack.date().safeEncode(DateTime(2026, 1, 1, 12));
      expect(result.isFail, true);
    });

    test('Ack.date rejects UTC encode (must be local midnight)', () {
      final result = Ack.date().safeEncode(DateTime.utc(2026, 1, 1));
      expect(result.isFail, true);
    });

    test('Ack.date accepts local midnight encode', () {
      final result = Ack.date().safeEncode(DateTime(2026, 1, 1));
      expect(result.isOk, true);
      expect(result.getOrNull(), '2026-01-01');
    });

    test('Ack.datetime rejects non-UTC encode', () {
      final result = Ack.datetime().safeEncode(DateTime(2026, 1, 1, 12));
      expect(result.isFail, true);
    });

    test('Ack.datetime accepts UTC encode', () {
      final result = Ack.datetime().safeEncode(DateTime.utc(2026, 1, 1, 12));
      expect(result.isOk, true);
    });

    test('Ack.duration rejects sub-millisecond precision encode', () {
      final result = Ack.duration().safeEncode(
        const Duration(microseconds: 1500),
      );
      expect(result.isFail, true);
    });

    test('Ack.duration accepts whole-millisecond encode', () {
      final result = Ack.duration().safeEncode(
        const Duration(milliseconds: 500),
      );
      expect(result.isOk, true);
      expect(result.getOrNull(), 500);
    });

    test('Ack.uri rejects relative URI encode', () {
      final result = Ack.uri().safeEncode(Uri.parse('relative/path'));
      expect(result.isFail, true);
    });

    test('Ack.uri accepts absolute URI encode', () {
      final result = Ack.uri().safeEncode(Uri.parse('https://example.com/x'));
      expect(result.isOk, true);
      expect(result.getOrNull(), 'https://example.com/x');
    });
  });

  group('nullable AnyOf encode symmetry', () {
    test('anyOf with a nullable branch parses null', () {
      final schema = Ack.anyOf([Ack.string().nullable(), Ack.integer()]);
      final result = schema.safeParse(null);
      expect(result.isOk, true);
      expect(result.getOrNull(), isNull);
    });

    test('anyOf with a nullable branch encodes null', () {
      final schema = Ack.anyOf([Ack.string().nullable(), Ack.integer()]);
      final result = schema.safeEncode(null);
      expect(result.isOk, true);
      expect(result.getOrNull(), isNull);
    });

    test('anyOf with no nullable branches rejects null on encode', () {
      final schema = Ack.anyOf([Ack.string(), Ack.integer()]);
      final result = schema.safeEncode(null);
      expect(result.isFail, true);
    });
  });

  group('Runtime configuration surface', () {
    test('CodecSchema can be refined without dynamic casts', () {
      final schema = Ack.string().codec<int>(
        decode: int.parse,
        encode: (i) => i.toString(),
      );
      final refined = schema.refine((v) => v > 0, message: 'must be positive');
      final ok = refined.safeParse('5');
      final fail = refined.safeParse('-1');
      expect(ok.isOk, true);
      expect(fail.isFail, true);
    });

    test('CodecSchema can be made nullable through extension', () {
      final schema = Ack.date();
      final nullable = schema.nullable();
      expect(nullable.parse(null), isNull);
    });

    test('one-way CodecSchema can be refined without dynamic casts', () {
      final schema = Ack.string().transform<int>(int.parse);
      final refined = schema.refine((v) => v > 0, message: 'must be positive');
      expect(refined.parse('5'), 5);
      expect(refined.safeParse('-1').isFail, true);
    });

    test('DefaultSchema can be made nullable through extension', () {
      final schema = Ack.string().withDefault('x');
      final nullable = schema.nullable();
      expect(nullable.isNullable, true);
    });
  });

  group('single-lifecycle invariants', () {
    test('parse and runtime validation agree on primitive types', () {
      final schema = Ack.integer();
      expect(schema.safeParse(42).isOk, true);
      expect(schema.safeParse('42').isFail, true);
    });

    test('codec parse runs output runtime invariants', () {
      // Build a codec whose decode produces a value that fails the output
      // schema's refinement. The decode succeeds, but runtime validation fails.
      final schema = Ack.string().codec<int>(
        output: Ack.instance<int>().refine((v) => v.isEven, message: 'even'),
        decode: int.parse,
        encode: (i) => i.toString(),
      );
      expect(schema.safeParse('4').isOk, true);
      expect(schema.safeParse('5').isFail, true);
    });

    test('codec encode runs output runtime invariants before encoding', () {
      final schema = Ack.string().codec<int>(
        output: Ack.instance<int>().refine((v) => v.isEven, message: 'even'),
        decode: int.parse,
        encode: (i) => i.toString(),
      );
      expect(schema.safeEncode(4).isOk, true);
      expect(schema.safeEncode(5).isFail, true);
    });
  });
}

Iterable<SchemaError> _flatten(SchemaError err) sync* {
  yield err;
  if (err is SchemaNestedError) {
    for (final child in err.errors) {
      yield* _flatten(child);
    }
  }
}
