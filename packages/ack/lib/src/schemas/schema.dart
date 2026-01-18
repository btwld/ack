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

  /// Handles null input according to schema's nullability and default value.
  ///
  /// This is the centralized null-handling logic that all schema types should use.
  /// For composite schemas (Object, List, Discriminated), override [processClonedDefault]
  /// to recursively validate the default structure instead of just applying constraints.
  ///
  /// Returns `null` if [inputValue] is not null (caller should continue with validation).
  /// Otherwise returns the appropriate [SchemaResult]:
  /// - If defaultValue exists: clones it and processes via [processClonedDefault]
  /// - If isNullable: returns Ok(null)
  /// - Otherwise: returns failure via [failNonNullable]
  @protected
  SchemaResult<DartType>? handleNullInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue != null) return null;

    if (defaultValue != null) {
      // Clone without casting - processClonedDefault handles validation/typing
      final clonedDefault = cloneDefault(defaultValue!);
      return processClonedDefault(clonedDefault, context);
    }

    if (isNullable) {
      return SchemaResult.ok(null);
    }

    return failNonNullable(context);
  }

  /// Processes a cloned default value through validation.
  ///
  /// Routes the cloned default through [parseAndValidate] to ensure proper
  /// type conversion and validation for all schema types, including collections.
  ///
  /// Override in schemas where the default value type differs from input type
  /// (e.g., TransformedSchema where default is OutputType, not InputType).
  @protected
  SchemaResult<DartType> processClonedDefault(
    Object? clonedDefault,
    SchemaContext context,
  ) {
    return parseAndValidate(clonedDefault, context);
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
    final actualType = AckSchema.getSchemaType(nonNullInput);

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
    // Use provided debugName or derive from runtime type (e.g., "StringSchema" -> "string")
    final typeName = runtimeType
        .toString()
        .replaceFirst(RegExp(r'Schema$'), '')
        .toLowerCase();
    final effectiveDebugName = debugName ?? typeName;
    final context = SchemaContext(
      name: effectiveDebugName,
      schema: this,
      value: value,
    );

    return parseAndValidate(value, context);
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
