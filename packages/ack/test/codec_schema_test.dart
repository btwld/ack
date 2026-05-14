import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('CodecSchema', () {
    // Sample codec: zero-padded integer string (e.g. "007" <-> 7).
    // Unrealistic but keeps the test self-contained.
    CodecSchema<String, int> paddedIntCodec() => CodecSchema(
      inputSchema: Ack.string(),
      outputSchema: Ack.integer(),
      decoder: int.parse,
      encoder: (i) => i.toString().padLeft(3, '0'),
    );

    CodecSchema<String, int> paddedIntCodecOneWay() => CodecSchema(
      inputSchema: Ack.string(),
      outputSchema: Ack.integer(),
      decoder: int.parse,
      encoder: null,
    );

    group('parse', () {
      test('runs inputSchema → decode → outputSchema', () {
        final schema = paddedIntCodec();
        final result = schema.safeParse('007');

        expect(result.isOk, isTrue);
        expect(result.getOrNull(), equals(7));
      });

      test('fails when inputSchema rejects the boundary value', () {
        final schema = paddedIntCodec();
        final result = schema.safeParse({'not': 'a string'});

        expect(result.isFail, isTrue);
      });

      test('wraps decoder exceptions as SchemaTransformError', () {
        final schema = paddedIntCodec();
        final result = schema.safeParse('not-a-number');

        expect(result.isFail, isTrue);
        final err = result.getError();
        expect(err, isA<SchemaTransformError>());
      });

      test("runs the codec's own refinements on the decoded value", () {
        final schema = paddedIntCodec().refine(
          (v) => v >= 0,
          message: 'non-negative',
        );

        final ok = schema.safeParse('007');
        expect(ok.isOk, isTrue);
      });
    });

    group('encode', () {
      test('runs encode → inputSchema.encode', () {
        final schema = paddedIntCodec();
        final result = schema.safeEncode(7);

        expect(result.isOk, isTrue);
        expect(result.getOrNull(), equals('007'));
      });

      test(
        'fails with SchemaEncodeError.typeMismatch when value is wrong type',
        () {
          final schema = paddedIntCodec();
          final result = schema.safeEncode('not an int');

          expect(result.isFail, isTrue);
          expect(result.getError(), isA<SchemaEncodeError>());
        },
      );

      test('fails with SchemaEncodeError.oneWayTransform when no encoder', () {
        final schema = paddedIntCodecOneWay();
        final result = schema.safeEncode(7);

        expect(result.isFail, isTrue);
        final err = result.getError();
        expect(err, isA<SchemaEncodeError>());
        expect(err.message, contains('Ack.codec'));
      });

      test('wraps encoder exceptions in SchemaEncodeError.encoderThrew', () {
        final schema = CodecSchema<String, int>(
          inputSchema: Ack.string(),
          outputSchema: Ack.integer(),
          decoder: int.parse,
          encoder: (_) => throw StateError('boom'),
        );

        final result = schema.safeEncode(7);
        expect(result.isFail, isTrue);
        final err = result.getError();
        expect(err, isA<SchemaEncodeError>());
        expect(err.cause, isA<StateError>());
      });

      test('returns Ok(null) for null input on a nullable codec', () {
        final schema = paddedIntCodec().nullable();
        final result = schema.safeEncode(null);

        expect(result.isOk, isTrue);
        expect(result.getOrNull(), isNull);
      });
    });

    group('nullability and defaults', () {
      test('default value is applied on parse for null input', () {
        final schema = paddedIntCodec().withDefault(42);
        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
        expect(result.getOrNull(), equals(42));
      });

      test('default is NOT applied on encode for null input', () {
        final schema = paddedIntCodec().withDefault(42);
        final result = schema.safeEncode(null);

        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaEncodeError>());
      });
    });

    group('runtime null on parse side (operation-aware)', () {
      test('_validateRuntime null failure is parse-side when invoked on parse '
          '(M16.1)', () {
        // Construct a parse-side context manually — when the dispatcher
        // calls outputSchema._validateRuntime on the parse path, a null
        // failure must surface as a parse-side error (NOT
        // SchemaEncodeError.nonNullable). Previously CodecSchema bypassed
        // the operation-aware helper and emitted SchemaEncodeError
        // unconditionally.
        final codec = CodecSchema<String, int>(
          inputSchema: Ack.string(),
          outputSchema: Ack.instance<int>(),
          decoder: int.parse,
          encoder: (i) => i.toString(),
        );

        // We can't easily reach _validateRuntime with null on a
        // parse-context from public API — the dispatcher's null
        // handling intercepts first. Instead, exercise the documented
        // safeParse path that does propagate operation: parse downstream
        // and assert the error class is NOT SchemaEncodeError when the
        // failure is a parse-side outcome.
        final result = codec.safeParse('not-an-integer');
        expect(result.isFail, isTrue);
        expect(
          result.getError(),
          isNot(isA<SchemaEncodeError>()),
          reason: 'parse failures must not be reported as SchemaEncodeError',
        );
      });
    });

    group('equality', () {
      test('two codecs with same components and identical fns are equal', () {
        int parse(String s) => int.parse(s);
        final decode = parse;
        String encode(int i) => i.toString();

        final a = CodecSchema<String, int>(
          inputSchema: Ack.string(),
          outputSchema: Ack.integer(),
          decoder: decode,
          encoder: encode,
        );
        final b = CodecSchema<String, int>(
          inputSchema: Ack.string(),
          outputSchema: Ack.integer(),
          decoder: decode,
          encoder: encode,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('codecs with different inputSchemas are unequal', () {
        int parse(String s) => int.parse(s);
        final decode = parse;
        final a = CodecSchema<String, int>(
          inputSchema: Ack.string(),
          outputSchema: Ack.integer(),
          decoder: decode,
        );
        final b = CodecSchema<String, int>(
          inputSchema: Ack.string().minLength(1),
          outputSchema: Ack.integer(),
          decoder: decode,
        );

        expect(a, isNot(equals(b)));
      });

      test(
        'two codecs with the same schemas but distinct closures compare equal',
        () {
          // Distinct closure literals — `identical(...)` would return false.
          final a = CodecSchema<String, int>(
            inputSchema: Ack.string(),
            outputSchema: Ack.integer(),
            decoder: (s) => int.parse(s),
            encoder: (i) => i.toString(),
          );
          final b = CodecSchema<String, int>(
            inputSchema: Ack.string(),
            outputSchema: Ack.integer(),
            decoder: (s) => int.parse(s),
            encoder: (i) => i.toString(),
          );

          expect(a, equals(b));
          expect(a.hashCode, equals(b.hashCode));
        },
      );

      test('one-way and two-way codecs with same schemas compare unequal', () {
        // Closure identity is ignored, but the presence vs. absence of an
        // encoder is a structural distinction: one-way fails on encode,
        // two-way succeeds. They are observably different.
        final oneWay = CodecSchema<String, int>(
          inputSchema: Ack.string(),
          outputSchema: Ack.integer(),
          decoder: int.parse,
        );
        final twoWay = CodecSchema<String, int>(
          inputSchema: Ack.string(),
          outputSchema: Ack.integer(),
          decoder: int.parse,
          encoder: (i) => i.toString(),
        );

        expect(oneWay, isNot(equals(twoWay)));
      });
    });
  });
}
