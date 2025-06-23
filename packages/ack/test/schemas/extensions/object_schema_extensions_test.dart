import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('ObjectSchemaExtensions', () {
    final userSchema = ObjectSchema(
      {
        'name': StringSchema(),
        'email': StringSchema().email(),
      },
      required: ['name', 'email'],
    );

    group('strict', () {
      test('should fail with additional properties', () {
        final schema = userSchema.strict();
        final result = schema.validate({
          'name': 'Leo',
          'email': 'leo@example.com',
          'extra': 'field',
        });
        expect(result.isOk, isFalse);
        final error = result.getError() as SchemaNestedError;
        final constraintError = error.errors.first as SchemaConstraintsError;
        expect(constraintError.constraints.first.message,
            'Property "extra" is not allowed.');
      });

      test('should pass without additional properties', () {
        final schema = userSchema.strict();
        final result = schema.validate({
          'name': 'Leo',
          'email': 'leo@example.com',
        });
        expect(result.isOk, isTrue);
      });
    });

    group('passthrough', () {
      test('should pass with additional properties', () {
        final schema = userSchema.passthrough();
        final result = schema.validate({
          'name': 'Leo',
          'email': 'leo@example.com',
          'extra': 'field',
        });
        expect(result.isOk, isTrue);
      });
    });

    group('merge', () {
      test('should merge properties and required fields', () {
        final addressSchema = ObjectSchema(
          {'street': StringSchema()},
          required: ['street'],
        );
        final mergedSchema = userSchema.merge(addressSchema);
        final result = mergedSchema.validate({
          'name': 'Leo',
          'email': 'leo@example.com',
          'street': '123 Main St',
        });
        expect(result.isOk, isTrue);

        final result2 =
            mergedSchema.validate({'name': 'Leo', 'email': 'leo@example.com'});
        expect(result2.isOk, isFalse);
        final error = result2.getError() as SchemaNestedError;
        final constraintError = error.errors.first as SchemaConstraintsError;
        expect(constraintError.constraints.first.message,
            'Required property "street" is missing.');
      });
    });

    group('partial', () {
      test('should make all properties optional', () {
        final partialSchema = userSchema.partial();
        final result = partialSchema.validate({'name': 'Leo'});
        expect(result.isOk, isTrue);
      });
    });

    group('pick', () {
      test('should pick specified properties and be strict by default', () {
        final pickedSchema = userSchema.pick(['name']);
        final result = pickedSchema.validate({'name': 'Leo'});
        expect(result.isOk, isTrue);

        final result2 =
            pickedSchema.validate({'name': 'Leo', 'email': 'a@b.com'});
        expect(result2.isOk, isFalse);
        final error = result2.getError() as SchemaNestedError;
        final constraintError = error.errors.first as SchemaConstraintsError;
        expect(constraintError.constraints.first.message,
            'Property "email" is not allowed.');
      });

      test('picked schema can be made to passthrough', () {
        final pickedSchema = userSchema.pick(['name']).passthrough();
        final result =
            pickedSchema.validate({'name': 'Leo', 'email': 'a@b.com'});
        expect(result.isOk, isTrue);
      });
    });

    group('omit', () {
      test('should omit specified properties', () {
        final omittedSchema = userSchema.omit(['email']);
        final result = omittedSchema.validate({'name': 'Leo'});
        expect(result.isOk, isTrue);

        final result2 = omittedSchema.validate({'email': 'a@b.com'});
        expect(result2.isOk, isFalse);
        final error = result2.getError() as SchemaNestedError;
        final constraintError = error.errors.first as SchemaConstraintsError;
        expect(constraintError.constraints.first.message,
            'Required property "name" is missing.');
      });
    });
  });
}
