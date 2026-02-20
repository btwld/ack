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
part 'discriminated_object_schema.dart';
part 'enum_schema.dart';
part 'fluent_schema.dart';
part 'list_schema.dart';
part 'num_schema.dart';
part 'object_schema.dart';
part 'schema_type.dart';
part 'string_schema.dart';
part 'transformed_schema.dart';
part 'testing/testing_schemas.dart';

typedef Refinement<T> = ({bool Function(T value) validate, String message});

@immutable
sealed class AckSchema<DartType extends Object> {
  final bool isNullable;
  final bool isOptional;
  final String? description;
  final DartType? defaultValue;
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
    this.defaultValue,
    List<Constraint<DartType>> constraints = const [],
    List<Refinement<DartType>> refinements = const [],
  }) : _constraints = constraints,
       _refinements = refinements;

  /// Utility method to get the schema type of any value.
  static SchemaType getSchemaType(Object? value) {
    return SchemaType.of(value);
  }

  /// Applies constraints and refinements to a validated value.
  ///
  /// Checks constraints first, then runs refinements if all constraints pass.
  /// Schemas call this after type validation and conversion.
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
  ///
  /// Folds constraint-specific JSON schema definitions into the base structure.
  /// Used in toJsonSchema() implementations.
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
  ///
  /// This helper centralizes the nullable/non-nullable pattern used by most
  /// schema types. It handles:
  /// - Adding description to the base schema
  /// - Wrapping in anyOf with null type when nullable
  /// - Placing default value at the correct level
  /// - Merging constraint schemas
  ///
  /// [typeSchema] contains type-specific fields (e.g., `{'type': 'string'}`
  /// or `{'type': 'array', 'items': ...}`).
  ///
  /// [serializedDefault] is the already-serialized default value (e.g.,
  /// enum values should pass `defaultValue?.name`).
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

  /// Handles null input for schemas using the standard null/default flow.
  ///
  /// Returns `null` when [inputValue] is non-null so callers can continue parsing.
  /// For null input, returns a validated clone of [defaultValue] when present,
  /// otherwise `Ok(null)` if nullable, else a non-nullable failure result.
  @protected
  SchemaResult<DartType>? handleNullInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue != null) return null;

    if (defaultValue != null) {
      // Clone mutable defaults to avoid shared state across parse calls.
      final clonedDefault = cloneDefault(defaultValue!);
      return parseAndValidate(clonedDefault, context);
    }

    if (isNullable) {
      return SchemaResult.ok(null);
    }

    return failNonNullable(context);
  }

  /// The schema type category for this schema.
  ///
  /// Subclasses must override to specify their type.
  /// Primitives return JSON types (string, integer), composites return
  /// schema categories (anyOf, discriminated).
  @protected
  SchemaType get schemaType;

  /// Human-readable type name for error messages and debugging.
  String get schemaTypeName => schemaType.typeName;

  /// Whether this schema uses strict primitive parsing.
  ///
  /// When true, only exact type matches are allowed.
  /// When false, compatible types can be coerced (e.g., "42" → 42).
  ///
  /// Subclasses that support strictPrimitiveParsing should override this.
  @protected
  bool get strictPrimitiveParsing => false;

  @protected
  SchemaResult<DartType> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Use centralized null handling
    final nullResult = handleNullInput(inputValue, context);
    if (nullResult != null) return nullResult;

    // After null check, inputValue is guaranteed non-null
    final nonNullInput = inputValue!;
    final targetType = schemaType;

    // Get the actual type of the input, catching any errors to maintain
    // the "never throws" guarantee of safeParse()
    SchemaType actualType;
    try {
      actualType = AckSchema.getSchemaType(nonNullInput);
    } catch (e) {
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Unsupported input type: ${nonNullInput.runtimeType}',
          context: context,
        ),
      );
    }

    // Type compatibility check
    if (!targetType.canAcceptFrom(actualType, strict: strictPrimitiveParsing)) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: targetType,
          actualType: actualType,
          context: context,
        ),
      );
    }

    // Parse using SchemaType's parsing logic
    final convertedResult = targetType.parse<DartType>(
      nonNullInput,
      actualType,
      context,
    );
    if (convertedResult.isFail) return convertedResult;

    final convertedValue = convertedResult.getOrThrow()!;

    return applyConstraintsAndRefinements(convertedValue, context);
  }

  /// Parses and validates a value, throwing an [AckException] if validation fails.
  ///
  /// This is the primary method for validation when you want exceptions.
  /// For error handling without exceptions, use [safeParse] instead.
  ///
  /// Example:
  /// ```dart
  /// final email = emailSchema.parse(input); // throws if invalid
  /// ```
  DartType? parse(Object? value, {String? debugName}) {
    final result = safeParse(value, debugName: debugName);
    return result.getOrThrow();
  }

  /// Parses and validates a value, then maps the validated value to [TOut].
  ///
  /// This method throws an [AckException] when validation fails (same as [parse]).
  /// Mapper exceptions are wrapped into a [SchemaTransformError] and then thrown
  /// as part of [AckException] for consistent error handling.
  TOut parseAs<TOut extends Object>(
    Object? value,
    TOut Function(DartType? validated) map, {
    String? debugName,
  }) {
    final result = safeParseAs(value, map, debugName: debugName);
    return result.getOrThrow() as TOut;
  }

  /// Parses and validates a value, returning a [SchemaResult].
  ///
  /// This method never throws exceptions. Instead, it returns a [SchemaResult]
  /// which can be either [Ok] (success) or [Fail] (validation error).
  ///
  /// This is the primary method for validation when you want explicit error handling.
  /// For throwing exceptions on error, use [parse] instead.
  ///
  /// Example:
  /// ```dart
  /// final result = emailSchema.safeParse(input);
  /// if (result.isOk) {
  ///   final email = result.getOrNull();
  /// } else {
  ///   print('Error: ${result.getError()}');
  /// }
  /// ```
  SchemaResult<DartType> safeParse(Object? value, {String? debugName}) {
    final context = _createRootContext(value, debugName: debugName);
    return parseAndValidate(value, context);
  }

  /// Parses and validates a value, then maps the validated value to [TOut].
  ///
  /// Validation failures are returned as [Fail] with the original schema error.
  /// Mapper exceptions are caught and returned as [SchemaTransformError].
  ///
  /// This method never throws exceptions.
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
          context: _createRootContext(value, debugName: debugName),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  SchemaContext _createRootContext(Object? value, {String? debugName}) {
    // Use provided debugName or derive from runtime type (e.g., "StringSchema" -> "string")
    final typeName = runtimeType
        .toString()
        .replaceFirst(RegExp(r'Schema$'), '')
        .toLowerCase();
    final effectiveDebugName = debugName ?? typeName;
    return SchemaContext(name: effectiveDebugName, schema: this, value: value);
  }

  /// Legacy alias for [safeParse].
  @Deprecated('Use safeParse(...) instead.')
  SchemaResult<DartType> validate(Object? value, {String? debugName}) =>
      safeParse(value, debugName: debugName);

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
    DartType? defaultValue,
    List<Constraint<DartType>>? constraints,
    List<Refinement<DartType>>? refinements,
  });

  /// Converts this schema to a JSON Schema Draft-7 representation.
  ///
  /// Returns a Map containing the JSON Schema structure.
  ///
  /// Subclasses must override this to provide their specific JSON Schema structure.
  /// The implementation should call [mergeConstraintSchemas] at the structurally
  /// appropriate point for the schema type.
  Map<String, Object?> toJsonSchema();

  Map<String, Object?> toMap() {
    return {
      'type': schemaType.typeName,
      'isNullable': isNullable,
      'description': description,
      'defaultValue': defaultValue?.toString(),
      'constraints': constraints.map((c) => c.toMap()).toList(),
    };
  }

  /// Compares base schema fields for equality.
  ///
  /// Subclasses should call this as part of their == implementation
  /// after the identical() and type checks.
  @protected
  bool baseFieldsEqual(AckSchema<DartType> other) {
    const listEq = ListEquality<Object?>();
    return isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description &&
        defaultValue == other.defaultValue &&
        listEq.equals(_constraints, other._constraints) &&
        listEq.equals(_refinements, other._refinements);
  }

  /// Computes hash code for base schema fields.
  ///
  /// Subclasses should include this in their hashCode computation.
  @protected
  int get baseFieldsHashCode {
    const listEq = ListEquality<Object?>();
    return Object.hash(
      isNullable,
      isOptional,
      description,
      defaultValue,
      listEq.hash(_constraints),
      listEq.hash(_refinements),
    );
  }
}
