part of 'ack_base.dart';

sealed class ConstraintsValidator<T> {
  final String type;
  final String description;
  const ConstraintsValidator({required this.type, required this.description});

  ConstraintsValidationError? validate(T value);

  Map<String, Object?> toMap() {
    return {
      'type': type,
      'description': description,
    };
  }
}

final class ConstraintsValidationError extends ValidationError {
  const ConstraintsValidationError({
    required super.type,
    required super.message,
    required super.context,
  });
}
