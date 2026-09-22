part of 'schema.dart';

/// Validates with another schema while preserving the original boundary value.
///
/// This is useful when callers need a composable schema for validating wire
/// data without retaining any runtime values produced by nested codecs.
@immutable
final class BoundarySchema<Boundary extends Object>
    extends AckSchema<Boundary, Boundary>
    with
        FluentSchema<Boundary, Boundary, BoundarySchema<Boundary>>,
        WrapperSchema<Boundary, Boundary, BoundarySchema<Boundary>> {
  @override
  final AckSchema<Boundary, Object> inner;

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

  SchemaResult<Boundary> _validateBoundary(
    Object? value,
    SchemaContext context,
  ) {
    final result = inner.parseWithContext(value, context);
    if (result.isFail) return SchemaResult.fail(result.getError());
    if (value == null) return SchemaResult.ok(null);

    final Boundary boundary;
    final normalizedMap = jsonMapOrNull(value);
    if (value is Boundary) {
      boundary = value;
    } else if (normalizedMap is Boundary) {
      boundary = normalizedMap as Boundary;
    } else {
      final runtime = result.getOrNull()!;
      final encodeContext = context.createChild(
        name: context.name,
        schema: inner,
        value: runtime,
        pathSegment: '',
        operation: SchemaOperation.encode,
      );
      final encoded = inner.encodeWithContext(runtime, encodeContext);
      if (encoded.isFail) return SchemaResult.fail(encoded.getError());
      boundary = encoded.getOrNull()!;
    }

    return applyConstraintsAndRefinements(boundary, context);
  }

  @override
  @protected
  SchemaResult<Boundary> parseWithContext(
    Object? value,
    SchemaContext context,
  ) => _validateBoundary(value, context);

  @override
  @protected
  SchemaResult<Boundary> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) => _validateBoundary(value, context);

  @override
  @protected
  SchemaResult<Boundary> encodeWithContext(
    Boundary value,
    SchemaContext context,
  ) => _validateBoundary(value, context);

  @override
  BoundarySchema<Boundary> copyWithInner(AnyAckSchema newInner) {
    return BoundarySchema<Boundary>(
      newInner as AckSchema<Boundary, Object>,
      isNullable: isNullable,
      isOptional: isOptional,
      description: description,
      constraints: constraints,
      refinements: refinements,
    );
  }

  @override
  BoundarySchema<Boundary> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Boundary>>? constraints,
    List<Refinement<Boundary>>? refinements,
  }) {
    return BoundarySchema<Boundary>(
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
    if (other is! BoundarySchema<Boundary>) return false;

    return baseFieldsEqual(other) && inner == other.inner;
  }

  @override
  SchemaType get schemaType => inner.schemaType;

  @override
  int get hashCode => Object.hash(baseFieldsHashCode, inner);
}
