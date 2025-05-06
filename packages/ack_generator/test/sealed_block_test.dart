import 'package:test/test.dart';

import 'models/sealed_block_model.dart';

void main() {
  group('Generated Sealed Block Model Tests', () {
    test('Can parse and validate TextBlock with discriminated type', () {
      // Create a JSON map for a text block
      final json = {
        'type': 'text',
        'align': 'center',
        'flex': 2,
        'content': 'This is a **markdown** text block',
      };

      // Validate with the discriminated schema
      final validationResult = SealedBlockSchema.schema.validate(json);
      expect(validationResult.isOk, isTrue);

      // Parse into the correct model type
      final schema = SealedBlockSchema(json);
      final block = schema.toModel();

      // Verify it's the correct type
      expect(block, isA<TextBlock>());

      // Check properties
      final textBlock = block as TextBlock;
      expect(textBlock.type, equals('text'));
      expect(textBlock.align, equals('center'));
      expect(textBlock.flex, equals(2));
      expect(textBlock.content, equals('This is a **markdown** text block'));

      // Verify round-trip serialization
      final roundTripJson = textBlock.toJson();
      expect(roundTripJson['type'], equals('text'));
      expect(
        roundTripJson['content'],
        equals('This is a **markdown** text block'),
      );

      // Parse the round-tripped JSON
      final roundTripSchema = SealedBlockSchema(roundTripJson);
      final roundTripBlock = roundTripSchema.toModel();
      expect(roundTripBlock, isA<TextBlock>());
    });

    test('Can parse and validate ImageBlock with discriminated type', () {
      // Create a JSON map for an image block
      final json = {
        'type': 'image',
        'align': 'left',
        'src': 'https://example.com/image.png',
        'width': 300.0,
        'height': 200.0,
        'fit': 'cover',
      };

      // Validate with the discriminated schema
      final validationResult = SealedBlockSchema.schema.validate(json);
      expect(validationResult.isOk, isTrue);

      // Parse into the correct model type
      final schema = SealedBlockSchema(json);
      final block = schema.toModel();

      // Verify it's the correct type
      expect(block, isA<ImageBlock>());

      // Check properties
      final imageBlock = block as ImageBlock;
      expect(imageBlock.type, equals('image'));
      expect(imageBlock.align, equals('left'));
      expect(imageBlock.src, equals('https://example.com/image.png'));
      expect(imageBlock.width, equals(300.0));
      expect(imageBlock.height, equals(200.0));
      expect(imageBlock.fit, equals('cover'));

      // Verify round-trip serialization
      final roundTripJson = imageBlock.toJson();
      expect(roundTripJson['type'], equals('image'));
      expect(roundTripJson['src'], equals('https://example.com/image.png'));

      // Parse the round-tripped JSON
      final roundTripSchema = SealedBlockSchema(roundTripJson);
      final roundTripBlock = roundTripSchema.toModel();
      expect(roundTripBlock, isA<ImageBlock>());
    });

    test('Can parse and validate WidgetBlock with custom properties', () {
      // Create a JSON map for a widget block with custom properties
      final json = {
        'type': 'widget',
        'name': 'CustomWidget',
        'align': 'right',
        'flex': 3,
        'customParam1': 'value1',
        'customParam2': 42,
        'nestedObject': {
          'key': 'value',
          'enabled': true,
        },
      };

      // Validate with the discriminated schema
      final validationResult = SealedBlockSchema.schema.validate(json);
      expect(validationResult.isOk, isTrue);

      // Parse into the correct model type
      final schema = SealedBlockSchema(json);
      final block = schema.toModel();

      // Verify it's the correct type
      expect(block, isA<WidgetBlock>());

      // Check properties
      final widgetBlock = block as WidgetBlock;
      expect(widgetBlock.type, equals('widget'));
      expect(widgetBlock.align, equals('right'));
      expect(widgetBlock.flex, equals(3));
      expect(widgetBlock.name, equals('CustomWidget'));

      // Check custom properties were captured
      expect(widgetBlock.properties['customParam1'], equals('value1'));
      expect(widgetBlock.properties['customParam2'], equals(42));
      expect(widgetBlock.properties['nestedObject'], isA<Map>());

      // Verify round-trip serialization
      final roundTripJson = widgetBlock.toJson();
      expect(roundTripJson['type'], equals('widget'));
      expect(roundTripJson['name'], equals('CustomWidget'));
      expect(roundTripJson['customParam1'], equals('value1'));
      expect(roundTripJson['customParam2'], equals(42));

      // Parse the round-tripped JSON
      final roundTripSchema = SealedBlockSchema(roundTripJson);
      final roundTripBlock = roundTripSchema.toModel();
      expect(roundTripBlock, isA<WidgetBlock>());
    });

    test('Rejects invalid block with discriminated validation', () {
      // Missing required property (content for text block)
      final invalidJson = {
        'type': 'text',
        'align': 'center',
        // Missing 'content' which is required
      };

      // Validation should fail
      final validationResult = SealedBlockSchema.schema.validate(invalidJson);
      expect(validationResult.isOk, isFalse);

      // Parsing should throw an exception
      expect(
        () {
          final schema = SealedBlockSchema(invalidJson);
          schema.toModel();
        },
        throwsException,
      );
    });

    test('Rejects unknown block type with discriminated validation', () {
      // Unknown block type
      final unknownTypeJson = {
        'type': 'unknown',
        'content': 'Some content',
      };

      // Validation should fail
      final validationResult =
          SealedBlockSchema.schema.validate(unknownTypeJson);
      expect(validationResult.isOk, isFalse);

      // Parsing should throw an exception
      expect(
        () {
          final schema = SealedBlockSchema(unknownTypeJson);
          schema.toModel();
        },
        throwsException,
      );
    });
  });
}
