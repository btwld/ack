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
  }) : super(schemaType: SchemaType.list);

  @override
  ListSchema<V> copyWith({
    AckSchema<V>? itemSchema,
    bool? isNullable,
    String? description,
    Object? defaultValue,
    List<Validator<List<V>>>? constraints,
  }) {
    return copyWithInternal(
      itemSchema: itemSchema,
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
    );
  }

  @override
  SchemaResult<List<V>> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue is List) {
      try {
        // This is an unsafe cast, but validateConvertedValue must be robust
        // enough to handle a List<dynamic> where items are not yet of type V.
        return SchemaResult.ok(List<V>.from(inputValue));
      } catch (e) {
        final constraintError =
            InvalidTypeConstraint(expectedType: List<V>).validate(inputValue);

        return SchemaResult.fail(SchemaConstraintsError(
          constraints: constraintError != null ? [constraintError] : [],
          context: context,
        ));
      }
    }

    final constraintError =
        InvalidTypeConstraint(expectedType: List).validate(inputValue);

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: constraintError != null ? [constraintError] : [],
      context: context,
    ));
  }

  @override
  SchemaResult<List<V>> validateConvertedValue(
    List<V> convertedValue,
    SchemaContext context,
  ) {
    final validatedItems = <V>[];
    final itemErrors = <SchemaError>[];

    for (var i = 0; i < convertedValue.length; i++) {
      final itemValue = convertedValue[i];
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
        if (validatedItemValue != null) {
          validatedItems.add(validatedItemValue);
        } else if (itemSchema.isNullable) {
          // If itemSchema is nullable and result is Ok(null), add null to the list.
          // The type V is V extends Object, which means it can't be assigned null
          // directly. However, if the schema is nullable, the intention is that
          // the list can contain nulls. We can use a temporary list to help the type system.
          final List<V?> tempList = [null];
          validatedItems.addAll(tempList.whereType());
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
  ListSchema<V> copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<List<V>>>? constraints,
    // ListSchema specific
    AckSchema<V>? itemSchema,
  }) {
    return ListSchema(
      itemSchema ?? this.itemSchema,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as List<V>?,
      constraints: constraints ?? this.constraints,
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
