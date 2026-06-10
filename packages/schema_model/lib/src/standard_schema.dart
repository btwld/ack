import 'dart:async';

/// A schema that conforms to the Standard Schema spec.
///
/// Implementers expose a single [standard] property carrying the validate tier
/// (always) and, optionally, the JSON Schema tier. Port of `StandardSchemaV1`
/// from [standardschema.dev](https://standardschema.dev); the `~standard` key
/// is spelled [standard] (the tilde is a JS autocomplete hack) and the phantom
/// `types` field is dropped because Dart generics carry that information.
abstract interface class StandardSchema<Input, Output> {
  /// The Standard Schema properties.
  StandardSchemaProps<Input, Output> get standard;
}

/// Validates an unknown value, synchronously or asynchronously.
///
/// Mirrors the spec's `validate(value, options?) => Result | Promise<Result>`.
typedef StandardValidate<Output> =
    FutureOr<StandardResult<Output>> Function(
      Object? value, [
      StandardValidateOptions? options,
    ]);

/// Converts one side (input or output) of a schema to a JSON Schema map.
///
/// May throw for schemas that cannot be represented, or for unsupported
/// [StandardJsonSchemaOptions.target] versions (both permitted by the spec).
typedef StandardJsonSchemaConvert =
    Map<String, Object?> Function(StandardJsonSchemaOptions options);

/// The properties of a [StandardSchema].
final class StandardSchemaProps<Input, Output> {
  const StandardSchemaProps({
    required this.vendor,
    required this.validate,
    this.version = 1,
    this.jsonSchema,
  });

  /// The vendor name of the schema library.
  final String vendor;

  /// The version of the standard. Always `1` for this spec revision (Dart
  /// cannot pin the literal type the way TypeScript's `version: 1` does).
  final int version;

  /// Validates an unknown input value.
  final StandardValidate<Output> validate;

  /// The JSON Schema tier converter, or `null` if this vendor does not
  /// implement the JSON Schema spec.
  final StandardJsonSchemaConverter? jsonSchema;
}

/// Optional parameters passed to [StandardValidate].
final class StandardValidateOptions {
  const StandardValidateOptions({this.libraryOptions});

  /// Vendor-specific parameters, if any.
  final Map<String, Object?>? libraryOptions;
}

/// The result of validation: either [StandardSuccess] or [StandardFailure].
sealed class StandardResult<Output> {
  const StandardResult();
}

/// A successful validation result carrying the typed [value].
final class StandardSuccess<Output> extends StandardResult<Output> {
  const StandardSuccess(this.value);

  /// The validated output value.
  final Output value;
}

/// A failed validation result carrying one or more [issues].
final class StandardFailure<Output> extends StandardResult<Output> {
  const StandardFailure(this.issues);

  /// The issues describing why validation failed.
  final List<StandardIssue> issues;
}

/// A single validation issue.
final class StandardIssue {
  const StandardIssue({required this.message, this.path = const []});

  /// The error message of the issue.
  final String message;

  /// The path to the offending value, as `PropertyKey` segments: a [String]
  /// object key or an [int] list index. Empty for a root-level issue.
  final List<Object> path;
}

/// The JSON Schema tier converter (`StandardJSONSchemaV1`).
///
/// The [input]/[output] split exists because validators transform: [input]
/// describes the value accepted (the boundary side), [output] the value
/// produced (the runtime side).
final class StandardJsonSchemaConverter {
  const StandardJsonSchemaConverter({
    required this.input,
    required this.output,
  });

  /// Converts the input type to a JSON Schema map.
  final StandardJsonSchemaConvert input;

  /// Converts the output type to a JSON Schema map.
  final StandardJsonSchemaConvert output;
}

/// Options for the JSON Schema converter methods.
final class StandardJsonSchemaOptions {
  const StandardJsonSchemaOptions({required this.target, this.libraryOptions});

  /// The target JSON Schema dialect. See [JsonSchemaTarget].
  final JsonSchemaTarget target;

  /// Vendor-specific parameters, if any.
  final Map<String, Object?>? libraryOptions;
}

/// The target version of the generated JSON Schema.
///
/// Mirrors the spec's
/// `Target = 'draft-2020-12' | 'draft-07' | 'openapi-3.0' | (string & {})`: a
/// zero-cost extension type over [String] where the constants are the
/// recommended targets, but any string is accepted via the constructor
/// (`JsonSchemaTarget('my-target')`). Because it `implements String`, a
/// `JsonSchemaTarget` is usable wherever a `String` is and compares equal to
/// its underlying value.
extension type const JsonSchemaTarget(String value) implements String {
  /// JSON Schema Draft 2020-12.
  static const draft202012 = JsonSchemaTarget('draft-2020-12');

  /// JSON Schema Draft 7.
  static const draft07 = JsonSchemaTarget('draft-07');

  /// OpenAPI 3.0 (a superset of JSON Schema Draft 4).
  static const openapi30 = JsonSchemaTarget('openapi-3.0');
}
