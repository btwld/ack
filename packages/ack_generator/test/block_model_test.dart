import 'package:test/test.dart';
import 'package:ack/ack.dart';

// Test for validating the specific Block model pattern shown in the example
void main() {
  group('Block Model Pattern Tests', () {
    // Helper function to create an enum schema
    StringSchema ackEnum(List<String> values) {
      return Ack.enumString(values);
    }

    // Define schemas
    test('Can validate Block model pattern with discriminated schemas', () {
      // Define ContentAlignment enum
      final contentAlignmentSchema = ackEnum([
        'topLeft',
        'topCenter',
        'topRight',
        'centerLeft',
        'center',
        'centerRight',
        'bottomLeft',
        'bottomCenter',
        'bottomRight'
      ]);

      // Create base Block schema
      final blockSchema = Ack.object(
        {
          'type': Ack.string,
          'align': contentAlignmentSchema.nullable(),
          'flex': Ack.int.nullable().min(1),
          'scrollable': Ack.boolean.nullable(),
        },
        required: ['type'],
        additionalProperties: true,
      );

      // Column block schema
      final columnSchema = blockSchema.extend(
        {
          'content': Ack.string.nullable(),
        },
      );

      // Image fit enum
      final imageFitSchema = ackEnum([
        'fill',
        'contain',
        'cover',
        'fitWidth',
        'fitHeight',
        'none',
        'scaleDown'
      ]);

      // Asset schema
      final assetSchema = Ack.object(
        {
          'path': Ack.string,
          'width': Ack.double.nullable(),
          'height': Ack.double.nullable(),
        },
        required: ['path'],
      );

      // Image block schema
      final imageSchema = blockSchema.extend(
        {
          'fit': imageFitSchema.nullable(),
          'asset': assetSchema,
          'width': Ack.double.nullable(),
          'height': Ack.double.nullable(),
        },
        required: ['asset'],
      );

      // DartPad theme enum
      final dartPadThemeSchema = ackEnum(['dark', 'light']);

      // DartPad block schema
      final dartPadSchema = blockSchema.extend(
        {
          'id': Ack.string,
          'theme': dartPadThemeSchema.nullable(),
          'embed': Ack.boolean.nullable(),
          'run': Ack.boolean.nullable(),
        },
        required: ['id'],
      );

      // Widget block schema with additionalProperties
      final widgetSchema = blockSchema.extend(
        {
          'name': Ack.string,
        },
        required: ['name'],
        additionalProperties: true,
      );

      // Now create the discriminated schema
      final discriminatedBlockSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'column': columnSchema,
          'image': imageSchema,
          'dartpad': dartPadSchema,
          'widget': widgetSchema,
        },
      );

      // Test a valid column block
      final columnBlock = {
        'type': 'column',
        'content': 'Some content',
        'align': 'center',
        'flex': 2,
      };

      expect(discriminatedBlockSchema.validate(columnBlock).isOk, isTrue);

      // Test a valid image block
      final imageBlock = {
        'type': 'image',
        'asset': {
          'path': '/images/logo.png',
          'width': 300.0,
        },
        'fit': 'contain',
        'width': 400.0,
        'height': 300.0,
      };

      expect(discriminatedBlockSchema.validate(imageBlock).isOk, isTrue);

      // Test a valid dartpad block
      final dartpadBlock = {
        'type': 'dartpad',
        'id': 'abcdef123456',
        'theme': 'dark',
        'embed': true,
        'run': true,
      };

      expect(discriminatedBlockSchema.validate(dartpadBlock).isOk, isTrue);

      // Test a valid widget block with additional properties
      final widgetBlock = {
        'type': 'widget',
        'name': 'CustomWidget',
        'align': 'topRight',
        'flex': 3,
        'customProp1': 'value1',
        'customProp2': 123,
        'customProp3': {'nestedProp': true},
      };

      expect(discriminatedBlockSchema.validate(widgetBlock).isOk, isTrue);

      // Test an invalid block (missing required property)
      final invalidBlock = {
        'type': 'image',
        'fit': 'contain',
        // Missing 'asset' which is required
      };

      expect(discriminatedBlockSchema.validate(invalidBlock).isOk, isFalse);

      // Test an unknown type
      final unknownTypeBlock = {
        'type': 'unknown',
        'content': 'Something',
      };

      expect(discriminatedBlockSchema.validate(unknownTypeBlock).isOk, isFalse);
    });

    test('Can use static discriminated schema in models', () {
      // This test simulates the pattern used in the example where
      // a static discriminatedSchema field exists on the parent class

      // Create schemas for the test
      final baseSchema = Ack.object(
        {
          'type': Ack.string,
        },
        required: ['type'],
      );

      final typeASchema = baseSchema.extend({'propA': Ack.string});
      final typeBSchema = baseSchema.extend({'propB': Ack.int});
      final typeCSchema = baseSchema.extend({'propC': Ack.boolean});

      // Create "static" discriminated schema
      final staticDiscriminatedSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'typeA': typeASchema,
          'typeB': typeBSchema,
          'typeC': typeCSchema,
        },
      );

      // Create objects to validate
      final validA = {'type': 'typeA', 'propA': 'value'};
      final validB = {'type': 'typeB', 'propB': 42};
      final validC = {'type': 'typeC', 'propC': true};

      // Validate all objects using the discriminated schema
      expect(staticDiscriminatedSchema.validate(validA).isOk, isTrue);
      expect(staticDiscriminatedSchema.validate(validB).isOk, isTrue);
      expect(staticDiscriminatedSchema.validate(validC).isOk, isTrue);

      // Test the parse method pattern similar to the example
      // This simulates:
      // static Block parse(Map<String, dynamic> map) {
      //   discriminatedSchema.validateOrThrow(map);
      //   return BlockMapper.fromMap(map);
      // }

      // Helper function to simulate validateOrThrow
      void validateOrThrow(Map<String, dynamic> map) {
        final result = staticDiscriminatedSchema.validate(map);
        if (result.isFail) {
          throw Exception('Validation failed: ${result.getError()}');
        }
      }

      // Test that validateOrThrow works as expected
      expect(() => validateOrThrow(validA), returnsNormally);
      expect(() => validateOrThrow({'type': 'unknown'}), throwsException);
    });
  });
}
