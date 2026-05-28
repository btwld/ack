import 'dart:io';

// The public firebase_ai library pulls in Flutter-only runtime libraries.
// The fixture generator is a `dart run` tool, so it imports the SDK schema
// definitions directly to snapshot their toJson() output.
// ignore: implementation_imports
import 'package:firebase_ai/src/schema.dart' as firebase_ai;

import 'firebase_ai_response_json_schema_cases.dart';

enum FirebaseAiNativeSchemaFixtureFamily {
  schema,
  jsonSchema;

  String get fixtureDirectoryName => switch (this) {
    schema => 'firebase_ai_native_schema',
    jsonSchema => 'firebase_ai_native_json_schema',
  };

  String get sourceClass => switch (this) {
    schema => 'Schema',
    jsonSchema => 'JSONSchema',
  };
}

enum FirebaseAiSchemaComparison {
  exact('exact'),
  equivalent('equivalent'),
  adapterTransformNeeded('adapter_transform_needed'),
  unsupportedByFirebaseSchema('unsupported_by_firebase_schema'),
  backendLimited('backend_limited');

  const FirebaseAiSchemaComparison(this.jsonValue);

  final String jsonValue;
}

enum FirebaseAiNativeSchemaStatus {
  generated('generated'),
  unsupported('unsupported');

  const FirebaseAiNativeSchemaStatus(this.jsonValue);

  final String jsonValue;
}

final class FirebaseAiNativeSchemaCase {
  const FirebaseAiNativeSchemaCase.generated({
    required this.id,
    required this.name,
    required this.source,
    required this.features,
    required this.comparisonEnum,
    required Map<String, Object?> Function() buildJsonSchema,
  }) : statusEnum = FirebaseAiNativeSchemaStatus.generated,
       unsupportedReason = null,
       _buildJsonSchema = buildJsonSchema;

  const FirebaseAiNativeSchemaCase.unsupported({
    required this.id,
    required this.name,
    required this.source,
    required this.features,
    required this.comparisonEnum,
    required this.unsupportedReason,
  }) : statusEnum = FirebaseAiNativeSchemaStatus.unsupported,
       _buildJsonSchema = null;

  final String id;
  final String name;
  final String source;
  final List<String> features;
  final FirebaseAiNativeSchemaStatus statusEnum;
  final FirebaseAiSchemaComparison comparisonEnum;
  final String? unsupportedReason;
  final Map<String, Object?> Function()? _buildJsonSchema;

  String get status => statusEnum.jsonValue;

  String get comparison => comparisonEnum.jsonValue;

  bool get isGenerated => statusEnum == FirebaseAiNativeSchemaStatus.generated;

  Map<String, Object?> buildJsonSchema() {
    final build = _buildJsonSchema;
    if (build == null) {
      throw StateError('Native Firebase schema case $id is unsupported.');
    }
    return build();
  }
}

List<FirebaseAiNativeSchemaCase> firebaseAiNativeSchemaCases(
  FirebaseAiNativeSchemaFixtureFamily family,
) {
  return [
    for (final schemaCase in firebaseAiResponseJsonSchemaCases())
      switch (family) {
        FirebaseAiNativeSchemaFixtureFamily.schema => _nativeSchemaCase(
          schemaCase,
        ),
        FirebaseAiNativeSchemaFixtureFamily.jsonSchema => _nativeJsonSchemaCase(
          schemaCase,
        ),
      },
  ];
}

String firebaseAiPackageVersion() {
  final lockFile = _findPubspecLock();
  final lines = lockFile.readAsLinesSync();
  for (var index = 0; index < lines.length; index += 1) {
    if (lines[index].trim() != 'firebase_ai:') continue;

    for (
      var versionIndex = index + 1;
      versionIndex < lines.length;
      versionIndex += 1
    ) {
      final line = lines[versionIndex];
      if (line.startsWith('  ') &&
          !line.startsWith('    ') &&
          line.trim().endsWith(':')) {
        break;
      }

      final match = RegExp(
        r'^\s+version:\s+"?([^"\s]+)"?\s*$',
      ).firstMatch(line);
      if (match != null) return match.group(1)!;
    }
  }

  throw StateError('Could not find firebase_ai version in ${lockFile.path}.');
}

