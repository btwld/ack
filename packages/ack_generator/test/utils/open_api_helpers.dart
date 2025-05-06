import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:ack/src/helpers.dart';

/// Create a combined OpenAPI specification for multiple schemas
Map<String, Object?> createCombinedApiSpec(
  List<Map<String, Object>> schemaDefinitions,
) {
  final components = <String, Map<String, Object?>>{};
  final paths = <String, Map<String, Object?>>{};

  for (final schemaDef in schemaDefinitions) {
    final schemaName = schemaDef['name'] as String;
    final schema = schemaDef['schema'] as ObjectSchema;

    // Convert to OpenAPI spec
    final converter = JsonSchemaConverter(schema: schema);
    final openApiSpec = converter.toSchema();

    // Add schema to components
    components[schemaName] = openApiSpec;

    // Add example path for this schema
    final path = '/${schemaName.toLowerCase()}s';
    paths[path] = {
      'get': {
        'summary': 'Get all ${schemaName}s',
        'responses': {
          '200': {
            'description': 'Successful response',
            'content': {
              'application/json': {
                'schema': {
                  'type': 'array',
                  'items': {
                    '\$ref': '#/components/schemas/$schemaName',
                  },
                },
              },
            },
          },
        },
      },
    };
  }

  return {
    'openapi': '3.0.0',
    'info': {
      'title': 'Generated API',
      'version': '1.0.0',
      'description': 'API generated from Ack schemas',
    },
    'paths': paths,
    'components': {
      'schemas': components,
    },
  };
}

/// Save an OpenAPI specification to a file
Future<void> saveOpenApiSpec(
  String schemaName,
  ObjectSchema schema,
  String directoryPath, {
  String? fileName,
}) async {
  final converter = JsonSchemaConverter(schema: schema);
  final spec = converter.toSchema();
  final jsonContent = prettyJson(spec);

  // Create the directory if it doesn't exist
  final directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }

  // Create the file path
  final outputFileName = fileName ?? '${schemaName.toLowerCase()}_schema.json';
  final filePath = '$directoryPath/$outputFileName';

  // Write the file
  await File(filePath).writeAsString(jsonContent);
  return;
}

/// Compare an OpenAPI spec with a golden file
bool compareWithGoldenFile(
  Map<String, Object?> actualSpec,
  String goldenFilePath, {
  bool updateGolden = false,
}) {
  final actualJson = prettyJson(actualSpec);
  final goldenFile = File(goldenFilePath);

  // If we're updating the golden file or it doesn't exist, write the current output
  if (updateGolden || !goldenFile.existsSync()) {
    goldenFile.parent.createSync(recursive: true);
    goldenFile.writeAsStringSync(actualJson);
    return true;
  }

  // Otherwise, compare with the golden file
  final expectedJson = goldenFile.readAsStringSync();

  // Normalize the JSON by parsing and stringifying again to avoid format differences
  final normalizedActual = prettyJson(json.decode(actualJson));
  final normalizedExpected = prettyJson(json.decode(expectedJson));

  return normalizedActual == normalizedExpected;
}
