part of 'schema.dart';

/// Schema for validating lists (`List<V>`) where each item conforms to `itemSchema`.
@immutable
final class ListSchema<V extends Object> extends AckSchema<List<V>>
    with FluentSchema<List<V>, ListSchema<V>> {
  final AckSchema<V> itemSchema;

  const ListSchema(
    this.itemSchema, {
    super.isNullable,
    super.description,
    super.defaultValue,
    super.constraints,
    super.refinements,
  }) : super(schemaType: SchemaType.list);

  @override
  @protected
  SchemaResult<List<V>> _onConvert(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue is! List) {
      final constraintError =
          InvalidTypeConstraint(expectedType: List).validate(inputValue);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    // Direct access to inputValue - no need for List.from() since we already know it's a List
    final inputList = inputValue;
    final validatedItems = <V>[];
    final itemErrors = <SchemaError>[];

    for (var i = 0; i < inputList.length; i++) {
      final itemValue = inputList[i];
      final itemContext = SchemaContext(
        name: '${context.name}[$i]',
        schema: itemSchema,
        value: itemValue,
      );

      final itemResult =
          itemSchema.validate(itemValue, debugName: itemContext.name);

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
      return SchemaResult.fail(SchemaNestedError(
        errors: itemErrors,
        context: context,
      ));
    }

    return SchemaResult.ok(validatedItems);
  }

  @override
  ListSchema<V> copyWith({
    AckSchema<V>? itemSchema,
    bool? isNullable,
    String? description,
    List<V>? defaultValue,
    List<Constraint<List<V>>>? constraints,
    List<Refinement<List<V>>>? refinements,
  }) {
    return copyWithInternal(
      itemSchema: itemSchema,
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      refinements: refinements,
    );
  }

  @override
  ListSchema<V> copyWithInternal({
    required bool? isNullable,
    required String? description,
    required List<V>? defaultValue,
    required List<Constraint<List<V>>>? constraints,
    required List<Refinement<List<V>>>? refinements,
    // ListSchema specific
    AckSchema<V>? itemSchema,
  }) {
    return ListSchema(
      itemSchema ?? this.itemSchema,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final Map<String, Object?> schema = {
      'type': isNullable ? ['array', 'null'] : 'array',
      'items': itemSchema.toJsonSchema(),
      if (description != null) 'description': description,
    };

    final constraintSchemas = <Map<String, Object?>>[];
    for (final constraint in constraints) {
      if (constraint is JsonSchemaSpec) {
        constraintSchemas.add((constraint as JsonSchemaSpec).toJsonSchema());
      }
    }

    return constraintSchemas.fold(
      schema,
      (prev, current) => deepMerge(prev, current),
    );
  }
}
