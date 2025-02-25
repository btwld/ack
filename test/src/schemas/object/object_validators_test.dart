import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../../test_helpers.dart';

void main() {
  group('Object Validators', () {
    test('Fails on additional unallowed property', () {
      final schema = ObjectSchema(
          {
            'age': IntegerSchema(),
          },
          additionalProperties: false,
          required: ['age']);
      final result = schema.validate({'age': 25, 'name': 'John'});
      expect(result.isFail, isTrue);
      expect(result, hasOneConstraintError('object_property_unallowed'));
    });

    test('Fails on missing required property', () {
      final schema = ObjectSchema(
          {
            'age': IntegerSchema(),
            'name': StringSchema(),
          },
          additionalProperties: true,
          required: ['age']);
      final result = schema.validate({'name': 'John'});
      expect(result.isFail, isTrue);
      expect(result, hasOneConstraintError('object_property_required'));
    });

    test('Fails on property schema error', () {
      // Assuming IntSchema validates that the value must be an integer.
      final schema = ObjectSchema(
          {
            'age': IntegerSchema(),
          },
          additionalProperties: true,
          required: ['age']);
      final result = schema.validate({'age': 'not an int'});
      expect(result, hasOneSchemaError(PathSchemaError.key));

      final failResult = result as Fail;
      final nestedSchemaError = failResult.pathSchemaError.first;
      expect(nestedSchemaError.path, 'age');
      expect(nestedSchemaError.errors, hasOneSchemaError('invalid_type'));
    });
  });
}
