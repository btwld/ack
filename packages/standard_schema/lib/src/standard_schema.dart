import 'dart:async';

/// An entity that exposes Standard Schema family metadata.
///
/// The Dart spelling of upstream `StandardTypedV1`: the upstream `~standard`
/// key is exposed as [standard], and the TypeScript-only phantom `types` field
/// is omitted because Dart generics carry input/output types.
abstract interface class StandardTypedV1<Input, Output> {
  /// The standard typed properties.
  StandardTypedPropsV1<Input, Output> get standard;
}

/// A schema that validates unknown values.
///
/// This is the Dart spelling of upstream `StandardSchemaV1`.
abstract interface class StandardSchemaV1<Input, Output>
    implements StandardTypedV1<Input, Output> {
  /// The standard schema properties.
  @override
  StandardSchemaPropsV1<Input, Output> get standard;
}

/// An entity that can convert its input/output sides to JSON Schema.
///
/// This is the Dart spelling of upstream `StandardJSONSchemaV1`. It is
/// intentionally separate from [StandardSchema]; an object may implement one
/// or both traits.
abstract interface class StandardJsonSchemaV1<Input, Output>
    implements StandardTypedV1<Input, Output> {
  /// The standard JSON Schema properties.
  @override
  StandardJsonSchemaPropsV1<Input, Output> get standard;
}

/// Dart-only convenience for entities that implement both standard validation
/// and standard JSON Schema conversion with one [standard] property.
///
/// Not a separate upstream interface. Upstream defines exactly two interfaces
/// (`StandardSchemaV1`, `StandardJSONSchemaV1`), each with its own `~standard`.
/// A TypeScript schema implementing both has one `~standard` that structurally
/// satisfies both Props. This interface models that intersection for Dart,
/// where one getter cannot return two unrelated types.
abstract interface class StandardSchemaWithJsonSchemaV1<Input, Output>
    implements
        StandardSchemaV1<Input, Output>,
        StandardJsonSchemaV1<Input, Output> {
  /// The combined standard properties.
  @override
  StandardSchemaWithJsonSchemaPropsV1<Input, Output> get standard;
}

/// Backward-compatible convenience alias for [StandardTypedV1].
typedef StandardTyped<Input, Output> = StandardTypedV1<Input, Output>;

/// Backward-compatible convenience alias for [StandardSchemaV1].
typedef StandardSchema<Input, Output> = StandardSchemaV1<Input, Output>;

/// Backward-compatible convenience alias for [StandardJsonSchemaV1].
typedef StandardJsonSchema<Input, Output> = StandardJsonSchemaV1<Input, Output>;

/// Backward-compatible convenience alias for [StandardSchemaWithJsonSchemaV1].
typedef StandardSchemaWithJsonSchema<Input, Output> =
    StandardSchemaWithJsonSchemaV1<Input, Output>;

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

/// The properties shared by every standard trait.
final class StandardTypedPropsV1<Input, Output> {
  const StandardTypedPropsV1({required this.vendor});

  /// The vendor name of the schema library.
  final String vendor;

  /// The version of the standard. Always `1` for this spec revision (Dart
  /// cannot pin the literal type the way TypeScript's `version: 1` does).
  int get version => 1;
}

/// The properties of a [StandardSchema].
final class StandardSchemaPropsV1<Input, Output>
    extends StandardTypedPropsV1<Input, Output> {
  const StandardSchemaPropsV1({required super.vendor, required this.validate});

  /// Validates an unknown input value.
  final StandardValidate<Output> validate;
}

/// The properties of a [StandardJsonSchema].
final class StandardJsonSchemaPropsV1<Input, Output>
    extends StandardTypedPropsV1<Input, Output> {
  const StandardJsonSchemaPropsV1({
    required super.vendor,
    required this.jsonSchema,
  });

  /// The JSON Schema tier converter.
  final StandardJsonSchemaConverter jsonSchema;
}

/// The properties of a [StandardSchemaWithJsonSchema].
final class StandardSchemaWithJsonSchemaPropsV1<Input, Output>
    extends StandardSchemaPropsV1<Input, Output>
    implements StandardJsonSchemaPropsV1<Input, Output> {
  const StandardSchemaWithJsonSchemaPropsV1({
    required super.vendor,
    required super.validate,
    required this.jsonSchema,
  });

  /// The JSON Schema tier converter.
  @override
  final StandardJsonSchemaConverter jsonSchema;
}

/// Backward-compatible convenience alias for [StandardTypedPropsV1].
typedef StandardTypedProps<Input, Output> = StandardTypedPropsV1<Input, Output>;

/// Backward-compatible convenience alias for [StandardSchemaPropsV1].
typedef StandardSchemaProps<Input, Output> =
    StandardSchemaPropsV1<Input, Output>;

/// Backward-compatible convenience alias for [StandardJsonSchemaPropsV1].
typedef StandardJsonSchemaProps<Input, Output> =
    StandardJsonSchemaPropsV1<Input, Output>;

/// Backward-compatible convenience alias for
/// [StandardSchemaWithJsonSchemaPropsV1].
typedef StandardSchemaWithJsonSchemaProps<Input, Output> =
    StandardSchemaWithJsonSchemaPropsV1<Input, Output>;

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
  StandardFailure(Iterable<StandardIssue> issues)
    : issues = List.unmodifiable(issues);

  /// The issues describing why validation failed.
  final List<StandardIssue> issues;
}

/// A single validation issue.
final class StandardIssue {
  StandardIssue({required this.message, Iterable<Object> path = const []})
    : path = List.unmodifiable(path);

  /// The error message of the issue.
  final String message;

  /// The path to the offending value, if any.
  ///
  /// Each entry is either a raw property key (for example a [String] object key
  /// or [num] index) or a [StandardPathSegment] object with a
  /// [StandardPathSegment.key]. Empty for a root-level issue.
  final List<Object> path;
}

/// An object path segment in a [StandardIssue.path].
///
/// This is the Dart spelling of upstream `StandardSchemaV1.PathSegment`.
final class StandardPathSegment {
  const StandardPathSegment({required this.key});

  /// The key representing a path segment.
  final Object key;
}

/// The JSON Schema tier converter.
///
/// The [input]/[output] split exists because validators transform: [input]
/// describes the value accepted at the boundary, while [output] describes the
/// value produced at runtime.
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
/// zero-cost extension type over [String] where the constants are recommended
/// targets, but any string is accepted via the constructor.
extension type const JsonSchemaTarget(String value) implements String {
  /// JSON Schema Draft 2020-12.
  static const draft202012 = JsonSchemaTarget('draft-2020-12');

  /// JSON Schema Draft 7.
  static const draft07 = JsonSchemaTarget('draft-07');

  /// OpenAPI 3.0 (a superset of JSON Schema Draft 4).
  static const openapi30 = JsonSchemaTarget('openapi-3.0');
}
