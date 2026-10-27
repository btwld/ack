part of 'schema.dart';

/// Wire view of a JSON object schema: validates with [inner] and returns the
/// JSON instead of the runtime value.
///
/// Parse, runtime validation, and encode all run the full parse of [inner]
/// (nested models, codecs, defaults, and refinements), never an encoder. Each
/// returns a detached, recursively unmodifiable copy of the validated input
/// map, so the result never depends on the input's container type and never
/// aliases the caller's map. Each wire view copies its whole subtree, so
/// compose wire views inside a plain `Ack.object(...)` rather than inside
/// another wire view.
///
/// The wrapper's own nullability decides whether `null` is accepted; `null`
/// never reaches [inner]. A default inside [inner] therefore does not apply.
/// Put `withDefault` outside the wrapper instead.
@immutable
final class BoundarySchema extends AckSchema<JsonMap, JsonMap>
    with
        FluentSchema<JsonMap, JsonMap, BoundarySchema>,
        WrapperSchema<JsonMap, JsonMap, BoundarySchema> {
  @override
  final AckSchema<JsonMap, Object> inner;

  BoundarySchema(
    this.inner, {
    bool? isNullable,
    bool? isOptional,
    String? description,
    super.constraints,
    super.refinements,
  }) : super(
         isNullable: isNullable ?? inner.acceptsNull,
         isOptional: isOptional ?? inner.isOptional,
         description: description ?? inner.description,
       );

  SchemaResult<JsonMap> _validateBoundary(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    // Encode leniency (for example, omitted defaults) must not let the wire
    // view accept a value that its parse would reject.
    final parseContext = context.operation == SchemaOperation.parse
        ? context
        : context.createChild(
            name: context.name,
            schema: inner,
            value: value,
            pathSegment: '',
            operation: SchemaOperation.parse,
          );
    final result = inner.parseWithContext(value, parseContext);
    if (result.isFail) return SchemaResult.fail(result.getError());

    // Copying also canonicalizes any string-keyed map to a JsonMap.
    final copy = deepUnmodifiableCopy(value);
    if (copy is! JsonMap) {
      return SchemaResult.fail(
        _buildTypeMismatch(
          expectedType: schemaType,
          actualValue: value,
          context: context,
        ),
      );
    }

    return applyConstraintsAndRefinements(copy, context);
  }

  @override
  @protected
  SchemaResult<JsonMap> parseWithContext(
    Object? value,
    SchemaContext context,
  ) => _validateBoundary(value, context);

  @override
  @protected
  SchemaResult<JsonMap> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) => _validateBoundary(value, context);

  @override
  @protected
  SchemaResult<JsonMap> encodeWithContext(
    JsonMap value,
    SchemaContext context,
  ) => _validateBoundary(value, context);

  @override
  BoundarySchema copyWithInner(AnyAckSchema newInner) {
    return BoundarySchema(
      newInner as AckSchema<JsonMap, Object>,
      isNullable: isNullable,
      isOptional: isOptional,
      description: description,
      constraints: constraints,
      refinements: refinements,
    );
  }

  @override
  BoundarySchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<JsonMap>>? constraints,
    List<Refinement<JsonMap>>? refinements,
  }) {
    return BoundarySchema(
      inner,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BoundarySchema) return false;

    return baseFieldsEqual(other) && inner == other.inner;
  }

  @override
  SchemaType get schemaType => inner.schemaType;

  @override
  int get hashCode => Object.hash(baseFieldsHashCode, inner);
}
