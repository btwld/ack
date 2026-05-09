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
        final schema =
            paddedIntCodec().refine((v) => v >= 0, message: 'non-negative');

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

      test('fails with SchemaEncodeError.typeMismatch when value is wrong type',
          () {
        final schema = paddedIntCodec();
        final result = schema.safeEncode('not an int');

        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaEncodeError>());
      });

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
    });
  });
}
