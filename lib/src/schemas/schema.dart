part of '../ack_base.dart';

mixin SchemaFluentMethods<S extends Schema<T>, T extends Object> on Schema<T> {
  S withConstraints(List<ConstraintValidator<T>> constraints) =>
      copyWith(constraints: [..._constraints, ...constraints]) as S;

  ListSchema<T> get list => ListSchema<T>(this);

  S nullable() => copyWith(nullable: true) as S;

  S strict() => copyWith(strict: true) as S;

  void validateOrThrow(Object value) {
    return checkResult(value).match(
      onOk: (data) => data,
      onFail: (errors) => throw AckException(errors),
    );
  }

  SchemaResult<T> validate(Object? value) {
    try {
      return checkResult(value);
    } catch (e, stackTrace) {
      return Fail(
        [SchemaError.unknownException(error: e, stackTrace: stackTrace)],
      );
    }
  }
}

abstract class Schema<T extends Object> {
  final bool _nullable;
  final bool _strict;
  final String _description;

  final List<ConstraintValidator<T>> _constraints;
  const Schema({
    bool nullable = false,
    required String? description,
    bool strict = false,
    List<ConstraintValidator<T>>? constraints,
  })  : _nullable = nullable,
        _description = description ?? '',
        _strict = strict,
        _constraints = constraints ?? const [];

  T? _tryParse(Object value) {
    if (value is T) return value;
    if (!_strict) {
      if (value is String) return _tryParseString(value);
      if (value is num) return _tryParseNum(value);
    }

    return null;
  }

  T? _tryParseNum(num value) {
    if (T == int) return value.toInt() as T?;
    if (T == double) return value.toDouble() as T?;
    if (T == String) return value.toString() as T?;

    return null;
  }

  T? _tryParseString(String value) {
    if (T == int) return int.tryParse(value) as T?;
    if (T == double) return double.tryParse(value) as T?;
    if (T == bool) return bool.tryParse(value) as T?;

    return null;
  }

  Schema<T> copyWith({
    bool? nullable,
    bool? strict,
    String? description,
    List<ConstraintValidator<T>>? constraints,
  });

  List<ConstraintValidator<T>> getConstraints() => _constraints;

  bool getNullable() => _nullable;

  bool getStrict() => _strict;

  @visibleForTesting
  List<SchemaError> validateAsType(T value) {
    return _constraints
        .map((e) => e.validate(value))
        .whereType<SchemaError>()
        .toList();
  }

  @protected
  SchemaResult<T> checkResult(Object? value) {
    if (value == null) {
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

    final errors = validateAsType(typedValue);

    return errors.isEmpty ? Ok(typedValue) : Fail(errors);
  }

  Map<String, Object?> toMap() {
    return {
      'type': T.toString(),
      'constraints': _constraints.map((e) => e.toMap()).toList(),
      'nullable': _nullable,
      'strict': _strict,
      'description': _description,
    };
  }

  String toJson() => prettyJson(toMap());
}
