import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('StringSchemaExtensions enumString', () {
    test('should pass for allowed values', () {
      final schema = Ack.string().enumString(['red', 'green', 'blue']);

      expect(schema.safeParse('red').isOk, isTrue);
      expect(schema.safeParse('green').isOk, isTrue);
      expect(schema.safeParse('blue').isOk, isTrue);
    });

    test('should fail for disallowed values', () {
      final schema = Ack.string().enumString(['red', 'green', 'blue']);

      final result = schema.safeParse('yellow');
      expect(result.isOk, isFalse);
      final error = result.getError() as SchemaConstraintsError;
      expect(error.constraints.first.message,
          contains('Must be one of: "red", "green", "blue"'));
      expect(error.constraints.first.message, contains('got "yellow"'));
    });

    test('should handle empty string if allowed', () {
      final schema = Ack.string().enumString(['', 'yes', 'no']);

      expect(schema.tryParse(''), isNotNull);
    });

    test('should work with nullable string schema', () {
      final schema = Ack.string().nullable().enumString(['active', 'inactive']);

      expect(schema.tryParse(null), isNull);
      expect(schema.tryParse('active'), isNotNull);
      expect(schema.tryParse('pending'), isNull);
    });

    test('should generate correct JSON schema', () {
      final schema = Ack.string().enumString(['small', 'medium', 'large']);

      final jsonSchema = schema.toJsonSchema();
      expect(jsonSchema['type'], equals('string'));
      expect(jsonSchema['enum'], equals(['small', 'medium', 'large']));
    });
  });
}
