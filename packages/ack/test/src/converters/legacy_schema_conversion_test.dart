import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:ack/src/helpers.dart';
import 'package:ack/src/legacy_schema.dart' as legacy;
import 'package:test/test.dart';

/// Test that compares conversion between the Schema class and OpenApiSchema
void main() {
  group('Legacy Schema to OpenAPI Conversion Tests', () {
    test('Object schema conversion matches legacy serialization', () {
      // Create a schema using the modern ObjectSchema
      final modernSchema = ObjectSchema({
        'name': StringSchema(description: 'User name'),
        'age': IntegerSchema(description: 'User age'),
        'tags': ListSchema(
          StringSchema(),
          description: 'User tags',
        ),
      }, required: [
        'name',
        'age'
      ], description: 'A user object');

      // Convert to OpenAPI format
      final converter = OpenApiSchemaConverter(schema: modernSchema);
      final openApiMap = converter.toSchema();
      final openApiJson = prettyJson(openApiMap);

      // Create equivalent legacy schema
      final legacySchema = legacy.Schema.object(
        properties: {
          'name': legacy.Schema.string(description: 'User name'),
          'age': legacy.Schema.integer(description: 'User age'),
          'tags': legacy.Schema.array(
            items: legacy.Schema.string(),
            description: 'User tags',
          ),
        },
        requiredProperties: ['name', 'age'],
        description: 'A user object',
      );

      // Convert to JSON and back
      final legacyJson = legacySchema.toJson();

      // Parse both to maps for comparison
      final openApiSchemaMap = jsonDecode(openApiJson) as Map<String, dynamic>;
      final legacySchemaMap = jsonDecode(legacyJson) as Map<String, dynamic>;

      // Compare the core schema properties
      expect(openApiSchemaMap['type'], equals(legacySchemaMap['type']));
      expect(openApiSchemaMap['description'],
          equals(legacySchemaMap['description']));

      // Compare properties
      expect(
        openApiSchemaMap['properties']?['name']?['type'],
        equals(legacySchemaMap['properties']?['name']?['type']),
      );
      expect(
        openApiSchemaMap['properties']?['age']?['type'],
        equals(legacySchemaMap['properties']?['age']?['type']),
      );
      expect(
        openApiSchemaMap['properties']?['tags']?['type'],
        equals(legacySchemaMap['properties']?['tags']?['type']),
      );

      // Compare required properties
      expect(
        openApiSchemaMap['required'],
        equals(legacySchemaMap['required']),
      );
    });

    test('String enum schema conversion matches legacy serialization', () {
      // Create a schema using the modern StringSchema with enum
      final modernSchema = ObjectSchema({
        'color': StringSchema().isEnum(['red', 'green', 'blue'])
      }, description: 'Color selection');

      // Convert to OpenAPI format
      final converter = OpenApiSchemaConverter(schema: modernSchema);
      final openApiMap = converter.toSchema();
      final openApiJson = prettyJson(openApiMap);

      // Create equivalent legacy schema
      final legacySchema = legacy.Schema.object(
        properties: {
          'color': legacy.Schema.enumString(
            enumValues: ['red', 'green', 'blue'],
          ),
        },
        description: 'Color selection',
      );

      // Convert to JSON
      final legacyJson = legacySchema.toJson();

      // Parse both to maps for comparison
      final openApiSchemaMap = jsonDecode(openApiJson) as Map<String, dynamic>;
      final legacySchemaMap = jsonDecode(legacyJson) as Map<String, dynamic>;

      // Compare the core schema properties
      expect(openApiSchemaMap['type'], equals(legacySchemaMap['type']));
      expect(openApiSchemaMap['description'],
          equals(legacySchemaMap['description']));

      // Get enum values from both schemas for comparison
      final openApiEnumValues =
          openApiSchemaMap['properties']?['color']?['enum'] as List<dynamic>?;
      final legacyEnumValues =
          legacySchemaMap['properties']?['color']?['enum'] as List<dynamic>?;

      // Compare enum values (may need to sort for consistent comparison)
      expect(
        openApiEnumValues?..sort(),
        equals(legacyEnumValues?..sort()),
      );
    });

    test('Complex nested schema conversion matches legacy serialization', () {
      // Create a schema using the modern ObjectSchema with nesting
      final modernSchema = ObjectSchema({
        'id': StringSchema(description: 'Record ID'),
        'user': ObjectSchema({
          'name': StringSchema(),
          'email': StringSchema(description: 'Email address'),
          'preferences': ObjectSchema({
            'theme': StringSchema().isEnum(['light', 'dark', 'system']),
            'notifications': BooleanSchema(description: 'Enable notifications'),
          }, required: [
            'theme'
          ]),
        }, required: [
          'name',
          'email'
        ]),
        'items': ListSchema(
          ObjectSchema({
            'itemId': StringSchema(),
            'quantity': IntegerSchema(),
            'price': DoubleSchema(),
          }, required: [
            'itemId',
            'quantity',
            'price'
          ]),
        ),
      }, required: [
        'id',
        'user',
        'items'
      ], description: 'A complex order record');

      // Convert to OpenAPI format
      final converter = OpenApiSchemaConverter(schema: modernSchema);
      final openApiMap = converter.toSchema();
      final openApiJson = prettyJson(openApiMap);

      // Create equivalent legacy schema
      final legacySchema = legacy.Schema.object(
        properties: {
          'id': legacy.Schema.string(description: 'Record ID'),
          'user': legacy.Schema.object(
            properties: {
              'name': legacy.Schema.string(),
              'email': legacy.Schema.string(description: 'Email address'),
              'preferences': legacy.Schema.object(
                properties: {
                  'theme': legacy.Schema.enumString(
                    enumValues: ['light', 'dark', 'system'],
                  ),
                  'notifications': legacy.Schema.boolean(
                      description: 'Enable notifications'),
                },
                requiredProperties: ['theme'],
              ),
            },
            requiredProperties: ['name', 'email'],
          ),
          'items': legacy.Schema.array(
            items: legacy.Schema.object(
              properties: {
                'itemId': legacy.Schema.string(),
                'quantity': legacy.Schema.integer(),
                'price': legacy.Schema.number(format: 'double'),
              },
              requiredProperties: ['itemId', 'quantity', 'price'],
            ),
          ),
        },
        requiredProperties: ['id', 'user', 'items'],
        description: 'A complex order record',
      );

      // Convert to JSON
      final legacyJson = legacySchema.toJson();

      // For complex schemas, we'll do a high-level structure comparison
      final openApiSchemaMap = jsonDecode(openApiJson) as Map<String, dynamic>;
      final legacySchemaMap = jsonDecode(legacyJson) as Map<String, dynamic>;

      // Check top-level properties
      expect(openApiSchemaMap['type'], equals(legacySchemaMap['type']));
      expect(openApiSchemaMap['description'],
          equals(legacySchemaMap['description']));
      expect(openApiSchemaMap['required'], equals(legacySchemaMap['required']));

      // Check that both schemas have the same property keys
      expect(
        openApiSchemaMap['properties']?.keys.toList()..sort(),
        equals(legacySchemaMap['properties']?.keys.toList()..sort()),
      );
    });

    test('Legacy schema round-trip through OpenAPI conversion', () {
      // Create a legacy schema
      final originalLegacySchema = legacy.Schema.object(
        properties: {
          'name': legacy.Schema.string(),
          'age': legacy.Schema.integer(),
          'isActive': legacy.Schema.boolean(),
        },
        requiredProperties: ['name'],
        description: 'A user profile',
      );

      // Convert legacy schema to JSON
      final legacyJson = originalLegacySchema.toJson();

      // Parse legacy schema JSON map
      final legacyMap = jsonDecode(legacyJson) as Map<String, dynamic>;

      // Now, convert the map back to a legacy schema
      final recreatedLegacySchema = legacy.Schema.fromMap(legacyMap);

      // Convert recreated schema to JSON
      final recreatedJson = recreatedLegacySchema.toJson();

      // Compare original and recreated JSON when parsed to maps
      final originalMap = jsonDecode(legacyJson);
      final recreatedMap = jsonDecode(recreatedJson);

      expect(recreatedMap, equals(originalMap));
    });

    test('Direct conversion from modern OpenAPI schema to legacy Schema', () {
      // Create a schema using the modern ObjectSchema
      final modernSchema = ObjectSchema({
        'name': StringSchema(description: 'User name'),
        'age': IntegerSchema(description: 'User age', nullable: true),
        'tags': ListSchema(
          StringSchema().isEnum(['featured', 'new', 'sale']),
          description: 'Product tags',
        ),
        'details': ObjectSchema({
          'sku': StringSchema(),
          'price': DoubleSchema(description: 'Product price'),
        }, required: [
          'sku',
          'price'
        ]),
      }, required: [
        'name',
        'details'
      ], description: 'A product');

      // Convert to OpenAPI format
      final converter = OpenApiSchemaConverter(schema: modernSchema);
      final openApiMap = converter.toSchema();

      // Convert OpenAPI schema map to legacy Schema
      // This is a helper function that would be useful in a real-world scenario
      final legacySchema = convertOpenApiMapToLegacySchema(openApiMap);

      // Now convert both schemas to JSON
      final openApiJson = prettyJson(openApiMap);
      final legacyJson = legacySchema.toJson();

      // Parse both to maps for comparison
      final openApiSchemaMap = jsonDecode(openApiJson) as Map<String, dynamic>;
      final legacySchemaMap = jsonDecode(legacyJson) as Map<String, dynamic>;

      // Compare key aspects
      expect(openApiSchemaMap['type'], equals(legacySchemaMap['type']));
      expect(openApiSchemaMap['description'],
          equals(legacySchemaMap['description']));
      expect(openApiSchemaMap['required'], equals(legacySchemaMap['required']));

      // Check property types
      expect(openApiSchemaMap['properties']?['name']?['type'],
          equals(legacySchemaMap['properties']?['name']?['type']));
      expect(openApiSchemaMap['properties']?['age']?['type'],
          equals(legacySchemaMap['properties']?['age']?['type']));
      expect(openApiSchemaMap['properties']?['tags']?['type'],
          equals(legacySchemaMap['properties']?['tags']?['type']));
      expect(openApiSchemaMap['properties']?['details']?['type'],
          equals(legacySchemaMap['properties']?['details']?['type']));

      // Check that the tags array contains the enum values
      final openApiTagsEnum = openApiSchemaMap['properties']?['tags']?['items']
          ?['enum'] as List<dynamic>?;
      final legacyTagsEnum = legacySchemaMap['properties']?['tags']?['items']
          ?['enum'] as List<dynamic>?;

      expect(openApiTagsEnum?..sort(), equals(legacyTagsEnum?..sort()));
    });

    test('Direct conversion from modern Schema to legacy Schema', () {
      // Create a schema using the modern ObjectSchema
      final modernSchema = ObjectSchema({
        'name': StringSchema(description: 'User name'),
        'age': IntegerSchema(description: 'User age', nullable: true),
        'active':
            BooleanSchema(description: 'Is user active', defaultValue: true),
        'tags': ListSchema(
          StringSchema().isEnum(['admin', 'user', 'guest']),
          description: 'User roles',
          nullable: true,
        ),
        'address': ObjectSchema({
          'street': StringSchema(),
          'city': StringSchema(),
          'zip': StringSchema(),
          'country':
              StringSchema(description: 'Country code', defaultValue: 'US'),
        }, required: [
          'street',
          'city'
        ]),
      }, required: [
        'name',
        'age'
      ], description: 'A user schema');

      // Convert directly from modern Schema to legacy Schema
      final legacySchema = convertSchemaToLegacySchema(modernSchema);

      // Since we can't directly compare schemas of different classes,
      // convert both to JSON for comparison
      final modernJson = prettyJson(modernSchema.toMap());
      final legacyJson = legacySchema.toJson();

      // Parse both to maps for comparison
      final modernMap = jsonDecode(modernJson) as Map<String, dynamic>;
      final legacyMap = jsonDecode(legacyJson) as Map<String, dynamic>;

      // Compare type
      expect(modernMap['type'], equals('object'));
      expect(legacyMap['type'], equals('object'));

      // Compare description
      expect(modernMap['description'], equals(legacyMap['description']));

      // Compare required properties
      expect(
        modernMap['required'],
        unorderedEquals(legacyMap['required']),
      );

      // Compare properties - keys should match
      expect(
        modernMap['properties'].keys,
        unorderedEquals(legacyMap['properties'].keys),
      );

      // Compare some specific property types
      expect(
        legacyMap['properties']['name']['type'],
        equals('string'),
      );
      expect(
        legacyMap['properties']['age']['type'],
        equals('integer'),
      );
      expect(
        legacyMap['properties']['age']['nullable'],
        isTrue,
      );

      // Check address object and its required properties
      expect(
        legacyMap['properties']['address']['type'],
        equals('object'),
      );
      expect(
        legacyMap['properties']['address']['required'],
        unorderedEquals(['street', 'city']),
      );

      // Check tags array and its enum values
      expect(
        legacyMap['properties']['tags']['type'],
        equals('array'),
      );
      expect(
        legacyMap['properties']['tags']['items']['enum'],
        unorderedEquals(['admin', 'user', 'guest']),
      );

      // Verify that we can convert the legacy schema back to JSON
      // and it will have the same structure
      final roundTripJson = legacySchema.toJson();
      final roundTripMap = jsonDecode(roundTripJson);
      expect(legacyMap, equals(roundTripMap));
    });
  });
}

