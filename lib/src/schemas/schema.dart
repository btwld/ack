import 'dart:convert';
import 'dart:developer';

import 'package:meta/meta.dart';

import '../helpers.dart';
import '../validation/ack_exception.dart';
import '../validation/constraint_validator.dart';
import '../validation/schema_error.dart';
import '../validation/schema_result.dart';

part 'boolean/boolean_schema.dart';
part 'boolean/boolean_validators.dart';
part 'discriminated/discriminated_object_schema.dart';
part 'discriminated/discriminated_object_validators.dart';
part 'list/list_schema.dart';
part 'list/list_validators.dart';
part 'num/num_schema.dart';
part 'num/num_validators.dart';
part 'object/object_schema.dart';
part 'object/object_validators.dart';
part 'string/string_schema.dart';
part 'string/string_validators.dart';

enum SchemaType {
  string,
  int,
  double,
  boolean,
  object,
  discriminatedObject,
  list,
}

/// {@template schema}
/// Abstract base class for defining data schemas.
///
/// Schemas are used to validate data against a defined structure and constraints.
/// They provide a way to ensure that data conforms to expected types and rules.
///
/// See also:
/// * [StringSchema] for validating strings.
/// * [IntegerSchema] for validating integers.
/// * [DoubleSchema] for validating doubles.
/// * [BooleanSchema] for validating booleans.
/// * [ListSchema] for validating lists of values.
/// * [ObjectSchema] for validating Maps
/// * [DiscriminatedObjectSchema] for validating unions
/// * [SchemaFluentMethods] for fluent methods to enhance [Schema] instances.
///
/// {@endtemplate}
sealed class Schema<T extends Object> {
  /// The type of the schema.
  final SchemaType type;

  /// Whether this schema allows null values.
  final bool _nullable;

  /// A human-readable description of this schema.
  ///
  /// This description can be used for documentation or error messages.
  final String _description;

  /// The default value to return if the value is not provided.
  final T? _defaultValue;

  /// A list of validators applied to this schema.
  final List<ConstraintValidator<T>> _constraints;

  /// {@macro schema}
  ///
  /// * [nullable]: Whether null values are allowed. Defaults to `false`.
  /// * [description]: A description of the schema. Defaults to an empty string if not provided. Must not be null.
  /// * [strict]: Whether parsing should be strict. Defaults to `false`.
  /// * [constraints]: A list of constraint validators to apply. Defaults to an empty list.
  const Schema({
    bool nullable = false,
    required String? description,
    required this.type,
    required List<ConstraintValidator<T>>? constraints,
    required T? defaultValue,
  })  : _nullable = nullable,
        _description = description ?? '',
        _constraints = constraints ?? const [],
        _defaultValue = defaultValue;

  /// Attempts to parse the given [value] into type [T].
  ///
  /// If [value] is already of type [T], it is returned directly.
  /// If [_strict] is `false`, attempts will be made to parse [String] and [num]
  /// values into [T] if possible.
  ///
  /// Returns the parsed value of type [T] or `null` if parsing fails.
  T? _tryParse(Object value) {
    return value is T ? value : null;
  }

  /// Validates the [value] against the constraints, assuming it is already of type [T].
  ///
  /// This method is primarily for internal use and testing, after the value has
  /// already been successfully parsed or is known to be of the correct type [T].
  ///
  /// Returns a list of [SchemaError] objects if any constraints are violated,
  /// otherwise returns an empty list.
  List<SchemaError> _validateAsType(T value) {
    return _constraints
        .map((e) => e.validate(value))
        .whereType<SchemaError>()
        .toList();
  }

  Schema<T> call({
    bool? nullable,
    String? description,
    List<ConstraintValidator<T>>? constraints,
  });

  /// Creates a new [Schema] with the same properties as this one, but with the
  /// given parameters overridden.
  ///
  /// This method is intended to be overridden in subclasses to provide a
  /// concrete `copyWith` implementation that returns the correct subclass type.
  Schema<T> copyWith({
    bool? nullable,
    String? description,
    List<ConstraintValidator<T>>? constraints,
  });

