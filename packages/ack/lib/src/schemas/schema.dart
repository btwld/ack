import 'package:meta/meta.dart';

import '../constraints/constraint.dart';
import '../constraints/string/string_enum_constraint.dart';
import '../constraints/validators.dart';
import '../context.dart';
import '../helpers.dart';
import '../utils/json_utils.dart';
import '../validation/schema_error.dart';
import '../validation/schema_result.dart';

part 'json_type.dart';
part 'any_of_schema.dart';
part 'any_schema.dart';
part 'boolean_schema.dart';
part 'discriminated_object_schema.dart';
part 'enum_schema.dart';
part 'fluent_schema.dart';
part 'list_schema.dart';
part 'num_schema.dart';
part 'object_schema.dart';
part 'optional_schema.dart';
part 'string_schema.dart';
part 'transformed_schema.dart';

typedef Refinement<T> = ({bool Function(T value) validate, String message});

@immutable
sealed class AckSchema<DartType extends Object> {
  final bool isNullable;
  final String? description;
  final DartType? defaultValue;
  final List<Constraint<DartType>> constraints;
  final List<Refinement<DartType>> refinements;

  const AckSchema({
    this.isNullable = false,
    this.description,
    this.defaultValue,
    this.constraints = const [],
    this.refinements = const [],
  });

  /// Utility method to get the JSON type of any value.
  static JsonType getJsonType(Object? value) {
    return JsonType.of(value);
  }

