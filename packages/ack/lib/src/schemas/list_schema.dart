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
  SchemaResult<List<V>> decodeBoundary(Object? input, SchemaContext context) {
    if (input is! List) {
      return SchemaResult.fail(
        AckSchema.parseTypeMismatch(
          expectedType: schemaType,
          actualValue: input,
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

  /// Validates a runtime list and its items.
  ///
  /// Runs item validation through each child's `_validateRuntime` before the
  /// list-level constraints/refinements, so refinements observe a
  /// structurally-valid list. Accepts any [List] (including type-erased
  /// `List<Object?>`); the returned list is a fresh `List<V>.unmodifiable`.
  ///
  /// Null items are rejected even when [itemSchema] is nullable, because
  /// `V extends Object` and the list's runtime form is `List<V>` — matching
  /// parse semantics where null items fail the `is V` check.
  @override
  @protected
  SchemaResult<List<V>> _validateRuntime(Object? value, SchemaContext context) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return SchemaResult.fail(_failNullForRuntime(context));
    }
    if (value is! List) {
      return SchemaResult.fail(_failTypeMismatchForRuntime(value, context));
    }

    final validatedItems = <V>[];
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
      if (v is V) {
        validatedItems.add(v);
        continue;
      }
      // null (item schema is nullable) or wrong runtime type: list items are
      // typed `V extends Object` and must be non-null. This matches parse
      // semantics on Ack.list.
      itemErrors.add(
        SchemaValidationError(
          message:
              'List item $i resolved to null. Use non-nullable item schemas for Ack.list.',
          context: itemContext,
        ),
      );
    }

    if (itemErrors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: itemErrors, context: context),
      );
    }

    final canonical = List<V>.unmodifiable(validatedItems);
    return applyConstraintsAndRefinements(canonical, context);
  }

  /// Recursively encodes the runtime [List<V>] back to its boundary form by
  /// invoking each item's `encodeBoundary`. List-level validation has already
  /// run in [_validateRuntime]; here we only translate runtime → boundary.
  /// Errors propagate under [SchemaNestedError] with per-index paths.
  @override
  @protected
  SchemaResult<Object> encodeBoundary(List<V> value, SchemaContext context) {
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

      final encoded = itemSchema.encodeBoundary(itemValue, itemContext);
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
