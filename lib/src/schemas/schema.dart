part of '../ack_base.dart';

abstract class Schema<T extends Object> {
  final bool _nullable;

  final List<ConstraintsValidator<T>> _constraints;
  const Schema({
    bool nullable = false,
    List<ConstraintsValidator<T>>? constraints,
  })  : _nullable = nullable,
        _constraints = constraints ?? const [];

  Schema<T> copyWith({
    bool? nullable,
    List<ConstraintsValidator<T>>? constraints,
  });

  @visibleForTesting
  List<ConstraintsValidator<T>> getConstraints() => _constraints;

  @visibleForTesting
  bool getNullable() => _nullable;

  // Schema<T> withConstraints(List<ConstraintsValidator<T>> constraints) {
  //   return copyWith(constraints: constraints);
  // }

  T? _tryParse(Object value);

  List<ConstraintsValidationError> _validateParsed(T value) {
    return _constraints
        .map((e) => e.validate(value))
        .whereType<ConstraintsValidationError>()
        .toList();
  }

  SchemaResult validate(Object? value) {
    if (value == null) {
      return _nullable
          ? Ok.unit()
          : Fail(SchemaValidationError.nonNullableValue());
    }

    final typedValue = _tryParse(value);
    if (typedValue == null) {
      return Fail(
        SchemaValidationError.invalidType(
          invalidType: value.runtimeType,
          expectedType: T,
        ),
      );
    }

    final errors = _validateParsed(typedValue);
    if (errors.isEmpty) {
      return Ok(typedValue);
    }
    return Fail(SchemaValidationError.constraints(errors: errors));
  }

  Map<String, Object?> toMap() {
    return {
      'constraints': _constraints.map((e) => e.toMap()),
      'nullable': _nullable,
    };
  }
}

final class SchemaValidationError extends ValidationError {
  const SchemaValidationError._({
    required super.type,
    required super.message,
    super.context = const {},
  });

  factory SchemaValidationError.invalidType({
    required Type invalidType,
    required Type expectedType,
  }) {
    return SchemaValidationError._(
      type: 'invalid_type',
      message: 'Invalid Type $invalidType, expected $expectedType',
      context: {
        'invalidType': invalidType,
        'expectedType': expectedType,
      },
    );
  }

  // constraints
  static SchemaValidationConstraintsError constraints({
    required List<ConstraintsValidationError> errors,
  }) {
    return SchemaValidationConstraintsError(errors);
  }

  factory SchemaValidationError.nonNullableValue() {
    return SchemaValidationError._(
      type: 'non_nullable_value',
      message: 'Non nullable value is null',
    );
  }

  factory SchemaValidationError.unknownException({
    Object? error,
    StackTrace? stackTrace,
  }) {
    return SchemaValidationError._(
      type: 'unknown_exception',
      message: 'Unknown Exception when validating schema',
      context: {
        'error': error,
        'stackTrace': stackTrace,
      },
    );
  }
}

final class SchemaValidationConstraintsError extends SchemaValidationError {
  final List<ConstraintsValidationError> errors;
  SchemaValidationConstraintsError(this.errors)
      : super._(
          type: 'constraints',
          message: 'Constraints validation failed',
          context: {
            'errors': errors.map((e) => e.toMap()).toList(),
          },
        );

  ConstraintsValidationError? getError(String type) {
    return _errorsMap()[type];
  }

  Map<String, ConstraintsValidationError> _errorsMap() {
    return {for (final error in errors) error.type: error};
  }
}