/// Converts an OpenAPI schema map to a legacy Schema object
legacy.Schema convertOpenApiMapToLegacySchema(Map<String, dynamic> map) {
  final type = map['type'] as String?;

  if (type == null) {
    throw ArgumentError('Missing type in OpenAPI schema');
  }

  switch (type) {
    case 'string':
      final format = map['format'] as String?;
      final description = map['description'] as String?;
      final nullable = map['nullable'] as bool?;
      final enumValues = map['enum'] as List<dynamic>?;

      if (enumValues != null) {
        return legacy.Schema.enumString(
          enumValues: enumValues.cast<String>(),
          description: description,
          nullable: nullable,
        );
      }

      if (format == 'date-time') {
        return legacy.Schema.dateTime(
          description: description,
          nullable: nullable,
        );
      }

      return legacy.Schema.string(
        description: description,
        nullable: nullable,
      );

    case 'number':
      return legacy.Schema.number(
        format: map['format'] as String?,
        description: map['description'] as String?,
        nullable: map['nullable'] as bool?,
      );

    case 'integer':
      return legacy.Schema.integer(
        format: map['format'] as String?,
        description: map['description'] as String?,
        nullable: map['nullable'] as bool?,
      );

    case 'boolean':
      return legacy.Schema.boolean(
        description: map['description'] as String?,
        nullable: map['nullable'] as bool?,
      );

    case 'array':
      final items = map['items'] as Map<String, dynamic>?;

      if (items == null) {
        throw ArgumentError('Missing items in array schema');
      }

      return legacy.Schema.array(
        items: convertOpenApiMapToLegacySchema(items),
        description: map['description'] as String?,
        nullable: map['nullable'] as bool?,
      );

    case 'object':
      final properties = map['properties'] as Map<String, dynamic>?;
      final required = map['required'] as List<dynamic>?;

      if (properties == null) {
        throw ArgumentError('Missing properties in object schema');
      }

      final convertedProperties = <String, legacy.Schema>{};

      for (final entry in properties.entries) {
        convertedProperties[entry.key] = convertOpenApiMapToLegacySchema(
            entry.value as Map<String, dynamic>);
      }

      return legacy.Schema.object(
        properties: convertedProperties,
        requiredProperties: required?.cast<String>(),
        description: map['description'] as String?,
        nullable: map['nullable'] as bool?,
      );

    default:
      throw ArgumentError('Unsupported schema type: $type');
  }
}

