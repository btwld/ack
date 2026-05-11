import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  // A small bidirectional codec used as a non-trivial child:
  // String <-> int. Encode produces the string form.
  CodecSchema<String, int> intString() => Ack.codec<String, int>(
    input: Ack.string(),
    output: Ack.instance<int>(),
    decoder: int.parse,
    encoder: (i) => i.toString(),
  );

  group('ObjectSchema.encode (M6)', () {
    test('identity encode for an object with primitive children', () {
      final schema = Ack.object({'name': Ack.string(), 'age': Ack.integer()});

      final result = schema.safeEncode({'name': 'Alice', 'age': 30});

      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals({'name': 'Alice', 'age': 30}));
    });

    test('recurses into codec children — runtime → boundary form (AC-07)', () {
      // Mirrors the AC-07 acceptance criterion: encoding an object whose
      // child is a codec produces the boundary form for that property.
      final schema = Ack.object({'count': intString()});

      final result = schema.safeEncode({'count': 42});

      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals({'count': '42'}));
    });

    test('recurses into nested ObjectSchemas containing codecs', () {
      final schema = Ack.object({
        'inner': Ack.object({'count': intString()}),
      });

      final result = schema.safeEncode({
        'inner': {'count': 42},
      });

      expect(result.isOk, isTrue);
      expect(
        result.getOrNull(),
        equals({
          'inner': {'count': '42'},
        }),
      );
    });

    test(
      'omits missing optional properties (no default synthesis on encode)',
      () {
        // Per §5.5: defaults are parse-only. Encoding an object with a missing
        // optional-with-default property must NOT inject the default.
        final schema = Ack.object({
          'name': Ack.string(),
          'nickname': Ack.string().withDefault('anon').optional(),
        });

        final result = schema.safeEncode({'name': 'Alice'});

        expect(result.isOk, isTrue);
        expect(
          result.getOrNull(),
          equals({'name': 'Alice'}),
          reason: 'optional missing → omitted, NOT injected from default',
        );
      },
    );

    test(
      'emits SchemaEncodeError.missingRequiredProperty for missing required',
      () {
        final schema = Ack.object({'name': Ack.string(), 'age': Ack.integer()});

        final result = schema.safeEncode({'name': 'Alice'});

        expect(result.isFail, isTrue);
        final err = result.getError();
        expect(err, isA<SchemaNestedError>());
        final nested = (err as SchemaNestedError).errors;
        expect(nested, hasLength(1));
        expect(nested.single, isA<SchemaEncodeError>());
        expect(nested.single.message.toLowerCase(), contains('required'));
        // Path of the nested error points at the missing key.
        expect(nested.single.path, equals('#/age'));
      },
    );

    test(
      'passes through unexpected keys when additionalProperties is true',
      () {
        final schema = Ack.object({
          'name': Ack.string(),
        }, additionalProperties: true);

        final result = schema.safeEncode({'name': 'Alice', 'extra': 'kept'});

        expect(result.isOk, isTrue);
        expect(result.getOrNull(), equals({'name': 'Alice', 'extra': 'kept'}));
      },
    );

    test(
      'rejects unexpected keys with SchemaEncodeError.unexpectedProperty when '
      'additionalProperties is false',
      () {
        final schema = Ack.object({'name': Ack.string()});
        // additionalProperties defaults to false.

        final result = schema.safeEncode({'name': 'Alice', 'extra': 'oops'});

        expect(result.isFail, isTrue);
        expect(result.getError().toString(), contains('extra'));
      },
    );

    test('returns an unmodifiable map', () {
      final schema = Ack.object({'name': Ack.string()});
      final result = schema.safeEncode({'name': 'Alice'});

      expect(result.isOk, isTrue);
      final encoded = result.getOrNull() as Map;
      expect(() => encoded['x'] = 'y', throwsUnsupportedError);
    });

    test('rejects non-Map runtime values', () {
      final schema = Ack.object({'name': Ack.string()});

      final result = schema.safeEncode('not a map');

      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('preserves child path in errors when a child encoder fails', () {
      final exploding = Ack.codec<String, int>(
        input: Ack.string(),
        output: Ack.instance<int>(),
        decoder: int.parse,
        encoder: (i) => throw StateError('boom'),
      );
      final schema = Ack.object({'count': exploding});

      final result = schema.safeEncode({'count': 42});

      expect(result.isFail, isTrue);
      // Path should reach into the child key.
      expect(result.getError().toString(), contains('count'));
    });

    test('encode then decode round-trips through codec children', () {
      // Round-trip property: parsing the boundary form of an encoded value
      // should reproduce the original runtime value.
      final schema = Ack.object({'count': intString(), 'name': Ack.string()});

      final original = {'count': 42, 'name': 'Alice'};
      final encoded = schema.encode(original);
      expect(encoded, isA<Map>());
      expect((encoded as Map)['count'], equals('42'));

      final reparsed = schema.parse(encoded);
      expect(reparsed, equals(original));
    });

    test(
      'null on a non-nullable object schema fails with SchemaEncodeError',
      () {
        final schema = Ack.object({'name': Ack.string()});
        final result = schema.safeEncode(null);

        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaEncodeError>());
      },
    );

    test('null on a nullable object schema returns Ok(null)', () {
      final schema = Ack.object({'name': Ack.string()}).nullable();
      final result = schema.safeEncode(null);

      expect(result.isOk, isTrue);
      expect(result.getOrNull(), isNull);
    });

    test(
      'child validation runs before object-level refinement during encode',
      () {
        // Regression: object-level refinements must observe a structurally-
        // valid map. Children are validated first so a bad child type does
        // not crash a refinement that downcasts.
        var refinementCalled = false;
        final schema = Ack.object({'a': Ack.integer()}).refine((m) {
          refinementCalled = true;
          return (m['a'] as int) > 0;
        });
        final result = schema.safeEncode({'a': 'bad'});
        expect(result.isFail, isTrue);
        expect(
          refinementCalled,
          isFalse,
          reason: 'refinement must not run when a child fails validation',
        );
        final err = result.getError();
        expect(err, isA<SchemaNestedError>());
        expect((err as SchemaNestedError).errors.single.path, equals('#/a'));
      },
    );

    test('child validation runs exactly once during encode', () {
      // Regression: previously ObjectSchema.encodeBoundary re-ran
      // child._validateRuntime, double-applying child refinements.
      // The dispatcher's _validateRuntime owns child runtime validation;
      // encodeBoundary should only translate runtime → boundary.
      var calls = 0;
      final schema = Ack.object({
        'a': Ack.integer().refine((value) {
          calls++;
          return true;
        }),
      });
      final result = schema.safeEncode({'a': 1});
      expect(result.isOk, isTrue);
      expect(calls, equals(1));
    });

    test('safeEncode does not throw on a map with non-String keys', () {
      // Regression: previously _validateRuntime used Map.cast<String, Object?>(),
      // which is a lazy view that throws TypeError when iterated over a map
      // with non-String keys. safeEncode must never throw.
      final schema = Ack.object({'name': Ack.string()});
      late SchemaResult<Object> result;
      expect(() => result = schema.safeEncode({1: 'bad'}), returnsNormally);
      expect(result.isFail, isTrue);
    });

    test('safeEncode does not throw on a lazy cast map view', () {
      final schema = Ack.object({'name': Ack.string()});
      final value = ({1: 'bad'} as Map).cast<String, Object?>();
      late SchemaResult<Object> result;

      expect(() => result = schema.safeEncode(value), returnsNormally);
      expect(result.isFail, isTrue);
    });

    test('safeParse does not throw on a map with non-String keys', () {
      final schema = Ack.object({'name': Ack.string()});
      late SchemaResult<Map<String, Object?>> result;
      expect(() => result = schema.safeParse({1: 'bad'}), returnsNormally);
      expect(result.isFail, isTrue);
    });

    test('safeParse does not throw on a lazy cast map view', () {
      final schema = Ack.object({'name': Ack.string()});
      final value = ({1: 'bad'} as Map).cast<String, Object?>();
      late SchemaResult<Map<String, Object?>> result;

      expect(() => result = schema.safeParse(value), returnsNormally);
      expect(result.isFail, isTrue);
    });

    test('safeParse does not throw on a non-map non-primitive value', () {
      // Regression: AckSchema.getSchemaType throws ArgumentError for values
      // outside the JSON primitives (DateTime, Uri, user classes). Composite
      // schemas must catch that and return a Fail rather than letting the
      // ArgumentError escape `safeParse`.
      final schema = Ack.object({'name': Ack.string()});
      late SchemaResult<Map<String, Object?>> result;
      expect(
        () => result = schema.safeParse(DateTime.utc(2025, 1, 1)),
        returnsNormally,
      );
      expect(result.isFail, isTrue);
    });

    test('safeEncode does not throw on a non-map non-primitive value', () {
      final schema = Ack.object({'name': Ack.string()});
      late SchemaResult<Object> result;
      expect(
        () => result = schema.safeEncode(Uri.parse('https://example.com')),
        returnsNormally,
      );
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });
  });
}
