part of '../ack_base.dart';

sealed class ConstraintValidator<T> {
  String get name;
  String get description;

  const ConstraintValidator();

  bool check(T value);

  ConstraintError? validate(T value) => check(value) ? null : onError(value);

  ConstraintError onError(T value);

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() => toJson();

  @protected
  ConstraintError buildError({
    required String message,
    required Map<String, Object?> context,
  }) {
    return ConstraintError(
      name: name,
      message: message,
      context: context,
    );
  }
}
