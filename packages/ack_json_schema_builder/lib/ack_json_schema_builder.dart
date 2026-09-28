/// Bidirectional JSON Schema Builder bridge for ACK validation library.
///
/// Converts ACK validation schemas to json_schema_builder Schema format
/// from ACK's stable Draft-7 JSON Schema renderer. Use the explicit preserving
/// export on an imported schema when its draft 2020-12 dialect is required.
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
  /// map, preserving the 1.x Draft-7 export representation.
  jsb.Schema toJsonSchemaBuilder() {
    return jsb.Schema.fromMap(toJsonSchema());
  }

  /// Converts imports without lowering their draft 2020-12 resources.
  /// Native schemas retain Draft-7 output.
  jsb.Schema toJsonSchemaBuilderPreservingImportedDialect() {
    return jsb.Schema.fromMap(toJsonSchemaPreservingImportedDialect());
  }
}

/// Converts a [AckSchemaModel] model directly to json_schema_builder [Schema] format.
///
/// This is useful for testing or when you have a pre-built AckSchemaModel model.
jsb.Schema convertAckSchemaModelToBuilder(AckSchemaModel schema) {
  return jsb.Schema.fromMap(schema.toJsonSchema());
}
