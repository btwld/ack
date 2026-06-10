import 'dart:async';

abstract interface class StandardSchema<Input, Output> {
  /// Standard schema properties.
  StandardSchemaProps<Input, Output> get standard;
}

final class StandardSchemaProps<Input, Output> {
  const StandardSchemaProps({
    required this.vendor,
    required this.validate,
    this.version = 1,
    this.jsonSchema,
  });

  final String vendor;
  final int version;
  final FutureOr<StandardResult<Output>> Function(
    Object? value, [
    StandardValidateOptions? options,
  ])
  validate;
  final StandardJsonSchemaConverter? jsonSchema;
}

final class StandardValidateOptions {
  const StandardValidateOptions({this.libraryOptions});

  final Map<String, Object?>? libraryOptions;
}

sealed class StandardResult<Output> {
  const StandardResult();
}

final class StandardSuccess<Output> extends StandardResult<Output> {
  const StandardSuccess(this.value);

  final Output value;
}

final class StandardFailure<Output> extends StandardResult<Output> {
  const StandardFailure(this.issues);

  final List<StandardIssue> issues;
}

final class StandardIssue {
  const StandardIssue({required this.message, this.path = const []});

  final String message;
  final List<Object> path;
}

final class StandardJsonSchemaConverter {
  const StandardJsonSchemaConverter({
    required this.input,
    required this.output,
  });

  final Map<String, Object?> Function(StandardJsonSchemaOptions options) input;
  final Map<String, Object?> Function(StandardJsonSchemaOptions options) output;
}

final class StandardJsonSchemaOptions {
  const StandardJsonSchemaOptions({required this.target, this.libraryOptions});

  final String target;
  final Map<String, Object?>? libraryOptions;
}

abstract final class JsonSchemaTarget {
  static const draft202012 = 'draft-2020-12';
  static const draft07 = 'draft-07';
  static const openapi30 = 'openapi-3.0';
}