FirebaseAiNativeSchemaCase _nativeSchemaCase(
  FirebaseAiResponseJsonSchemaCase schemaCase,
) {
  return switch (schemaCase.id) {
    'ack_schema_string_constraints' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.string(description: 'Code'),
    ),
    'ack_schema_string_literal' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.enumString(enumValues: ['ready']),
    ),
    'ack_schema_enum_values_default' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.enumString(enumValues: ['admin', 'member']),
    ),
    'ack_schema_integer_constraints' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.integer(minimum: 1, maximum: 10),
    ),
    'ack_schema_number_constraints' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.number(minimum: 0.5, maximum: 9.5),
    ),
    'ack_schema_nullable_boolean_default' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.boolean(nullable: true),
    ),
    'ack_schema_array_constraints' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.array(
        items: firebase_ai.Schema.string(format: 'uuid'),
        minItems: 1,
        maxItems: 3,
      ),
    ),
    'ack_schema_object_properties_requiredness' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.object(
        description: 'User payload',
        properties: {
          'name': firebase_ai.Schema.string(description: 'Full name'),
          'age': firebase_ai.Schema.integer(minimum: 0, maximum: 120),
          'role': firebase_ai.Schema.enumString(
            enumValues: ['admin', 'member'],
          ),
          'tags': firebase_ai.Schema.array(
            items: firebase_ai.Schema.string(),
            minItems: 1,
            maxItems: 5,
          ),
        },
        optionalProperties: ['age', 'tags'],
        propertyOrdering: ['name', 'age', 'role', 'tags'],
      ),
    ),
    'ack_schema_object_passthrough' => _unsupported(
      schemaCase,
      'Firebase Schema cannot represent Ack.any() or open additional properties.',
    ),
    'ack_schema_anyof_nullable_composition' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.equivalent,
      firebase_ai.Schema.anyOf(
        schemas: [
          firebase_ai.Schema.string(nullable: true),
          firebase_ai.Schema.integer(nullable: true),
        ],
      ),
    ),
    'ack_schema_generic_transform' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.string(),
    ),
    'ack_schema_any_json_compatible_branches' => _unsupported(
      schemaCase,
      'Firebase Schema has no unconstrained JSON value representation.',
    ),
    'ack_schema_date_transform_constraints' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.string(format: 'date'),
    ),
    'ack_schema_datetime_transform' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.string(format: 'date-time'),
    ),
    'ack_schema_uri_transform' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.string(format: 'uri'),
    ),
    'ack_schema_duration_transform_constraints' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.integer(minimum: 1000, maximum: 2000),
    ),
    'ack_schema_discriminated_union' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      _nativeSchemaDiscriminatedUnion(),
    ),
    'ack_schema_recursive_lazy_ref' => _unsupported(
      schemaCase,
      'Firebase Schema does not support reusable definitions or references.',
    ),
    'schema_model_string_common_options' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.string(
        title: 'Status',
        description: 'Current status',
        format: 'custom-format',
      ),
    ),
    'schema_model_integer_const_format' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.integer(format: 'int32'),
    ),
    'schema_model_number_const_format' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.number(format: 'double'),
    ),
    'schema_model_boolean_const' => _unsupported(
      schemaCase,
      'Firebase Schema cannot represent a boolean const value.',
    ),
    'schema_model_nullable_default_extensions' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.string(nullable: true),
    ),
    'schema_model_array_without_item_schema' => _unsupported(
      schemaCase,
      'Firebase Schema.array requires an item schema.',
    ),
    'schema_model_object_schema_additional_properties' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.object(
        properties: {'id': firebase_ai.Schema.string()},
        propertyOrdering: ['id'],
      ),
    ),
    'schema_model_null' => _unsupported(
      schemaCase,
      'Firebase Schema has no null-only schema type.',
    ),
    'schema_model_anyof_common_fields_explicit_null' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.anyOf(
        schemas: [
          firebase_ai.Schema.string(nullable: true),
          firebase_ai.Schema.integer(nullable: true),
        ],
      ),
    ),
    'schema_model_oneof_nullable_composition' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.Schema.anyOf(
        schemas: [
          firebase_ai.Schema.enumString(enumValues: ['ready'], nullable: true),
          firebase_ai.Schema.integer(minimum: 1, nullable: true),
        ],
      ),
    ),
    'schema_model_oneof_discriminator' => _generatedSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      _nativeSchemaDiscriminatorUnion(),
    ),
    'schema_model_allof' => _unsupported(
      schemaCase,
      'Firebase Schema has no allOf composition builder.',
    ),
    _ => _unsupported(
      schemaCase,
      'No Firebase Schema fixture mapping has been defined for ${schemaCase.id}.',
    ),
  };
}

