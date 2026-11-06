import 'package:ack/ack.dart';
import 'package:test/test.dart';

final _usesJavaScriptNumberRepresentation = <num>[1e20].single is int;

void main() {
  test('preserves milliseconds within the exact range on VM and web', () {
    final schema = Ack.duration();
    for (final milliseconds in <int>[0, 1, -1, 9007199254740, -9007199254740]) {
      final parsed = schema.parse(milliseconds)!;
      expect(parsed.inMilliseconds, milliseconds);
      expect(schema.encode(parsed), milliseconds);
    }
  });

  test('retains lossless JSON integer normalization', () {
    final schema = Ack.duration();
    expect(schema.encode(schema.parse(1500.0)), 1500);
    expect(schema.encode(schema.parse(-1500.0)), -1500);
    expect(schema.safeParse(1.5).isFail, isTrue);
  });

  test('any accepted large input must round-trip without corruption', () {
    final schema = Ack.duration();
    for (final text in [
      '9007199254740991',
      '-9007199254740991',
      '9223372036854775',
      '-9223372036854775',
      '9223372036854776',
      '-9223372036854776',
      '9223372036854775807',
      '-9223372036854775808',
    ]) {
      final milliseconds = int.parse(text);
      final result = schema.safeParse(milliseconds);
      if (result.isOk) {
        final parsed = result.getOrNull()!;
        expect(parsed.inMilliseconds, milliseconds, reason: text);
        expect(schema.encode(parsed), milliseconds, reason: text);
      }
    }
  });

  group(
    'native signed 64-bit Duration bounds',
    () {
      test('accepts both whole-millisecond supported edges', () {
        final schema = Ack.duration();
        final edge = (BigInt.parse('9223372036854775807') ~/ BigInt.from(1000))
            .toInt();
        for (final milliseconds in [edge, -edge]) {
          final parsed = schema.parse(milliseconds)!;
          expect(parsed.inMilliseconds, milliseconds);
          expect(schema.encode(parsed), milliseconds);
        }
      });

      test('rejects values outside the representable microsecond range', () {
        final schema = Ack.duration();
        for (final text in [
          '9223372036854776',
          '-9223372036854776',
          '9223372036854775807',
          '-9223372036854775808',
        ]) {
          final result = schema.safeParse(int.parse(text));
          expect(result.isFail, isTrue, reason: text);
          expect(result.getError(), isA<SchemaTransformError>(), reason: text);
          expect(result.getError().cause, isA<FormatException>(), reason: text);
        }
      });
    },
    skip: _usesJavaScriptNumberRepresentation
        ? 'JavaScript does not use the native signed 64-bit representation.'
        : false,
  );
}
