part of '../ack_base.dart';

abstract class Schema<T extends Object> {
  final bool _nullable;
  final bool _strict;

  final List<ConstraintValidator<T>> _constraints;
  const Schema({
    bool nullable = false,
    bool strict = false,
    List<ConstraintValidator<T>>? constraints,
  })  : _nullable = nullable,
        _strict = strict,
        _constraints = constraints ?? const [];

  Schema<T> copyWith({
    bool? nullable,
    bool? strict,
    List<ConstraintValidator<T>>? constraints,
  });

  @visibleForTesting
  List<ConstraintValidator<T>> getConstraints() => _constraints;

  bool get isNullable => _nullable;

  bool get isStrict => _strict;

  T? _tryParse(Object value) {
    if (value is T) return value;
    if (!_strict) {
      if (value is String) return _tryParseString(value);
      if (value is num) {
        if (T == int) return value.toInt() as T?;
        if (T == double) return value.toDouble() as T?;
        if (T == String) return value.toString() as T?;
      }
    }
    return null;
  }

  T? _tryParseString(String value) {
    if (T == int) return int.tryParse(value) as T?;
    if (T == double) return double.tryParse(value) as T?;
    if (T == bool) return bool.tryParse(value) as T?;
    return null;
  }

  @visibleForTesting
  List<SchemaError> validateAsType(T value) {
    return _constraints
        .map((e) => e.validate(value))
        .whereType<SchemaError>()
        .toList();
  }

  SchemaResult validate(Object? value) {
    if (value == null) {
      return _nullable ? Ok.unit() : Fail([SchemaError.nonNullableValue()]);
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

    final errors = validateAsType(typedValue);
    return errors.isEmpty ? Ok(typedValue) : Fail(errors);
  }

  Map<String, Object?> toMap() {
    return {
      'type': T.toString(),
      'constraints': _constraints.map((e) => e.toMap()).toList(),
      'nullable': _nullable,
    };
  }

  String toJson() => prettyJson(toMap());
}
