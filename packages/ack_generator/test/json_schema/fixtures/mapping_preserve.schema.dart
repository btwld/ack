// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80
// ignore_for_file: type=lint
// coverage:ignore-file
//
// Draft 2020-12 value models retain source-schema validation.
// Complex shapes use Object? values, not inferred typed fields.
// unknown_properties: preserve widened these objects:
// - #/$defs/Listing
// - #/$defs/Listing/properties/address

import 'dart:convert';

import 'package:ack/ack.dart' as ack;

// dart format off
final Object _jsonSchemaDocument =
    jsonDecode('{"\$schema":"https://json-schema.org/draft/2020-12/schema","\$defs":{"Listing":{"type":"object","description":"A listing.\\nWith a second line.","properties":{"key":{"type":"string","minLength":2,"maxLength":8,"description":"The key, with \'quotes\', \$dollars, and \\\\backslashes\\\\."},"code":{"type":"string","pattern":"^[A-Z]{2}-\\\\d+\$","examples":["AB-12"]},"rooms":{"type":"integer","minimum":1,"maximum":9},"floors":{"type":"integer","exclusiveMinimum":0,"exclusiveMaximum":4.5},"price":{"type":"number","minimum":0,"exclusiveMaximum":1000000.5},"active":{"type":"boolean"},"status":{"enum":["Active","Closed","Active",null]},"kind":{"const":"residential"},"tags":{"type":"array","items":{"type":"string"},"minItems":1,"maxItems":3,"uniqueItems":true},"notes":{"anyOf":[{"type":"string"},{"type":"null"}]},"nickname":{"type":["string","null"]},"streetNumber":{"anyOf":[{"anyOf":[{"type":"string"},{"type":"number"}]},{"type":"null"}]},"extra":{},"labels":{"type":"object","propertyNames":{"type":"string"},"additionalProperties":{"type":"integer"}},"meta":{"type":"object","additionalProperties":true},"address":{"type":"object","properties":{"city":{"type":"string"}},"required":["city"],"additionalProperties":true},"photo":{"\$ref":"#/\$defs/Photo"},"cover":{"anyOf":[{"\$ref":"#/\$defs/Photo"},{"type":"null"}]},"photos":{"type":"array","items":{"\$ref":"#/\$defs/Photo"}}},"required":["key","rooms","active"],"additionalProperties":true},"Photo":{"type":"object","properties":{"url":{"type":"string"},"width":{"type":"integer"}},"required":["url"]}}}') as Object;
final Map<Uri, Object> _jsonSchemaDocuments = {
  Uri.parse('package:ack_generator_fixtures/mapping.schema.json'): _jsonSchemaDocument,
};
// dart format on

final listingSchema = ack.Ack.fromJsonSchema(
  {
    r'$ref':
        'package:ack_generator_fixtures/mapping.schema.json#/\$defs/Listing',
  },
  baseUri: Uri.parse(
    'package:ack_generator_fixtures/__ack_json_schema_generated__.json',
  ),
  documents: _jsonSchemaDocuments,
);

/// A validated Draft 2020-12 value model.
final class Listing {
  const Listing._(this.value);

  /// The parsed, immutable JSON value.
  final Object? value;

  /// The exact source-schema validator for this model.
  static ack.AckSchema<Object, Object> get schema => listingSchema;

  static Listing parse(Object? value) => safeParse(value).getOrThrow()!;

  static ack.SchemaResult<Listing> safeParse(Object? value) =>
      schema.safeParse(value).map((parsed) => Listing._(parsed));

  static Object? encode(Listing model) => safeEncode(model).getOrThrow();

  static ack.SchemaResult<Object> safeEncode(Listing model) =>
      schema.safeEncode(model.value);

  Object? toJson() => encode(this);

  static Map<String, Object?> toJsonSchema() => schema.toJsonSchema();
}

final photoSchema = ack.Ack.fromJsonSchema(
  {r'$ref': 'package:ack_generator_fixtures/mapping.schema.json#/\$defs/Photo'},
  baseUri: Uri.parse(
    'package:ack_generator_fixtures/__ack_json_schema_generated__.json',
  ),
  documents: _jsonSchemaDocuments,
);

/// A validated Draft 2020-12 value model.
final class Photo {
  const Photo._(this.value);

  /// The parsed, immutable JSON value.
  final Object? value;

  /// The exact source-schema validator for this model.
  static ack.AckSchema<Object, Object> get schema => photoSchema;

  static Photo parse(Object? value) => safeParse(value).getOrThrow()!;

  static ack.SchemaResult<Photo> safeParse(Object? value) =>
      schema.safeParse(value).map((parsed) => Photo._(parsed));

  static Object? encode(Photo model) => safeEncode(model).getOrThrow();

  static ack.SchemaResult<Object> safeEncode(Photo model) =>
      schema.safeEncode(model.value);

  Object? toJson() => encode(this);

  static Map<String, Object?> toJsonSchema() => schema.toJsonSchema();
}
