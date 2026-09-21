part of 'schema.dart';

/// Schema for JSON objects with arbitrary string keys whose values all
/// conform to [valueSchema].
///
/// `MapSchema` models open records such as `Map<String, int>` or a `JsonMap`.
/// Use `Ack.object(...)` for objects with declared properties.
///
/// ## Null values
///
/// A value may be `null` only when [valueSchema] accepts null, so
/// `Ack.map(Ack.any().nullable())` models `Map<String, Object?>`. Because
/// nullability is a runtime flag in Ack, the static value types are nullable
/// even when [valueSchema] rejects null.
///
/// The `optional` flag of [valueSchema] has no effect: a map has no declared
/// keys that could be missing.
@immutable
final class MapSchema<ValueBoundary extends Object, ValueRuntime extends Object>
    extends AckSchema<Map<String, ValueBoundary?>, Map<String, ValueRuntime?>>
    with
        FluentSchema<
          Map<String, ValueBoundary?>,
          Map<String, ValueRuntime?>,
          MapSchema<ValueBoundary, ValueRuntime>
        > {
  final AckSchema<ValueBoundary, ValueRuntime> valueSchema;

  const MapSchema(
    this.valueSchema, {
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  SchemaResult<Map<String, ValueRuntime?>> _processEntries(
    Object? value,
    SchemaContext context, {
    required bool parse,
  }) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final mapValue = jsonMapOrNull(value);
    if (mapValue == null) {
      return SchemaResult.fail(
        _buildTypeMismatch(
          expectedType: schemaType,
          actualValue: value,
          context: context,
        ),
      );
    }

    final isEncode = context.operation == SchemaOperation.encode;
    final typed = <String, ValueRuntime?>{};
    final errors = <SchemaError>[];
    for (final MapEntry(:key, value: item) in mapValue.entries) {
      final itemCtx = context.createChild(
        name: key,
        schema: valueSchema,
        value: item,
        pathSegment: key,
      );
      if (item == null && isEncode) {
        if (valueSchema.acceptsNull) {
          typed[key] = null;
        } else {
          errors.add(SchemaEncodeError.nonNullable(context: itemCtx));
        }
        continue;
      }
      final r = parse
          ? valueSchema.parseWithContext(item, itemCtx)
          : valueSchema.validateRuntimeWithContext(item, itemCtx);
      r.match(
        onOk: (v) {
          typed[key] = v;
        },
        onFail: errors.add,
      );
    }

    if (errors.isNotEmpty) {
      return SchemaResult.fail(
        SchemaNestedError(errors: errors, context: context),
      );
    }

    return applyConstraintsAndRefinements(
      Map<String, ValueRuntime?>.unmodifiable(typed),
      context,
    );
  }

  @override
  @protected
  SchemaResult<Map<String, ValueRuntime?>> parseWithContext(
    Object? value,
    SchemaContext context,
  ) => _processEntries(value, context, parse: true);

  @override
  @protected
  SchemaResult<Map<String, ValueRuntime?>> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) => _processEntries(value, context, parse: false);

  @override
  @protected
  SchemaResult<Map<String, ValueBoundary?>> encodeWithContext(
    Map<String, ValueRuntime?> value,
    SchemaContext context,
  ) {
    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) return SchemaResult.fail(validated.getError());

    final encoded = <String, ValueBoundary?>{};
    final errors = <SchemaError>[];
    for (final MapEntry(:key, value: item) in value.entries) {
      if (item == null) {
        encoded[key] = null;
        continue;
      }
      final itemCtx = context.createChild(
        name: key,
        schema: valueSchema,
        value: item,
        pathSegment: key,
        operation: SchemaOperation.encode,
      );
      try {
        final r = valueSchema.encodeWithContext(item, itemCtx);
        if (r.isFail) {
          errors.add(r.getError());
        } else {
          encoded[key] = r.getOrNull();
        }
      } catch (e, st) {
        _rethrowIfError(e, st);
        errors.add(
          SchemaEncodeError.encoderThrew(
            message: 'Map value "$key" encoder threw: $e',
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

    return SchemaResult.ok(Map<String, ValueBoundary?>.unmodifiable(encoded));
  }

  @override
  MapSchema<ValueBoundary, ValueRuntime> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Map<String, ValueRuntime?>>>? constraints,
    List<Refinement<Map<String, ValueRuntime?>>>? refinements,
  }) {
    return MapSchema(
      valueSchema,
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
      'valueSchema': valueSchema.schemaType.typeName,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MapSchema<ValueBoundary, ValueRuntime>) return false;

    return baseFieldsEqual(other) && valueSchema == other.valueSchema;
  }

  @override
  SchemaType get schemaType => SchemaType.object;

  @override
  int get hashCode => Object.hash(baseFieldsHashCode, valueSchema);
}
