// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_this, unnecessary_new, unnecessary_const, prefer_collection_literals
// ignore_for_file: lines_longer_than_80_chars, unnecessary_null_checks, non_constant_identifier_names

part of 'slide_model.dart';

/// Generated schema for Slide
/// A slide in the presentation.
class SlideSchema extends SchemaModel<Slide> {
  // Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {
        'key': Ack.string,
        'options': SlideOptionsSchema.schema.nullable(),
        'sections': Ack.list(SectionBlockSchema.schema),
        'comments': Ack.list(Ack.string),
      },
      required: ['key'],
      additionalProperties: false,
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<Slide, SlideSchema>(
      (data) => SlideSchema(data),
    );
    // Register schema dependencies
    SlideOptionsSchema.ensureInitialize();
  }

  // Override to return the schema for validation
  @override
  AckSchema getSchema() => schema;

  // Constructor that validates input
  SlideSchema([Object? value]) : super(value);

  // Type-safe getters
  String get key => getValue<String>('key')!;
  SlideOptionsSchema? get options {
    final map = getValue<Map<String, dynamic>>('options');
    return map == null ? null : SlideOptionsSchema(map);
  }

  List<SectionBlockSchema> get sections {
    return getValue<List<dynamic>>('sections')!
        .map((item) => SectionBlockSchema(item as Map<String, dynamic>))
        .toList();
  }

  List<String> get comments => getValue<List<String>>('comments')!;

  // Model conversion methods
  @override
  Slide toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return Slide(
      key: key,
      options: options.toModel(),
      sections: sections.map((item) => item.toModel()).toList(),
      comments: comments,
    );
  }

  /// Parses the input and returns a Slide instance.
  /// Throws an [AckException] if validation fails.
  @override
  Slide parse(Object? input, {String? debugName}) {
    final result = validate(input, debugName: debugName);
    if (result.isOk) {
      return toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a Slide instance.
  /// Returns null if validation fails.
  @override
  Slide? tryParse(Object? input, {String? debugName}) {
    final result = validate(input, debugName: debugName);
    return result.isOk ? toModel() : null;
  }

  /// Create a schema from a model instance
  static SlideSchema fromModel(Slide model) {
    return SlideSchema(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel(Slide instance) {
    final Map<String, Object?> result = {
      'key': instance.key,
      'options': SlideOptionsSchema.toMapFromModel(instance.options),
      'sections': instance.sections
          .map((item) => SectionBlockSchema.toMapFromModel(item))
          .toList(),
      'comments': instance.comments,
    };

    return result;
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}

/// Generated schema for SlideOptions
/// Options for a slide.
class SlideOptionsSchema extends SchemaModel<SlideOptions> {
  // Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {
        'title': Ack.string.nullable(),
        'style': Ack.string.nullable(),
        'args': Ack.object({}, additionalProperties: true),
      },
      required: [],
      additionalProperties: false,
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<SlideOptions, SlideOptionsSchema>(
      (data) => SlideOptionsSchema(data),
    );
  }

  // Override to return the schema for validation
  @override
  AckSchema getSchema() => schema;

  // Constructor that validates input
  SlideOptionsSchema([Object? value]) : super(value);

  // Type-safe getters
  String? get title => getValue<String>('title');
  String? get style => getValue<String>('style');
  Map<String, Object> get args => getValue<Map<String, Object>>('args')!;

  // Model conversion methods
  @override
  SlideOptions toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return SlideOptions(
      title: title,
      style: style,
      args: args,
    );
  }

  /// Parses the input and returns a SlideOptions instance.
  /// Throws an [AckException] if validation fails.
  @override
  SlideOptions parse(Object? input, {String? debugName}) {
    final result = validate(input, debugName: debugName);
    if (result.isOk) {
      return toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a SlideOptions instance.
  /// Returns null if validation fails.
  @override
  SlideOptions? tryParse(Object? input, {String? debugName}) {
    final result = validate(input, debugName: debugName);
    return result.isOk ? toModel() : null;
  }

  /// Create a schema from a model instance
  static SlideOptionsSchema fromModel(SlideOptions model) {
    return SlideOptionsSchema(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel(SlideOptions instance) {
    final Map<String, Object?> result = {
      'title': instance.title,
      'style': instance.style,
      'args': instance.args,
    };

    return result;
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}