  /// Checks if input value matches the expected JSON type.
  ///
  /// Returns SchemaResult.fail with TypeMismatchError if type doesn't match.
  /// Returns null if type matches (caller should continue processing).
  ///
  /// Schemas that need simple type checking can use this:
  /// ```dart
  /// final typeError = checkTypeMatch(inputValue, context);
  /// if (typeError != null) return typeError;
  /// ```
  @protected
  SchemaResult<DartType>? checkTypeMatch(
      Object inputValue, SchemaContext context) {
    final actualType = AckSchema.getJsonType(inputValue);
    if (actualType != acceptedType) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: acceptedType,
          actualType: actualType,
          context: context,
        ),
      );
    }
    return null; // Type matches, continue processing
  }

  /// Applies constraints and refinements to a validated value.
  ///
  /// This method centralizes the final validation step used by all schemas.
  /// Checks constraints first, then runs refinements if constraints pass.
  ///
  /// Schemas should call this after parsing/conversion:
  /// ```dart
  /// return applyConstraintsAndRefinements(validatedValue, context);
  /// ```
  @protected
  SchemaResult<DartType> applyConstraintsAndRefinements(
    DartType value,
    SchemaContext context,
  ) {
    final constraintViolations = _checkConstraints(value, context);
    if (constraintViolations.isNotEmpty) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintViolations,
        context: context,
      ));
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
          SchemaValidationError(
            message: refinement.message,
            context: context,
          ),
        );
      }
    }

    return SchemaResult.ok(value);
  }

  /// Helper method to merge constraint JSON schemas into a base schema.
  ///
  /// This is used in toJsonSchema() implementations to fold constraint-specific
  /// JSON schema definitions into the base schema structure.
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

  /// Helper method to create a standard non-nullable constraint error.
  ///
  /// Returns a SchemaResult.fail with a NonNullableConstraint error.
  @protected
  SchemaResult<DartType> failNonNullable(SchemaContext context) {
    final constraintError = NonNullableConstraint().validate(null);
    return SchemaResult.fail(SchemaConstraintsError(
      constraints: constraintError != null ? [constraintError] : [],
      context: context,
    ));
  }

  /// The primary JSON type this schema validates to.
  ///
  /// Each schema subclass must override this to specify its target JSON type.
  /// The [canAcceptFrom] method on JsonType determines which source types
  /// can be converted to the target type.
  ///
  /// Examples:
  /// - `StringSchema`: returns `JsonType.string`
  /// - `IntegerSchema`: returns `JsonType.integer`
  /// - `ObjectSchema`: returns `JsonType.object`
  /// - `ListSchema`: returns `JsonType.array`
  ///
  /// For composite schemas like AnyOfSchema that accept multiple types,
  /// this getter may throw UnimplementedError since they override parseAndValidate directly.
  @protected
  JsonType get acceptedType;

  /// Returns a human-readable type name for this schema.
  ///
  /// For schemas with a single JSON type (StringSchema, IntegerSchema, etc.),
  /// returns the JSON Schema standard type name ("string", "integer", etc.).
  ///
  /// For composite schemas (AnyOfSchema, etc.) that don't have a single type,
  /// returns the Dart class name as a fallback.
  ///
  /// This is used in error messages and debugging output to provide
  /// clear, standards-aligned type information.
  String get schemaTypeName {
    try {
      return acceptedType.typeName;
    } catch (_) {
      // Composite schemas without single type fall back to class name
      return runtimeType.toString();
    }
  }

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
    // Inline null handling for scalar schemas
    // Composite schemas (Object, List, AnyOf, Discriminated) override this method entirely
    if (inputValue == null) {
      if (defaultValue != null) {
        return applyConstraintsAndRefinements(defaultValue!, context);
      }
      if (isNullable) {
        return SchemaResult.ok(null);
      }
      return failNonNullable(context);
    }

    final targetType = acceptedType;
    final actualType = AckSchema.getJsonType(inputValue);

    // Type checking: ask JsonType if it can accept the source type
    if (!targetType.canAcceptFrom(actualType, strict: strictPrimitiveParsing)) {
      return SchemaResult.fail(
        TypeMismatchError(
          expectedType: targetType,
          actualType: actualType,
          context: context,
        ),
      );
    }

    // Parse using JsonType's centralized parsing logic
    final convertedResult =
        targetType.parse<DartType>(inputValue, actualType, context);
    if (convertedResult.isFail) return convertedResult;

    final convertedValue = convertedResult.getOrThrow()!;

    // Use centralized constraints and refinements check
    return applyConstraintsAndRefinements(convertedValue, context);
  }

  SchemaResult<DartType> validate(Object? value, {String? debugName}) {
    // Use provided debugName or derive from runtime type (e.g., "StringSchema" -> "string")
    final typeName = runtimeType
        .toString()
        .replaceFirst(RegExp(r'Schema$'), '')
        .toLowerCase();
    final effectiveDebugName = debugName ?? typeName;
    final context =
        SchemaContext(name: effectiveDebugName, schema: this, value: value);

    return parseAndValidate(value, context);
  }

  /// validateOrThrow is a convenience method that validates the value
  /// and throws an exception if validation fails.
  void validateOrThrow(Object? value, {String? debugName}) {
    final result = validate(value, debugName: debugName);

    result.getOrThrow();
  }

  DartType? parse(Object? value, {String? debugName}) {
    final result = validate(value, debugName: debugName);

    return result.getOrThrow();
  }

  DartType? tryParse(Object? value, {String? debugName}) {
    final result = validate(value, debugName: debugName);

    return result.getOrNull();
  }

  SchemaResult<DartType> safeParse(Object? value, {String? debugName}) {
    return validate(value, debugName: debugName);
  }

  @protected
  AckSchema<DartType> copyWithInternal({
    required bool? isNullable,
    required String? description,
    required DartType? defaultValue,
    required List<Constraint<DartType>>? constraints,
    required List<Refinement<DartType>>? refinements,
  });

  AckSchema<DartType> copyWith({
    bool? isNullable,
    String? description,
    DartType? defaultValue,
    List<Constraint<DartType>>? constraints,
    List<Refinement<DartType>>? refinements,
  }) {
    return copyWithInternal(
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
      refinements: refinements,
    );
  }

  Map<String, Object?> toJsonSchema();

  Map<String, Object?> toMap() {
    return {
      'type': acceptedType.typeName,
      'isNullable': isNullable,
      'description': description,
      'defaultValue': defaultValue?.toString(),
      'constraints': constraints.map((c) => c.toMap()).toList(),
    };
  }
}
