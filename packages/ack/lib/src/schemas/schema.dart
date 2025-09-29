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

enum SchemaType {
  string,
  integer,
  double,
  boolean,
  object,
  discriminatedObject,
  list,
  enumType,
  unknown,
}

/// JSON type enumeration following JSON Schema Draft 2020-12.
/// Treats null as a first-class type rather than the absence of a value.
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
}

typedef Refinement<T> = ({bool Function(T value) validate, String message});

@immutable
sealed class AckSchema<DartType extends Object> {
  final SchemaType schemaType;
  final bool isNullable;
  final String? description;
  final DartType? defaultValue;
  final List<Constraint<DartType>> constraints;
  final List<Refinement<DartType>> refinements;

  const AckSchema({
    required this.schemaType,
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
      _ => throw ArgumentError('Unknown JSON type for value: $value'),
    };
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

  /// Performs type conversion on a non-null input value to the schema's DartType.
  ///
  /// This method MUST NOT receive null values - the base class handles null
  /// in parseAndValidate before calling this method.
  ///
  /// This method MUST NOT return SchemaResult.ok(null) unless DartType
  /// explicitly includes null as a valid value.
  @protected
  SchemaResult<DartType> _performTypeConversion(
    Object inputValue,
    SchemaContext context,
  );

  /// Derives a Dart Type from acceptedTypes for InvalidTypeConstraint.
  Type _deriveExpectedTypeFromAcceptedTypes() {
    if (acceptedTypes.isEmpty) return Object;

    // Use the first non-null type, or Object if only null is accepted
    for (final jsonType in acceptedTypes) {
      switch (jsonType) {
        case JsonType.string:
          return String;
        case JsonType.integer:
          return int;
        case JsonType.number:
          return double;
        case JsonType.boolean:
          return bool;
        case JsonType.object:
          return Map;
        case JsonType.array:
          return List;
        case JsonType.nil:
          continue; // Skip null, look for other types
      }
    }

    return Object; // Fallback
  }

  /// Whether this schema represents an optional field in an object.
  /// Override this in OptionalSchema to return true.
  bool get isOptional => false;

  /// The JSON types that this schema accepts.
  /// Defaults to a single type based on schemaType, but can be overridden
  /// for schemas that accept multiple types (e.g., nullable schemas).
  List<JsonType> get acceptedTypes {
    final baseType = switch (schemaType) {
      SchemaType.string => JsonType.string,
      SchemaType.integer => JsonType.integer,
      SchemaType.double => JsonType.number,
      SchemaType.boolean => JsonType.boolean,
      SchemaType.object || SchemaType.discriminatedObject => JsonType.object,
      SchemaType.list => JsonType.array,
      SchemaType.enumType ||
      SchemaType.unknown =>
        JsonType.string, // Enums and unknown fallback to string
    };

    // If nullable, add null type to the accepted types
    return isNullable ? [baseType, JsonType.nil] : [baseType];
  }

  /// Helper method to validate that input value matches one of the expected types.
  ///
  /// Returns Ok(inputValue) if the type is acceptable, or Fail with InvalidTypeConstraint
  /// if the type doesn't match any of the acceptedTypes.
  @protected
  SchemaResult<Object> validateExpectedType(
      Object inputValue, SchemaContext context) {
    final inputType = AckSchema.getJsonType(inputValue);

    if (acceptedTypes.contains(inputType)) {
      return SchemaResult.ok(inputValue);
    }

    // Derive expected type from acceptedTypes for error message
    final expectedType = _deriveExpectedTypeFromAcceptedTypes();
    final constraintError = InvalidTypeConstraint(
      expectedType: expectedType,
      inputValue: inputValue,
    ).validate(inputValue);

    return SchemaResult.fail(SchemaConstraintsError(
      constraints: constraintError != null ? [constraintError] : [],
      context: context,
    ));
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

  @protected
  SchemaResult<DartType> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue == null) {
      if (defaultValue != null) {
        final constraintViolations = _checkConstraints(defaultValue!, context);
        if (constraintViolations.isNotEmpty) {
          return SchemaResult.fail(SchemaConstraintsError(
            constraints: constraintViolations,
            context: context,
          ));
        }

        return _runRefinements(defaultValue!, context);
      }

      if (isNullable) {
        return SchemaResult.ok(null);
      }

      return failNonNullable(context);
    }

    final convertedResult = _performTypeConversion(inputValue, context);
    if (convertedResult.isFail) return convertedResult;

    final convertedValue = convertedResult.getOrThrow()!;

    final constraintViolations = _checkConstraints(convertedValue, context);
    if (constraintViolations.isNotEmpty) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintViolations,
        context: context,
      ));
    }

    return _runRefinements(convertedValue, context);
  }

  SchemaResult<DartType> validate(Object? value, {String? debugName}) {
    final effectiveDebugName = debugName ?? schemaType.name.toLowerCase();
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
      'schemaType': schemaType.name,
      'isNullable': isNullable,
      'description': description,
      'defaultValue': defaultValue?.toString(),
      'constraints': constraints.map((c) => c.toMap()).toList(),
    };
  }
}
