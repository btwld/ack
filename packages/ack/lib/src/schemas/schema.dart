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
part 'schema_type.dart';
part 'string_schema.dart';
part 'transformed_schema.dart';
part 'testing/testing_schemas.dart';

typedef Refinement<T> = ({bool Function(T value) validate, String message});

/// Indicates whether a schema operation is parsing inbound data or encoding
/// runtime values back to the boundary representation.
enum SchemaOperation { parse, encode }

/// The bidirectional schema contract.
///
/// Every schema declares two type parameters:
///
/// * [Boundary] is the encoded / wire / JSON-facing value type.
/// * [Runtime] is the parsed Dart application value type.
///
/// Parsing converts [Object?] input into [Runtime]; encoding converts
/// [Runtime] into [Boundary].
@immutable
abstract class AckSchema<Boundary extends Object, Runtime extends Object> {
  final bool isNullable;
  final bool isOptional;
  final String? description;
  final List<Constraint<Runtime>> _constraints;
  final List<Refinement<Runtime>> _refinements;

  /// Returns an unmodifiable view of the constraints for this schema.
  List<Constraint<Runtime>> get constraints => List.unmodifiable(_constraints);

  /// Returns an unmodifiable view of the refinements for this schema.
  List<Refinement<Runtime>> get refinements => List.unmodifiable(_refinements);

  const AckSchema({
    this.isNullable = false,
    this.isOptional = false,
    this.description,
    List<Constraint<Runtime>> constraints = const [],
    List<Refinement<Runtime>> refinements = const [],
  }) : _constraints = constraints,
       _refinements = refinements;

  /// Utility method to get the schema type of any value.
  static SchemaType getSchemaType(Object? value) {
    return SchemaType.of(value);
  }

  /// Applies constraints and refinements to a validated value.
  @protected
  SchemaResult<Runtime> applyConstraintsAndRefinements(
    Runtime value,
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
    Runtime value,
    SchemaContext context,
  ) {
    if (_constraints.isEmpty) return const [];
    final errors = <ConstraintError>[];
    for (final constraint in _constraints) {
      if (constraint is Validator<Runtime>) {
        final error = constraint.validate(value);
        if (error != null) {
          errors.add(error);
        }
      }
    }
    return errors;
  }

  @protected
  SchemaResult<Runtime> _runRefinements(
    Runtime value,
    SchemaContext context,
  ) {
    for (final refinement in _refinements) {
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
    for (final constraint in _constraints) {
      if (constraint is JsonSchemaSpec<Runtime>) {
        constraintSchemas.add(constraint.toJsonSchema());
      }
    }
    return constraintSchemas.fold(
      baseSchema,
      (prev, current) => deepMerge(prev, current),
    );
  }

  /// Builds a JSON Schema map with proper nullable handling.
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

  /// Creates a non-nullable constraint error result for the runtime channel.
  @protected
  SchemaResult<Runtime> failNonNullable(SchemaContext context) {
    final constraintError = NonNullableConstraint().validate(null);
    return SchemaResult.fail(
      SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ),
    );
  }

  /// Encode-side null failure.
  @protected
  SchemaResult<Boundary> failNonNullableEncode(SchemaContext context) {
    return SchemaResult.fail(
      SchemaEncodeError.nonNullable(context: context),
    );
  }

