import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('TransformedSchema default handling', () {
    test('applies default when input is null', () {
      final schema = Ack.string()
          .transform((v) => v?.toUpperCase() ?? '')
          .copyWith(defaultValue: 'DEF');

      final result = schema.safeParse(null);
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals('DEF'));
    });

    test('validates default against constraints/refinements', () {
      final schema = Ack.string()
          .transform((v) => v?.toUpperCase() ?? '')
          .refine((out) => out.length >= 3, message: 'Too short')
          .copyWith(defaultValue: 'X');

      final result = schema.safeParse(null);
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaValidationError>());
    });

    test('clones primitive defaults to prevent mutation', () {
      // Primitive types (String, int, bool) are immutable, so cloning is safe
      final schema = Ack.string()
          .transform((v) => v ?? 'default')
          .copyWith(defaultValue: 'hello');

      final result1 = schema.safeParse(null);
      final result2 = schema.safeParse(null);

      expect(result1.getOrNull(), equals('hello'));
      expect(result2.getOrNull(), equals('hello'));
    });

    test('handles List<Object> defaults with cloning', () {
      // List<Object> can be cloned because cloneDefault returns List<Object?>
      // which is assignable to List<Object>
      final schema = Ack.string()
          .transform((v) => <Object>[v ?? 'default'])
          .copyWith(defaultValue: <Object>['a', 'b']);

      final result = schema.safeParse(null);
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals(['a', 'b']));
    });

    // Documents known limitation: parameterized collection defaults may not be cloned
    // because cloneDefault() returns List<Object?>/Map<Object?, Object?> which
    // cannot be safely cast to parameterized types like List<String>.
    // The implementation falls back to the original value (mutation risk).
    test('handles parameterized List<String> defaults without crashing', () {
      // This would previously crash with a TypeError because cloneDefault
      // returns List<Object?> which cannot cast to List<String>.
      // Now it falls back to the original default (accepts mutation risk).
      final schema = Ack.string()
          .transform((v) => v?.split(',') ?? <String>[])
          .copyWith(defaultValue: <String>['a', 'b', 'c']);

      final result = schema.safeParse(null);
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals(['a', 'b', 'c']));
    });
  });
}
