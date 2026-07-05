part of 'schema.dart';

/// Defers resolving another schema until parse, validation, encode, or export
/// time.
///
/// This enables recursive schema graphs where a child schema needs to refer
/// back to an outer schema that is assigned after construction.
@immutable
final class LazySchema<Boundary extends Object, Runtime extends Object>
    extends AckSchema<Boundary, Runtime>
    with FluentSchema<Boundary, Runtime, LazySchema<Boundary, Runtime>> {
  /// Human-readable name for this deferred schema reference.
  final String name;

  /// Maximum number of times this lazy schema may appear in its active context
  /// chain before parsing, runtime validation, or encoding fails.
  ///
  /// A value of `null` leaves recursion depth unlimited.
  final int? maxDepth;

  final AckSchema<Boundary, Runtime> Function() _builder;

  late final AckSchema<Boundary, Runtime> _target = _builder();

  LazySchema(
    this.name,
    this._builder, {
    this.maxDepth,
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @internal
  AckSchema<Boundary, Runtime> get target => _target;

  @internal
  int get runtimeConstraintCount =>
      _constraints.length + (maxDepth == null ? 0 : 1);

  @internal
  int get runtimeRefinementCount => _refinements.length;

  @override
  @protected
  SchemaResult<Runtime> parseWithContext(Object? value, SchemaContext context) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final depthResult = _checkMaxDepth<Runtime>(context);
    if (depthResult != null) return depthResult;

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

    final depthResult = _checkMaxDepth<Runtime>(context);
    if (depthResult != null) return depthResult;

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
    final depthResult = _checkMaxDepth<Boundary>(context);
    if (depthResult != null) return depthResult;

    final ownChecked = applyConstraintsAndRefinements(value, context);
    if (ownChecked.isFail) return SchemaResult.fail(ownChecked.getError());

    return _target.encodeWithContext(ownChecked.getOrThrow()!, context);
  }

  SchemaResult<T>? _checkMaxDepth<T extends Object>(SchemaContext context) {
    final limit = maxDepth;
    if (limit == null) return null;

    var depth = 0;
    for (SchemaContext? c = context; c != null; c = c.parent) {
      if (identical(c.schema, this)) depth++;
    }
    if (depth <= limit) return null;

    return SchemaResult.fail(
      SchemaConstraintsError(
        constraints: [
          ConstraintError(
            constraint: _LazyMaxDepthConstraint(limit),
            message: 'Maximum recursion depth ($limit) exceeded.',
            context: {'depth': depth, 'maxDepth': limit, 'lazyName': name},
          ),
        ],
        context: context,
      ),
    );
  }

  @override
  LazySchema<Boundary, Runtime> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
    int? maxDepth,
  }) {
    return LazySchema(
      name,
      _builder,
      maxDepth: maxDepth ?? this.maxDepth,
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  Map<String, Object?> toMap() => {
    ...super.toMap(),
    'name': name,
    'maxDepth': maxDepth,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LazySchema<Boundary, Runtime>) return false;

    return baseFieldsEqual(other) &&
        name == other.name &&
        maxDepth == other.maxDepth &&
        identical(_builder, other._builder);
  }

  @override
  SchemaType get schemaType => SchemaType.lazy;

  @override
  int get hashCode {
    return Object.hash(
      baseFieldsHashCode,
      name,
      maxDepth,
      identityHashCode(_builder),
    );
  }
}

final class _LazyMaxDepthConstraint extends Constraint<Object> {
  _LazyMaxDepthConstraint(this.maxDepth)
    : super(
        constraintKey: 'lazy_max_depth',
        description: 'Lazy recursion depth must not exceed $maxDepth.',
      );

  final int maxDepth;

  @override
  Map<String, Object?> toMap() => {...super.toMap(), 'maxDepth': maxDepth};
}
