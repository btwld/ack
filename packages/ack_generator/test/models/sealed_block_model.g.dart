// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_this, unnecessary_new, unnecessary_const, prefer_collection_literals
// ignore_for_file: lines_longer_than_80_chars, unnecessary_null_checks, non_constant_identifier_names

part of 'sealed_block_model.dart';

/// Generated schema for SealedBlock
/// Base block class with polymorphic subclasses
class SealedBlockSchema {
  // Schema definition as a static field
  static final DiscriminatedObjectSchema schema = _createSchema();

  // Create the validation schema
  static DiscriminatedObjectSchema _createSchema() {
    // Define base properties for all block types
    final baseProperties = {
      'type': Ack.string,
      'align': Ack.string.nullable(),
      'flex': Ack.int.nullable(),
      'scrollable': Ack.boolean.nullable(),
    };

    // Define individual schemas for each subtype
    final textBlockSchema = Ack.object({
      ...baseProperties,
      'content': Ack.string,
    }, required: ['type', 'content']);

    final imageBlockSchema = Ack.object({
      ...baseProperties,
      'src': Ack.string,
      'width': Ack.double.nullable(),
      'height': Ack.double.nullable(),
      'fit': Ack.string.nullable(),
    }, required: ['type', 'src']);

    final widgetBlockSchema = Ack.object({
      ...baseProperties,
      'name': Ack.string,
    }, 
    required: ['type', 'name'],
    additionalProperties: true);

    // Create the discriminated schema
    return Ack.discriminated(
      discriminatorKey: 'type',
      schemas: {
        'text': textBlockSchema,
        'image': imageBlockSchema,
        'widget': widgetBlockSchema,
      },
    );
  }

  // Static parse method to correctly instantiate the appropriate subtype
  static SealedBlock parseModel(Map<String, dynamic> json) {
    final validationResult = schema.validate(json);
    if (validationResult.isFail) {
      throw AckException(validationResult.getError()!);
    }
    
    // Use the discriminator field to determine which subclass to instantiate
    switch (json['type']) {
      case 'text':
        return TextBlock(
          align: json['align'] as String?,
          flex: json['flex'] as int?,
          scrollable: json['scrollable'] as bool?,
          content: json['content'] as String,
        );
      
      case 'image':
        return ImageBlock(
          align: json['align'] as String?,
          flex: json['flex'] as int?,
          scrollable: json['scrollable'] as bool?,
          src: json['src'] as String,
          width: json['width'] as double?,
          height: json['height'] as double?,
          fit: json['fit'] as String?,
        );
      
      case 'widget':
        // Extract additional properties
        final Map<String, dynamic> properties = Map.of(json);
        // Remove standard fields
        properties.remove('type');
        properties.remove('align');
        properties.remove('flex');
        properties.remove('scrollable');
        properties.remove('name');
        
        return WidgetBlock(
          align: json['align'] as String?,
          flex: json['flex'] as int?,
          scrollable: json['scrollable'] as bool?,
          name: json['name'] as String,
          properties: properties,
        );
      
      default:
        throw AckException.validation('Unknown block type: ${json["type"]}');
    }
  }
}

/// Generated schema for TextBlock
/// A text block with markdown content
class TextBlockSchema {
  // Schema definition
  static final ObjectSchema schema = Ack.object({
    'type': Ack.string.literal('text'),
    'align': Ack.string.nullable(),
    'flex': Ack.int.nullable(),
    'scrollable': Ack.boolean.nullable(),
    'content': Ack.string,
  }, required: ['type', 'content']);
}

/// Generated schema for ImageBlock
/// An image block with image source and attributes
class ImageBlockSchema {
  // Schema definition
  static final ObjectSchema schema = Ack.object({
    'type': Ack.string.literal('image'),
    'align': Ack.string.nullable(),
    'flex': Ack.int.nullable(),
    'scrollable': Ack.boolean.nullable(),
    'src': Ack.string,
    'width': Ack.double.nullable(),
    'height': Ack.double.nullable(),
    'fit': Ack.string.nullable(),
  }, required: ['type', 'src']);
}

/// Generated schema for WidgetBlock
/// A widget block with custom properties
class WidgetBlockSchema {
  // Schema definition
  static final ObjectSchema schema = Ack.object({
    'type': Ack.string.literal('widget'),
    'align': Ack.string.nullable(),
    'flex': Ack.int.nullable(),
    'scrollable': Ack.boolean.nullable(),
    'name': Ack.string,
  }, 
  required: ['type', 'name'],
  additionalProperties: true);
}