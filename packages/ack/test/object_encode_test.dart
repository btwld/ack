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
      final schema = Ack.object({
        'name': Ack.string(),
        'age': Ack.integer(),
      });

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

    test('omits missing optional properties (no default synthesis on encode)',
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
    });

    test('emits SchemaEncodeError.missingRequiredProperty for missing required',
        () {
      final schema = Ack.object({
        'name': Ack.string(),
        'age': Ack.integer(),
      });

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
    });

    test('passes through unexpected keys when additionalProperties is true',
        () {
      final schema = Ack.object(
        {'name': Ack.string()},
        additionalProperties: true,
      );

      final result = schema.safeEncode({'name': 'Alice', 'extra': 'kept'});

      expect(result.isOk, isTrue);
      expect(
        result.getOrNull(),
        equals({'name': 'Alice', 'extra': 'kept'}),
      );
    });

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

    test(
      'preserves child path in errors when a child encoder fails',
      () {
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
      },
    );

    test('encode then decode round-trips through codec children', () {
      // Round-trip property: parsing the boundary form of an encoded value
      // should reproduce the original runtime value.
      final schema = Ack.object({
        'count': intString(),
        'name': Ack.string(),
      });

      final original = {'count': 42, 'name': 'Alice'};
      final encoded = schema.encode(original);
      expect(encoded, isA<Map>());
      expect((encoded as Map)['count'], equals('42'));

      final reparsed = schema.parse(encoded);
      expect(reparsed, equals(original));
    });

    test('null on a non-nullable object schema fails with SchemaEncodeError',
        () {
      final schema = Ack.object({'name': Ack.string()});
      final result = schema.safeEncode(null);

      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('null on a nullable object schema returns Ok(null)', () {
      final schema = Ack.object({'name': Ack.string()}).nullable();
      final result = schema.safeEncode(null);

      expect(result.isOk, isTrue);
      expect(result.getOrNull(), isNull);
    });
  });
}
