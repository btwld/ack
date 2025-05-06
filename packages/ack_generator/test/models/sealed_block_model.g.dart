// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_this, unnecessary_new, unnecessary_const, prefer_collection_literals
// ignore_for_file: lines_longer_than_80_chars, unnecessary_null_checks, non_constant_identifier_names

part of 'sealed_block_model.dart';

/// Generated schema for SealedBlock
class SealedBlockSchema extends SchemaModel<SealedBlock> {
  // Schema definition
  static final DiscriminatedObjectSchema schema = _createSchema();

  // Create the validation schema
  static DiscriminatedObjectSchema _createSchema() {
    // This method will be populated at runtime when child schemas are registered
    return Ack.discriminated(
      discriminatorKey: 'type',
      schemas: {},
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<SealedBlock, SealedBlockSchema>(
      (data) => SealedBlockSchema(data),
    );

    // Child schemas will register themselves
  }

  // Constructor that validates input
  SealedBlockSchema([Object? value]) : super(value);

  @override
  AckSchema getSchema() => schema;

  // Parsing method that delegates based on discriminator
  @override
  SealedBlock parse(Object? input, {String? debugName}) {
    // Validate using the discriminated schema
    final result = schema.validate(input, debugName: debugName);
    if (result.isFail) {
      throw AckException(result.getError()!);
    }

    // Get discriminator value
    final json = input as Map<String, dynamic>;
    final type = json['type'] as String;

    // Get the schema map - this will have been populated by the child schemas
    final schemaMap = schema.getSchemaMap();

    // Check if we have a schema for this type
    if (!schemaMap.containsKey(type)) {
      throw AckException.validation('Unknown discriminator value: $type');
    }

    // Delegate to the appropriate schema based on type
    switch (type) {
      // This will be filled in when child schemas are registered
      default:
        // Use registry to find the appropriate schema class
        final schemaInstance = SchemaRegistry.resolve(input);
        if (schemaInstance == null) {
          throw AckException.validation('No schema found for type: $type');
        }
        return schemaInstance.parse(input, debugName: debugName) as SealedBlock;
    }
  }

  // Simple tryParse implementation
  @override
  SealedBlock? tryParse(Object? input, {String? debugName}) {
    try {
      return parse(input, debugName: debugName);
    } catch (e) {
      return null;
    }
  }
}

/// Generated schema for TextBlock
/// A text block with markdown content
class TextBlockSchema extends SchemaModel<TextBlock> {
  // Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {
        'type': Ack.string.literal('text'),
        'align': Ack.string.nullable(),
        'flex': Ack.int.nullable(),
        'scrollable': Ack.boolean.nullable(),
        'content': Ack.string,
      },
      required: ['type', 'content'],
      additionalProperties: false,
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.registerDiscriminated<TextBlock, TextBlockSchema>(
      factory: (data) => TextBlockSchema(data),
      discriminatorKey: 'type',
      discriminatorValue: 'text',
    );
  }

  // Override to return the schema for validation
  @override
  AckSchema getSchema() => schema;

  // Constructor that validates input
  TextBlockSchema([Object? value]) : super(value);

  /// Validate the input against the schema
  SchemaResult<MapValue> validate(Object? input, {String? debugName}) {
    return schema.validate(input, debugName: debugName);
  }

  // Type-safe getters
  String? get align => getValue<String>('align');
  int? get flex => getValue<int>('flex');
  bool? get scrollable => getValue<bool>('scrollable');
  String get content => getValue<String>('content')!;

  // Model conversion methods
  @override
  TextBlock toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return TextBlock(
      align: align,
      flex: flex,
      scrollable: scrollable,
      content: content,
    );
  }

  /// Parses the input and returns a TextBlock instance.
  /// Throws an [AckException] if validation fails.
  @override
  TextBlock parse(Object? input, {String? debugName}) {
    final result = validate(input, debugName: debugName);
    if (result.isOk) {
      return toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a TextBlock instance.
  /// Returns null if validation fails.
  @override
  TextBlock? tryParse(Object? input, {String? debugName}) {
    final result = validate(input, debugName: debugName);
    return result.isOk ? toModel() : null;
  }

  /// Create a schema from a model instance
  static TextBlockSchema fromModel(TextBlock model) {
    return TextBlockSchema(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel(TextBlock instance) {
    final Map<String, Object?> result = {
      'align': instance.align,
      'flex': instance.flex,
      'scrollable': instance.scrollable,
      'content': instance.content,
      'type': instance.type,
    };

    return result;
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}

/// Generated schema for ImageBlock
/// An image block with image source and attributes
class ImageBlockSchema extends SchemaModel<ImageBlock> {
  // Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {
        'type': Ack.string.literal('image'),
        'align': Ack.string.nullable(),
        'flex': Ack.int.nullable(),
        'scrollable': Ack.boolean.nullable(),
        'src': Ack.string,
        'width': Ack.double.nullable(),
        'height': Ack.double.nullable(),
        'fit': Ack.string.nullable(),
      },
      required: ['type', 'src'],
      additionalProperties: false,
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.registerDiscriminated<ImageBlock, ImageBlockSchema>(
      factory: (data) => ImageBlockSchema(data),
      discriminatorKey: 'type',
      discriminatorValue: 'image',
    );
  }

  // Override to return the schema for validation
  @override
  AckSchema getSchema() => schema;

  // Constructor that validates input
  ImageBlockSchema([Object? value]) : super(value);

  /// Validate the input against the schema
  SchemaResult<MapValue> validate(Object? input, {String? debugName}) {
    return schema.validate(input, debugName: debugName);
  }

  // Type-safe getters
  String? get align => getValue<String>('align');
  int? get flex => getValue<int>('flex');
  bool? get scrollable => getValue<bool>('scrollable');
  String get src => getValue<String>('src')!;
  double? get width => getValue<double>('width');
  double? get height => getValue<double>('height');
  String? get fit => getValue<String>('fit');

  // Model conversion methods
  @override
  ImageBlock toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return ImageBlock(
      align: align,
      flex: flex,
      scrollable: scrollable,
      src: src,
      width: width,
      height: height,
      fit: fit,
    );
  }

  /// Parses the input and returns a ImageBlock instance.
  /// Throws an [AckException] if validation fails.
  @override
  ImageBlock parse(Object? input, {String? debugName}) {
    final result = validate(input, debugName: debugName);
    if (result.isOk) {
      return toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a ImageBlock instance.
  /// Returns null if validation fails.
  @override
  ImageBlock? tryParse(Object? input, {String? debugName}) {
    final result = validate(input, debugName: debugName);
    return result.isOk ? toModel() : null;
  }

  /// Create a schema from a model instance
  static ImageBlockSchema fromModel(ImageBlock model) {
    return ImageBlockSchema(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel(ImageBlock instance) {
    final Map<String, Object?> result = {
      'align': instance.align,
      'flex': instance.flex,
      'scrollable': instance.scrollable,
      'src': instance.src,
      'width': instance.width,
      'height': instance.height,
      'fit': instance.fit,
    };

    return result;
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}

/// Generated schema for WidgetBlock
/// A widget block with custom properties
class WidgetBlockSchema extends SchemaModel<WidgetBlock> {
  // Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {
        'align': Ack.string.nullable(),
        'flex': Ack.int.nullable(),
        'scrollable': Ack.boolean.nullable(),
        'name': Ack.string,
      },
      required: ['name'],
      additionalProperties: true,
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<WidgetBlock, WidgetBlockSchema>(
      (data) => WidgetBlockSchema(data),
    );
  }

  // Override to return the schema for validation
  @override
  AckSchema getSchema() => schema;

  // Constructor that validates input
  WidgetBlockSchema([Object? value]) : super(value);

  /// Validate the input against the schema
  SchemaResult<MapValue> validate(Object? input, {String? debugName}) {
    return schema.validate(input, debugName: debugName);
  }

  // Type-safe getters
  String? get align => getValue<String>('align');
  int? get flex => getValue<int>('flex');
  bool? get scrollable => getValue<bool>('scrollable');
  String get name => getValue<String>('name')!;

  // Get metadata with fallback
  Map<String, Object?> get properties {
    final result = <String, Object?>{};
    final knownFields = ['align', 'flex', 'scrollable', 'name'];

    for (final key in toMap().keys) {
      if (!knownFields.contains(key)) {
        result[key] = toMap()[key];
      }
    }
    return result;
  }

  // Model conversion methods
  @override
  WidgetBlock toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return WidgetBlock(
      align: align,
      flex: flex,
      scrollable: scrollable,
      name: name,
      properties: properties,
    );
  }

  /// Parses the input and returns a WidgetBlock instance.
  /// Throws an [AckException] if validation fails.
  @override
  WidgetBlock parse(Object? input, {String? debugName}) {
    final result = validate(input, debugName: debugName);
    if (result.isOk) {
      return toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a WidgetBlock instance.
  /// Returns null if validation fails.
  @override
  WidgetBlock? tryParse(Object? input, {String? debugName}) {
    final result = validate(input, debugName: debugName);
    return result.isOk ? toModel() : null;
  }

  /// Create a schema from a model instance
  static WidgetBlockSchema fromModel(WidgetBlock model) {
    return WidgetBlockSchema(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel(WidgetBlock instance) {
    final Map<String, Object?> result = {
      'align': instance.align,
      'flex': instance.flex,
      'scrollable': instance.scrollable,
      'name': instance.name,
    };

    // Include additional properties
    if (instance.properties.isNotEmpty) {
      result.addAll(instance.properties);
    }

    return result;
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}

