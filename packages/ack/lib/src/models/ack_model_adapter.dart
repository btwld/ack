import '../schemas/schema.dart';
import '../schemas/extensions/ack_schema_extensions.dart';
import '../validation/schema_result.dart';

/// Connects a generated immutable model to an Ack schema.
///
/// The schema owns boundary validation and codec behavior. Generated model
/// classes only map between the schema's validated runtime value and their
/// stored Dart fields.
final class AckModelAdapter<
  Boundary extends Object,
  Runtime extends Object,
  Model extends Object
> {
  /// Creates an adapter for a generated model.
  ///
  /// [schema] is a callback rather than a stored schema value so generated
  /// models can safely participate in recursive and mutually-recursive graphs.
  const AckModelAdapter({
    required AckSchema<Boundary, Runtime> Function() schema,
    required Model Function(Runtime value) fromRuntime,
    required Runtime Function(Model value) toRuntime,
  }) : _schema = schema,
       _fromRuntime = fromRuntime,
       _toRuntime = toRuntime;

  final AckSchema<Boundary, Runtime> Function() _schema;
  final Model Function(Runtime value) _fromRuntime;
  final Runtime Function(Model value) _toRuntime;

  /// Resolves the source schema for this model.
  AckSchema<Boundary, Runtime> get schema => _schema();

  /// Resolves a schema that decodes to this model.
  ///
  /// The source schema keeps ownership of boundary validation and encoding.
  AckSchema<Boundary, Model> get modelSchema =>
      schema.codec<Model>(decode: _fromRuntime, encode: _toRuntime);

  /// Converts an already-validated Ack runtime value into the model.
  ///
  /// Use this for nested generated models. Calling [parse] on a nested runtime
  /// value can decode codecs twice because the parent schema has already
  /// completed boundary-to-runtime conversion.
  Model fromRuntime(Runtime value) => _fromRuntime(value);

  /// Converts a model into the runtime value expected by its Ack schema.
  Runtime toRuntime(Model value) => _toRuntime(value);

  /// Parses and validates boundary input, then creates the generated model.
  Model parse(Object? input, {String? debugName}) {
    return schema.parseAs<Model>(
      input,
      (validated) => _fromRuntime(validated as Runtime),
      debugName: debugName,
    );
  }

  /// Safely parses boundary input into the generated model.
  SchemaResult<Model> safeParse(Object? input, {String? debugName}) {
    return schema.safeParseAs<Model>(
      input,
      (validated) => _fromRuntime(validated as Runtime),
      debugName: debugName,
    );
  }

  /// Encodes a generated model to its boundary representation.
  Boundary encode(Model value, {String? debugName}) {
    return schema.encode(_toRuntime(value), debugName: debugName) as Boundary;
  }

  /// Safely encodes a generated model to its boundary representation.
  SchemaResult<Boundary> safeEncode(Model value, {String? debugName}) {
    return schema.safeEncode(_toRuntime(value), debugName: debugName);
  }
}
