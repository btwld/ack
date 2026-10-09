/// Bidirectional JSON Schema Builder bridge for ACK validation library.
///
/// Converts ACK validation schemas to json_schema_builder Schema format,
/// preserving imported Draft 2020-12 resources by default and emitting ACK's
/// Draft-7 representation for native schemas. Use [toJsonSchemaBuilderDraft7]
/// when an imported schema must be lowered to Draft-7 definitions.
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
  /// Converts this draft 2020-12 model to an ACK validator.
  /// Formats are annotations unless [assertFormats] is true or the model's
  /// dialect requires format assertions.
  /// Unsupported semantics throw [JsonSchemaImportException].
  AckSchema<Object, Object> toAckSchema({
    Uri? baseUri,
    Map<Uri, jsb.Schema> documents = const {},
    bool assertFormats = false,
  }) => Ack.fromJsonSchema(
    value,
    baseUri: baseUri,
    documents: documents.map((uri, schema) => MapEntry(uri, schema.value)),
    assertFormats: assertFormats,
  );
}

/// Extension methods for converting ACK schemas to json_schema_builder format.
extension JsonSchemaBuilderExtension on AckSchema {
  /// Converts this ACK schema to json_schema_builder Schema format.
  ///
  /// Returns a json_schema_builder [Schema] instance from ACK's JSON Schema
  /// map, preserving imported Draft 2020-12 resources by default.
  jsb.Schema toJsonSchemaBuilder() {
    return jsb.Schema.fromMap(toJsonSchema());
  }

  /// Converts imports using the legacy Draft-7 `definitions` / `$ref` lowering.
  jsb.Schema toJsonSchemaBuilderDraft7() {
    return jsb.Schema.fromMap(toJsonSchemaDraft7());
  }
}

/// Converts a [AckSchemaModel] model directly to json_schema_builder [Schema] format.
///
/// This is useful for testing or when you have a pre-built AckSchemaModel model.
jsb.Schema convertAckSchemaModelToBuilder(AckSchemaModel schema) {
  return jsb.Schema.fromMap(schema.toJsonSchema());
}
