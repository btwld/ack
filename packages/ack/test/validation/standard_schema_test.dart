import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('StandardSchemaV1', () {
    test('exposes version 1 and vendor ack', () {
      final schema = Ack.string().minLength(3);
      final standard = schema.standard;

      expect(standard.version, equals(1));
      expect(standard.vendor, equals('ack'));
    });

    test('returns StandardSchemaSuccess on valid input', () {
      final schema = Ack.object({
        'name': Ack.string().trim(),
        'age': Ack.integer().min(0),
      });

      final result = schema.standard.validate({'name': '  Ada  ', 'age': 36});
      expect(result, isA<StandardSchemaSuccess<Map<String, Object?>>>());
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.issues, isNull);

      final success = result as StandardSchemaSuccess<Map<String, Object?>>;
      expect(success.value, equals({'name': 'Ada', 'age': 36}));
    });

    test(
      'returns StandardSchemaFailure with path segments on nested object/list errors',
      () {
        final schema = Ack.object({
          'user': Ack.object({'tags': Ack.list(Ack.string().minLength(3))}),
        });

        final result = schema.standard.validate({
          'user': {
            'tags': ['valid', 'no'],
          },
        });

        expect(result, isA<StandardSchemaFailure<Map<String, Object?>>>());
        expect(result.isFailure, isTrue);
        expect(result.isSuccess, isFalse);

        final issues = result.issues!;
        expect(issues, isNotEmpty);
        expect(issues.first.path, equals(['user', 'tags', 1]));
        expect(issues.first.message, isNotEmpty);
      },
    );

    test('delegates toJsonSchema() to underlying AckSchema', () {
      final schema = Ack.string().email();
      expect(schema.standard.toJsonSchema(), equals(schema.toJsonSchema()));
    });
  });
}
