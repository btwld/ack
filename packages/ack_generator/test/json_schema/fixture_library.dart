import 'dart:convert';
import 'dart:io';

import 'package:ack_generator/src/json_schema/json_schema_library.dart';

/// Directory of the JSON Schema fixtures and their golden schema libraries.
const fixtureDirectory = 'test/json_schema/fixtures';

/// The fixture `<name>.schema.json` as a decoded document.
Map<String, Object?> fixtureDocument(String name) =>
    jsonDecode(File('$fixtureDirectory/$name.schema.json').readAsStringSync())
        as Map<String, Object?>;

/// The URI the fixture `<name>.schema.json` is generated under.
Uri fixtureUri(String name) =>
    Uri.parse('package:ack_generator_fixtures/$name.schema.json');

/// Generates the parts-free schema library for the fixture [name].
AckJsonSchemaLibrary generateFixture(
  String name, {
  AckUnknownPropertiesMode unknownProperties = AckUnknownPropertiesMode.schema,
}) => generateAckSchemaLibrary(
  document: fixtureDocument(name),
  documentUri: fixtureUri(name),
  partStem: '$name.schema',
  includeParts: false,
  options: AckJsonSchemaLibraryOptions(unknownProperties: unknownProperties),
);
