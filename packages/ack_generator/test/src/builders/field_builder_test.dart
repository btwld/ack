import 'package:ack_generator/src/builders/field_builder.dart';
import 'package:ack_generator/src/models/constraint_info.dart';
import 'package:test/test.dart';

import '../test_utilities.dart';

void main() {
  group('FieldBuilder', () {
    late FieldBuilder builder;

    setUp(() {
      builder = FieldBuilder();
    });

    group('primitive schemas', () {
      test('builds string schema', () {
        final field = createField('name', 'String', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.string'));
      });

      test('builds integer schema', () {
        final field = createField('age', 'int', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.integer'));
      });

      test('builds double schema', () {
        final field = createField('price', 'double', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.double'));
      });

      test('builds number schema', () {
        final field = createField('value', 'num', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.number'));
      });

      test('builds boolean schema', () {
        final field = createField('active', 'bool', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.boolean'));
      });
    });

    group('nullable fields', () {
      test('adds nullable to optional fields', () {
        final field = createField('email', 'String', isNullable: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.string.nullable()'));
      });

      test('does not add nullable to required fields', () {
        final field = createField('name', 'String', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.string'));
      });
    });

    group('constraints', () {
      test('applies email constraint', () {
        final field = createField(
          'email',
          'String',
          isRequired: true,
          constraints: [ConstraintInfo(name: 'email', arguments: [])],
        );
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.string.email()'));
      });

      test('applies multiple constraints in order', () {
        final field = createField(
          'password',
          'String',
          isRequired: true,
          constraints: [
            ConstraintInfo(name: 'notEmpty', arguments: []),
            ConstraintInfo(name: 'minLength', arguments: ['8']),
            ConstraintInfo(name: 'maxLength', arguments: ['100']),
          ],
        );
        final schema = builder.buildFieldSchema(field);
        expect(schema,
            equals('Ack.string.notEmpty().minLength(8).maxLength(100)'));
      });

      test('applies numeric constraints', () {
        final field = createField(
          'age',
          'int',
          isRequired: true,
          constraints: [
            ConstraintInfo(name: 'positive', arguments: []),
            ConstraintInfo(name: 'max', arguments: ['150']),
          ],
        );
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.integer.positive().max(150)'));
      });
    });

    group('list schemas', () {
      test('builds list schema with primitive items', () {
        final field = createListField('tags', 'String');
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.list(Ack.string)'));
      });

      test('builds list schema with nested schema items', () {
        final field = createListField('users', 'User');
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.list(UserSchema().definition)'));
      });

      test('builds nullable list schema', () {
        final field = createListField('tags', 'String', isNullable: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.list(Ack.string).nullable()'));
      });
    });

    group('nested schemas', () {
      test('builds nested schema reference', () {
        final field = createField('address', 'Address', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('AddressSchema().definition'));
      });

      test('builds nullable nested schema', () {
        final field = createField('profile', 'Profile', isNullable: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('ProfileSchema().definition.nullable()'));
      });
    });

    group('map schemas', () {
      test('builds generic map schema', () {
        final field = createMapField('metadata');
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.object({}, additionalProperties: true)'));
      });
    });
  });
}