  /// Handles null input for parse operations.
  ///
  /// Returns `null` when input is non-null so callers can continue parsing.
  /// For null input, returns `Ok(null)` if nullable, else a non-nullable
  /// failure result. Defaults are handled at the [DefaultSchema] wrapper layer.
  @protected
  SchemaResult<Runtime>? handleNullInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue != null) return null;

    if (isNullable) {
      return SchemaResult.ok(null);
    }

    return failNonNullable(context);
  }

  /// The schema type category for this schema.
  @protected
  SchemaType get schemaType;

  /// Human-readable type name for error messages and debugging.
  String get schemaTypeName => schemaType.typeName;

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// Parses [inputValue] and produces a [Runtime] value, or returns a
  /// failure. Subclasses override to implement boundary decoding plus
  /// runtime validation.
  @protected
  SchemaResult<Runtime> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  );

  /// Parses and validates a value, throwing an [AckException] if validation fails.
  Runtime? parse(Object? value, {String? debugName}) {
    final result = safeParse(value, debugName: debugName);
    return result.getOrThrow();
  }

  /// Parses and validates a value, then maps the validated value to [TOut].
  TOut parseAs<TOut extends Object>(
    Object? value,
    TOut Function(Runtime? validated) map, {
    String? debugName,
  }) {
    final result = safeParseAs(value, map, debugName: debugName);
    return result.getOrThrow()!;
  }

  /// Parses and validates a value, returning a [SchemaResult].
  SchemaResult<Runtime> safeParse(Object? value, {String? debugName}) {
    final context = _createRootContext(
      value,
      debugName: debugName,
      operation: SchemaOperation.parse,
    );
    return parseAndValidate(value, context);
  }

  /// Parses and validates a value, then maps the validated value to [TOut].
  SchemaResult<TOut> safeParseAs<TOut extends Object>(
    Object? value,
    TOut Function(Runtime? validated) map, {
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

  // ---------------------------------------------------------------------------
  // Encoding
  // ---------------------------------------------------------------------------

  /// Encodes a [Runtime] value back into a [Boundary] value.
  ///
  /// Subclasses override to implement runtime → boundary conversion.
  @protected
  SchemaResult<Boundary> encodeRuntime(
    Runtime value,
    SchemaContext context,
  );

  /// Encodes a runtime value to a boundary value, returning a [SchemaResult].
  SchemaResult<Boundary> safeEncode(Runtime? value, {String? debugName}) {
    final context = _createRootContext(
      value,
      debugName: debugName,
      operation: SchemaOperation.encode,
    );

    if (value == null) {
      if (isNullable) {
        return SchemaResult.ok(null);
      }
      return failNonNullableEncode(context);
    }

    // Apply runtime constraints/refinements before encoding so we don't
    // emit a boundary value that the schema would reject on parse.
    final constraintViolations = _checkConstraints(value, context);
    if (constraintViolations.isNotEmpty) {
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: constraintViolations,
          context: context,
        ),
      );
    }
    for (final refinement in _refinements) {
      if (!refinement.validate(value)) {
        return SchemaResult.fail(
          SchemaValidationError(message: refinement.message, context: context),
        );
      }
    }

    try {
      return encodeRuntime(value, context);
    } catch (e, st) {
      return SchemaResult.fail(
        SchemaEncodeError.encoderThrew(
          message: 'Encoder threw: ${e.toString()}',
          context: context,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Encodes a runtime value to a boundary value, throwing on failure.
  Boundary? encode(Runtime? value, {String? debugName}) {
    final result = safeEncode(value, debugName: debugName);
    return result.getOrThrow();
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

  /// Legacy alias for [safeParse].
  @Deprecated('Use safeParse(...) instead.')
  SchemaResult<Runtime> validate(Object? value, {String? debugName}) =>
      safeParse(value, debugName: debugName);

  /// Legacy helper that returns the parsed value or `null` when validation fails.
  @Deprecated('Use safeParse(...).getOrNull() instead.')
  Runtime? tryParse(Object? value, {String? debugName}) {
    final result = safeParse(value, debugName: debugName);
    return result.getOrNull();
  }

  /// Converts this schema to a JSON Schema Draft-7 representation.
  Map<String, Object?> toJsonSchema();

  Map<String, Object?> toMap() {
    return {
      'type': schemaType.typeName,
      'isNullable': isNullable,
      'description': description,
      'constraints': _constraints.map((c) => c.toMap()).toList(),
    };
  }

  /// Compares base schema fields for equality.
  @protected
  bool baseFieldsEqual(AckSchema other) {
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
