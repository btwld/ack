import 'package:meta/meta.dart';

import '../constraints/constraint.dart';
import '../constraints/validators.dart';
import '../context.dart';
import '../helpers.dart';
import '../validation/schema_error.dart';
import '../validation/schema_result.dart';

part 'boolean_schema.dart';
part 'discriminated_object_schema.dart';
part 'list_schema.dart';
part 'nullable_schema.dart';
part 'num_schema.dart';
part 'object_schema.dart';
part 'string_schema.dart';

const ackRawDefaultValue = Object();

enum SchemaType {
  string,
  integer,
  double,
  boolean,
  object,
  discriminatedObject,
  list,
  unknown,
}

@immutable
sealed class AckSchema<T> {
  final SchemaType schemaType;
  final String? description;
  final T? defaultValue;
  final List<Validator<T>> constraints;

  const AckSchema({
    required this.schemaType,
    this.description,
    this.defaultValue,
    this.constraints = const [],
  });

  @protected
  List<ConstraintError> _checkConstraints(T value, SchemaContext context) {
    if (constraints.isEmpty) return const [];
    final errors = <ConstraintError>[];
    for (final validator in constraints) {
      final error = validator.validate(value);
      if (error != null) {
        errors.add(error);
      }
    }

    return errors;
  }

  @protected
  SchemaResult<T> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue == null) {
      // This is now the crucial check. If the type T is nullable,
      // this schema can handle nulls.
      if (null is T) {
        return defaultValue != null
            ? SchemaResult.ok(defaultValue as T)
            : SchemaResult.ok(null as T);
      }

      // Otherwise, if T is non-nullable, fail.
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: [NonNullableConstraint().validate(null)],
        context: context,
      ));
    }

    final SchemaResult<T> convertedResult =
        tryConvertInput(inputValue, context);
    if (convertedResult.isFail) return convertedResult;

    final convertedValue = convertedResult.getOrNull();

    if (convertedValue == null) {
      // This path indicates a failed conversion within a nullable context.
      if (null is T) {
        return defaultValue != null
            ? SchemaResult.ok(defaultValue as T)
            : SchemaResult.ok(null as T);
      }

      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: [
            InvalidTypeConstraint(expectedType: T, inputValue: inputValue)
                .validate(inputValue),
          ],
          context: context,
        ),
      );
    }

    // Only validate constraints if we have a non-null converted value
    final constraintViolations = _checkConstraints(convertedValue, context);
    if (constraintViolations.isNotEmpty) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintViolations,
        context: context,
      ));
    }

    return validateConvertedValue(convertedValue, context);
  }

  @protected
  SchemaResult<T> tryConvertInput(Object? inputValue, SchemaContext context);

  @protected
  SchemaResult<T> validateConvertedValue(
    T? convertedValue,
    SchemaContext context,
  );

  SchemaResult<T> validate(Object? value, {String? debugName}) {
    final effectiveDebugName = debugName ?? schemaType.name.toLowerCase();

    return executeWithContext(
      SchemaContext(name: effectiveDebugName, schema: this, value: value),
      (ctx) => parseAndValidate(value, ctx),
    );
  }

  T parse(Object? value, {String? debugName}) {
    final result = validate(value, debugName: debugName);

    return result.getOrThrow();
  }

  T? tryParse(Object? value, {String? debugName}) {
    final result = validate(value, debugName: debugName);

    return result.getOrNull();
  }

  // Abstract Methods for Fluent API
  AckSchema<T> copyWith({
    String? description,
    Object? defaultValue,
    List<Validator<T>>? constraints,
  });

  AckSchema<T> withDescription(String? newDescription);
  AckSchema<T> withDefault(T newDefaultValue);
  AckSchema<T> addConstraint(Validator<T> constraint);
  AckSchema<T> addConstraints(List<Validator<T>> newConstraints);

  Map<String, Object?> toJsonSchema();
  String toJsonSchemaString() => prettyJson(toJsonSchema());

  Map<String, Object?> toDefinitionMap() {
    return {
      'schemaType': schemaType.name,
      'description': description,
      'defaultValue': defaultValue?.toString(),
      'constraints': constraints.map((c) => c.toMap()).toList(),
    };
  }
}

/// Extension to provide the `.nullable()` method on non-nullable schemas.
extension NullableSchemaExtension<T extends Object> on AckSchema<T> {
  /// Transforms a non-nullable schema into a schema that accepts `null`.
  AckSchema<T?> nullable() {
    return NullableSchema(this);
  }
}
