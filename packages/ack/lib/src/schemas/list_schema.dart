part of 'schema.dart';

/// Schema for validating `List<ItemRuntime>` whose items conform to
/// [itemSchema], with boundary type `List<ItemBoundary>`.
@immutable
final class ListSchema<
  ItemBoundary extends Object,
  ItemRuntime extends Object
>
    extends AckSchema<List<ItemBoundary>, List<ItemRuntime>>
    with
        FluentSchema<
          List<ItemBoundary>,
          List<ItemRuntime>,
          ListSchema<ItemBoundary, ItemRuntime>
        > {
  final AckSchema<ItemBoundary, ItemRuntime> itemSchema;

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
  SchemaResult<List<ItemRuntime>> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;

    if (inputValue is! List) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: AckSchema.getSchemaType(inputValue),
          context: context,
        ),
      );
    }
    final inputList = inputValue;
    final validatedItems = <ItemRuntime>[];
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
        if (validatedItemValue is ItemRuntime) {
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

    final unmodifiableList = List<ItemRuntime>.unmodifiable(validatedItems);
    return applyConstraintsAndRefinements(unmodifiableList, context);
  }

  @override
  @protected
  SchemaResult<List<ItemBoundary>> encodeRuntime(
    List<ItemRuntime> value,
    SchemaContext context,
  ) {
    final encodedItems = <ItemBoundary>[];
    final errors = <SchemaError>[];
    for (var i = 0; i < value.length; i++) {
      final itemValue = value[i];
      final itemContext = context.createChild(
        name: '$i',
        schema: itemSchema,
        value: itemValue,
        pathSegment: '$i',
      );
      final encoded = itemSchema.safeEncode(itemValue, debugName: '$i');
      if (encoded.isFail) {
        errors.add(encoded.getError());
        continue;
      }
      final boundary = encoded.getOrNull();
      if (boundary is ItemBoundary) {
        encodedItems.add(boundary);
      } else {
        errors.add(
          SchemaEncodeError.typeMismatch(
            message: 'List item $i encoded to an unexpected type.',
            context: itemContext,
          ),
        );
      }
    }
    if (errors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: errors, context: context),
      );
    }
    return SchemaResult.ok(List<ItemBoundary>.unmodifiable(encodedItems));
  }

  @override
  ListSchema<ItemBoundary, ItemRuntime> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<List<ItemRuntime>>>? constraints,
    List<Refinement<List<ItemRuntime>>>? refinements,
  }) {
    return ListSchema<ItemBoundary, ItemRuntime>(
      itemSchema,
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
    if (other is! ListSchema<ItemBoundary, ItemRuntime>) return false;
    return baseFieldsEqual(other) && itemSchema == other.itemSchema;
  }

  @override
  int get hashCode => Object.hash(baseFieldsHashCode, itemSchema);
}
