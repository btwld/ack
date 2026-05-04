import 'package:ack/ack.dart';
import 'package:test/test.dart';

class _Color {
  final String hex;
  const _Color(this.hex);
}

void main() {
  group('InstanceSchema parse', () {
    test('accepts matching instance', () {
      final schema = Ack.instance<DateTime>();
      final dt = DateTime(2026, 5, 4);
      expect(schema.parse(dt), same(dt));
    });

    test('rejects wrong runtime type', () {
      final schema = Ack.instance<DateTime>();
      final result = schema.safeParse('not a datetime');
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaValidationError>());
    });

    test('refine runs during parse', () {
      final schema = Ack.instance<_Color>().refine(
        (c) => c.hex.startsWith('#'),
        message: 'must start with #',
      );
      expect(schema.parse(const _Color('#fff'))?.hex, equals('#fff'));

      final fail = schema.safeParse(const _Color('fff'));
      expect(fail.isFail, isTrue);
    });
  });

  group('InstanceSchema encode', () {
    test('returns the instance unchanged', () {
      final schema = Ack.instance<DateTime>();
      final dt = DateTime(2026, 5, 4);
      expect(schema.encode(dt), same(dt));
    });

    test('rejects wrong runtime type', () {
      final schema = Ack.instance<DateTime>();
      final result = schema.safeEncode('nope');
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('refine runs during encode', () {
      final schema = Ack.instance<_Color>().refine(
        (c) => c.hex.startsWith('#'),
        message: 'must start with #',
      );
      expect(schema.encode(const _Color('#abc')), isA<_Color>());

      final fail = schema.safeEncode(const _Color('abc'));
      expect(fail.isFail, isTrue);
    });
  });

  group('InstanceSchema null semantics', () {
    test('nullable accepts null on parse and encode', () {
      final schema = Ack.instance<DateTime>().nullable();
      expect(schema.parse(null), isNull);
      expect(schema.encode(null), isNull);
    });

    test('non-nullable rejects null on encode', () {
      final result = Ack.instance<DateTime>().safeEncode(null);
      expect(result.isFail, isTrue);
    });
  });
}
