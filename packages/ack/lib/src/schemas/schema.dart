import 'package:meta/meta.dart';

import '../constraints/constraint.dart';
import '../constraints/string/string_enum_constraint.dart';
import '../constraints/validators.dart';
import '../context.dart';
import '../helpers.dart';
import '../utils/json_utils.dart';
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
part 'optional_schema.dart';
part 'string_schema.dart';
part 'transformed_schema.dart';

/// JSON type enumeration following JSON Schema Draft 2020-12.
///
/// This enum serves as the central authority for type validation and conversion logic.
/// Each JsonType knows:
/// 1. Which other JsonTypes it can accept/parse from (via [canAcceptFrom])
/// 2. How to parse values from those types (via [parse])
///
/// This centralizes all coercion rules in one place, eliminating duplication
/// between schema classes.
///
/// Example:
/// ```dart
/// // JsonType.integer can parse from number/string in non-strict mode
/// JsonType.integer.canAcceptFrom(JsonType.string, strict: false) // true
/// JsonType.integer.parse("42", JsonType.string, context) // Ok(42)
/// ```
enum JsonType {
  string('string'),
  integer('integer'),
  number('number'),
  boolean('boolean'),
  object('object'),
  array('array'),
  nil('null');

  const JsonType(this.typeName);

  /// The string representation used in JSON Schema.
  final String typeName;

  /// Determines if this type can accept/parse values from [sourceType].
  ///
  /// When [strict] is true, only exact type matches are allowed (except number ← integer).
  /// When [strict] is false, primitive types can parse from compatible types:
  /// - integer: from number, string
  /// - string: from integer, number, boolean
  /// - boolean: from string
  /// - number: from integer, string
  bool canAcceptFrom(JsonType sourceType, {required bool strict}) {
    // Same type always OK
    if (this == sourceType) return true;

    return switch (this) {
      // Integer can parse from number/string (if not strict)
      JsonType.integer =>
        !strict && (sourceType == JsonType.number || sourceType == JsonType.string),

      // String can parse from primitives (if not strict)
      JsonType.string => !strict &&
          (sourceType == JsonType.integer ||
              sourceType == JsonType.number ||
              sourceType == JsonType.boolean),

      // Boolean can parse from string (if not strict)
      JsonType.boolean => !strict && sourceType == JsonType.string,

      // Number can always accept integer, or string if not strict
      JsonType.number =>
        sourceType == JsonType.integer || (!strict && sourceType == JsonType.string),

      // Object/Array/Nil are strict - only accept exact type
      _ => false,
    };
  }

  /// Parses [value] from [sourceType] to this type.
  ///
  /// Precondition: [canAcceptFrom] returned true for these types.
  /// Returns SchemaResult.fail if parsing fails (e.g., "abc" → integer).
  SchemaResult<T> parse<T extends Object>(
    Object value,
    JsonType sourceType,
    SchemaContext context,
  ) {
    // If same type, just cast (already validated by type checking)
    if (this == sourceType) {
      return SchemaResult.ok(value as T);
    }

    return switch (this) {
      JsonType.integer =>
        _parseInteger(value, sourceType, context) as SchemaResult<T>,
      JsonType.string => SchemaResult.ok(value.toString() as T),
      JsonType.boolean =>
        _parseBoolean(value, sourceType, context) as SchemaResult<T>,
      JsonType.number =>
        _parseNumber(value, sourceType, context) as SchemaResult<T>,
      _ => SchemaResult.fail(
          SchemaValidationError(
            message: 'Cannot parse ${sourceType.typeName} to ${this.typeName}',
            context: context,
          ),
        ),
    };
  }

