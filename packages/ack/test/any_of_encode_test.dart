import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  CodecSchema<String, int> intString() => Ack.codec<String, int>(
    input: Ack.string(),
    output: Ack.instance<int>(),
    decoder: int.parse,
    encoder: (i) => i.toString(),
  );

  group('AnyOfSchema encode (M9)', () {
    test('falls through when first branch validates but cannot encode', () {
      // First branch is a one-way CodecSchema (encoder: null). Its
      // _validateRuntime succeeds for any int, but encodeBoundary fails
      // with SchemaEncodeError.oneWayTransform. Per A5, encode must fall
      // through to the next fully-successful branch.
      final oneWay = CodecSchema<String, int>(
        inputSchema: Ack.string(),
        outputSchema: Ack.instance<int>(),
        decoder: int.parse,
        // encoder: null
      );
      final twoWay = intString();
      final schema = Ack.anyOf([oneWay, twoWay]);
      final result = schema.safeEncode(42);
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals('42'));
    });

    test('uses the first fully successful branch (deterministic order)', () {
      final schema = Ack.anyOf([
        Ack.codec<String, int>(
          input: Ack.string(),
          output: Ack.instance<int>(),
          decoder: int.parse,
          encoder: (_) => 'first',
        ),
        Ack.codec<String, int>(
          input: Ack.string(),
          output: Ack.instance<int>(),
          decoder: int.parse,
          encoder: (_) => 'second',
        ),
      ]);
      expect(schema.encode(1), equals('first'));
    });

    test('aggregates branch errors when no branch encodes', () {
      final schema = Ack.anyOf([Ack.string(), Ack.integer()]);
      final result = schema.safeEncode(true);
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaNestedError>());
    });

    test('accepts null when a nullable member accepts null', () {
      final schema = Ack.anyOf([Ack.string().nullable()]);
      final result = schema.safeEncode(null);
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), isNull);
    });

    test('runs AnyOf-level refinement exactly once during encode', () {
      // The refinement runs in _validateRuntime (after a winning branch).
      // It must not re-run inside encodeBoundary.
      var calls = 0;
      final schema = Ack.anyOf([intString()]).refine((value) {
        calls++;
        return value is int && value > 0;
      });
      final result = schema.safeEncode(1);
      expect(result.isOk, isTrue);
      expect(calls, equals(1));
    });

    test(
      'preserves parent path for branch failures (no synthetic segments)',
      () {
        // Branch contexts use pathSegment: '' so user-facing paths stay at
        // the parent value path, not '#/anyOf:0'.
        final schema = Ack.object({
          'value': Ack.anyOf([Ack.string(), Ack.integer()]),
        });
        final result = schema.safeEncode({'value': true});
        expect(result.isFail, isTrue);
        final objectError = result.getError();
        expect(objectError, isA<SchemaNestedError>());
        final valueError = (objectError as SchemaNestedError).errors.single;
        expect(valueError.path, equals('#/value'));
      },
    );

    test('encode is identity for a primitive branch matching the value', () {
      // No codec children: each branch is a primitive. The boundary form
      // equals the runtime form.
      final schema = Ack.anyOf([Ack.string(), Ack.integer()]);
      expect(schema.encode('hi'), equals('hi'));
      expect(schema.encode(42), equals(42));
    });

    test('encode works for AnyOf with mixed primitive + codec branches', () {
      final schema = Ack.anyOf([Ack.string(), intString()]);
      // 'hi' matches Ack.string() first.
      expect(schema.encode('hi'), equals('hi'));
      // 42 fails Ack.string()'s _validateRuntime (int is not String), then
      // falls through to intString() which encodes to '42'.
      expect(schema.encode(42), equals('42'));
    });
  });
}
