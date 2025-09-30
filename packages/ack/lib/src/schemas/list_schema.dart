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
  });

  @override
  JsonType get acceptedType => JsonType.array;

  /// ListSchema uses custom validation logic for items,
  /// so it overrides parseAndValidate directly.
  @override
  @protected
  SchemaResult<List<V>> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Use centralized null handling
    if (inputValue == null) return handleNullInput(context);

    // Use centralized type checking
    final typeError = checkTypeMatch(inputValue, context);
    if (typeError != null) return typeError;

    // Custom list validation logic
    final inputList = inputValue as List;
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
      return SchemaResult.fail(SchemaNestedError(
        errors: itemErrors,
        context: context,
      ));
    }

    // Use centralized constraints and refinements check
    return applyConstraintsAndRefinements(validatedItems, context);
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
    if (defaultValue != null) {
      throw StateError('Default not supported for ListSchema');
    }
    return ListSchema(
      itemSchema ?? this.itemSchema,
      isNullable: isNullable ?? this.isNullable,
      description: description ?? this.description,
      // ignore defaultValue by design
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    final schema = {
      'type': isNullable ? ['array', 'null'] : 'array',
      'items': itemSchema.toJsonSchema(),
      if (description != null) 'description': description,
    };

    return mergeConstraintSchemas(schema);
  }
}
