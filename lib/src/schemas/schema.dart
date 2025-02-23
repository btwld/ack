part of '../ack_base.dart';

final class Schema<T extends Object> {
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
  }) {
    return Schema<T>(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
    );
  }

  T? _tryParse(Object value) {
    if (value is T) return value;
    if (value is! String) return null;
    if (T == bool) return bool.tryParse(value) as T?;
    if (T == int) return int.tryParse(value) as T?;
    if (T == double) return double.tryParse(value) as T?;
    if (T == num) return num.tryParse(value) as T?;
    return null;
  }

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
      'type': 'schema',
      'constraints': _constraints.map((e) => e.toMap()),
    };
  }
}

extension SchemaExt<S extends Schema<T>, T extends Object> on S {
  S constraint(ConstraintsValidator<T> validator) {
    return copyWith(
      constraints: [..._constraints, validator],
    ) as S;
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
  factory SchemaValidationError.constraints({
    required List<ConstraintsValidationError> errors,
  }) {
    return SchemaValidationError._(
      type: 'constraints',
      message: 'Constraints validation failed',
      context: {
        'errors': errors,
      },
    );
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
