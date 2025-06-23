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

    // This is an unsafe cast, but the logic below must be robust enough
    // to handle a List<dynamic> where items are not yet of type V.
    final list = List.from(inputValue);
    final validatedItems = <V>[];
    final itemErrors = <SchemaError>[];

    for (var i = 0; i < list.length; i++) {
      final itemValue = list[i];
      final itemContext = SchemaContext(
        name: '${context.name}[$i]',
        schema: itemSchema,
        value: itemValue,
      );

      final itemResult =
          itemSchema.validate(itemValue, debugName: itemContext.name);

      if (itemResult.isOk) {
        // itemResult.getOrNull() can return null if itemSchema is nullable and itemValue was null
        final validatedItemValue = itemResult.getOrNull();
        if (validatedItemValue is V) {
          validatedItems.add(validatedItemValue);
        } else if (validatedItemValue == null && itemSchema.isNullable) {
          // If itemSchema is nullable and result is Ok(null), we need to add a null.
          // Since the list is `List<V>`, we can't add null directly.
          // This path indicates a potential type mismatch in very specific scenarios,
          // but we will trust the schema's nullability flag.
          // The best approach is to continue and let downstream code handle it,
          // as forcing a `null` into a `List<V>` is not type-safe at compile time.
          // Intentionally empty - we skip adding this item to maintain type safety.
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
    List<Validator<List<V>>>? constraints,
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
    required List<Validator<List<V>>>? constraints,
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
