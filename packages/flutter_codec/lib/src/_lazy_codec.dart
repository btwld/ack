// ignore_for_file: implementation_imports, invalid_use_of_internal_member
// ignore_for_file: invalid_use_of_protected_member

import 'package:ack/src/constraints/constraint.dart' show Constraint;
import 'package:ack/src/context.dart' show SchemaContext;
import 'package:ack/src/schemas/schema.dart';
import 'package:ack/src/validation/schema_result.dart' show SchemaResult;

/// Private lazy schema wrapper used for recursive Flutter codec graphs.
///
/// The resolver is intentionally not invoked at construction time; the inner
/// schema is resolved on first parse/encode/schema traversal and then reused.
class _LazyCodec<Boundary extends Object, Runtime extends Object>
    extends AckSchema<Boundary, Runtime>
    with
        FluentSchema<Boundary, Runtime, _LazyCodec<Boundary, Runtime>>,
        WrapperSchema<Boundary, Runtime, _LazyCodec<Boundary, Runtime>> {
  _LazyCodec(
    this._resolver, {
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  final AckSchema<Boundary, Runtime> Function() _resolver;
  late final AckSchema<Boundary, Runtime> _resolved = _resolver();

  AckSchema<Boundary, Runtime> get _inner => _resolved;

  @override
  AnyAckSchema get inner => _inner as AnyAckSchema;

  @override
  SchemaType get schemaType => _inner.schemaType;

  @override
  SchemaResult<Runtime> parseWithContext(Object? value, SchemaContext context) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final result = _inner.parseWithContext(value, context);
    if (result.isFail) return SchemaResult.fail(result.getError());
    return validateRuntimeWithContext(result.getOrNull(), context);
  }

  @override
  SchemaResult<Runtime> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final result = _inner.validateRuntimeWithContext(value, context);
    if (result.isFail) return SchemaResult.fail(result.getError());
    return applyConstraintsAndRefinements(result.getOrNull()!, context);
  }

  @override
  SchemaResult<Boundary> encodeWithContext(
    Runtime value,
    SchemaContext context,
  ) {
    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) return SchemaResult.fail(validated.getError());
    return _inner.encodeWithContext(validated.getOrNull()!, context);
  }

  @override
  _LazyCodec<Boundary, Runtime> copyWithInner(AnyAckSchema newInner) {
    return _LazyCodec<Boundary, Runtime>(
      () => newInner as AckSchema<Boundary, Runtime>,
      isNullable: isNullable,
      isOptional: isOptional,
      description: description,
      constraints: constraints,
      refinements: refinements,
    );
  }

  @override
  _LazyCodec<Boundary, Runtime> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  }) {
    return _LazyCodec<Boundary, Runtime>(
      _resolver,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }
}

AckSchema<Boundary, Runtime> lazyCodec<
  Boundary extends Object,
  Runtime extends Object
>(AckSchema<Boundary, Runtime> Function() resolver) {
  return _LazyCodec<Boundary, Runtime>(resolver);
}
