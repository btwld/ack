part of 'schema.dart';

enum _StringNormalizer {
  trim,
  toLowerCase,
  toUpperCase;

  String apply(String value) => switch (this) {
    _StringNormalizer.trim => value.trim(),
    _StringNormalizer.toLowerCase => value.toLowerCase(),
    _StringNormalizer.toUpperCase => value.toUpperCase(),
  };
}

@immutable
final class _StringNormalizerStep {
  const _StringNormalizerStep({
    required this.normalizer,
    required this.constraintIndex,
    required this.refinementIndex,
  });

  final _StringNormalizer normalizer;
  final int constraintIndex;
  final int refinementIndex;

  @override
  bool operator ==(Object other) =>
      other is _StringNormalizerStep &&
      normalizer == other.normalizer &&
      constraintIndex == other.constraintIndex &&
      refinementIndex == other.refinementIndex;

  @override
  int get hashCode => Object.hash(normalizer, constraintIndex, refinementIndex);
}

/// Schema for validating string values.
@immutable
final class StringSchema extends AckSchema<String, String>
    with FluentSchema<String, String, StringSchema> {
  final List<_StringNormalizerStep> _normalizers;

  const StringSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  }) : _normalizers = const [];

  const StringSchema._({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
    List<_StringNormalizerStep> normalizers = const [],
  }) : _normalizers = normalizers;

  StringSchema _withNormalizer(_StringNormalizer normalizer) {
    return StringSchema._(
      isNullable: isNullable,
      isOptional: isOptional,
      description: description,
      constraints: constraints,
      refinements: refinements,
      normalizers: List.unmodifiable([
        ..._normalizers,
        _StringNormalizerStep(
          normalizer: normalizer,
          constraintIndex: _constraints.length,
          refinementIndex: _refinements.length,
        ),
      ]),
    );
  }

  @override
  @protected
  SchemaResult<String> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    final nullResult = handleNullInput(value, context);
    if (nullResult != null) return nullResult;

    if (value is! String) {
      return SchemaResult.fail(
        _buildTypeMismatch(
          expectedType: schemaType,
          actualValue: value,
          context: context,
        ),
      );
    }

    if (_normalizers.isEmpty) {
      return applyConstraintsAndRefinements(value, context);
    }

    var current = value;
    var constraintStart = 0;
    var refinementStart = 0;

    for (final step in _normalizers) {
      final constraintEnd = step.constraintIndex.clamp(
        constraintStart,
        _constraints.length,
      );
      final refinementEnd = step.refinementIndex.clamp(
        refinementStart,
        _refinements.length,
      );
      final segmentResult = _applySegment(
        current,
        context,
        constraintStart: constraintStart,
        constraintEnd: constraintEnd,
        refinementStart: refinementStart,
        refinementEnd: refinementEnd,
      );
      if (segmentResult.isFail) return segmentResult;
      constraintStart = constraintEnd;
      refinementStart = refinementEnd;
      current = step.normalizer.apply(current);
    }

    return _applySegment(
      current,
      context,
      constraintStart: constraintStart,
      constraintEnd: _constraints.length,
      refinementStart: refinementStart,
      refinementEnd: _refinements.length,
    );
  }

  SchemaResult<String> _applySegment(
    String value,
    SchemaContext context, {
    required int constraintStart,
    required int constraintEnd,
    required int refinementStart,
    required int refinementEnd,
  }) {
    return applyConstraintsAndRefinements(
      value,
      context,
      constraints: _constraints.getRange(constraintStart, constraintEnd),
      refinements: _refinements.getRange(refinementStart, refinementEnd),
    );
  }

  @override
  @protected
  SchemaResult<String> encodeWithContext(String value, SchemaContext context) =>
      validateRuntimeWithContext(value, context);

  @override
  StringSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<String>>? constraints,
    List<Refinement<String>>? refinements,
  }) {
    return StringSchema._(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
      normalizers: _normalizers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StringSchema) return false;

    return baseFieldsEqual(other) &&
        const ListEquality<_StringNormalizerStep>().equals(
          _normalizers,
          other._normalizers,
        );
  }

  @override
  SchemaType get schemaType => SchemaType.string;

  @override
  int get hashCode => Object.hash(
    baseFieldsHashCode,
    const ListEquality<_StringNormalizerStep>().hash(_normalizers),
  );

  /// Trims leading and trailing whitespace from the string.
  ///
  /// Runs in declaration order with any constraints and refinements chained
  /// before or after this call, on both `parse` and `encode`.
  StringSchema trim() => _withNormalizer(_StringNormalizer.trim);

  /// Converts the string to lowercase.
  ///
  /// Runs in declaration order with any constraints and refinements chained
  /// before or after this call, on both `parse` and `encode`.
  StringSchema toLowerCase() => _withNormalizer(_StringNormalizer.toLowerCase);

  /// Converts the string to uppercase.
  ///
  /// Runs in declaration order with any constraints and refinements chained
  /// before or after this call, on both `parse` and `encode`.
  StringSchema toUpperCase() => _withNormalizer(_StringNormalizer.toUpperCase);
}
