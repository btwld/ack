import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// A union whose null acceptance comes from a branch, not from its own flag.
AnyOfSchema _nullableUnion() =>
    Ack.anyOf([Ack.string().nullable(), Ack.integer()]);

void main() {
  group('effective nullability — object fields', () {
    test('required nullable-union field parses and encodes null', () {
      final schema = Ack.object({'v': _nullableUnion()});

      final parsed = schema.safeParse({'v': null});
      expect(
        parsed.isOk,
        isTrue,
        reason: parsed.isFail ? parsed.getError().toString() : null,
      );
      expect(parsed.getOrNull(), equals({'v': null}));

      final encoded = schema.safeEncode({'v': null});
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), equals({'v': null}));
    });

    test('optional nullable-union field encodes a present null as null', () {
      final schema = Ack.object({'v': _nullableUnion().optional()});

      final encoded = schema.safeEncode({'v': null});
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), equals({'v': null}));
      expect(encoded.getOrNull()!.containsKey('v'), isTrue);
    });

    test('optional nullable-union field keeps a missing key missing', () {
      final schema = Ack.object({'v': _nullableUnion().optional()});

      final encoded = schema.safeEncode({});
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), isEmpty);
    });
  });

  group('effective nullability — nested unions', () {
    test('union containing a nullable union encodes null at the root', () {
      final schema = Ack.anyOf([_nullableUnion(), Ack.boolean()]);

      expect(schema.safeParse(null).isOk, isTrue);
      final encoded = schema.safeEncode(null);
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), isNull);
    });

    test('union containing a nullable union encodes null as a field', () {
      final schema = Ack.object({
        'v': Ack.anyOf([_nullableUnion(), Ack.boolean()]),
      });

      final encoded = schema.safeEncode({'v': null});
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), equals({'v': null}));
    });
  });

  group('effective nullability — DefaultSchema', () {
    test('withDefault over a nullable union encodes null at the root', () {
      final schema = _nullableUnion().withDefault('x');

      final encoded = schema.safeEncode(null);
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), isNull);
    });

    test('withDefault over a nullable union encodes null as a field', () {
      final schema = Ack.object({'v': _nullableUnion().withDefault('x')});

      final encoded = schema.safeEncode({'v': null});
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), equals({'v': null}));
    });
  });

  group('effective nullability — BoundarySchema', () {
    test('preserveBoundary over a nullable union encodes null at the root', () {
      final schema = Ack.preserveBoundary(_nullableUnion());

      final encoded = schema.safeEncode(null);
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), isNull);
    });

    test('preserveBoundary over a nullable union encodes null as a field', () {
      final schema = Ack.object({'v': Ack.preserveBoundary(_nullableUnion())});

      final encoded = schema.safeEncode({'v': null});
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), equals({'v': null}));
    });
  });

  group('effective nullability — codecs over a nullable union', () {
    test('.transform() parses null to null', () {
      final schema = _nullableUnion().transform((value) => value.toString());

      final parsed = schema.safeParse(null);
      expect(
        parsed.isOk,
        isTrue,
        reason: parsed.isFail ? parsed.getError().toString() : null,
      );
      expect(parsed.getOrNull(), isNull);
    });

    test('.codec() parses and encodes null', () {
      final schema = _nullableUnion().codec<String>(
        decode: (value) => value.toString(),
        encode: (value) => value,
      );

      final parsed = schema.safeParse(null);
      expect(
        parsed.isOk,
        isTrue,
        reason: parsed.isFail ? parsed.getError().toString() : null,
      );
      expect(parsed.getOrNull(), isNull);

      final encoded = schema.safeEncode(null);
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), isNull);
    });

    test('Ack.codec() parses and encodes null', () {
      final schema = Ack.codec<Object, Object, String>(
        input: _nullableUnion(),
        decode: (value) => value.toString(),
        encode: (value) => value,
      );

      final parsed = schema.safeParse(null);
      expect(
        parsed.isOk,
        isTrue,
        reason: parsed.isFail ? parsed.getError().toString() : null,
      );
      expect(parsed.getOrNull(), isNull);

      final encoded = schema.safeEncode(null);
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), isNull);
    });

    test('codec export still advertises the null branch and is valid', () {
      final schema = _nullableUnion().codec<String>(
        decode: (value) => value.toString(),
        encode: (value) => value,
      );

      final exported = schema.toJsonSchema();
      expect(exported, isNotEmpty);
      final branches = exported['anyOf'];
      expect(branches, isA<List<Object?>>());
      expect(
        (branches! as List<Object?>).whereType<Map<Object?, Object?>>().any(
          (branch) => branch['type'] == 'null',
        ),
        isTrue,
        reason: 'Export advertises a null branch: $exported',
      );
    });

    test('explicit .nullable(value: false) overrides the inferred flag', () {
      final schema = _nullableUnion()
          .codec<String>(
            decode: (value) => value.toString(),
            encode: (value) => value,
          )
          .nullable(value: false);

      expect(schema.safeParse(null).isFail, isTrue);
      expect(schema.safeEncode(null).isFail, isTrue);
    });
  });

  group('effective nullability — list construction', () {
    test('Ack.list rejects a nested nullable union item', () {
      expect(
        () => Ack.list(Ack.anyOf([_nullableUnion(), Ack.boolean()])),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('nullable item schemas'),
          ),
        ),
      );
    });

    test('Ack.list rejects a codec over a nullable union', () {
      expect(
        () => Ack.list(
          _nullableUnion().codec<String>(
            decode: (value) => value.toString(),
            encode: (value) => value,
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('nullable item schemas'),
          ),
        ),
      );
    });

    test('Ack.list rejects withDefault over a nullable union', () {
      expect(
        () => Ack.list(_nullableUnion().withDefault('fallback')),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('nullable item schemas'),
          ),
        ),
      );
    });

    test('Ack.list rejects preserveBoundary over a nullable union', () {
      expect(
        () => Ack.list(Ack.preserveBoundary(_nullableUnion())),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('nullable item schemas'),
          ),
        ),
      );
    });

    test('Ack.list still rejects a directly nullable item schema', () {
      expect(
        () => Ack.list(Ack.string().nullable()),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('effective nullability — unchanged behavior', () {
    test('Ack.map over a nullable union is unchanged', () {
      final schema = Ack.map(_nullableUnion());

      expect(schema.safeParse({'a': null}).isOk, isTrue);
      final encoded = schema.safeEncode({'a': null});
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), equals({'a': null}));
    });

    test('optional non-nullable field rejects a present null on parse', () {
      final schema = Ack.object({'v': Ack.string().optional()});

      expect(schema.safeParse({'v': null}).isFail, isTrue);
    });

    test('optional non-nullable field omits a present null on encode', () {
      final schema = Ack.object({'v': Ack.string().optional()});

      final encoded = schema.safeEncode({'v': null});
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), isEmpty);
    });

    test('nullable().withDefault() keeps its parse and encode behavior', () {
      final field = Ack.string().nullable().withDefault('x');

      expect(field.safeParse(null).getOrNull(), equals('x'));

      final schema = Ack.object({'d': field});
      final encoded = schema.safeEncode({'d': null});
      expect(
        encoded.isOk,
        isTrue,
        reason: encoded.isFail ? encoded.getError().toString() : null,
      );
      expect(encoded.getOrNull(), equals({'d': null}));
    });

    test('LazySchema nullability still comes from its own flag', () {
      final lazy = Ack.lazy('nullableUnionTarget', _nullableUnion);

      expect(lazy.safeParse(null).isFail, isTrue);
      expect(lazy.nullable().safeParse(null).isOk, isTrue);
    });
  });
}
