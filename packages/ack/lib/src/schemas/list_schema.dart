part of 'schema.dart';

/// Schema for validating lists (`List<V>`) where each item conforms to `itemSchema`.
@immutable
final class ListSchema<V extends Object> extends AckSchema<List<V>>
    with FluentSchema<List<V>, ListSchema<V>> {
  final AckSchema<V> itemSchema;

  const ListSchema(
    this.itemSchema, {
    super.isNullable,
    super.isOptional,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.array;

  /// Decodes a non-null boundary value into `List<V>`. Each item is decoded
  /// recursively through `itemSchema._parse(...)` so child constraints still
  /// apply. The schema's own constraints/refinements are applied by [_parse]
  /// after this returns.
  @override
  @protected
  SchemaResult<List<V>> decodeBoundary(
    Object? input,
    SchemaContext context,
  ) {
    if (input is! List) {
      final actualType = AckSchema.getSchemaType(input);
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: actualType,
          context: context,
        ),
      );
    }
    final inputList = input;
    final validatedItems = <V>[];
    final itemErrors = <SchemaError>[];

    for (var i = 0; i < inputList.length; i++) {
      final itemValue = inputList[i];
      final itemContext = context.createChild(
        name: '$i',
        schema: itemSchema,
        value: itemValue,
        pathSegment: '$i',
      );

      final itemResult = itemSchema._parse(itemValue, itemContext);

      if (itemResult.isOk) {
        final validatedItemValue = itemResult.getOrNull();
        if (validatedItemValue is V) {
          validatedItems.add(validatedItemValue);
        } else {
          itemErrors.add(
            SchemaValidationError(
              message:
                  'List item ${itemContext.name} resolved to null. Use non-nullable item schemas for Ack.list.',
              context: itemContext,
            ),
          );
        }
      } else {
        itemErrors.add(itemResult.getError());
      }
    }

    if (itemErrors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: itemErrors, context: context),
      );
    }

    return SchemaResult.ok(List<V>.unmodifiable(validatedItems));
  }

  /// Recursively encodes the runtime [List<V>] back to its boundary form by
  /// invoking each item's encode pipeline (`_validateRuntime` followed by
  /// `encodeBoundary`). Errors are aggregated under [SchemaNestedError] with
  /// per-index paths preserved.
  @override
  @protected
  SchemaResult<Object> encodeBoundary(
    List<V> value,
    SchemaContext context,
  ) {
    final out = <Object?>[];
    final itemErrors = <SchemaError>[];

    for (var i = 0; i < value.length; i++) {
      final itemValue = value[i];
      final itemContext = context.createChild(
        name: '$i',
        schema: itemSchema,
        value: itemValue,
        pathSegment: '$i',
      );

      final validated = itemSchema._validateRuntime(itemValue, itemContext);
      if (validated.isFail) {
        itemErrors.add(validated.getError());
        continue;
      }
      final v = validated.getOrNull();
      if (v == null) {
        // Item schema accepted null (nullable); the boundary form is null.
        out.add(null);
        continue;
      }

      final encoded = itemSchema.encodeBoundary(v, itemContext);
      if (encoded.isFail) {
        itemErrors.add(encoded.getError());
        continue;
      }
      out.add(encoded.getOrNull());
    }

    if (itemErrors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: itemErrors, context: context),
      );
    }

    return SchemaResult.ok(List<Object?>.unmodifiable(out));
  }

  @override
  ListSchema<V> copyWith({
    AckSchema<V>? itemSchema,
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<V>? defaultValue,
    List<Constraint<List<V>>>? constraints,
    List<Refinement<List<V>>>? refinements,
  }) {
    return ListSchema(
      itemSchema ?? this.itemSchema,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() => buildJsonSchemaWithNullable(
    typeSchema: {'type': 'array', 'items': itemSchema.toJsonSchema()},
    serializedDefault: defaultValue,
  );

  @override
  Map<String, Object?> toMap() {
    return {
      'type': schemaType.typeName,
      'isNullable': isNullable,
      'description': description,
      'defaultValue': defaultValue,
      'constraints': constraints.map((c) => c.toMap()).toList(),
      'itemSchema': itemSchema.schemaType.typeName,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ListSchema<V>) return false;
    return baseFieldsEqual(other) && itemSchema == other.itemSchema;
  }

  @override
  int get hashCode => Object.hash(baseFieldsHashCode, itemSchema);
}
