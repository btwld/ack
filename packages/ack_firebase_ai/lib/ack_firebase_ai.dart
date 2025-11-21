/// Firebase AI (Gemini) schema converter for ACK validation library.
///
/// Converts ACK validation schemas to Firebase AI Schema format for structured
/// output generation with Gemini models.
library;

import 'package:ack/ack.dart';
import 'package:ack/schema_converter_base.dart';
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;

/// Extension methods for converting ACK schemas to Firebase AI format.
extension FirebaseAiSchemaExtension on AckSchema {
  /// Converts this ACK schema to Firebase AI (Gemini) Schema format.
  firebase_ai.Schema toFirebaseAiSchema() {
    return const FirebaseAiSchemaConverter().convert(this);
  }
}

/// Converter implementation using the shared [AckSchemaConverter] template.
class FirebaseAiSchemaConverter
    extends AckSchemaConverter<firebase_ai.Schema> {
  const FirebaseAiSchemaConverter();

  @override
  firebase_ai.Schema buildString(
    StringSchema schema,
    JsonSchema jsonSchema,
  ) {
    if (jsonSchema.isEnum) {
      return firebase_ai.Schema.enumString(
        enumValues: jsonSchema.enum_!,
        description: jsonSchema.description,
        title: jsonSchema.title,
      );
    }

    return firebase_ai.Schema.string(
      description: jsonSchema.description,
      title: jsonSchema.title,
      format: jsonSchema.format,
    );
  }

  @override
  firebase_ai.Schema buildInteger(
    IntegerSchema schema,
    JsonSchema jsonSchema,
  ) {
    return firebase_ai.Schema.integer(
      description: jsonSchema.description,
      title: jsonSchema.title,
      minimum: jsonSchema.minimum?.toInt(),
      maximum: jsonSchema.maximum?.toInt(),
      format: jsonSchema.format,
    );
  }

  @override
  firebase_ai.Schema buildDouble(
    DoubleSchema schema,
    JsonSchema jsonSchema,
  ) {
    return firebase_ai.Schema.number(
      description: jsonSchema.description,
      title: jsonSchema.title,
      minimum: jsonSchema.minimum?.toDouble(),
      maximum: jsonSchema.maximum?.toDouble(),
      format: jsonSchema.format,
    );
  }

  @override
  firebase_ai.Schema buildBoolean(
    BooleanSchema schema,
    JsonSchema jsonSchema,
  ) {
    return firebase_ai.Schema.boolean(
      description: jsonSchema.description,
      title: jsonSchema.title,
    );
  }

  @override
  firebase_ai.Schema buildEnum(
    EnumSchema schema,
    JsonSchema jsonSchema,
  ) {
    final enumValues = [
      for (final value in schema.values) value.name,
    ];

    return firebase_ai.Schema.enumString(
      enumValues: enumValues,
      description: jsonSchema.description,
      title: jsonSchema.title,
    );
  }

  @override
  firebase_ai.Schema buildObject(
    ObjectSchema schema,
    JsonSchema jsonSchema,
    ObjectShape<firebase_ai.Schema> shape,
  ) {
    return firebase_ai.Schema.object(
      properties: shape.properties,
      optionalProperties:
          shape.optionalKeys.isEmpty ? null : shape.optionalKeys,
      propertyOrdering:
          shape.propertyOrdering.isEmpty ? null : shape.propertyOrdering,
      description: jsonSchema.description,
      title: jsonSchema.title,
    );
  }

  @override
  firebase_ai.Schema buildArray(
    ListSchema schema,
    JsonSchema jsonSchema,
    firebase_ai.Schema items,
  ) {
    return firebase_ai.Schema.array(
      items: items,
      description: jsonSchema.description,
      title: jsonSchema.title,
      minItems: jsonSchema.minItems,
      maxItems: jsonSchema.maxItems,
    );
  }

  @override
  firebase_ai.Schema buildAnyOf(
    AnyOfSchema schema,
    List<firebase_ai.Schema> branches,
  ) {
    return firebase_ai.Schema(
      firebase_ai.SchemaType.anyOf,
      description: schema.description,
      anyOf: branches,
    );
  }

  @override
  firebase_ai.Schema buildAny(
    AnySchema schema,
    JsonSchema jsonSchema,
    List<firebase_ai.Schema> primitives, {
    required String? description,
  }) {
    final arrayItems = firebase_ai.Schema(
      firebase_ai.SchemaType.anyOf,
      anyOf: primitives,
    );

    return firebase_ai.Schema(
      firebase_ai.SchemaType.anyOf,
      description: description,
      anyOf: [
        ...primitives,
        firebase_ai.Schema.array(
          items: arrayItems,
          description: description,
        ),
      ],
    );
  }

  @override
  firebase_ai.Schema buildDiscriminated(
    DiscriminatedObjectSchema schema,
    List<firebase_ai.Schema> branches,
  ) {
    if (schema.schemas.isEmpty) {
      return firebase_ai.Schema.object(
        properties: const {},
        description: schema.description,
      );
    }

    return firebase_ai.Schema(
      firebase_ai.SchemaType.anyOf,
      description: schema.description,
      anyOf: branches,
    );
  }

  @override
  List<firebase_ai.Schema> buildPrimitiveAnyBranches(String? description) {
    return [
      firebase_ai.Schema.string(description: description),
      firebase_ai.Schema.number(description: description),
      firebase_ai.Schema.integer(description: description),
      firebase_ai.Schema.boolean(description: description),
      firebase_ai.Schema.object(properties: const {}, description: description),
    ];
  }

  @override
  firebase_ai.Schema wrapNullable(
    firebase_ai.Schema schema,
    bool isNullable,
  ) {
    if (!isNullable) return schema;
    if (schema.nullable != true) {
      schema.nullable = true;
    }
    return schema;
  }

  @override
  firebase_ai.Schema applyOverrides({
    required firebase_ai.Schema target,
    required JsonMap source,
    required bool forceNullable,
  }) {
    final jsonSchema = JsonSchema.fromJson(source);

    if (jsonSchema.description != null) {
      target.description = jsonSchema.description;
    }

    if (jsonSchema.title != null) {
      target.title = jsonSchema.title;
    }

    if (forceNullable && target.nullable != true) {
      target.nullable = true;
    }

    return target;
  }
}
