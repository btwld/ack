/// Bidirectional JSON Schema Builder bridge for ACK validation library.
///
/// Converts ACK validation schemas to json_schema_builder Schema format
/// from ACK's generic Draft-7 JSON Schema renderer.
/// Imports draft 2020-12 builder models through [AckSchemaImportExtension].
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

/// Imports json_schema_builder models using ACK's JSON Schema importer.
extension AckSchemaImportExtension on jsb.Schema {
  /// Strictly converts this draft 2020-12 model to an ACK validator.
  /// Unsupported semantics throw [JsonSchemaImportException].
  AckSchema<Object, Object> toAckSchema({
    Uri? baseUri,
    Map<Uri, jsb.Schema> documents = const {},
  }) => Ack.fromJsonSchema(
    value,
    baseUri: baseUri,
    documents: documents.map((uri, schema) => MapEntry(uri, schema.value)),
  );
}

/// Extension methods for converting ACK schemas to json_schema_builder format.
extension JsonSchemaBuilderExtension on AckSchema {
  /// Converts this ACK schema to json_schema_builder Schema format.
  ///
  /// Returns a json_schema_builder [Schema] instance from ACK's generic
  /// Draft-7 JSON Schema map.
  jsb.Schema toJsonSchemaBuilder() {
    return jsb.Schema.fromMap(toJsonSchema());
  }
}

/// Converts a [AckSchemaModel] model directly to json_schema_builder [Schema] format.
///
/// This is useful for testing or when you have a pre-built AckSchemaModel model.
jsb.Schema convertAckSchemaModelToBuilder(AckSchemaModel schema) {
  return jsb.Schema.fromMap(schema.toJsonSchema());
}
