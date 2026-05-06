import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../common_types.dart';
import '../constraints/constraint.dart';
import '../constraints/pattern_constraint.dart';
import '../constraints/validators.dart';
import '../context.dart';
import '../helpers.dart';
import '../validation/schema_error.dart';
import '../validation/schema_result.dart';

part 'any_of_schema.dart';
part 'any_schema.dart';
part 'boolean_schema.dart';
part 'codec_schema.dart';
part 'default_schema.dart';
part 'discriminated_object_schema.dart';
part 'enum_schema.dart';
part 'fluent_schema.dart';
part 'instance_schema.dart';
part 'list_schema.dart';
part 'num_schema.dart';
part 'object_schema.dart';
part 'string_schema.dart';
part 'transformed_schema.dart';
part 'testing/testing_schemas.dart';

typedef Refinement<T> = ({bool Function(T value) validate, String message});

/// Operation currently using a schema.
///
/// Schemas have one validation primitive. The operation is carried in context
/// only for behaviors that are intentionally directional, such as defaults
/// applying during parse but not during encode.
enum SchemaOperation { parse, encode }

/// Schema type categories used for JSON Schema output and error messages.
enum SchemaType {
  string('string'),
  integer('integer'),
  number('number'),
  boolean('boolean'),
  object('object'),
  array('array'),
  null_('null'),
  any('any'),
  anyOf('anyOf'),
  enum_('enum'),
  discriminated('discriminated');

  const SchemaType(this.typeName);

  final String typeName;

  static SchemaType of(Object? value) => switch (value) {
    null => SchemaType.null_,
    Map() => SchemaType.object,
    List() => SchemaType.array,
    Enum() => SchemaType.enum_,
    String() => SchemaType.string,
    bool() => SchemaType.boolean,
    int() => SchemaType.integer,
    double() || num() => SchemaType.number,
    _ => throw ArgumentError('Unknown schema type for value: $value'),
  };
}

SchemaResult<Object> _encodeWithSchema(
  AckSchema schema,
  Object? value,
  SchemaContext context,
) {
  final result = schema.validate(value, context);
  if (result.isFail) return result.castFail();

  final validated = result.getOrNull();
  if (validated == null) return SchemaResult.ok(null);

  return schema.encodeBoundary(validated, context);
}

@immutable
sealed class AckSchema<DartType extends Object> {
  final bool isNullable;
  final bool isOptional;
  final String? description;
  final List<Constraint<DartType>> _constraints;
  final List<Refinement<DartType>> _refinements;

  /// Returns an unmodifiable view of the constraints for this schema.
  List<Constraint<DartType>> get constraints => List.unmodifiable(_constraints);

  /// Returns an unmodifiable view of the refinements for this schema.
  List<Refinement<DartType>> get refinements => List.unmodifiable(_refinements);

  const AckSchema({
    this.isNullable = false,
    this.isOptional = false,
    this.description,
    List<Constraint<DartType>> constraints = const [],
    List<Refinement<DartType>> refinements = const [],
  }) : _constraints = constraints,
       _refinements = refinements;

  /// Utility method to get the schema type of any value.
  static SchemaType getSchemaType(Object? value) => SchemaType.of(value);

  /// The schema type category for this schema.
  @protected
  SchemaType get schemaType;

  /// Human-readable type name for error messages and debugging.
  String get schemaTypeName => schemaType.typeName;

