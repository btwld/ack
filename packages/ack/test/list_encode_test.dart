import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  CodecSchema<String, int> intString() => Ack.codec<String, int>(
        input: Ack.string(),
        output: Ack.instance<int>(),
        decoder: int.parse,
        encoder: (i) => i.toString(),
      );

  group('ListSchema.encode (M7)', () {
    test('identity encode for a list of primitives', () {
      final schema = Ack.list(Ack.string());
      final result = schema.safeEncode(['a', 'b', 'c']);
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals(['a', 'b', 'c']));
    });

    test('recurses into codec items — runtime → boundary form (AC-08)', () {
      final schema = Ack.list(intString());
      final result = schema.safeEncode([1, 2, 3]);
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals(['1', '2', '3']));
    });

    test('recurses into nested ObjectSchema items', () {
      final schema = Ack.list(Ack.object({'count': intString()}));
      final result = schema.safeEncode([
        {'count': 42},
        {'count': 7},
      ]);
      expect(result.isOk, isTrue);
      expect(
        result.getOrNull(),
        equals([
          {'count': '42'},
          {'count': '7'},
        ]),
      );
    });

    test('returns an unmodifiable list', () {
      final schema = Ack.list(Ack.string());
      final result = schema.safeEncode(['a']);
      expect(result.isOk, isTrue);
      final encoded = result.getOrNull() as List;
      expect(() => encoded.add('b'), throwsUnsupportedError);
    });

    test('rejects non-List runtime values', () {
      final schema = Ack.list(Ack.string());
      final result = schema.safeEncode('not a list');
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('preserves item index path on item-encoder failure', () {
      final exploding = Ack.codec<String, int>(
        input: Ack.string(),
        output: Ack.instance<int>(),
        decoder: int.parse,
        encoder: (i) => throw StateError('boom'),
      );
      final schema = Ack.list(exploding);

      final result = schema.safeEncode([1, 2, 3]);
      expect(result.isFail, isTrue);
      final err = result.getError();
      expect(err, isA<SchemaNestedError>());
      final inner = (err as SchemaNestedError).errors;
      // First item's encode throws → first error has path #/0
      expect(inner.first.path, equals('#/0'));
    });

    test('aggregates errors across multiple failing items', () {
      final exploding = Ack.codec<String, int>(
        input: Ack.string(),
        output: Ack.instance<int>(),
        decoder: int.parse,
        encoder: (i) => throw StateError('boom'),
      );
      final schema = Ack.list(exploding);

      final result = schema.safeEncode([1, 2]);
      expect(result.isFail, isTrue);
      final err = result.getError() as SchemaNestedError;
      expect(err.errors, hasLength(2));
      expect(err.errors[0].path, equals('#/0'));
      expect(err.errors[1].path, equals('#/1'));
    });

    test('encode then decode round-trips through codec items', () {
      final schema = Ack.list(intString());
      final original = [1, 2, 3];
      final encoded = schema.encode(original);
      expect(encoded, equals(['1', '2', '3']));
      final reparsed = schema.parse(encoded);
      expect(reparsed, equals(original));
    });

    test('null on a non-nullable list schema fails with SchemaEncodeError',
        () {
      final schema = Ack.list(Ack.string());
      final result = schema.safeEncode(null);
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('null on a nullable list schema returns Ok(null)', () {
      final schema = Ack.list(Ack.string()).nullable();
      final result = schema.safeEncode(null);
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), isNull);
    });

    test('empty list encodes to empty list', () {
      final schema = Ack.list(intString());
      final result = schema.safeEncode(<int>[]);
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals([]));
    });

    test(
      'item validation runs before list-level refinement during encode',
      () {
        // Regression: list-level refinements must observe a structurally-valid
        // list. Items must be validated first so that bad item types do not
        // crash the refinement.
        var refinementCalled = false;
        final schema = Ack.list(Ack.integer()).refine((xs) {
          refinementCalled = true;
          return xs.first > 0;
        });
        final result = schema.safeEncode(<Object?>['bad']);
        expect(result.isFail, isTrue);
        expect(refinementCalled, isFalse,
            reason: 'refinement must not run when items fail validation');
        final err = result.getError();
        expect(err, isA<SchemaNestedError>());
        expect(
          (err as SchemaNestedError).errors.single.path,
          equals('#/0'),
        );
      },
    );

    test('encode rejects null item even when item schema is nullable', () {
      // Regression: list items must be non-null on encode (V extends Object),
      // matching parse behaviour. A nullable item schema accepting null should
      // still produce a per-index error on encode.
      final schema = Ack.list(Ack.string().nullable());
      final result = schema.safeEncode(<Object?>[null]);
      expect(result.isFail, isTrue);
      final err = result.getError();
      expect(err, isA<SchemaNestedError>());
      expect((err as SchemaNestedError).errors.single.path, equals('#/0'));
    });

    test('encode accepts type-erased valid runtime lists', () {
      // List<Object?> with valid item types (e.g. all int) should encode
      // successfully — the override accepts any List, not strictly List<V>.
      final schema = Ack.list(Ack.integer());
      final result = schema.safeEncode(<Object?>[1, 2]);
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals([1, 2]));
    });
  });
}
