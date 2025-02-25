part of '../ack.dart';

abstract class ConstraintValidator<T> {
  const ConstraintValidator();

  String get name;
  String get description;

  bool isValid(T value);

  ConstraintError? validate(T value) => isValid(value) ? null : onError(value);

  ConstraintError onError(T value);

  Map<String, Object?> toMap() {
    return {'name': name, 'description': description};
  }

  String toJson() => prettyJson(toMap());

  @protected
  ConstraintError buildError({
    required String message,
    required Map<String, Object?> context,
  }) {
    return ConstraintError(name: name, message: message, context: context);
  }

  @override
  String toString() => toJson();
}

abstract class OpenApiConstraintValidator<T> extends ConstraintValidator<T> {
  const OpenApiConstraintValidator();

  Map<String, Object?> toSchema();
}
