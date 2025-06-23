part of 'schema.dart';

/// Schema for validating lists (`List<V>`) where each item conforms to `itemSchema`.
@immutable
final class ListSchema<V> extends AckSchema<List<V>> {
  final AckSchema<V> itemSchema;

  const ListSchema(
    this.itemSchema, {
    String? description,
    List<V>? defaultValue,
    List<Validator<List<V>>> constraints = const [],
  }) : super(
          schemaType: SchemaType.list,
          description: description,
          defaultValue: defaultValue,
          constraints: constraints,
        );

  /// Creates a new ListSchema with modified list-specific properties
  ListSchema<V> copyWithListProperties({
    AckSchema<V>? itemSchema,
    String? description,
    Object? defaultValue,
    List<Validator<List<V>>>? constraints,
  }) {
    return ListSchema(
      itemSchema ?? this.itemSchema,
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : (defaultValue as List<V>?),
      constraints: constraints ?? this.constraints,
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
    List<V>? convertedList,
    SchemaContext context,
  ) {
    if (convertedList == null) {
      // Should not be reached due to base class handling
      final constraintError = NonNullableConstraint().validate(null);

      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: constraintError != null ? [constraintError] : [],
          context: context,
        ),
      );
    }
    final validatedItems = <V>[];
    final itemErrors = <SchemaError>[];

    for (var i = 0; i < convertedList.length; i++) {
      final itemValue = convertedList[i];
      final itemContext = SchemaContext(
        name: '${context.name}[$i]', // Path for the item
        schema: itemSchema,
        value: itemValue,
      );

      final itemResult = itemSchema.parseAndValidate(itemValue, itemContext);

      itemResult.match(onOk: validatedItems.add, onFail: itemErrors.add);
    }

    if (itemErrors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: itemErrors, context: context),
      );
    }

    return SchemaResult.ok(validatedItems);
  }

  @override
  ListSchema<V> copyWithInternal({
    String? description,
    Object? defaultValue,
    List<Validator<List<V>>>? constraints,
  }) {
    return ListSchema(
      this.itemSchema,
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : (defaultValue as List<V>?),
      constraints: constraints ?? this.constraints,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    Map<String, Object?> schema = {
      'type': 'array',
      'items': itemSchema.toJsonSchema(),
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };

    // Check constraints that implement JsonSchemaSpec using dynamic typing
    // This avoids the unrelated type assertion issue
    final constraintSchemas = <Map<String, Object?>>[];
    for (final constraint in constraints) {
      // Use dynamic typing to check if constraint has toJsonSchema method
      try {
        final dynamic dynamicConstraint = constraint;
        if (dynamicConstraint is JsonSchemaSpec) {
          constraintSchemas.add(dynamicConstraint.toJsonSchema());
        }
      } catch (_) {
        // Ignore constraints that don't implement JsonSchemaSpec
      }
    }

    return constraintSchemas.fold(
      schema,
      (prev, current) => deepMerge(prev, current),
    );
  }
}
