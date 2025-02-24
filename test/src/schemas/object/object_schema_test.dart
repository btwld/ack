import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../../test_helpers.dart';

void main() {
  group('ObjectSchema', () {
    test('copyWith changes additionalProperties and required', () {
      final schema = ObjectSchema(
          {
            'age': IntSchema(),
          },
          additionalProperties: false,
          required: ['age']);
      final newSchema = schema.copyWith(additionalProperties: true);
      // With additionalProperties set to true, extra keys should be allowed.
      final result = newSchema.validate({'age': 30, 'extra': 'value'});
      expect(result.isOk, isTrue);
    });

    test('Non-nullable schema fails on null', () {
      final schema = ObjectSchema({
        'age': IntSchema(),
      });
      final result = schema.validate(null);
      expect(result.isFail, isTrue);
      expect(result, hasOneSchemaError('non_nullable_value'));
    });

    test('Nullable schema passes on null', () {
      final schema = ObjectSchema({
        'age': IntSchema(),
      }, nullable: true);
      final result = schema.validate(null);
      expect(result.isOk, isTrue);
    });

    test('Invalid type returns invalid type error', () {
      final schema = ObjectSchema({
        'age': IntSchema(),
      });
      final result = schema.validate('not a map');
      expect(result.isFail, isTrue);
      expect(result, hasOneSchemaError('invalid_type'));
    });

    test('Valid object passes with correct properties', () {
      final schema = ObjectSchema(
          {
            'age': IntSchema(),
          },
          additionalProperties: false,
          required: ['age']);
      final result = schema.validate({'age': 25});
      expect(result.isOk, isTrue);
    });

    test('extend merges properties correctly', () {
      final baseSchema = ObjectSchema({
        'age': IntSchema(),
      }, additionalProperties: false);
      // Extend the schema by adding a new property 'score'
      final extendedSchema = baseSchema.extend(
          {
            'score': IntSchema(),
          },
          additionalProperties: false,
          required: ['score']);
      final result = extendedSchema.validate({'age': 30, 'score': 100});
      expect(result.isOk, isTrue);
    });
  });
}
