# Discriminated Schema Implementation Plan

## Overview
This document outlines the plan for implementing discriminated schema support in the Ack library, supporting both sealed and abstract classes with inheritance hierarchies.

## Goals
- Support discriminated types through the Schema annotation
- Generate discriminated schemas for classes with inheritance hierarchies
- Implement a type-safe parsing mechanism for discriminated types
- Generate toJson methods for classes in the hierarchy (consistent with current approach)
- Maintain the existing behavior patterns for non-discriminated schemas

## Implementation Clarifications
- Support both sealed and abstract classes with subclasses
- Generate toJson methods for all classes in the discriminated hierarchy
- Maintain consistent behavior with current toModel approach
- Keep changes focused on the specific requirements without over-engineering

## Task Breakdown

### Phase 1: Update Annotations and Schema Classes
- [ ] Modify `Schema` annotation in `packages/ack/lib/src/annotations.dart`
  - [ ] Add `discriminatedKey` parameter to identify the discriminator field
  - [ ] Add `discriminatedValue` parameter to specify subclass type values
- [ ] Update `SchemaData` class in the generator
  - [ ] Add corresponding fields to extract and store discriminator information
  - [ ] Update constructor and serialization methods

### Phase 2: Enhance Schema Model Builder
- [ ] Modify `SchemaModelBuilder` in `packages/ack_generator/lib/src/schema_model_builder.dart`
  - [ ] Add detection for both sealed and abstract classes
  - [ ] Track relationship between parent classes and their child classes
  - [ ] Extract discriminator information from annotations
- [ ] Create a hierarchical relationship model
  - [ ] Define data structure for storing parent-child relationships
  - [ ] Implement mapping of discriminated values to specific subclasses
  - [ ] Handle inheritance and property inheritance

### Phase 3: Modify Schema Generator Logic
- [ ] Update `SchemaModelGenerator` to handle discriminated schemas
  - [ ] Generate individual schemas for each subclass
  - [ ] Create a combined discriminated schema for the parent class
  - [ ] Support for discriminator constants in subclass schemas
- [ ] Implement schema generation logic
  - [ ] For parent classes: generate discriminated schema
  - [ ] For child classes: generate normal schema with discriminated value
  - [ ] Handle property inheritance from parent to child schemas

### Phase 4: Implement Parse Method Generation
- [ ] Create parse method generator
  - [ ] Generate type-safe parseModel method for the parent class
  - [ ] Implement discriminator-based switch statement
  - [ ] Generate proper property mapping for each subclass
- [ ] Handle toJson conversion consistently with existing code
  - [ ] Generate toJson methods for each subclass following existing pattern
  - [ ] Ensure consistency between parsing and serialization
- [ ] Support additional properties
  - [ ] Handle classes with additionalProperties flag
  - [ ] Properly extract and pass through additional properties

### Phase 5: Testing and Documentation
- [ ] Create test cases
  - [ ] Test basic discriminated type validation
  - [ ] Test parsing of different subtypes
  - [ ] Test error handling for invalid discriminator values
  - [ ] Test nested discriminated schemas
- [ ] Write documentation
  - [ ] Update code comments
  - [ ] Create usage examples
  - [ ] Document best practices and limitations

## Detailed Example Implementation

The sealed_block_model.dart example will demonstrate a complete implementation including:

```dart
@Schema(
  description: 'Base block class with polymorphic subclasses',
  discriminatedKey: 'type',
)
sealed class SealedBlock {
  final String type;
  final String? align;
  final int? flex;
  final bool? scrollable;

  const SealedBlock({
    required this.type,
    this.align,
    this.flex,
    this.scrollable,
  });
}

@Schema(
  description: 'A text block with markdown content',
  discriminatedValue: 'text',
)
class TextBlock extends SealedBlock {
  final String content;

  const TextBlock({
    super.align,
    super.flex,
    super.scrollable,
    required this.content,
  }) : super(type: 'text');
}

// Additional subclasses omitted for brevity...
```

The generated code will create a discriminated schema and parse method like:

```dart
/// Generated schema for SealedBlock
/// Base block class with polymorphic subclasses
class SealedBlockSchema extends SchemaModel<SealedBlock> {
  // Schema definition moved to a static field for easier access
  static final DiscriminatedObjectSchema schema = _createSchema();

  // Create the validation schema
  static DiscriminatedObjectSchema _createSchema() {
    return Ack.discriminated(
      discriminatorKey: 'type',
      schemas: {
        'text': TextBlockSchema.schema,
        'image': ImageBlockSchema.schema,
        'widget': WidgetBlockSchema.schema,
      },
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<SealedBlock, SealedBlockSchema>(
      (data) => SealedBlockSchema(data),
    );
    // Register schema dependencies
    TextBlockSchema.ensureInitialize();
    ImageBlockSchema.ensureInitialize();
    WidgetBlockSchema.ensureInitialize();
  }

  // Override to return the schema for validation
  @override
  AckSchema getSchema() => schema;

  // Constructor that validates input
  SealedBlockSchema([Object? value]) : super(value);

  // Model conversion methods
  @override
  SealedBlock toModel();

  /// Parses the input and returns a SealedBlock instance.
  /// Throws an [AckException] if validation fails.
  @override
  SealedBlock parse(Object? input, {String? debugName}) {
    final result = validate(input, debugName: debugName);
    if (result.isOk) {
      return toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a SealedBlock instance.
  /// Returns null if validation fails.
  @override
  SealedBlock? tryParse(Object? input, {String? debugName}) {
    final result = validate(input, debugName: debugName);
    return result.isOk ? toModel() : null;
  }

  /// Create a schema from a model instance
  static SealedBlockSchema fromModel(SealedBlock model) {
    return SealedBlockSchema(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel(SealedBlock instance) {
    // Use pattern matching to delegate to appropriate subclass
    return switch (instance) {
      TextBlock m => TextBlockSchema.toMapFromModel(m),
      ImageBlock m => ImageBlockSchema.toMapFromModel(m),
      WidgetBlock m => WidgetBlockSchema.toMapFromModel(m),
    };
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}
```

## Implementation Scope and Boundaries

To avoid over-engineering and maintain focus:

1. We will only implement what's needed for discriminated schemas to work
2. We'll maintain the existing API patterns for consistency
3. We'll focus on the specific task of generating schemas and parse methods
4. We'll avoid adding features not directly related to discriminated schemas

## Implementation Timeline

1. **Week 1**: Update annotation classes and schema model builder
2. **Week 2**: Implement schema generation logic and parse method generation
3. **Week 3**: Testing, documentation, and refinement

## Notes and Considerations

- Discriminated schemas work with both sealed and abstract class hierarchies
- The approach will maintain consistency with current schema generation
- This implementation focuses on removing manual fromJson/toJson boilerplate
- The parsing approach will be consistent with current schema validation patterns