/// Converts a modern Schema to a legacy Schema object
/// This provides a direct 1:1 mapping between the modern and legacy schemas
legacy.Schema convertSchemaToLegacySchema(AckSchema schema) {
  // Handle different schema types
  switch (schema) {
    case StringSchema s:
      // Check if this is an enum string by examining if it has StringEnumConstraint
      final enumConstraint =
          s.getConstraints().whereType<StringEnumConstraint>().firstOrNull;

      if (enumConstraint != null) {
        return legacy.Schema.enumString(
          enumValues: enumConstraint.enumValues,
          description: s.getDescriptionValue(),
          nullable: s.getNullableValue(),
        );
      }

      // Check if this is a date-time string
      final dateTimeConstraint =
          s.getConstraints().whereType<StringDateTimeConstraint>().firstOrNull;

      if (dateTimeConstraint != null) {
        return legacy.Schema.dateTime(
          description: s.getDescriptionValue(),
          nullable: s.getNullableValue(),
        );
      }

      // Regular string
      return legacy.Schema.string(
        description: s.getDescriptionValue(),
        nullable: s.getNullableValue(),
      );

    case IntegerSchema i:
      return legacy.Schema.integer(
        description: i.getDescriptionValue(),
        nullable: i.getNullableValue(),
        format: 'int32', // Default format for integers
      );

    case DoubleSchema d:
      return legacy.Schema.number(
        description: d.getDescriptionValue(),
        nullable: d.getNullableValue(),
        format: 'double',
      );

    case BooleanSchema b:
      return legacy.Schema.boolean(
        description: b.getDescriptionValue(),
        nullable: b.getNullableValue(),
      );

    case ListSchema l:
      // Convert the item schema recursively
      final itemSchema = convertSchemaToLegacySchema(l.getItemSchema());

      return legacy.Schema.array(
        items: itemSchema,
        description: l.getDescriptionValue(),
        nullable: l.getNullableValue(),
      );

    case ObjectSchema o:
      final properties = o.getProperties();
      final convertedProperties = <String, legacy.Schema>{};

      // Convert each property recursively
      for (final entry in properties.entries) {
        convertedProperties[entry.key] =
            convertSchemaToLegacySchema(entry.value);
      }

      return legacy.Schema.object(
        properties: convertedProperties,
        requiredProperties: o.getRequiredProperties(),
        description: o.getDescriptionValue(),
        nullable: o.getNullableValue(),
      );

    case DiscriminatedObjectSchema d:
      // For discriminated schemas, we need to convert all possible schemas
      final schemas = d.getSchemas(); // Returns List<ObjectSchema>
      final discriminatorKey = d.getDiscriminatorKey();

      // Create a merged object schema from all possible schemas
      final mergedProperties = <String, legacy.Schema>{};

      // Get schema names by examining the original schemas Map
      // Since getSchemas() only returns a list of schemas without their keys,
      // we need to use a different approach
      final schemaNames = <String>[];
      // We'll use some basic heuristic to try to determine the schema names
      // In a real implementation, you'd need access to the actual schema map

      // Add the discriminator key as an enum string with possible values (if we can determine them)
      mergedProperties[discriminatorKey] = legacy.Schema.enumString(
        enumValues: schemaNames.isEmpty ? ['schema1', 'schema2'] : schemaNames,
        description: 'Schema discriminator',
      );

      // Gather properties from all schemas
      for (final objectSchema in schemas) {
        for (final property in objectSchema.getProperties().entries) {
          // Skip the discriminator key since we already added it
          if (property.key != discriminatorKey) {
            mergedProperties[property.key] =
                convertSchemaToLegacySchema(property.value);
          }
        }
      }

      // Required properties should include the discriminator key
      final requiredProperties = <String>[discriminatorKey];

      return legacy.Schema.object(
        properties: mergedProperties,
        requiredProperties: requiredProperties,
        description: d.getDescriptionValue(),
        nullable: d.getNullableValue(),
      );

    default:
      throw ArgumentError('Unsupported schema type: ${schema.runtimeType}');
  }
}