  /// Applies constraints and refinements to a validated value.
  @protected
  SchemaResult<DartType> applyConstraintsAndRefinements(
    DartType value,
    SchemaContext context,
  ) {
    final constraintViolations = _checkConstraints(value, context);
    if (constraintViolations.isNotEmpty) {
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: constraintViolations,
          context: context,
        ),
      );
    }
    return _runRefinements(value, context);
  }

  @protected
  List<ConstraintError> _checkConstraints(
    DartType value,
    SchemaContext context,
  ) {
    if (constraints.isEmpty) return const [];
    final errors = <ConstraintError>[];
    for (final constraint in constraints) {
      if (constraint is Validator<DartType>) {
        final error = constraint.validate(value);
        if (error != null) {
          errors.add(error);
        }
      }
    }

    return errors;
  }

  @protected
  SchemaResult<DartType> _runRefinements(
    DartType value,
    SchemaContext context,
  ) {
    for (final refinement in refinements) {
      if (!refinement.validate(value)) {
        return SchemaResult.fail(
          SchemaValidationError(message: refinement.message, context: context),
        );
      }
    }

    return SchemaResult.ok(value);
  }

  /// Merges constraint JSON schemas into a base schema.
  @protected
  Map<String, Object?> mergeConstraintSchemas(Map<String, Object?> baseSchema) {
    final constraintSchemas = <Map<String, Object?>>[];
    for (final constraint in constraints) {
      if (constraint is JsonSchemaSpec<DartType>) {
        constraintSchemas.add(constraint.toJsonSchema());
      }
    }
    return constraintSchemas.fold(
      baseSchema,
      (prev, current) => deepMerge(prev, current),
    );
  }

  /// Builds a JSON Schema with proper nullable handling.
  @protected
  Map<String, Object?> buildJsonSchemaWithNullable({
    required Map<String, Object?> typeSchema,
    Object? serializedDefault,
  }) {
    if (isNullable) {
      final baseSchema = {
        ...typeSchema,
        if (description != null) 'description': description,
      };
      final mergedSchema = mergeConstraintSchemas(baseSchema);
      return {
        if (serializedDefault != null) 'default': serializedDefault,
        'anyOf': [
          mergedSchema,
          {'type': 'null'},
        ],
      };
    }

    final schema = {
      ...typeSchema,
      if (description != null) 'description': description,
      if (serializedDefault != null) 'default': serializedDefault,
    };

    return mergeConstraintSchemas(schema);
  }

  /// Creates a non-nullable constraint error result.
  @protected
  SchemaResult<DartType> failNonNullable(SchemaContext context) {
    final constraintError = NonNullableConstraint().validate(null);
    return SchemaResult.fail(
      SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ),
    );
  }

  @protected
  SchemaResult<DartType> failNull(SchemaContext context) {
    if (context.operation == SchemaOperation.encode) {
      return SchemaResult.fail(SchemaEncodeError.requiredNotNull(context));
    }
    return failNonNullable(context);
  }

  @protected
  SchemaResult<DartType> failTypeMismatch(Object value, SchemaContext context) {
    if (context.operation == SchemaOperation.encode) {
      return SchemaResult.fail(
        SchemaEncodeError.typeMismatch(
          expected: DartType,
          actual: value,
          context: context,
        ),
      );
    }

    try {
      final actualType = AckSchema.getSchemaType(value);
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: schemaType,
          actualType: actualType,
          context: context,
        ),
      );
    } catch (_) {
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Expected $schemaTypeName, got ${value.runtimeType}.',
          context: context,
        ),
      );
    }
  }

  /// The one overridable validation primitive.
  ///
  /// Implementations validate runtime values only. Boundary conversion belongs
  /// to [decodeBoundary] and [encodeBoundary], which only codecs override.
  @protected
  SchemaResult<DartType> validate(Object? value, SchemaContext context) {
    if (value == null) {
      if (isNullable) return SchemaResult.ok(null);
      return failNull(context);
    }

    if (value is! DartType) {
      return failTypeMismatch(value, context);
    }

    return applyConstraintsAndRefinements(value, context);
  }

  /// Parse-side boundary hook. Non-codec schemas validate the value directly.
  @protected
  SchemaResult<DartType> decodeBoundary(Object? input, SchemaContext context) {
    return validate(input, context);
  }

  /// Encode-side boundary hook. Non-codec schemas return the validated value.
  @protected
  SchemaResult<Object> encodeBoundary(DartType value, SchemaContext context) {
    return SchemaResult.ok(value);
  }

  /// Parses and validates a value, throwing an [AckException] if validation fails.
  DartType? parse(Object? value, {String? debugName}) {
    final result = safeParse(value, debugName: debugName);
    return result.getOrThrow();
  }

  /// Parses and validates a value, then maps the validated value to [TOut].
  TOut parseAs<TOut extends Object>(
    Object? value,
    TOut Function(DartType? validated) map, {
    String? debugName,
  }) {
    final result = safeParseAs(value, map, debugName: debugName);
    return result.getOrThrow()!;
  }

  /// Parses and validates a value, returning a [SchemaResult].
  SchemaResult<DartType> safeParse(Object? value, {String? debugName}) {
    final context = _createRootContext(
      value,
      debugName: debugName,
      operation: SchemaOperation.parse,
    );
    return decodeBoundary(value, context);
  }

  /// Encodes a runtime value back into its boundary representation, throwing
  /// an [AckException] on failure.
  Object? encode(Object? value, {String? debugName}) {
    final result = safeEncode(value, debugName: debugName);
    return result.getOrThrow();
  }

  /// Encodes a runtime value back into its boundary representation, returning
  /// a [SchemaResult]. Never throws.
  SchemaResult<Object> safeEncode(Object? value, {String? debugName}) {
    final context = _createRootContext(
      value,
      debugName: debugName,
      operation: SchemaOperation.encode,
    );
    final result = validate(value, context);
    return switch (result) {
      Ok(value: final typedValue) =>
        typedValue == null
            ? SchemaResult.ok(null)
            : encodeBoundary(typedValue, context),
      Fail(error: final error) => SchemaResult.fail(error),
    };
  }

  /// Parses and validates a value, then maps the validated value to [TOut].
  SchemaResult<TOut> safeParseAs<TOut extends Object>(
    Object? value,
    TOut Function(DartType? validated) map, {
    String? debugName,
  }) {
    final result = safeParse(value, debugName: debugName);
    if (result case Fail(error: final error)) {
      return SchemaResult.fail(error);
    }

    final validated = result.getOrNull();
    try {
      return SchemaResult.ok(map(validated));
    } catch (e, st) {
      return SchemaResult.fail(
        SchemaTransformError(
          message: 'Transformation failed: ${e.toString()}',
          context: _createRootContext(
            value,
            debugName: debugName,
            operation: SchemaOperation.parse,
          ),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  SchemaContext _createRootContext(
    Object? value, {
    String? debugName,
    required SchemaOperation operation,
  }) {
    final typeName = runtimeType
        .toString()
        .replaceFirst(RegExp(r'Schema$'), '')
        .toLowerCase();
    final effectiveDebugName = debugName ?? typeName;
    return SchemaContext(
      name: effectiveDebugName,
      schema: this,
      value: value,
      operation: operation,
    );
  }

  /// Legacy helper that returns the parsed value or `null` when validation fails.
  @Deprecated('Use safeParse(...).getOrNull() instead.')
  DartType? tryParse(Object? value, {String? debugName}) {
    final result = safeParse(value, debugName: debugName);
    return result.getOrNull();
  }

  AckSchema<DartType> copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<DartType>>? constraints,
    List<Refinement<DartType>>? refinements,
  });

  /// Converts this schema to a JSON Schema Draft-7 representation.
  Map<String, Object?> toJsonSchema();

  Map<String, Object?> toMap() {
    return {
      'type': schemaType.typeName,
      'isNullable': isNullable,
      'description': description,
      'constraints': constraints.map((c) => c.toMap()).toList(),
    };
  }

  /// Compares base schema fields for equality.
  @protected
  bool baseFieldsEqual(AckSchema<DartType> other) {
    const listEq = ListEquality<Object?>();
    return isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description &&
        listEq.equals(_constraints, other._constraints) &&
        listEq.equals(_refinements, other._refinements);
  }

  /// Compares base schema fields while erasing generic type parameters.
  @protected
  bool baseFieldsEqualErased(AckSchema other) {
    const listEq = ListEquality<Object?>();
    return isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description &&
        listEq.equals(
          _constraints as List<Object?>,
          other._constraints as List<Object?>,
        ) &&
        listEq.equals(
          _refinements as List<Object?>,
          other._refinements as List<Object?>,
        );
  }

  /// Computes hash code for base schema fields.
  @protected
  int get baseFieldsHashCode {
    const listEq = ListEquality<Object?>();
    return Object.hash(
      isNullable,
      isOptional,
      description,
      listEq.hash(_constraints),
      listEq.hash(_refinements),
    );
  }
}
