library;

import 'package:ack/ack.dart';

typedef JsonMap = Map<String, Object?>;

/// Shape data produced while converting an [ObjectSchema].
class ObjectShape<TSchema> {
  ObjectShape({
    required this.properties,
    required this.requiredKeys,
    required this.optionalKeys,
    required this.propertyOrdering,
  });

  final Map<String, TSchema> properties;
  final List<String> requiredKeys;
  final List<String> optionalKeys;
  final List<String> propertyOrdering;
}

/// Template-method style converter that turns ACK schemas into another schema
/// representation.
///
/// Concrete converters only implement the small set of builder methods for
/// their target type (Firebase AI, json_schema_builder, etc). The traversal,
/// nullability unwrapping, discriminator injection, and error-path handling are
/// centralized here to keep all converters aligned.
abstract class AckSchemaConverter<TSchema> {
  const AckSchemaConverter();

  /// Entry point used by the extension methods.
  TSchema convert(AckSchema schema) => _convert(schema);

  // ---------------------------------------------------------------------------
  // Conversion traversal (do not override)
  // ---------------------------------------------------------------------------

  TSchema _convert(AckSchema schema) {
    final jsonSchema = JsonSchema.fromJson(schema.toJsonSchema());
    final effectiveJsonSchema = _unwrapNullable(jsonSchema);

    if (schema is TransformedSchema) {
      final base = _convert(schema.schema);
      return applyOverrides(
        target: base,
        source: schema.toJsonSchema(),
        forceNullable: schema.isNullable,
      );
    }

    return switch (schema) {
      StringSchema() => wrapNullable(
          buildString(schema, effectiveJsonSchema), //
          schema.isNullable,
        ),
      IntegerSchema() => wrapNullable(
          buildInteger(schema, effectiveJsonSchema), //
          schema.isNullable,
        ),
      DoubleSchema() => wrapNullable(
          buildDouble(schema, effectiveJsonSchema), //
          schema.isNullable,
        ),
      BooleanSchema() => wrapNullable(
          buildBoolean(schema, effectiveJsonSchema), //
          schema.isNullable,
        ),
      EnumSchema() => wrapNullable(
          buildEnum(schema, effectiveJsonSchema), //
          schema.isNullable,
        ),
      ObjectSchema() => wrapNullable(
          buildObject(
            schema,
            effectiveJsonSchema,
            _convertObjectShape(schema),
          ),
          schema.isNullable,
        ),
      ListSchema() => wrapNullable(
          buildArray(
            schema,
            effectiveJsonSchema,
            _convert(schema.itemSchema),
          ),
          schema.isNullable,
        ),
      AnyOfSchema() => wrapNullable(
          buildAnyOf(
            schema,
            [for (final child in schema.schemas) _convert(child)],
          ),
          schema.isNullable,
        ),
      AnySchema() => _convertAny(schema, effectiveJsonSchema),
      DiscriminatedObjectSchema() => wrapNullable(
          buildDiscriminated(
            schema,
            _convertDiscriminatedBranches(schema),
          ),
          schema.isNullable,
        ),
      _ => throw UnsupportedError(
          'Schema type ${schema.runtimeType} is not supported for conversion.',
        ),
    };
  }

  ObjectShape<TSchema> _convertObjectShape(ObjectSchema schema) {
    final properties = <String, TSchema>{};
    final required = <String>[];
    final optional = <String>[];

    for (final entry in schema.properties.entries) {
      final key = entry.key;
      final childSchema = entry.value;

      properties[key] = _wrapProperty(key, () => _convert(childSchema));

      if (childSchema.isOptional) {
        optional.add(key);
      } else {
        required.add(key);
      }
    }

    final ordering = schema.properties.keys.toList(growable: false);

    return ObjectShape(
      properties: properties,
      requiredKeys: required,
      optionalKeys: optional,
      propertyOrdering: ordering,
    );
  }

