import 'package:meta/meta.dart';

import '../constraints/constraint.dart';
import '../constraints/validators.dart';
import '../context.dart';
import '../helpers.dart';
import '../validation/schema_error.dart';
import '../validation/schema_result.dart';

part 'any_of_schema.dart';
part 'boolean_schema.dart';
part 'discriminated_object_schema.dart';
part 'enum_schema.dart';
part 'list_schema.dart';
part 'mixins/fluent_schema.dart';
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
  enumType,
  unknown,
}

@immutable
sealed class AckSchema<DartType extends Object> {
  final SchemaType schemaType;
  final bool isNullable;
  final String? description;
  final DartType? defaultValue;
  final List<Validator<DartType>> constraints;

  const AckSchema({
    required this.schemaType,
    this.isNullable = false,
    this.description,
    this.defaultValue,
    this.constraints = const [],
  });

  @protected
  List<ConstraintError> _checkConstraints(
    DartType value,
    SchemaContext context,
  ) {
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
  SchemaResult<DartType> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue == null) {
      if (isNullable) {
        return SchemaResult.ok(defaultValue);
      }
      if (defaultValue != null) {
        return SchemaResult.ok(defaultValue);
      }
      final constraintError = NonNullableConstraint().validate(null);

      return SchemaResult.fail(SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ));
    }

    final SchemaResult<DartType> convertedResult =
        tryConvertInput(inputValue, context);
    if (convertedResult.isFail) return convertedResult;

    final convertedValue = convertedResult.getOrNull();

    if (convertedValue == null) {
      final constraintError =
          InvalidTypeConstraint(expectedType: DartType, inputValue: inputValue)
              .validate(inputValue);

      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: constraintError != null ? [constraintError] : [],
          context: context,
        ),
      );
    }

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
  SchemaResult<DartType> tryConvertInput(
    Object? inputValue,
    SchemaContext context,
  );

  @protected
  SchemaResult<DartType> validateConvertedValue(
    DartType convertedValue,
    SchemaContext context,
  );

  SchemaResult<DartType> validate(Object? value, {String? debugName}) {
    final effectiveDebugName = debugName ?? schemaType.name.toLowerCase();

    return executeWithContext(
      SchemaContext(name: effectiveDebugName, schema: this, value: value),
      (ctx) => parseAndValidate(value, ctx),
    );
  }

  DartType? parse(Object? value, {String? debugName}) {
    final result = validate(value, debugName: debugName);

    return result.getOrThrow();
  }

  DartType? tryParse(Object? value, {String? debugName}) {
    final result = validate(value, debugName: debugName);

    return result.getOrNull();
  }

  @protected
  AckSchema<DartType> copyWithInternal({
    required bool? isNullable,
    required String? description,
    required Object? defaultValue,
    required List<Validator<DartType>>? constraints,
  });

  AckSchema<DartType> copyWith({
    bool? isNullable,
    String? description,
    Object? defaultValue,
    List<Validator<DartType>>? constraints,
  }) {
    return copyWithInternal(
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
      constraints: constraints,
    );
  }

  Map<String, Object?> toJsonSchema();
  String toJsonSchemaString() => prettyJson(toJsonSchema());

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