  /// Returns the list of constraint validators associated with this schema.
  List<ConstraintValidator<T>> getConstraints() => _constraints;

  /// Returns whether this schema allows null values.
  bool getNullableValue() => _nullable;

  /// Returns the description of this schema.
  String getDescriptionValue() => _description;

  /// Returns the type of this schema.
  SchemaType getSchemaTypeValue() => type;

  /// Returns the default value of this schema.
  T? getDefaultValue() => _defaultValue;

  /// Checks the [value] against this schema, performing type checking and
  /// constraint validation.
  ///
  /// This is the core validation method for [Schema].
  ///
  /// If [value] is `null`:
  ///   - If [_nullable] is `true`, returns [Ok] with `null` data.
  ///   - If [_nullable] is `false`, returns [Fail] with a [SchemaError.nonNullableValue].
  ///
  /// If [value] is not `null`:
  ///   - Attempts to parse [value] to type [T] using [_tryParse].
  ///   - If parsing fails, returns [Fail] with a [SchemaError.invalidType].
  ///   - If parsing succeeds, validates the parsed value against the schema's
  ///     constraints using [_validateAsType].
  ///   - Returns [Ok] with the parsed value if validation succeeds, or [Fail]
  ///     with a list of [SchemaError] objects if validation fails.
  @protected
  SchemaResult<T> checkResult(Object? value) {
    if (value == null) {
      if (_defaultValue != null) {
        return Ok(_defaultValue);
      }

      return _nullable ? Ok(null) : Fail([SchemaError.nonNullableValue()]);
    }

    final typedValue = _tryParse(value);
    if (typedValue == null) {
      return Fail(
        [
          SchemaError.invalidType(
            valueType: value.runtimeType,
            expectedType: T,
          ),
        ],
      );
    }

    final errors = _validateAsType(typedValue);

    return errors.isEmpty
        ? Ok(typedValue)
        : _defaultValue != null
            ? Ok(_defaultValue)
            : Fail(errors);
  }

  /// Validates the [value] against this schema and returns a [SchemaResult].
  ///
  /// This method provides a non-throwing way to validate values against the schema.
  /// It wraps the validation logic in a `try-catch` block to handle potential
  /// exceptions during validation and returns a [Fail] result with a
  /// [SchemaError.unknownException] if an exception occurs.
  ///
  /// Use [validateOrThrow] if you prefer to throw an exception on validation failure.
  SchemaResult<T> validate(Object? value) {
    try {
      return checkResult(value);
    } catch (e, stackTrace) {
      return Fail(
        [SchemaError.unknownException(error: e, stackTrace: stackTrace)],
      );
    }
  }

  /// Converts this schema to a [Map] representation.
  ///
  /// This map includes the schema's type, constraints, nullability, strictness,
  /// and description. It is used by [toJson].
  Map<String, Object?> toMap() {
    return {
      'type': type.name,
      'constraints': _constraints.map((e) => e.toMap()).toList(),
      'nullable': _nullable,
      'description': _description,
      'defaultValue': _defaultValue,
    };
  }

  /// Converts this schema to a JSON string representation.
  ///
  /// Uses [toMap] to generate the map and then pretty-prints it as JSON.
  String toJson() => prettyJson(toMap());
}