FirebaseAiNativeSchemaCase _nativeJsonSchemaCase(
  FirebaseAiResponseJsonSchemaCase schemaCase,
) {
  return switch (schemaCase.id) {
    'ack_schema_string_constraints' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.string(description: 'Code'),
    ),
    'ack_schema_string_literal' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.enumString(enumValues: ['ready']),
    ),
    'ack_schema_enum_values_default' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.enumString(enumValues: ['admin', 'member']),
    ),
    'ack_schema_integer_constraints' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.integer(minimum: 1, maximum: 10),
    ),
    'ack_schema_number_constraints' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.number(minimum: 0.5, maximum: 9.5),
    ),
    'ack_schema_nullable_boolean_default' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.boolean(nullable: true),
    ),
    'ack_schema_array_constraints' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.array(
        items: firebase_ai.JSONSchema.string(format: 'uuid'),
        minItems: 1,
        maxItems: 3,
      ),
    ),
    'ack_schema_object_properties_requiredness' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.object(
        description: 'User payload',
        properties: {
          'name': firebase_ai.JSONSchema.string(description: 'Full name'),
          'age': firebase_ai.JSONSchema.integer(minimum: 0, maximum: 120),
          'role': firebase_ai.JSONSchema.enumString(
            enumValues: ['admin', 'member'],
          ),
          'tags': firebase_ai.JSONSchema.array(
            items: firebase_ai.JSONSchema.string(),
            minItems: 1,
            maxItems: 5,
          ),
        },
        optionalProperties: ['age', 'tags'],
      ),
    ),
    'ack_schema_object_passthrough' => _unsupported(
      schemaCase,
      'Firebase JSONSchema cannot represent Ack.any() or open additional properties.',
    ),
    'ack_schema_anyof_nullable_composition' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.equivalent,
      firebase_ai.JSONSchema.anyOf(
        schemas: [
          firebase_ai.JSONSchema.string(nullable: true),
          firebase_ai.JSONSchema.integer(nullable: true),
        ],
      ),
    ),
    'ack_schema_generic_transform' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.string(),
    ),
    'ack_schema_any_json_compatible_branches' => _unsupported(
      schemaCase,
      'Firebase JSONSchema has no unconstrained JSON value representation.',
    ),
    'ack_schema_date_transform_constraints' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.string(format: 'date'),
    ),
    'ack_schema_datetime_transform' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.string(format: 'date-time'),
    ),
    'ack_schema_uri_transform' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.string(format: 'uri'),
    ),
    'ack_schema_duration_transform_constraints' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.integer(minimum: 1000, maximum: 2000),
    ),
    'ack_schema_discriminated_union' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      _nativeJsonSchemaDiscriminatedUnion(),
    ),
    'ack_schema_recursive_lazy_ref' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.backendLimited,
      _nativeJsonSchemaRecursiveCategory(),
    ),
    'schema_model_string_common_options' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.string(
        title: 'Status',
        description: 'Current status',
        format: 'custom-format',
      ),
    ),
    'schema_model_integer_const_format' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.integer(),
    ),
    'schema_model_number_const_format' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.number(),
    ),
    'schema_model_boolean_const' => _unsupported(
      schemaCase,
      'Firebase JSONSchema cannot represent a boolean const value.',
    ),
    'schema_model_nullable_default_extensions' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.string(nullable: true),
    ),
    'schema_model_array_without_item_schema' => _unsupported(
      schemaCase,
      'Firebase JSONSchema.array requires an item schema.',
    ),
    'schema_model_object_schema_additional_properties' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.object(
        properties: {'id': firebase_ai.JSONSchema.string()},
      ),
    ),
    'schema_model_null' => _unsupported(
      schemaCase,
      'Firebase JSONSchema has no null-only schema type.',
    ),
    'schema_model_anyof_common_fields_explicit_null' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.anyOf(
        schemas: [
          firebase_ai.JSONSchema.string(nullable: true),
          firebase_ai.JSONSchema.integer(nullable: true),
        ],
      ),
    ),
    'schema_model_oneof_nullable_composition' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      firebase_ai.JSONSchema.anyOf(
        schemas: [
          firebase_ai.JSONSchema.enumString(
            enumValues: ['ready'],
            nullable: true,
          ),
          firebase_ai.JSONSchema.integer(minimum: 1, nullable: true),
        ],
      ),
    ),
    'schema_model_oneof_discriminator' => _generatedJsonSchema(
      schemaCase,
      FirebaseAiSchemaComparison.adapterTransformNeeded,
      _nativeJsonSchemaDiscriminatorUnion(),
    ),
    'schema_model_allof' => _unsupported(
      schemaCase,
      'Firebase JSONSchema has no allOf composition builder.',
    ),
    _ => _unsupported(
      schemaCase,
      'No Firebase JSONSchema fixture mapping has been defined for ${schemaCase.id}.',
    ),
  };
}

FirebaseAiNativeSchemaCase _generatedSchema(
  FirebaseAiResponseJsonSchemaCase schemaCase,
  FirebaseAiSchemaComparison comparison,
  firebase_ai.Schema schema,
) {
  return FirebaseAiNativeSchemaCase.generated(
    id: schemaCase.id,
    name: schemaCase.name,
    source: schemaCase.source,
    features: schemaCase.features,
    comparisonEnum: comparison,
    buildJsonSchema: () => _jsonObject(schema.toJson()),
  );
}

