part of 'schema.dart';

/// Schema for validating lists (`List<V>`) where each item conforms to `itemSchema`.
@immutable
final class ListSchema<V extends Object> extends AckSchema<List<V>> {
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
        return SchemaResult.fail(SchemaConstraintsError(
          constraints: [
            InvalidTypeConstraint(expectedType: List<V>).validate(inputValue)!,
          ],
          context: context,
        ));
      }
    }

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: [
        InvalidTypeConstraint(expectedType: List).validate(inputValue)!,
      ],
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
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: [NonNullableConstraint().validate(null)!],
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
  ListSchema<V> copyWith({
    String? description,
    Object? defaultValue,
    List<Validator<List<V>>>? constraints,
    AckSchema<V>? itemSchema,
  }) {
    return ListSchema(
      itemSchema ?? this.itemSchema,
      description: description ?? this.description,
      defaultValue: defaultValue == ackRawDefaultValue
          ? this.defaultValue
          : defaultValue as List<V>?,
      constraints: constraints ?? this.constraints,
    );
  }

  @override
  ListSchema<V> withDefault(List<V> val) {
    return copyWith(defaultValue: val);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    Map<String, Object?> schema = {
      'type': 'array',
      'items': itemSchema.toJsonSchema(),
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
    final constraintSchemas = constraints
        .whereType<JsonSchemaSpec<List<V>>>()
        .map((c) => c.toJsonSchema())
        .fold<Map<String, Object?>>(
      {},
      (prev, current) => deepMerge(prev, current),
    );

    return deepMerge(schema, constraintSchemas);
  }

  @override
  ListSchema<V> addConstraint(Validator<List<V>> constraint) {
    return copyWith(constraints: [...constraints, constraint]);
  }

  @override
  ListSchema<V> addConstraints(List<Validator<List<V>>> newConstraints) {
    return copyWith(constraints: [...constraints, ...newConstraints]);
  }

  @override
  ListSchema<V> withDescription(String? newDescription) {
    return copyWith(description: newDescription);
  }
}