/// {@template schema_fluent_methods}
/// Mixin providing fluent methods to enhance [Schema] instances.
///
/// This mixin adds methods like `withConstraints`, `nullable`, `strict`,
/// `validateOrThrow`, and `validate` to [Schema] subclasses, allowing for
/// a more readable and chainable schema definition and validation process.
///
/// {@endtemplate}
mixin SchemaFluentMethods<S extends Schema<T>, T extends Object> on Schema<T> {
  /// Creates a new schema of the same type with additional [constraints].
  ///
  /// The new schema will inherit all properties of the original schema and
  /// include the provided [constraints] in addition to its existing ones.
  S withConstraints(List<ConstraintValidator<T>> constraints) =>
      copyWith(constraints: [..._constraints, ...constraints]) as S;

  /// Creates a [ListSchema] with this schema as its item schema.
  ///
  /// This allows you to define schemas for lists where each item must conform
  /// to this schema.
  ListSchema<T> get list => ListSchema<T>(this);

  /// Creates a new schema of the same type that allows null values.
  ///
  /// This is a convenience method equivalent to calling `copyWith(nullable: true)`.
  S nullable() => copyWith(nullable: true) as S;

  /// Validates the [value] against this schema and throws an [AckException] if validation fails.
  ///
  /// If validation is successful, returns the validated value of type [T].
  /// If validation fails, throws an [AckException] containing a list of [SchemaError] objects.
  ///
  /// **Note**: `AckException` is assumed to be a custom exception class defined elsewhere,
  /// likely in `ack_base.dart`, to handle schema validation errors. Ensure `AckException`
  /// is properly documented to explain its structure and usage for conveying validation failure details.
  void validateOrThrow(Object value) {
    return checkResult(value).match(
      onOk: (data) => data,
      onFail: (errors) => throw AckException(errors),
    );
  }
}

sealed class ScalarSchema<Self extends ScalarSchema<Self, T>, T extends Object>
    extends Schema<T> with SchemaFluentMethods<Self, T> {
  /// Whether parsing should be strict, only accepting values of type [T].
  ///
  /// If `false`, attempts will be made to parse compatible types like [String]
  /// or [num] into the expected type [T].
  final bool _strict;

  const ScalarSchema({
    bool? nullable,
    bool? strict,
    super.description,
    super.constraints,
    required super.type,
    super.defaultValue,
  })  : _strict = strict ?? false,
        super(nullable: nullable ?? false);

  /// Attempts to parse the given [value] into type [T].
  ///
  /// If [value] is already of type [T], it is returned directly.
  /// If [_strict] is `false`, attempts will be made to parse [String] and [num]
  /// values into [T] if possible.
  ///
  /// Returns the parsed value of type [T] or `null` if parsing fails.
  @override
  T? _tryParse(Object value) {
    if (value is T) return value;
    if (!_strict) {
      if (value is String) return _tryParseString(value);
      if (value is num) return _tryParseNum(value);
    }

    return null;
  }

  /// Attempts to parse a [num] value into type [T].
  ///
  /// Supports parsing [num] to [int], [double], or [String].
  /// Returns the parsed value of type [T] or `null` if parsing is not supported.
  T? _tryParseNum(num value) {
    if (T == int) return value.toInt() as T?;
    if (T == double) return value.toDouble() as T?;
    if (T == String) return value.toString() as T?;

    return null;
  }

  /// Attempts to parse a [String] value into type [T].
  ///
  /// Supports parsing [String] to [int], [double], or [bool].
  /// Returns the parsed value of type [T] or `null` if parsing is not supported.
  T? _tryParseString(String value) {
    if (T == int) return int.tryParse(value) as T?;
    if (T == double) return double.tryParse(value) as T?;
    if (T == bool) return bool.tryParse(value) as T?;

    return null;
  }

  @protected
  Self Function({
    bool? nullable,
    String? description,
    bool? strict,
    List<ConstraintValidator<T>>? constraints,
  }) get builder;

  /// Creates a new schema of the same type that enforces strict parsing.
  ///
  /// This is a convenience method equivalent to calling `copyWith(strict: true)`.
  Self strict() => copyWith(strict: true);

  bool getStrictValue() => _strict;

  @override
  Self call({
    bool? nullable,
    String? description,
    bool? strict,
    List<ConstraintValidator<T>>? constraints,
  }) {
    return copyWith(
      nullable: nullable,
      constraints: constraints,
      strict: strict,
      description: description,
    );
  }

  @override
  Self copyWith({
    bool? nullable,
    List<ConstraintValidator<T>>? constraints,
    bool? strict,
    String? description,
  }) {
    return builder(
      constraints: constraints ?? _constraints,
      description: description ?? _description,
      nullable: nullable ?? _nullable,
      strict: strict ?? _strict,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'strict': _strict};
  }
}
