/// JSON Schema Builder converter for ACK validation library.
///
/// Converts ACK validation schemas to json_schema_builder Schema format
/// for JSON Schema Draft 2020-12 validation and documentation.
///
/// ## Usage
///
/// ```dart
/// import 'package:ack/ack.dart';
/// import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
///
/// final schema = Ack.object({
///   'name': Ack.string().minLength(2),
///   'age': Ack.integer().min(0).optional(),
/// });
///
/// // Convert to json_schema_builder 
/// final jsbSchema = schema.toJsonSchemaBuilder();
/// ```
library;

import 'package:ack/ack.dart';
import 'package:ack/schema_converter_base.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;

/// Extension methods for converting ACK schemas to json_schema_builder format.
extension JsonSchemaBuilderExtension on AckSchema {
  /// Converts this ACK schema to json_schema_builder Schema format.
  ///
  /// Returns a json_schema_builder [Schema] instance for JSON Schema Draft 2020-12.
  jsb.Schema toJsonSchemaBuilder() {
    return const JsonSchemaBuilderConverter().convert(this);
  }
}

/// Converter implementation using the shared [AckSchemaConverter] template.
class JsonSchemaBuilderConverter extends AckSchemaConverter<jsb.Schema> {
  const JsonSchemaBuilderConverter();

  @override
  jsb.Schema buildString(StringSchema schema, JsonSchema jsonSchema) {
    if (jsonSchema.isEnum) {
      return jsb.Schema.string(
        enumValues: jsonSchema.enum_!,
        description: jsonSchema.description,
        title: jsonSchema.title,
      );
    }

    return jsb.Schema.string(
      description: jsonSchema.description,
      title: jsonSchema.title,
      minLength: jsonSchema.minLength,
      maxLength: jsonSchema.maxLength,
      pattern: jsonSchema.pattern,
      format: jsonSchema.format,
    );
  }

  @override
  jsb.Schema buildInteger(IntegerSchema schema, JsonSchema jsonSchema) {
    return jsb.Schema.integer(
      description: jsonSchema.description,
      title: jsonSchema.title,
      minimum: jsonSchema.minimum?.toInt(),
      maximum: jsonSchema.maximum?.toInt(),
    );
  }

  @override
  jsb.Schema buildDouble(DoubleSchema schema, JsonSchema jsonSchema) {
    return jsb.Schema.number(
      description: jsonSchema.description,
      title: jsonSchema.title,
      minimum: jsonSchema.minimum?.toDouble(),
      maximum: jsonSchema.maximum?.toDouble(),
    );
  }

  @override
  jsb.Schema buildBoolean(BooleanSchema schema, JsonSchema jsonSchema) {
    return jsb.Schema.boolean(
      description: jsonSchema.description,
      title: jsonSchema.title,
    );
  }

  @override
  jsb.Schema buildEnum(EnumSchema schema, JsonSchema jsonSchema) {
    final enumValues = [for (final value in schema.values) value.name];

    return jsb.Schema.string(
      enumValues: enumValues,
      description: jsonSchema.description,
      title: jsonSchema.title,
    );
  }

  @override
  jsb.Schema buildObject(
    ObjectSchema schema,
    JsonSchema jsonSchema,
    ObjectShape<jsb.Schema> shape,
  ) {
    return jsb.Schema.object(
      properties: shape.properties,
      required: shape.requiredKeys.isEmpty ? null : shape.requiredKeys,
      description: jsonSchema.description,
      title: jsonSchema.title,
      additionalProperties: jsonSchema.additionalProperties,
    );
  }

  @override
  jsb.Schema buildArray(
    ListSchema schema,
    JsonSchema jsonSchema,
    jsb.Schema items,
  ) {
    return jsb.Schema.list(
      items: items,
      description: jsonSchema.description,
      title: jsonSchema.title,
      minItems: jsonSchema.minItems,
      maxItems: jsonSchema.maxItems,
      uniqueItems: jsonSchema.uniqueItems,
    );
  }

  @override
  jsb.Schema buildAnyOf(
    AnyOfSchema schema,
    List<jsb.Schema> branches,
  ) {
    return jsb.Schema.combined(
      anyOf: branches,
      description: schema.description,
    );
  }

  @override
  jsb.Schema buildAny(
    AnySchema schema,
    JsonSchema jsonSchema,
    List<jsb.Schema> primitives, {
    required String? description,
  }) {
    final arrayItems =
        jsb.Schema.combined(anyOf: primitives, description: description);

    return jsb.Schema.combined(
      anyOf: [
        ...primitives,
        jsb.Schema.list(items: arrayItems, description: description),
      ],
      description: description,
    );
  }

  @override
  jsb.Schema buildDiscriminated(
    DiscriminatedObjectSchema schema,
    List<jsb.Schema> branches,
  ) {
    if (schema.schemas.isEmpty) {
      return jsb.Schema.object(
        properties: const {},
        description: schema.description,
      );
    }

    return jsb.Schema.combined(
      anyOf: branches,
      description: schema.description,
    );
  }

  @override
  List<jsb.Schema> buildPrimitiveAnyBranches(String? description) {
    return [
      jsb.Schema.string(description: description),
      jsb.Schema.number(description: description),
      jsb.Schema.integer(description: description),
      jsb.Schema.boolean(description: description),
      jsb.Schema.object(properties: const {}, description: description),
    ];
  }

  @override
  jsb.Schema wrapNullable(jsb.Schema schema, bool isNullable) {
    if (!isNullable) return schema;
    return jsb.Schema.combined(anyOf: [schema, jsb.Schema.nil()]);
  }

  @override
  jsb.Schema applyOverrides({
    required jsb.Schema target,
    required JsonMap source,
    required bool forceNullable,
  }) {
    final jsonSchema = JsonSchema.fromJson(source);

    final map = Map<String, Object?>.from(target.value);

    if (jsonSchema.description != null) {
      map['description'] = jsonSchema.description;
    }

    if (jsonSchema.title != null) {
      map['title'] = jsonSchema.title;
    }

    var rebuilt = jsb.Schema.fromMap(map);

    if (forceNullable) {
      rebuilt = jsb.Schema.combined(anyOf: [rebuilt, jsb.Schema.nil()]);
    }

    return rebuilt;
  }
}
