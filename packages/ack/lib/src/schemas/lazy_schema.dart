part of 'schema.dart';

/// Defers resolving another schema until parse, validation, or encode time.
///
/// This enables recursive schema graphs where a child schema needs to refer
/// back to an outer schema that is assigned after construction.
@immutable
final class LazySchema<Boundary extends Object, Runtime extends Object>
    extends AckSchema<Boundary, Runtime>
    with FluentSchema<Boundary, Runtime, LazySchema<Boundary, Runtime>> {
  LazySchema(
    this.name,
    this._builder, {
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  /// Human-readable name for this deferred schema reference.
  final String name;

  final AckSchema<Boundary, Runtime> Function() _builder;

  late final AckSchema<Boundary, Runtime> _target = _builder();

  @internal
  AckSchema<Boundary, Runtime> get target => _target;

  @internal
  int get runtimeConstraintCount => _constraints.length;

  @internal
  int get runtimeRefinementCount => _refinements.length;

  @override
  SchemaType get schemaType => SchemaType.lazy;

  @override
  @protected
  SchemaResult<Runtime> parseWithContext(Object? value, SchemaContext context) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final result = _target.parseWithContext(value, context);
    if (result.isFail) return SchemaResult.fail(result.getError());

    final runtime = result.getOrNull();
    if (runtime == null) return SchemaResult.ok(null);
    return applyConstraintsAndRefinements(runtime, context);
  }

  @override
  @protected
  SchemaResult<Runtime> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final result = _target.validateRuntimeWithContext(value, context);
    if (result.isFail) return SchemaResult.fail(result.getError());

    final runtime = result.getOrNull();
    if (runtime == null) return SchemaResult.ok(null);
    return applyConstraintsAndRefinements(runtime, context);
  }

  @override
  @protected
  SchemaResult<Boundary> encodeWithContext(
    Runtime value,
    SchemaContext context,
  ) {
    final ownChecked = applyConstraintsAndRefinements(value, context);
    if (ownChecked.isFail) return SchemaResult.fail(ownChecked.getError());
    return _target.encodeWithContext(ownChecked.getOrThrow()!, context);
  }

  @override
  LazySchema<Boundary, Runtime> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  }) {
    return LazySchema<Boundary, Runtime>(
      name,
      _builder,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toMap() => {...super.toMap(), 'name': name};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LazySchema<Boundary, Runtime>) return false;
    return baseFieldsEqual(other) &&
        name == other.name &&
        identical(_builder, other._builder);
  }

  @override
  int get hashCode {
    return Object.hash(baseFieldsHashCode, name, identityHashCode(_builder));
  }
}
