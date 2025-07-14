import 'package:ack_generator/src/builders/schema_builder.dart';
import 'package:ack_generator/src/models/model_info.dart';
import 'package:test/test.dart';

import '../test_utilities.dart';

void main() {
  group('SchemaBuilder', () {
    late SchemaBuilder builder;

    setUp(() {
      builder = SchemaBuilder();
    });

    test('builds complete schema variable', () {
      final model = ModelInfo(
        className: 'User',
        schemaClassName: 'UserSchema',
        description: 'User model for testing',
        fields: [
          createField('id', 'String', isRequired: true),
          createField('name', 'String', isRequired: true),
          createField('email', 'String', isNullable: true),
        ],
        requiredFields: ['id', 'name'],
        additionalProperties: false,
      );

      final result = builder.build(model);

      // Check variable declaration
      expect(result, contains('final userSchema = Ack.object('));

      // Check documentation
      expect(result, contains('/// Generated schema for User'));
      expect(result, contains('/// User model for testing'));

      // Check field definitions
      expect(result, contains("'id': Ack.string()"));
      expect(result, contains("'name': Ack.string()"));
      expect(result, contains("'email': Ack.string().optional().nullable()"));
    });

    test('generates schema for primitive types', () {
      final model = ModelInfo(
        className: 'Product',
        schemaClassName: 'ProductSchema',
        fields: [
          createField('name', 'String', isRequired: true),
          createField('price', 'double', isRequired: true),
          createField('inStock', 'bool', isRequired: true),
          createField('description', 'String', isNullable: true),
        ],
        requiredFields: ['name', 'price', 'inStock'],
        additionalProperties: false,
      );

      final result = builder.build(model);

      expect(result, contains('final productSchema = Ack.object('));
      expect(result, contains("'name': Ack.string()"));
      expect(result, contains("'price': Ack.double()"));
      expect(result, contains("'inStock': Ack.boolean()"));
      expect(result,
          contains("'description': Ack.string().optional().nullable()"));
    });

    test('generates schema for list fields', () {
      final model = ModelInfo(
        className: 'Post',
        schemaClassName: 'PostSchema',
        fields: [
          createField('title', 'String', isRequired: true),
          createListField('tags', 'String'),
        ],
        requiredFields: ['title', 'tags'],
        additionalProperties: false,
      );

      final result = builder.build(model);

      expect(result, contains('final postSchema = Ack.object('));
      expect(result, contains("'title': Ack.string()"));
      expect(result, contains("'tags': Ack.list(Ack.any())"));
    });

    test('generates schema for nested objects', () {
      final model = ModelInfo(
        className: 'Order',
        schemaClassName: 'OrderSchema',
        fields: [
          createField('id', 'String', isRequired: true),
          createField('customer', 'Customer', isRequired: true),
        ],
        requiredFields: ['id', 'customer'],
        additionalProperties: false,
      );

      final result = builder.build(model);

      expect(result, contains('final orderSchema = Ack.object('));
      expect(result, contains("'id': Ack.string()"));
      expect(result, contains("'customer': customerSchema"));
    });

    test('formats output correctly', () {
      final model = ModelInfo(
        className: 'Simple',
        schemaClassName: 'SimpleSchema',
        fields: [
          createField('value', 'String', isRequired: true),
        ],
        requiredFields: ['value'],
        additionalProperties: false,
      );

      final result = builder.build(model);

      // Check that it's properly formatted
      expect(result, contains('// GENERATED CODE - DO NOT MODIFY BY HAND'));
      expect(result, contains('import \'package:ack/ack.dart\';'));
      expect(result, contains(';'));
    });

    test('handles additional properties', () {
      final model = ModelInfo(
        className: 'Flexible',
        schemaClassName: 'FlexibleSchema',
        fields: [
          createField('name', 'String', isRequired: true),
        ],
        requiredFields: ['name'],
        additionalProperties: true,
      );

      final result = builder.build(model);

      expect(result, contains('final flexibleSchema = Ack.object('));
      expect(result, contains("'name': Ack.string()"));
      expect(result, contains('additionalProperties: true'));
    });
  });
}
