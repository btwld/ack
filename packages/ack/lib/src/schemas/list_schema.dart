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

  @override
  @protected
  SchemaResult<List<V>> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Null handling with default cloning to prevent mutation
    if (inputValue == null) {
      if (defaultValue != null) {
        final clonedDefault = cloneDefault(defaultValue!);
        // Recursively validate the cloned default
        return parseAndValidate(clonedDefault, context);
      }
      if (isNullable) {
        return SchemaResult.ok(null);
      }
      return failNonNullable(context);
    }

    // Type guard
    if (inputValue is! List) {
      final actualType = AckSchema.getSchemaType(inputValue);
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: actualType,
          context: context,
        ),
      );
    }
    final inputList = inputValue;
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

      final itemResult = itemSchema.parseAndValidate(itemValue, itemContext);

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

    return applyConstraintsAndRefinements(validatedItems, context);
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
        typeSchema: {
          'type': 'array',
          'items': itemSchema.toJsonSchema(),
        },
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