  List<TSchema> _convertDiscriminatedBranches(
    DiscriminatedObjectSchema schema,
  ) {
    if (schema.schemas.isEmpty) return <TSchema>[];

    final entries = schema.schemas.entries.toList(growable: false);

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final branchSchema = entry.value;

      if (branchSchema is! ObjectSchema) {
        return _convert(branchSchema);
      }

      if (branchSchema.properties.containsKey(schema.discriminatorKey)) {
        throw ArgumentError(
          'Discriminator key "${schema.discriminatorKey}" conflicts with existing property '
          'in branch "${entry.key}".',
        );
      }

      final normalized = branchSchema.copyWith(
        properties: {
          ...branchSchema.properties,
          schema.discriminatorKey: Ack.string().enumString([entry.key]),
        },
      );

      return _convert(normalized);
    });
  }

  TSchema _convertAny(AnySchema schema, JsonSchema effectiveJsonSchema) {
    final description = effectiveJsonSchema.description ?? schema.description;
    final primitives = buildPrimitiveAnyBranches(description);
    return wrapNullable(
      buildAny(
        schema,
        effectiveJsonSchema,
        primitives,
        description: description,
      ),
      schema.isNullable,
    );
  }

  // ---------------------------------------------------------------------------
  // Abstract builder surface (override in subclasses)
  // ---------------------------------------------------------------------------

  TSchema buildString(StringSchema schema, JsonSchema jsonSchema);

  TSchema buildInteger(IntegerSchema schema, JsonSchema jsonSchema);

  TSchema buildDouble(DoubleSchema schema, JsonSchema jsonSchema);

  TSchema buildBoolean(BooleanSchema schema, JsonSchema jsonSchema);

  TSchema buildEnum(EnumSchema schema, JsonSchema jsonSchema);

  TSchema buildObject(
    ObjectSchema schema,
    JsonSchema jsonSchema,
    ObjectShape<TSchema> shape,
  );

  TSchema buildArray(
    ListSchema schema,
    JsonSchema jsonSchema,
    TSchema items,
  );

  TSchema buildAnyOf(
    AnyOfSchema schema,
    List<TSchema> branches,
  );

  TSchema buildAny(
    AnySchema schema,
    JsonSchema jsonSchema,
    List<TSchema> primitives, {
    required String? description,
  });

  TSchema buildDiscriminated(
    DiscriminatedObjectSchema schema,
    List<TSchema> branches,
  );

  List<TSchema> buildPrimitiveAnyBranches(String? description);

  TSchema wrapNullable(TSchema schema, bool isNullable);

  TSchema applyOverrides({
    required TSchema target,
    required JsonMap source,
    required bool forceNullable,
  });

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  JsonSchema _unwrapNullable(JsonSchema jsonSchema) {
    final anyOf = jsonSchema.anyOf;
    if (anyOf == null || anyOf.isEmpty) {
      return jsonSchema;
    }

    final nullBranches =
        anyOf.where((candidate) => _isNullSchema(candidate)).toList();
    if (nullBranches.isEmpty) {
      return jsonSchema;
    }

    final nonNullBranches =
        anyOf.where((candidate) => !_isNullSchema(candidate)).toList();

    if (nonNullBranches.length == 1) {
      return nonNullBranches.first;
    }

    return jsonSchema;
  }

  bool _isNullSchema(JsonSchema schema) {
    if (schema.singleType == JsonSchemaType.null_) {
      return true;
    }

    final types = schema.type;
    if (types != null && types.contains(JsonSchemaType.null_)) {
      return types.length == 1;
    }

    final nestedAnyOf = schema.anyOf;
    if (nestedAnyOf == null || nestedAnyOf.isEmpty) {
      return false;
    }

    return nestedAnyOf.every(_isNullSchema);
  }

  T _wrapProperty<T>(String key, T Function() fn) {
    try {
      return fn();
    } catch (e, st) {
      final msg =
          'Error converting property "$key": ${e is Error ? e.toString() : e}';
      if (e is UnsupportedError) {
        Error.throwWithStackTrace(UnsupportedError(msg), st);
      } else if (e is ArgumentError) {
        Error.throwWithStackTrace(ArgumentError(msg), st);
      } else if (e is StateError) {
        Error.throwWithStackTrace(StateError(msg), st);
      }
      rethrow;
    }
  }
}
