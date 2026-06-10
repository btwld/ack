part of 'schema.dart';

/// Schema for validating `List<ItemRuntime>` whose items conform to
/// [itemSchema], with boundary type `List<ItemBoundary>`.
@immutable
final class ListSchema<ItemBoundary extends Object, ItemRuntime extends Object>
    extends AckSchema<List<ItemBoundary>, List<ItemRuntime>>
    with
        FluentSchema<
          List<ItemBoundary>,
          List<ItemRuntime>,
          ListSchema<ItemBoundary, ItemRuntime>
        > {
  final AckSchema<ItemBoundary, ItemRuntime> itemSchema;

  ListSchema(
    this.itemSchema, {
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  }) {
    if (itemSchema.isNullable) {
      throw ArgumentError.value(
        itemSchema,
        'itemSchema',
        'Ack.list(...) does not support nullable item schemas yet.',
      );
    }
  }

  @override
  SchemaType get schemaType => SchemaType.array;

  @override
  @protected
  SchemaResult<List<ItemRuntime>> parseWithContext(
    Object? value,
    SchemaContext context,
  ) => _processItems(value, context, parse: true);

  @override
  @protected
  SchemaResult<List<ItemRuntime>> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) => _processItems(value, context, parse: false);

  SchemaResult<List<ItemRuntime>> _processItems(
    Object? value,
    SchemaContext context, {
    required bool parse,
  }) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    if (value is! List) {
      return SchemaResult.fail(
        _buildTypeMismatch(
          expectedType: schemaType,
          actualValue: value,
          context: context,
        ),
      );
    }

    final typed = <ItemRuntime>[];
    final errors = <SchemaError>[];
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      final itemCtx = context.createChild(
        name: '$i',
        schema: itemSchema,
        value: item,
        pathSegment: SchemaPathSegment.index(i),
      );
      final r = parse
          ? itemSchema.parseWithContext(item, itemCtx)
          : itemSchema.validateRuntimeWithContext(item, itemCtx);
      if (r.isOk) {
        final v = r.getOrNull();
        if (v is ItemRuntime) {
          typed.add(v);
        } else {
          errors.add(
            SchemaValidationError(
              message:
                  'List item $i resolved to null. Use non-nullable item schemas for Ack.list.',
              context: itemCtx,
            ),
          );
        }
      } else {
        errors.add(r.getError());
      }
    }

    if (errors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: errors, context: context),
      );
    }

    return applyConstraintsAndRefinements(
      List<ItemRuntime>.unmodifiable(typed),
      context,
    );
  }

  @override
  @protected
  SchemaResult<List<ItemBoundary>> encodeWithContext(
    List<ItemRuntime> value,
    SchemaContext context,
  ) {
    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) return SchemaResult.fail(validated.getError());

    final encoded = <ItemBoundary>[];
    final errors = <SchemaError>[];
    for (var i = 0; i < value.length; i++) {
      final item = value[i];
      final itemCtx = context.createChild(
        name: '$i',
        schema: itemSchema,
        value: item,
        pathSegment: SchemaPathSegment.index(i),
        operation: SchemaOperation.encode,
      );
      try {
        final r = itemSchema.encodeWithContext(item, itemCtx);
        if (r.isFail) {
          errors.add(r.getError());
          continue;
        }
        final boundary = r.getOrNull();
        if (boundary is ItemBoundary) {
          encoded.add(boundary);
        } else {
          errors.add(
            SchemaEncodeError.typeMismatch(
              message: 'List item $i encoded to an unexpected type.',
              context: itemCtx,
            ),
          );
        }
      } catch (e, st) {
        errors.add(
          SchemaEncodeError.encoderThrew(
            message: 'List item $i encoder threw: $e',
            context: itemCtx,
            cause: e,
            stackTrace: st,
          ),
        );
      }
    }
    if (errors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: errors, context: context),
      );
    }
    return SchemaResult.ok(List<ItemBoundary>.unmodifiable(encoded));
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
