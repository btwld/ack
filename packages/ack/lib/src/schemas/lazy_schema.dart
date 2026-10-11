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
  /// Default recursion cap applied to `Ack.lazy` schemas that do not
  /// specify their own [maxDepth].
  static const defaultMaxDepth = 100;

  /// Human-readable name for this deferred schema reference.
  final String name;

  /// Maximum number of times this lazy schema may appear in its active context
  /// chain before parsing, runtime validation, or encoding fails.
  final int maxDepth;

  final AckSchema<Boundary, Runtime> Function() _builder;
  final Object _recursionToken;

  late final AckSchema<Boundary, Runtime> _target = _builder();

  LazySchema(
    this.name,
    this._builder, {
    this.maxDepth = defaultMaxDepth,
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  }) : _recursionToken = Object() {
    _validateMaxDepth(maxDepth);
  }

  LazySchema._copy(
    this.name,
    this._builder,
    this._recursionToken, {
    this.maxDepth = defaultMaxDepth,
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  }) {
    _validateMaxDepth(maxDepth);
  }

  static void _validateMaxDepth(int maxDepth) {
    if (maxDepth < 1) {
      throw ArgumentError.value(maxDepth, 'maxDepth', 'Must be >= 1.');
    }
  }

  @internal
  AckSchema<Boundary, Runtime> get target => _target;

  /// Count of runtime-only constraints, including the always-present
  /// max-depth check that every `Ack.lazy` schema enforces.
  @internal
  int get runtimeConstraintCount => _constraints.length + 1;

  @internal
  int get runtimeRefinementCount => _refinements.length;

  @override
  @protected
  SchemaResult<Runtime> parseWithContext(Object? value, SchemaContext context) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    final recursionContext = _enterRecursion(value, context);
    final depthResult = _checkMaxDepth<Runtime>(recursionContext);
    if (depthResult != null) return depthResult;

    final target = _target;
    final result = target.parseWithContext(value, recursionContext);
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

    final recursionContext = _enterRecursion(value, context);
    final depthResult = _checkMaxDepth<Runtime>(recursionContext);
    if (depthResult != null) return depthResult;

    final target = _target;
    final result = target.validateRuntimeWithContext(value, recursionContext);
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
    final recursionContext = _enterRecursion(value, context);
    final depthResult = _checkMaxDepth<Boundary>(recursionContext);
    if (depthResult != null) return depthResult;

    final ownChecked = applyConstraintsAndRefinements(value, context);
    if (ownChecked.isFail) return SchemaResult.fail(ownChecked.getError());

    final target = _target;
    return target.encodeWithContext(ownChecked.getOrThrow()!, recursionContext);
  }

  SchemaContext _enterRecursion(Object? value, SchemaContext context) {
    return _LazyRecursionContext(
      name: name,
      schema: this as AnyAckSchema,
      recursionToken: _recursionToken,
      value: value,
      parent: context,
    );
  }

  SchemaResult<T>? _checkMaxDepth<T extends Object>(SchemaContext context) {
    var depth = 0;
    for (SchemaContext? c = context; c != null; c = c.parent) {
      if (c is _LazyRecursionContext &&
          identical(c.recursionToken, _recursionToken)) {
        depth++;
      }
    }
    if (depth <= maxDepth) return null;

    return SchemaResult.fail(
      SchemaConstraintsError(
        constraints: [
          ConstraintError(
            constraint: _LazyMaxDepthConstraint(maxDepth),
            message: 'Maximum recursion depth ($maxDepth) exceeded.',
            context: {'depth': depth, 'maxDepth': maxDepth, 'lazyName': name},
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
    return LazySchema<Boundary, Runtime>._copy(
      name,
      _builder,
      _recursionToken,
      maxDepth: maxDepth ?? this.maxDepth,
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

/// Marks one active lazy invocation without conflating it with structural
/// child contexts created by object, list, union, or wrapper schemas.
final class _LazyRecursionContext extends SchemaContext {
  _LazyRecursionContext({
    required String name,
    required AnyAckSchema schema,
    required this.recursionToken,
    required Object? value,
    required SchemaContext parent,
  }) : super(
         name: name,
         schema: schema,
         value: value,
         parent: parent,
         pathSegment: '',
         operation: parent.operation,
       );

  final Object recursionToken;
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
