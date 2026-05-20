/// JSON Schema Builder converter for ACK validation library.
///
/// Converts ACK validation schemas to json_schema_builder Schema format
/// for JSON Schema Draft 2020-12 validation and documentation.
///
/// ## Usage
///
/// ```dart
/// import 'package:ack/ack.dart';
/// import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
///
/// final schema = Ack.object({
///   'name': Ack.string().minLength(2),
///   'age': Ack.integer().min(0).optional(),
/// });
///
/// // Convert to json_schema_builder
/// final jsbSchema = schema.toJsonSchemaBuilder();
/// ```
library;

import 'package:ack/ack.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;

/// Extension methods for converting ACK schemas to json_schema_builder format.
extension JsonSchemaBuilderExtension on AckSchema {
  /// Converts this ACK schema to json_schema_builder Schema format.
  ///
  /// Returns a json_schema_builder [Schema] instance for JSON Schema Draft 2020-12.
  jsb.Schema toJsonSchemaBuilder() {
    return convertAckSchemaModelToBuilder(toSchemaModel());
  }
}

/// Converts a [AckSchemaModel] model directly to json_schema_builder [Schema] format.
///
/// This is useful for testing or when you have a pre-built AckSchemaModel model.
jsb.Schema convertAckSchemaModelToBuilder(AckSchemaModel schema) {
  return jsb.Schema.fromMap(schema.toJsonSchema());
}