FirebaseAiNativeSchemaCase _generatedJsonSchema(
  FirebaseAiResponseJsonSchemaCase schemaCase,
  FirebaseAiSchemaComparison comparison,
  firebase_ai.JSONSchema schema,
) {
  return FirebaseAiNativeSchemaCase.generated(
    id: schemaCase.id,
    name: schemaCase.name,
    source: schemaCase.source,
    features: schemaCase.features,
    comparisonEnum: comparison,
    buildJsonSchema: () => _jsonObject(schema.toJson()),
  );
}

FirebaseAiNativeSchemaCase _unsupported(
  FirebaseAiResponseJsonSchemaCase schemaCase,
  String reason,
) {
  return FirebaseAiNativeSchemaCase.unsupported(
    id: schemaCase.id,
    name: schemaCase.name,
    source: schemaCase.source,
    features: schemaCase.features,
    comparisonEnum: FirebaseAiSchemaComparison.unsupportedByFirebaseSchema,
    unsupportedReason: reason,
  );
}

firebase_ai.Schema _nativeSchemaDiscriminatedUnion() {
  return firebase_ai.Schema.anyOf(
    schemas: [
      firebase_ai.Schema.object(
        properties: {
          'type': firebase_ai.Schema.enumString(enumValues: ['circle']),
          'radius': firebase_ai.Schema.number(minimum: 0),
        },
      ),
      firebase_ai.Schema.object(
        properties: {
          'type': firebase_ai.Schema.enumString(enumValues: ['square']),
          'side': firebase_ai.Schema.number(minimum: 0),
        },
      ),
    ],
  );
}

firebase_ai.Schema _nativeSchemaDiscriminatorUnion() {
  return firebase_ai.Schema.anyOf(
    schemas: [
      firebase_ai.Schema.object(
        properties: {
          'type': firebase_ai.Schema.enumString(enumValues: ['email']),
          'address': firebase_ai.Schema.string(format: 'email'),
        },
      ),
      firebase_ai.Schema.object(
        properties: {
          'type': firebase_ai.Schema.enumString(enumValues: ['sms']),
          'number': firebase_ai.Schema.string(),
        },
      ),
    ],
  );
}

firebase_ai.JSONSchema _nativeJsonSchemaDiscriminatedUnion() {
  return firebase_ai.JSONSchema.anyOf(
    schemas: [
      firebase_ai.JSONSchema.object(
        properties: {
          'type': firebase_ai.JSONSchema.enumString(enumValues: ['circle']),
          'radius': firebase_ai.JSONSchema.number(minimum: 0),
        },
      ),
      firebase_ai.JSONSchema.object(
        properties: {
          'type': firebase_ai.JSONSchema.enumString(enumValues: ['square']),
          'side': firebase_ai.JSONSchema.number(minimum: 0),
        },
      ),
    ],
  );
}

firebase_ai.JSONSchema _nativeJsonSchemaDiscriminatorUnion() {
  return firebase_ai.JSONSchema.anyOf(
    schemas: [
      firebase_ai.JSONSchema.object(
        properties: {
          'type': firebase_ai.JSONSchema.enumString(enumValues: ['email']),
          'address': firebase_ai.JSONSchema.string(format: 'email'),
        },
      ),
      firebase_ai.JSONSchema.object(
        properties: {
          'type': firebase_ai.JSONSchema.enumString(enumValues: ['sms']),
          'number': firebase_ai.JSONSchema.string(),
        },
      ),
    ],
  );
}

firebase_ai.JSONSchema _nativeJsonSchemaRecursiveCategory() {
  firebase_ai.JSONSchema categoryDefinition() => firebase_ai.JSONSchema.object(
    properties: {
      'name': firebase_ai.JSONSchema.string(),
      'children': firebase_ai.JSONSchema.array(
        items: firebase_ai.JSONSchema.ref(r'#/$defs/Category'),
      ),
      'featured': firebase_ai.JSONSchema.ref(r'#/$defs/Category'),
    },
  );

  return firebase_ai.JSONSchema.object(
    properties: {
      'name': firebase_ai.JSONSchema.string(),
      'children': firebase_ai.JSONSchema.array(
        items: firebase_ai.JSONSchema.ref(r'#/$defs/Category'),
      ),
      'featured': firebase_ai.JSONSchema.ref(r'#/$defs/Category'),
    },
    defs: {'Category': categoryDefinition()},
  );
}

Map<String, Object?> _jsonObject(Map<String, Object> value) {
  return value.cast<String, Object?>();
}

File _findPubspecLock() {
  var current = Directory.current.absolute;
  while (true) {
    final lock = File('${current.path}/pubspec.lock');
    if (lock.existsSync()) return lock;

    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError(
        'Could not find pubspec.lock from ${Directory.current}.',
      );
    }
    current = parent;
  }
}
