import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('ObjectSchemaExtensions', () {
    final userSchema = Ack.object({
      'name': Ack.string(),
      'email': Ack.string().email(),
    });

    group('strict', () {
      test('should fail with additional properties', () {
        final schema = userSchema.strict();
        final result = schema.safeParse({
          'name': 'Leo',
          'email': 'leo@example.com',
          'extra': 'field',
        });
        expect(result.isOk, isFalse);
        final error = result.getError() as SchemaNestedError;
        final constraintError = error.errors.first as SchemaConstraintsError;
        expect(
          constraintError.constraints.first.message,
          'Property "extra" is not allowed.',
        );
      });

      test('should pass without additional properties', () {
        final schema = userSchema.strict();
        final result = schema.safeParse({
          'name': 'Leo',
          'email': 'leo@example.com',
        });
        expect(result.isOk, isTrue);
      });
    });

    group('passthrough', () {
      test('should pass with additional properties', () {
        final schema = userSchema.passthrough();
        final result = schema.safeParse({
          'name': 'Leo',
          'email': 'leo@example.com',
          'extra': 'field',
        });
        expect(result.isOk, isTrue);
      });
    });

    group('merge', () {
      test('should merge properties and required fields', () {
        final addressSchema = Ack.object({'street': Ack.string()});
        final mergedSchema = userSchema.merge(addressSchema);
        final result = mergedSchema.safeParse({
          'name': 'Leo',
          'email': 'leo@example.com',
          'street': '123 Main St',
        });
        expect(result.isOk, isTrue);

        final result2 = mergedSchema.safeParse({
          'name': 'Leo',
          'email': 'leo@example.com',
        });
        expect(result2.isOk, isFalse);
        final error = result2.getError() as SchemaNestedError;
        final constraintError = error.errors.first as SchemaConstraintsError;
        expect(
          constraintError.constraints.first.message,
          'Required property "street" is missing.',
        );
      });
    });

    group('partial', () {
      test('should make all properties optional', () {
        final partialSchema = userSchema.partial();
        final result = partialSchema.safeParse({'name': 'Leo'});
        expect(result.isOk, isTrue);
      });
    });

    group('pick', () {
      test('should pick specified properties and be strict by default', () {
        final pickedSchema = userSchema.pick(['name']);
        final result = pickedSchema.safeParse({'name': 'Leo'});
        expect(result.isOk, isTrue);

        final result2 = pickedSchema.safeParse({
          'name': 'Leo',
          'email': 'a@b.com',
        });
        expect(result2.isOk, isFalse);
        final error = result2.getError() as SchemaNestedError;
        final constraintError = error.errors.first as SchemaConstraintsError;
        expect(
          constraintError.constraints.first.message,
          'Property "email" is not allowed.',
        );
      });

      test('picked schema can be made to passthrough', () {
        final pickedSchema = userSchema.pick(['name']).passthrough();
        final result = pickedSchema.safeParse({
          'name': 'Leo',
          'email': 'a@b.com',
        });
        expect(result.isOk, isTrue);
      });
    });

    group('omit', () {
      test('should omit specified properties', () {
        final omittedSchema = userSchema.omit(['email']);
        final result = omittedSchema.safeParse({'name': 'Leo'});
        expect(result.isOk, isTrue);

        final result2 = omittedSchema.safeParse({'email': 'a@b.com'});
        expect(result2.isOk, isFalse);
        final error = result2.getError() as SchemaNestedError;
        final constraintError = error.errors.first as SchemaConstraintsError;
        expect(
          constraintError.constraints.first.message,
          'Required property "name" is missing.',
        );
      });
    });

    group('extend', () {
      test('should extend with new properties', () {
        final extendedSchema = userSchema.extend({
          'age': IntegerSchema().min(0),
          'phone': StringSchema(),
        });

        final result = extendedSchema.safeParse({
          'name': 'Leo',
          'email': 'leo@example.com',
          'age': 30,
          'phone': '+1234567890',
        });
        expect(result.isOk, isTrue);
      });

      test('should override existing properties', () {
        final extendedSchema = userSchema.extend({
          'name': StringSchema().minLength(
            5,
          ), // Override with stricter constraint
        });

        // Should fail with short name due to override
        final result = extendedSchema.safeParse({
          'name': 'Leo', // Only 3 characters
          'email': 'leo@example.com',
        });
        expect(result.isOk, isFalse);

        // Should pass with longer name
        final result2 = extendedSchema.safeParse({
          'name': 'Leonardo',
          'email': 'leo@example.com',
        });
        expect(result2.isOk, isTrue);
      });

      test('should add required fields by default', () {
        final extendedSchema = userSchema.extend({'age': Ack.integer().min(0)});

        // Should fail without age (required by default)
        final result = extendedSchema.safeParse({
          'name': 'Leo',
          'email': 'leo@example.com',
        });
        expect(result.isOk, isFalse);

        // Should pass with age
        final result2 = extendedSchema.safeParse({
          'name': 'Leo',
          'email': 'leo@example.com',
          'age': 30,
        });
        expect(result2.isOk, isTrue);
      });

      test('should override schema construction elements', () {
        final extendedSchema = userSchema.extend(
          {'extra': StringSchema()},
          additionalProperties: true,
          description: 'Extended user schema',
        );

        // Should allow additional properties
        final result = extendedSchema.safeParse({
          'name': 'Leo',
          'email': 'leo@example.com',
          'extra': 'value',
          'unknown': 'allowed',
        });
        expect(result.isOk, isTrue);

        // Check description was set
        expect(extendedSchema.description, 'Extended user schema');
      });
    });
  });
}
