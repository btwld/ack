// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_this, unnecessary_new, unnecessary_const, prefer_collection_literals
// ignore_for_file: lines_longer_than_80_chars, unnecessary_null_checks, non_constant_identifier_names

part of 'block_model.dart';

/// Generated schema for Block
/// Base class for blocks that make up a slide
class BlockSchema extends SchemaModel<Block> {
  // Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {},
      required: [],
      additionalProperties: false,
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<Block, BlockSchema>(
      (data) => BlockSchema(data),
    );
  }

  // Override to return the schema for validation
  @override
  AckSchema getSchema() => schema;

  // Constructor that validates input
  BlockSchema([Object? value]) : super(value);

  // Type-safe getters

  // Model conversion methods
  @override
  Block toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    throw UnimplementedError(
        'Cannot instantiate abstract class Block. Use a concrete subclass instead.');
  }

  /// Parses the input and returns a Block instance.
  /// Throws an [AckException] if validation fails.
  static Block parse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    if (result.isOk) {
      return BlockSchema(result.getOrNull()).toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a Block instance.
  /// Returns null if validation fails.
  static Block? tryParse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    return result.isOk ? BlockSchema(result.getOrNull()).toModel() : null;
  }

  /// Create a schema from a model instance
  static BlockSchema fromModel(Block model) {
    return BlockSchema(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel(Block instance) {
    final Map<String, Object?> result = {};

    return result;
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}

/// Generated schema for SectionBlock
/// A section block that contains multiple columns
class SectionBlockSchema extends SchemaModel<SectionBlock> {
  // Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {
        'columns': Ack.list(ColumnBlockSchema.schema),
      },
      required: ['columns'],
      additionalProperties: false,
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<SectionBlock, SectionBlockSchema>(
      (data) => SectionBlockSchema(data),
    );
    // Register schema dependencies
    ColumnBlockSchema.ensureInitialize();
  }

  // Override to return the schema for validation
  @override
  AckSchema getSchema() => schema;

  // Constructor that validates input
  SectionBlockSchema([Object? value]) : super(value);

  // Type-safe getters
  List<ColumnBlockSchema> get columns {
    return getValue<List<dynamic>>('columns')!
        .map((item) => ColumnBlockSchema(item as Map<String, dynamic>))
        .toList();
  }

  // Model conversion methods
  @override
  SectionBlock toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return SectionBlock(
      columns: columns.map((item) => item.toModel()).toList(),
    );
  }

  /// Parses the input and returns a SectionBlock instance.
  /// Throws an [AckException] if validation fails.
  static SectionBlock parse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    if (result.isOk) {
      return SectionBlockSchema(result.getOrNull()).toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a SectionBlock instance.
  /// Returns null if validation fails.
  static SectionBlock? tryParse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    return result.isOk
        ? SectionBlockSchema(result.getOrNull()).toModel()
        : null;
  }

  /// Create a schema from a model instance
  static SectionBlockSchema fromModel(SectionBlock model) {
    return SectionBlockSchema(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel(SectionBlock instance) {
    final Map<String, Object?> result = {
      'columns': instance.columns
          .map((item) => ColumnBlockSchema.toMapFromModel(item))
          .toList(),
    };

    return result;
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}

/// Generated schema for ColumnBlock
/// A column block that contains markdown content
class ColumnBlockSchema extends SchemaModel<ColumnBlock> {
  // Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {
        'content': Ack.string,
      },
      required: ['content'],
      additionalProperties: false,
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<ColumnBlock, ColumnBlockSchema>(
      (data) => ColumnBlockSchema(data),
    );
  }

  // Override to return the schema for validation
  @override
  AckSchema getSchema() => schema;

  // Constructor that validates input
  ColumnBlockSchema([Object? value]) : super(value);

  // Type-safe getters
  String get content => getValue<String>('content')!;

  // Model conversion methods
  @override
  ColumnBlock toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return ColumnBlock(
      content: content,
    );
  }

  /// Parses the input and returns a ColumnBlock instance.
  /// Throws an [AckException] if validation fails.
  static ColumnBlock parse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    if (result.isOk) {
      return ColumnBlockSchema(result.getOrNull()).toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a ColumnBlock instance.
  /// Returns null if validation fails.
  static ColumnBlock? tryParse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    return result.isOk ? ColumnBlockSchema(result.getOrNull()).toModel() : null;
  }

  /// Create a schema from a model instance
  static ColumnBlockSchema fromModel(ColumnBlock model) {
    return ColumnBlockSchema(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel(ColumnBlock instance) {
    final Map<String, Object?> result = {
      'content': instance.content,
    };

    return result;
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}