  /// Parses value to integer from compatible source types.
  SchemaResult<int> _parseInteger(
    Object value,
    JsonType sourceType,
    SchemaContext context,
  ) {
    return switch (sourceType) {
      JsonType.integer => SchemaResult.ok(value as int),
      JsonType.number => _convertDoubleToInt(value as double, context),
      JsonType.string => _parseIntFromString(value as String, context),
      _ => SchemaResult.fail(
          SchemaValidationError(
            message: 'Cannot convert ${sourceType.typeName} to integer',
            context: context,
          ),
        ),
    };
  }

  /// Parses value to number from compatible source types.
  SchemaResult<double> _parseNumber(
    Object value,
    JsonType sourceType,
    SchemaContext context,
  ) {
    return switch (sourceType) {
      JsonType.number => SchemaResult.ok(value as double),
      JsonType.integer => SchemaResult.ok((value as int).toDouble()),
      JsonType.string => _parseDoubleFromString(value as String, context),
      _ => SchemaResult.fail(
          SchemaValidationError(
            message: 'Cannot convert ${sourceType.typeName} to number',
            context: context,
          ),
        ),
    };
  }

  /// Parses value to boolean from compatible source types.
  SchemaResult<bool> _parseBoolean(
    Object value,
    JsonType sourceType,
    SchemaContext context,
  ) {
    return switch (sourceType) {
      JsonType.boolean => SchemaResult.ok(value as bool),
      JsonType.string => _parseBoolFromString(value as String, context),
      _ => SchemaResult.fail(
          SchemaValidationError(
            message: 'Cannot convert ${sourceType.typeName} to boolean',
            context: context,
          ),
        ),
    };
  }

  /// Converts double to int, checking for precision loss.
  static SchemaResult<int> _convertDoubleToInt(
    double value,
    SchemaContext context,
  ) {
    if (value.isFinite && value == value.truncate()) {
      return SchemaResult.ok(value.toInt());
    }
    return SchemaResult.fail(
      SchemaValidationError(
        message: 'Cannot convert $value to integer without losing precision.',
        context: context,
      ),
    );
  }

  /// Parses integer from string.
  static SchemaResult<int> _parseIntFromString(
    String value,
    SchemaContext context,
  ) {
    final parsed = int.tryParse(value);
    if (parsed != null) return SchemaResult.ok(parsed);
    return SchemaResult.fail(
      SchemaValidationError(
        message: 'Cannot convert "$value" to integer.',
        context: context,
      ),
    );
  }

  /// Parses double from string.
  static SchemaResult<double> _parseDoubleFromString(
    String value,
    SchemaContext context,
  ) {
    final parsed = double.tryParse(value);
    if (parsed != null) return SchemaResult.ok(parsed);
    return SchemaResult.fail(
      SchemaValidationError(
        message: 'Cannot convert "$value" to number.',
        context: context,
      ),
    );
  }

  /// Parses boolean from string.
  static SchemaResult<bool> _parseBoolFromString(
    String value,
    SchemaContext context,
  ) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return SchemaResult.ok(true);
    if (normalized == 'false') return SchemaResult.ok(false);
    return SchemaResult.fail(
      SchemaValidationError(
        message: 'Cannot convert "$value" to boolean.',
        context: context,
      ),
    );
  }
}

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
    return switch (value) {
      null => JsonType.nil,
      Map() => JsonType.object,
      List() => JsonType.array,
      String() => JsonType.string,
      int() => JsonType.integer,
      double() || num() => JsonType.number, // For double and other num types
      bool() => JsonType.boolean,
      Enum() => JsonType.string, // Enums serialize to strings (their name)
      _ => throw ArgumentError('Unknown JSON type for value: $value'),
    };
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
  SchemaResult<DartType>? checkTypeMatch(Object inputValue, SchemaContext context) {
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
    final convertedResult = targetType.parse<DartType>(inputValue, actualType, context);
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
      'runtimeType': runtimeType.toString(),
      'isNullable': isNullable,
      'description': description,
      'defaultValue': defaultValue?.toString(),
      'constraints': constraints.map((c) => c.toMap()).toList(),
    };
  }
}
