import 'package:ack/ack.dart';
import 'package:test/test.dart';

// Test that validates discriminated schema patterns for polymorphic models
void main() {
  group('Discriminated Schema Tests', () {
    // Define a base type and schemas for testing
    test('Can validate discriminated models with type field', () {
      // Create schemas for each subtype
      final baseSchema = Ack.object(
        {
          'type': Ack.string,
          'flex': Ack.int.nullable().min(1),
          'scrollable': Ack.boolean.nullable(),
        },
        required: ['type'],
      );

      final columnSchema = baseSchema.extend(
        {
          'content': Ack.string.nullable(),
        },
      );

      final imageSchema = baseSchema.extend(
        {
          'url': Ack.string,
          'width': Ack.double.nullable(),
          'height': Ack.double.nullable(),
        },
        required: ['url'],
      );

      // Create a discriminated schema
      final discriminatedSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'column': columnSchema,
          'image': imageSchema,
        },
      );

      // Test valid column instance
      final validColumn = {
        'type': 'column',
        'content': 'Test content',
        'flex': 2,
        'scrollable': true,
      };

      expect(discriminatedSchema.validate(validColumn).isOk, isTrue);

      // Test valid image instance
      final validImage = {
        'type': 'image',
        'url': 'https://example.com/image.png',
        'width': 100.0,
        'height': 100.0,
      };

      expect(discriminatedSchema.validate(validImage).isOk, isTrue);

      // Test invalid type
      final invalidType = {
        'type': 'unknown',
        'content': 'Test content',
      };

      expect(discriminatedSchema.validate(invalidType).isOk, isFalse);

      // Test missing discriminator
      final missingType = {
        'content': 'Test content',
      };

      expect(discriminatedSchema.validate(missingType).isOk, isFalse);

      // Test missing required field
      final missingRequired = {
        'type': 'image',
        'width': 100.0,
        'height': 100.0,
      };

      expect(discriminatedSchema.validate(missingRequired).isOk, isFalse);
    });

    test('Can build complex discriminated models with nested objects', () {
      // Define enum schema for alignments
      final alignmentSchema = Ack.enumString(['left', 'center', 'right']);

      // Create component schema
      final componentSchema = Ack.object(
        {
          'id': Ack.string,
          'required': Ack.boolean.nullable(),
        },
        required: ['id'],
      );

      // Create base block schema
      final blockSchema = Ack.object(
        {
          'type': Ack.string,
          'align': alignmentSchema.nullable(),
          'flex': Ack.int.nullable().min(1),
          'scrollable': Ack.boolean.nullable(),
        },
        required: ['type'],
      );

      // First create individual schema types
      final columnSchema = blockSchema.extend(
        {
          'content': Ack.string.nullable(),
        },
      );

      final widgetSchema = blockSchema.extend(
        {
          'name': Ack.string,
          'components': componentSchema.list.nullable(),
        },
        required: ['name'],
        additionalProperties: true, // Allows extra properties
      );

      // Now create a map for block types we'll use in multiple places
      final blockTypes = {
        'column': columnSchema,
        'widget': widgetSchema,
      };

      // Create section schema that contains blocks
      final sectionSchema = blockSchema.extend(
        {
          'blocks': Ack.discriminated(
            discriminatorKey: 'type',
            schemas: blockTypes,
          ).list.nullable(),
        },
      );

      // Schemas already defined above

      // Create final discriminated schema with self-referencing
      // This is a complex case: a discriminated schema that can contain itself
      final discriminatedBlockSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'section': sectionSchema,
          'column': columnSchema,
          'widget': widgetSchema,
        },
      );

      // Test a complex nested structure
      final complexBlock = {
        'type': 'section',
        'align': 'center',
        'blocks': [
          {
            'type': 'column',
            'content': 'Left side content',
            'align': 'left',
            'flex': 1,
          },
          {
            'type': 'widget',
            'name': 'CustomWidget',
            'align': 'right',
            'flex': 2,
            'components': [
              {'id': 'comp1'},
              {'id': 'comp2', 'required': true},
            ],
            'customProp': 'This is allowed due to additionalProperties',
          },
        ],
      };

      // Validate the complex structure
      final result = discriminatedBlockSchema.validate(complexBlock);

      // Print detailed info about the result
      print('Validation result isOk: ${result.isOk}');
      if (result.isFail) {
        final error = result.getError();
        print('Validation error: $error');
        print('Error details: ${error.toMap()}');
      }

      expect(result.isOk, isTrue);

      // Test invalid nested structure
      final invalidNestedBlock = {
        'type': 'section',
        'blocks': [
          {
            'type': 'unknown', // Invalid type
            'content': 'Something',
          },
        ],
      };

      expect(
        discriminatedBlockSchema.validate(invalidNestedBlock).isOk,
        isFalse,
      );
    });
  });
}
