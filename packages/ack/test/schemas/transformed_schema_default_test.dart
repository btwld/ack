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
  });
}
