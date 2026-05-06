part of 'schema.dart';

SchemaValidationError _nullListItemError(SchemaContext context) {
  return SchemaValidationError(
    message:
        'List item ${context.name} resolved to null. Ack.list items must be non-null.',
    context: context,
  );
}

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
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.array;

  @override
  @protected
  SchemaResult<List<V>> validate(Object? value, SchemaContext context) =>
      _validateChildren(
        value,
        context,
        (item, ctx) => itemSchema.validate(item, ctx),
      );

  @override
  @protected
  SchemaResult<List<V>> decodeBoundary(Object? input, SchemaContext context) =>
      _validateChildren(
        input,
        context,
        (item, ctx) => itemSchema.decodeBoundary(item, ctx),
      );

  SchemaResult<List<V>> _validateChildren(
    Object? value,
    SchemaContext context,
    SchemaResult<V> Function(Object? item, SchemaContext ctx) handle,
  ) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNull(context);
    }

    if (value is! List) {
      return failTypeMismatch(value, context);
    }

    final items = <V>[];
    final errors = <SchemaError>[];

    for (var i = 0; i < value.length; i++) {
      final itemValue = value[i];
      final itemContext = context.createChild(
        name: '$i',
        schema: itemSchema,
        value: itemValue,
        pathSegment: '$i',
      );

      final result = handle(itemValue, itemContext);
      if (result.isOk) {
        final validated = result.getOrNull();
        if (validated is V) {
          items.add(validated);
        } else {
          errors.add(_nullListItemError(itemContext));
        }
      } else {
        errors.add(result.getError());
      }
    }

    if (errors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: errors, context: context),
      );
    }

    return applyConstraintsAndRefinements(List<V>.unmodifiable(items), context);
  }

  @override
  @protected
  SchemaResult<Object> encodeBoundary(List<V> value, SchemaContext context) {
    final encodedItems = <Object?>[];
    final itemErrors = <SchemaError>[];

    for (var i = 0; i < value.length; i++) {
      final itemValue = value[i];
      final itemContext = context.createChild(
        name: '$i',
        schema: itemSchema,
        value: itemValue,
        pathSegment: '$i',
      );

      final itemResult = _encodeWithSchema(itemSchema, itemValue, itemContext);
      itemResult.match(onOk: encodedItems.add, onFail: itemErrors.add);
    }

    if (itemErrors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: itemErrors, context: context),
      );
    }

    return SchemaResult.ok(List<Object?>.unmodifiable(encodedItems));
  }

  @override
  ListSchema<V> copyWith({
    AckSchema<V>? itemSchema,
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<List<V>>>? constraints,
    List<Refinement<List<V>>>? refinements,
  }) {
    return ListSchema(
      itemSchema ?? this.itemSchema,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() => buildJsonSchemaWithNullable(
    typeSchema: {'type': 'array', 'items': itemSchema.toJsonSchema()},
  );

  @override
  Map<String, Object?> toMap() {
    return {
      'type': schemaType.typeName,
      'isNullable': isNullable,
      'description': description,
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
