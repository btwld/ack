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
part 'fluent_schema.dart';
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

  @protected
  SchemaResult<DartType> _onConvert(
    Object? inputValue,
    SchemaContext context,
  );

  /// Whether this schema represents an optional field in an object.
  /// Override this in OptionalSchema to return true.
  bool get isOptional => false;

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
        inputValue = defaultValue;
      } else {
        final constraintError = NonNullableConstraint().validate(null);

        return SchemaResult.fail(SchemaConstraintsError(
          constraints: constraintError != null ? [constraintError] : [],
          context: context,
        ));
      }
    }

    final SchemaResult<DartType> convertedResult =
        _onConvert(inputValue, context);
    if (convertedResult.isFail) return convertedResult;

    final convertedValue = convertedResult.getOrNull();

    if (convertedValue == null) {
      if (isNullable) {
        return SchemaResult.ok(null);
      }
    }

    final constraintViolations =
        _checkConstraints(convertedValue as DartType, context);
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

    return executeWithContext(
      SchemaContext(name: effectiveDebugName, schema: this, value: value),
      (ctx) => parseAndValidate(value, ctx),
    );
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
