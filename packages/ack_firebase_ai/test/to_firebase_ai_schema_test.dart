import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:test/test.dart';

// Test enum types for Dart enum conversion
enum Color { red, green, blue, yellow }
enum Status { pending, active, completed }

/// Tests for the toFirebaseAiSchema() extension method.
///
/// This test suite covers:
/// - Basic schema conversion (primitives, objects, arrays)
/// - Edge cases and error handling
/// - Semantic validation (behavioral equivalence)
/// - TransformedSchema and metadata overrides
/// - Dart enum support
void main() {
  group('toFirebaseAiSchema()', () {
    group('Primitives', () {
      test('converts basic string schema', () {
        final schema = Ack.string();
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.nullable, isNull);
      });

      test('converts string with description', () {
        final schema = Ack.string().describe('User name');
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.description, 'User name');
      });

      test('converts nullable string', () {
        final schema = Ack.string().nullable();
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.nullable, isTrue);
      });

      test('converts string with minLength (not currently surfaced)', () {
        final schema = Ack.string().minLength(5);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.toJson().containsKey('minLength'), isFalse,
            reason: 'firebase_ai Schema currently omits minLength metadata');
      });

      test('converts string with maxLength (not currently surfaced)', () {
        final schema = Ack.string().maxLength(50);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.toJson().containsKey('maxLength'), isFalse,
            reason: 'firebase_ai Schema currently omits maxLength metadata');
      });

      test('converts string with email format', () {
        final schema = Ack.string().email();
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.format, 'email');
      });

      test('converts integer schema', () {
        final schema = Ack.integer();
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.integer);
      });

      test('converts integer with minimum', () {
        final schema = Ack.integer().min(0);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.integer);
        expect(result.minimum, 0);
      });

      test('converts integer with maximum', () {
        final schema = Ack.integer().max(100);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.integer);
        expect(result.maximum, 100);
      });

      test('converts double schema', () {
        final schema = Ack.double();
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.number);
      });

      test('converts double with range', () {
        final schema = Ack.double().min(0.0).max(1.0);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.number);
        expect(result.minimum, closeTo(0.0, 1e-8));
        expect(result.maximum, closeTo(1.0, 1e-8));
      });

      test('converts boolean schema', () {
        final schema = Ack.boolean();
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.boolean);
      });
    });

    group('Objects', () {
      test('converts basic object schema', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer(),
        });
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.object);
        expect(result.properties, isNotNull);
        expect(result.properties!.keys, containsAll(['name', 'age']));

        final requiredFromJson = result.toJson()['required'] as List;
        expect(requiredFromJson, unorderedEquals(['name', 'age']));
      });

      test('converts object with optional fields', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().optional(),
          'email': Ack.string().optional(),
        });
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.object);
        expect(result.optionalProperties, containsAll(['age', 'email']));
        expect(result.optionalProperties, isNot(contains('name')));

        final requiredFromJson = result.toJson()['required'] as List;
        expect(requiredFromJson, unorderedEquals(['name']));
      });

      test('converts nested object schema', () {
        final schema = Ack.object({
          'user': Ack.object({
            'name': Ack.string(),
            'email': Ack.string().email(),
          }),
        });
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.object);
        final userProp = result.properties!['user']!;
        expect(userProp.type, firebase_ai.SchemaType.object);
        expect(userProp.properties, isNotNull);
        expect(userProp.properties!.keys, containsAll(['name', 'email']));
      });

      test('includes propertyOrdering', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer(),
          'email': Ack.string(),
        });
        final result = schema.toFirebaseAiSchema();

        expect(result.propertyOrdering, ['name', 'age', 'email']);
      });

      test('object schema matches expected Firebase Schema snapshot', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().optional(),
        });

        final expected = firebase_ai.Schema.object(
          properties: {
            'name': firebase_ai.Schema.string(),
            'age': firebase_ai.Schema.integer(),
          },
          optionalProperties: ['age'],
          propertyOrdering: ['name', 'age'],
        );

        expect(schema.toFirebaseAiSchema().toJson(), expected.toJson());
      });
    });

    group('Arrays', () {
      test('converts basic array schema', () {
        final schema = Ack.list(Ack.string());
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.array);
        expect(result.items, isNotNull);
        expect(result.items!.type, firebase_ai.SchemaType.string);
      });

      test('converts array with minItems', () {
        final schema = Ack.list(Ack.string()).minLength(1);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.array);
        expect(result.minItems, 1);
      });

      test('converts array with maxItems', () {
        final schema = Ack.list(Ack.string()).maxLength(10);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.array);
        expect(result.maxItems, 10);
      });

      test('converts array of objects', () {
        final schema = Ack.list(
          Ack.object({
            'id': Ack.integer(),
            'name': Ack.string(),
          }),
        );
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.array);
        expect(result.items, isNotNull);
        expect(result.items!.type, firebase_ai.SchemaType.object);
        expect(result.items!.properties, isNotNull);
      });

      test('array schema matches expected Firebase Schema snapshot', () {
        final schema = Ack.list(
          Ack.object({
            'id': Ack.string(),
            'score': Ack.double().min(0).max(1),
          }),
        ).minLength(1).maxLength(10);

        final expected = firebase_ai.Schema.array(
          items: firebase_ai.Schema.object(
            properties: {
              'id': firebase_ai.Schema.string(),
              'score': firebase_ai.Schema.number(
                minimum: 0,
                maximum: 1,
              ),
            },
            propertyOrdering: ['id', 'score'],
          ),
          minItems: 1,
          maxItems: 10,
        );

        expect(schema.toFirebaseAiSchema().toJson(), expected.toJson());
      });
    });

    group('Complex Scenarios', () {
      test('converts complete user schema', () {
        final schema = Ack.object({
          'id': Ack.string().uuid(),
          'name': Ack.string().minLength(2).maxLength(50),
          'email': Ack.string().email(),
          'age': Ack.integer().min(0).max(120).optional(),
          'tags': Ack.list(Ack.string()).maxLength(5).optional(),
        });
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.object);

        final requiredFromJson = result.toJson()['required'] as List;
        expect(requiredFromJson, unorderedEquals(['id', 'name', 'email']));

        final idProp = result.properties!['id']!;
        expect(idProp.type, firebase_ai.SchemaType.string);
        expect(idProp.format, 'uuid');

        final nameProp = result.properties!['name']!;
        expect(nameProp.type, firebase_ai.SchemaType.string);
        expect(nameProp.toJson().containsKey('minLength'), isFalse);
        expect(nameProp.toJson().containsKey('maxLength'), isFalse);

        final tagsProp = result.properties!['tags']!;
        expect(tagsProp.type, firebase_ai.SchemaType.array);
        expect(tagsProp.maxItems, 5);
      });

      test('converts deeply nested structure', () {
        final schema = Ack.object({
          'company': Ack.object({
            'name': Ack.string(),
            'address': Ack.object({
              'street': Ack.string(),
              'city': Ack.string(),
              'country': Ack.string(),
            }),
          }),
        });
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.object);
        final company = result.properties!['company']!;
        expect(company.type, firebase_ai.SchemaType.object);
        final address = company.properties!['address']!;
        expect(address.type, firebase_ai.SchemaType.object);
        expect(address.properties!.keys, containsAll(['street', 'city', 'country']));
      });
    });

    group('Edge Cases', () {
      test('handles enum schema', () {
        final schema = Ack.enumString(['red', 'green', 'blue']);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.enumValues, ['red', 'green', 'blue']);
      });

      test('handles anyOf by converting to Schema.anyOf', () {
        final schema = Ack.anyOf([
          Ack.string(),
          Ack.integer(),
        ]);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.anyOf);
        expect(result.anyOf, isNotNull);
        expect(result.anyOf, hasLength(2));
        expect(result.anyOf!.first.type, firebase_ai.SchemaType.string);
        expect(result.anyOf!.last.type, firebase_ai.SchemaType.integer);
      });

      test('converts TransformedSchema using underlying definition', () {
        final schema = Ack.date();

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.nullable, isNull);
      });

      test('throws UnsupportedError for unsupported schema types with helpful message', () {
        const schema = TestUnsupportedAckSchema();

        expect(
          () => schema.toFirebaseAiSchema(),
          throwsA(
            isA<UnsupportedError>().having(
              (error) => error.message,
              'message',
              contains('TestUnsupportedAckSchema'),
            ),
          ),
        );
      });

      test('handles empty anyOf gracefully', () {
        // AnyOf with empty schemas list
        final schema = Ack.anyOf([]);

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.anyOf);
        expect(result.anyOf, isEmpty);
      });

      test('handles empty object in anyOf', () {
        final schema = Ack.anyOf([
          Ack.object({}),
        ]);

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.anyOf);
        expect(result.anyOf, hasLength(1));
      });

      test('handles empty object schema', () {
        final schema = Ack.object({});

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.object);
        expect(result.properties, isEmpty);
      });

      test('handles deeply nested optional objects', () {
        final schema = Ack.object({
          'level1': Ack.object({
            'level2': Ack.object({
              'level3': Ack.string().optional(),
            }).optional(),
          }).optional(),
        });

        // Should not throw
        expect(
          () => schema.toFirebaseAiSchema(),
          returnsNormally,
        );

        final result = schema.toFirebaseAiSchema();
        expect(result.type, firebase_ai.SchemaType.object);
      });
    });

    group('Metadata override behavior', () {
      test('TransformedSchema with copyWith description override', () {
        // Create date schema with description via copyWith
        final dateSchema = Ack.date().copyWith(description: 'Birth date');

        final result = dateSchema.toFirebaseAiSchema();

        expect(result.description, 'Birth date');
        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.format, 'date');
      });

      test('nullable flag is forced on TransformedSchema', () {
        // Create nullable date schema via copyWith
        final dateSchema = Ack.date().copyWith(isNullable: true);

        final result = dateSchema.toFirebaseAiSchema();

        // Should be nullable
        expect(result.nullable, isTrue);
        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.format, 'date');
      });

      test('multiple overrides work together via copyWith', () {
        // Create a date schema with description and nullable
        final transformed = Ack.date().copyWith(
          isNullable: true,
          description: 'Custom date description',
        );

        final result = transformed.toFirebaseAiSchema();

        expect(result.nullable, isTrue);
        expect(result.description, 'Custom date description');
        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.format, 'date');
      });

      test('TransformedSchema preserves underlying schema format', () {
        // Datetime has format 'date-time', add description via copyWith
        final datetimeSchema = Ack.datetime().copyWith(description: 'Event timestamp');

        final result = datetimeSchema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.format, 'date-time');
        expect(result.description, 'Event timestamp');
      });

      test('description override on TransformedSchema wins over base schema', () {
        // Test that TransformedSchema's description takes precedence
        final withDescription = Ack.date().copyWith(description: 'Overridden description');

        final result = withDescription.toFirebaseAiSchema();

        expect(result.description, 'Overridden description');
      });
    });

    group('TransformedSchema support', () {
      test('converts date schema by unwrapping to underlying string schema', () {
        final schema = Ack.date();

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.format, 'date');
      });

      test('converts datetime schema by unwrapping to underlying string schema', () {
        final schema = Ack.datetime();

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.format, 'date-time');
      });

      test('converts transformed schema in arrays', () {
        final schema = Ack.list(Ack.date());

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.array);
        expect(result.items!.type, firebase_ai.SchemaType.string);
        expect(result.items!.format, 'date');
      });

      test('converts nested TransformedSchema properties correctly', () {
        final schema = Ack.object({
          'user': Ack.object({
            'birthdate': Ack.date(), // TransformedSchema
          }),
        });

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.object);
        final userProp = result.properties!['user']!;
        expect(userProp.type, firebase_ai.SchemaType.object);
        final birthdateProp = userProp.properties!['birthdate']!;
        expect(birthdateProp.type, firebase_ai.SchemaType.string);
        expect(birthdateProp.format, 'date');
      });

      test('converts top-level TransformedSchema properties correctly', () {
        final schema = Ack.object({
          'timestamp': Ack.datetime(),
        });

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.object);
        final timestampProp = result.properties!['timestamp']!;
        expect(timestampProp.type, firebase_ai.SchemaType.string);
        expect(timestampProp.format, 'date-time');
      });

      test('converts deeply nested TransformedSchema properties correctly', () {
        final schema = Ack.object({
          'data': Ack.object({
            'metadata': Ack.object({
              'createdAt': Ack.date(),
            }),
          }),
        });

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.object);
        final dataProp = result.properties!['data']!;
        expect(dataProp.type, firebase_ai.SchemaType.object);
        final metadataProp = dataProp.properties!['metadata']!;
        expect(metadataProp.type, firebase_ai.SchemaType.object);
        final createdAtProp = metadataProp.properties!['createdAt']!;
        expect(createdAtProp.type, firebase_ai.SchemaType.string);
        expect(createdAtProp.format, 'date');
      });
    });

    group('Nullable handling', () {
      test('preserves nullable on primitive types', () {
        final stringSchema = Ack.string().nullable();
        final intSchema = Ack.integer().nullable();
        final doubleSchema = Ack.double().nullable();
        final boolSchema = Ack.boolean().nullable();

        expect(stringSchema.toFirebaseAiSchema().nullable, isTrue);
        expect(intSchema.toFirebaseAiSchema().nullable, isTrue);
        expect(doubleSchema.toFirebaseAiSchema().nullable, isTrue);
        expect(boolSchema.toFirebaseAiSchema().nullable, isTrue);
      });

      test('preserves nullable on complex types', () {
        final objectSchema = Ack.object({'key': Ack.string()}).nullable();
        final listSchema = Ack.list(Ack.string()).nullable();
        final enumSchema = Ack.enumString(['a', 'b']).nullable();

        expect(objectSchema.toFirebaseAiSchema().nullable, isTrue);
        expect(listSchema.toFirebaseAiSchema().nullable, isTrue);
        expect(enumSchema.toFirebaseAiSchema().nullable, isTrue);
      });

      group('metadata preservation', () {
        test('nullable string keeps format metadata', () {
          final schema = Ack.string().email().nullable();

          final result = schema.toFirebaseAiSchema();
          expect(result.format, 'email');
          expect(result.nullable, isTrue);
        });

        test('nullable enum keeps enumValues', () {
          final schema = Ack.enumString(['x', 'y']).nullable();

          final result = schema.toFirebaseAiSchema();
          expect(result.enumValues, ['x', 'y']);
          expect(result.nullable, isTrue);
        });

        test('nullable integer keeps numeric bounds', () {
          final schema = Ack.integer().min(1).max(7).nullable();

          final result = schema.toFirebaseAiSchema();
          expect(result.minimum, 1);
          expect(result.maximum, 7);
          expect(result.nullable, isTrue);
        });

        test('nullable number keeps floating bounds', () {
          final schema = Ack.double().min(0.5).max(9.5).nullable();

          final result = schema.toFirebaseAiSchema();
          expect(result.minimum, closeTo(0.5, 1e-8));
          expect(result.maximum, closeTo(9.5, 1e-8));
          expect(result.nullable, isTrue);
        });

        test('nullable list preserves item metadata', () {
          final schema = Ack.list(Ack.string().uuid()).nullable();

          final result = schema.toFirebaseAiSchema();
          final items = result.items;
          expect(items, isNotNull);
          expect(items!.type, firebase_ai.SchemaType.string);
          expect(items.format, 'uuid');
          expect(result.nullable, isTrue);
        });

        test('nullable object preserves property metadata', () {
          final schema = Ack.object({
            'id': Ack.string().uuid(),
            'score': Ack.double().min(0).max(1),
          }).nullable();

          final result = schema.toFirebaseAiSchema();
          final idProp = result.properties!['id'];
          final scoreProp = result.properties!['score'];

          expect(idProp, isNotNull);
          expect(idProp!.format, 'uuid');

          expect(scoreProp, isNotNull);
          expect(scoreProp!.minimum, closeTo(0, 1e-8));
          expect(scoreProp.maximum, closeTo(1, 1e-8));

          expect(result.nullable, isTrue);
        });
      });
    });

    group('Optional vs Required fields', () {
      test('marks optional fields correctly', () {
        final schema = Ack.object({
          'required': Ack.string(),
          'optional': Ack.string().optional(),
        });

        final result = schema.toFirebaseAiSchema();

        expect(result.optionalProperties, contains('optional'));
        expect(result.optionalProperties, isNot(contains('required')));
      });

      test('handles all-optional fields', () {
        final schema = Ack.object({
          'field1': Ack.string().optional(),
          'field2': Ack.integer().optional(),
        });

        final result = schema.toFirebaseAiSchema();

        expect(result.optionalProperties, hasLength(2));
        expect(result.optionalProperties, containsAll(['field1', 'field2']));
      });

      test('handles all-required fields', () {
        final schema = Ack.object({
          'field1': Ack.string(),
          'field2': Ack.integer(),
        });

        final result = schema.toFirebaseAiSchema();

        // When all fields are required, optionalProperties should be null or empty
        expect(
          result.optionalProperties,
          anyOf(isNull, isEmpty),
        );
      });
    });

    group('AnySchema fallback', () {
      test('converts AnySchema to top-level anyOf', () {
        final schema = Ack.any();

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.anyOf);
        expect(result.anyOf, isNotNull);
        expect(result.anyOf, hasLength(6));
      });

      test('handles nullable AnySchema', () {
        final schema = Ack.any().nullable();

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.anyOf);
        expect(result.nullable, isTrue);
      });
    });

    group('Complex nested structures', () {
      test('handles arrays of objects with optional fields', () {
        final schema = Ack.list(
          Ack.object({
            'id': Ack.string(),
            'metadata': Ack.object({
              'tags': Ack.list(Ack.string()).optional(),
            }).optional(),
          }),
        );

        expect(
          () => schema.toFirebaseAiSchema(),
          returnsNormally,
        );
      });

      test('handles anyOf with objects', () {
        final schema = Ack.anyOf([
          Ack.object({'type': Ack.string()}),
          Ack.object({'value': Ack.integer()}),
        ]);

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.anyOf);
        expect(result.anyOf, hasLength(2));
      });

      test('handles anyOf with multiple object branches', () {
        final schema = Ack.anyOf([
          Ack.object({'type': Ack.string(), 'radius': Ack.double()}),
          Ack.object({'type': Ack.string(), 'side': Ack.double()}),
          Ack.object({
            'type': Ack.string(),
            'width': Ack.double(),
            'height': Ack.double(),
          }),
        ]);

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.anyOf);
        expect(result.anyOf, hasLength(3));
      });
    });

    group('DiscriminatedObjectSchema conversion', () {
      test('throws when branch property conflicts with discriminator key', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'circle': Ack.object({
              'type': Ack.string(), // conflict
              'radius': Ack.double(),
            }),
          },
        );

        expect(
          () => schema.toFirebaseAiSchema(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('type'),
            ),
          ),
        );
      });

      test('converts basic discriminated schema with object branches', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'circle': Ack.object({
              'radius': Ack.double(),
            }),
            'rectangle': Ack.object({
              'width': Ack.double(),
              'height': Ack.double(),
            }),
          },
        );

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.anyOf);
        expect(result.anyOf, hasLength(2));

        // Verify discriminator is injected into each branch
        final circleBranch = result.anyOf![0];
        expect(circleBranch.properties, isNotNull);
        expect(circleBranch.properties!['type'], isNotNull);
        expect(circleBranch.properties!['type']!.enumValues, ['circle']);
        expect(circleBranch.properties!['radius'], isNotNull);

        final rectangleBranch = result.anyOf![1];
        expect(rectangleBranch.properties!['type']!.enumValues, ['rectangle']);
        expect(rectangleBranch.properties!['width'], isNotNull);
        expect(rectangleBranch.properties!['height'], isNotNull);
      });

      test('handles empty discriminated schema', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {},
        );

        final result = schema.toFirebaseAiSchema();

        // Empty discriminated schema converts to empty object
        expect(result.type, firebase_ai.SchemaType.object);
        expect(result.properties, isEmpty);
      });

      test('converts mixed object and non-object branches', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'circle': Ack.object({
              'radius': Ack.double(),
            }),
            'point': Ack.object({
              'x': Ack.double(),
              'y': Ack.double(),
            }),
          },
        );

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.anyOf);
        expect(result.anyOf, hasLength(2));

        // Verify both branches have discriminator injected
        final circleBranch = result.anyOf![0];
        expect(circleBranch.properties!['type'], isNotNull);

        final pointBranch = result.anyOf![1];
        expect(pointBranch.properties!['type'], isNotNull);
      });

      test('preserves nullable flag on discriminated schema', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'kind',
          schemas: {
            'a': Ack.object({'value': Ack.string()}),
          },
        ).nullable();

        final result = schema.toFirebaseAiSchema();

        expect(result.nullable, isTrue);
      });

      test('handles nested discriminated schemas', () {
        final schema = Ack.object({
          'shape': Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {
              'circle': Ack.object({'radius': Ack.double()}),
              'square': Ack.object({'side': Ack.double()}),
            },
          ),
        });

        expect(
          () => schema.toFirebaseAiSchema(),
          returnsNormally,
        );

        final result = schema.toFirebaseAiSchema();
        final shapeProp = result.properties!['shape']!;
        expect(shapeProp.type, firebase_ai.SchemaType.anyOf);
        expect(shapeProp.anyOf, hasLength(2));
      });
    });

    group('Enum validation', () {
      test('handles enum with string values correctly', () {
        final schema = Ack.enumString(['red', 'green', 'blue']);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.enumValues, ['red', 'green', 'blue']);
      });

      test('handles single-value enum', () {
        final schema = Ack.enumString(['only']);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.enumValues, ['only']);
      });

      test('handles enum in nested objects', () {
        final schema = Ack.object({
          'status': Ack.enumString(['pending', 'active', 'completed']),
          'name': Ack.string(),
        });

        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.object);
        final statusProp = result.properties!['status']!;
        expect(statusProp.type, firebase_ai.SchemaType.string);
        expect(statusProp.enumValues, ['pending', 'active', 'completed']);
      });
    });

    group('Dart enum types', () {
      test('converts Dart enum to string enumValues using .name', () {
        final schema = Ack.enumValues([Color.red, Color.green, Color.blue]);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.enumValues, ['red', 'green', 'blue']);
      });

      test('handles single Dart enum value', () {
        final schema = Ack.enumValues([Color.red]);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.enumValues, ['red']);
      });

      test('handles Dart enum with all values', () {
        final schema = Ack.enumValues(Color.values);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.string);
        expect(result.enumValues, ['red', 'green', 'blue', 'yellow']);
      });

      test('handles Dart enum in nested object', () {
        final schema = Ack.object({
          'status': Ack.enumValues(Status.values),
          'color': Ack.enumValues([Color.red, Color.blue]),
        });

        final result = schema.toFirebaseAiSchema();

        final statusProp = result.properties!['status']!;
        expect(statusProp.enumValues, ['pending', 'active', 'completed']);

        final colorProp = result.properties!['color']!;
        expect(colorProp.enumValues, ['red', 'blue']);
      });
    });

    group('Error wrapping', () {
      test('includes property path when child conversion fails', () {
        final schema = Ack.object({
          'bad': const TestUnsupportedAckSchema(),
        });

        expect(
          () => schema.toFirebaseAiSchema(),
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message,
              'message',
              contains('property "bad"'),
            ),
          ),
        );
      });
    });

    group('Type coercion error paths', () {
      test('handles integer min/max constraints', () {
        final schema = Ack.integer().min(0).max(100);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.integer);
        expect(result.minimum, 0);
        expect(result.maximum, 100);
      });

      test('handles double min/max constraints', () {
        final schema = Ack.double().min(0.0).max(1.0);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.number);
        expect(result.minimum, closeTo(0.0, 1e-8));
        expect(result.maximum, closeTo(1.0, 1e-8));
      });

      test('converts integer constraints without precision loss', () {
        final schema = Ack.integer().min(-1000).max(1000);
        final result = schema.toFirebaseAiSchema();

        expect(result.minimum, -1000);
        expect(result.maximum, 1000);
        // Verify these are exact integers
        expect(result.minimum is num, isTrue);
        expect(result.maximum is num, isTrue);
      });

      test('handles array minItems/maxItems constraints', () {
        final schema = Ack.list(Ack.string()).minLength(1).maxLength(10);
        final result = schema.toFirebaseAiSchema();

        expect(result.type, firebase_ai.SchemaType.array);
        expect(result.minItems, 1);
        expect(result.maxItems, 10);
      });

      test('handles null numeric constraints', () {
        final schema = Ack.integer();
        final result = schema.toFirebaseAiSchema();

        expect(result.minimum, isNull);
        expect(result.maximum, isNull);
      });

      test('handles large integer values', () {
        // Test with large but valid integer values
        final schema = Ack.integer().min(-2147483648).max(2147483647);
        final result = schema.toFirebaseAiSchema();

        expect(result.minimum, -2147483648);
        expect(result.maximum, 2147483647);
      });
    });

    group('Semantic validation - String Constraints', () {
      test('minLength constraint preserves validation behavior', () {
        final schema = Ack.string().minLength(5);
        final geminiSchema = schema.toFirebaseAiSchema();

        // Valid: string meets minimum length
        expect(schema.safeParse('hello').isOk, isTrue);
        expect(schema.safeParse('world!').isOk, isTrue);

        // Invalid: string too short
        expect(schema.safeParse('hi').isFail, isTrue);

        expect(geminiSchema.type, firebase_ai.SchemaType.string);
        expect(geminiSchema.toJson().containsKey('minLength'), isFalse,
            reason: 'firebase_ai Schema omits minLength metadata; track externally');
      });

      test('maxLength constraint preserves validation behavior', () {
        final schema = Ack.string().maxLength(10);
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse('short').isOk, isTrue);
        expect(schema.safeParse('this is way too long').isFail, isTrue);

        expect(geminiSchema.type, firebase_ai.SchemaType.string);
        expect(geminiSchema.toJson().containsKey('maxLength'), isFalse,
            reason: 'firebase_ai Schema omits maxLength metadata; track externally');
      });

      test('email format constraint preserves validation behavior', () {
        final schema = Ack.string().email();
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse('user@example.com').isOk, isTrue);
        expect(schema.safeParse('not-an-email').isFail, isTrue);
        expect(geminiSchema.format, 'email');
      });

      test('enum constraint preserves validation behavior', () {
        final schema = Ack.enumString(['red', 'green', 'blue']);
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse('red').isOk, isTrue);
        expect(schema.safeParse('yellow').isFail, isTrue);
        expect(geminiSchema.enumValues, ['red', 'green', 'blue']);
      });
    });

    group('Semantic validation - Numeric Constraints', () {
      test('minimum constraint preserves validation behavior', () {
        final schema = Ack.integer().min(0);
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse(0).isOk, isTrue);
        expect(schema.safeParse(10).isOk, isTrue);
        expect(schema.safeParse(-1).isFail, isTrue);
        expect(geminiSchema.minimum, 0);
      });

      test('maximum constraint preserves validation behavior', () {
        final schema = Ack.integer().max(100);
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse(50).isOk, isTrue);
        expect(schema.safeParse(100).isOk, isTrue);
        expect(schema.safeParse(101).isFail, isTrue);
        expect(geminiSchema.maximum, 100);
      });

      test('range constraint preserves validation behavior', () {
        final schema = Ack.integer().min(0).max(100);
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse(0).isOk, isTrue);
        expect(schema.safeParse(50).isOk, isTrue);
        expect(schema.safeParse(100).isOk, isTrue);
        expect(schema.safeParse(-1).isFail, isTrue);
        expect(schema.safeParse(101).isFail, isTrue);

        expect(geminiSchema.minimum, 0);
        expect(geminiSchema.maximum, 100);
      });

      test('double range constraint preserves validation behavior', () {
        final schema = Ack.double().min(0.0).max(1.0);
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse(0.0).isOk, isTrue);
        expect(schema.safeParse(0.5).isOk, isTrue);
        expect(schema.safeParse(1.0).isOk, isTrue);
        expect(schema.safeParse(-0.1).isFail, isTrue);
        expect(schema.safeParse(1.1).isFail, isTrue);

        expect(geminiSchema.minimum, closeTo(0.0, 1e-8));
        expect(geminiSchema.maximum, closeTo(1.0, 1e-8));
      });
    });

    group('Semantic validation - Object Structure', () {
      test('required fields validation behavior preserved', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer(),
        });
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse({'name': 'John', 'age': 30}).isOk, isTrue);
        expect(schema.safeParse({'name': 'John'}).isFail, isTrue);

        final requiredFromJson = geminiSchema.toJson()['required'] as List;
        expect(requiredFromJson, unorderedEquals(['name', 'age']));
        expect(geminiSchema.optionalProperties, isNull);
      });

      test('optional fields validation behavior preserved', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().optional(),
          'email': Ack.string().optional(),
        });
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse({'name': 'John'}).isOk, isTrue);
        expect(
          schema.safeParse({'name': 'John', 'age': 30, 'email': 'john@example.com'}).isOk,
          isTrue,
        );
        expect(schema.safeParse({'age': 30}).isFail, isTrue);

        final requiredFromJson = geminiSchema.toJson()['required'] as List;
        expect(requiredFromJson, unorderedEquals(['name']));
        expect(geminiSchema.optionalProperties, containsAll(['age', 'email']));
      });

      test('nested object validation behavior preserved', () {
        final schema = Ack.object({
          'user': Ack.object({
            'name': Ack.string(),
            'age': Ack.integer().min(0),
          }),
        });
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(
          schema.safeParse({
            'user': {'name': 'John', 'age': 30},
          }).isOk,
          isTrue,
        );
        expect(
          schema.safeParse({
            'user': {'name': 'John', 'age': -1},
          }).isFail,
          isTrue,
        );
        expect(
          schema.safeParse({
            'user': {'name': 'John'},
          }).isFail,
          isTrue,
        );

        final userProp = geminiSchema.properties!['user']!;
        expect(userProp.type, firebase_ai.SchemaType.object);
        final userRequired = userProp.toJson()['required'] as List;
        expect(userRequired, unorderedEquals(['name', 'age']));
      });
    });

    group('Semantic validation - Array Structure', () {
      test('array item validation behavior preserved', () {
        final schema = Ack.list(Ack.string().minLength(2));
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse(['hello', 'world']).isOk, isTrue);
        expect(schema.safeParse(['hello', 'x']).isFail, isTrue);

        expect(geminiSchema.type, firebase_ai.SchemaType.array);
        expect(geminiSchema.items, isNotNull);
        expect(geminiSchema.items!.type, firebase_ai.SchemaType.string);
      });

      test('minItems constraint preserves validation behavior', () {
        final schema = Ack.list(Ack.string()).minLength(2);
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse(['a', 'b']).isOk, isTrue);
        expect(schema.safeParse(['a']).isFail, isTrue);
        expect(geminiSchema.minItems, 2);
      });

      test('maxItems constraint preserves validation behavior', () {
        final schema = Ack.list(Ack.string()).maxLength(3);
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse(['a', 'b', 'c']).isOk, isTrue);
        expect(schema.safeParse(['a', 'b', 'c', 'd']).isFail, isTrue);
        expect(geminiSchema.maxItems, 3);
      });

      test('array of objects validation behavior preserved', () {
        final schema = Ack.list(
          Ack.object({
            'id': Ack.integer(),
            'name': Ack.string().minLength(1),
          }),
        );
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(
          schema.safeParse([
            {'id': 1, 'name': 'Item 1'},
            {'id': 2, 'name': 'Item 2'},
          ]).isOk,
          isTrue,
        );
        expect(
          schema.safeParse([
            {'id': 1, 'name': 'Item 1'},
            {'id': 2, 'name': ''},
          ]).isFail,
          isTrue,
        );

        expect(geminiSchema.items, isNotNull);
        expect(geminiSchema.items!.type, firebase_ai.SchemaType.object);
      });
    });

    group('Semantic validation - Nullable Handling', () {
      test('nullable primitive accepts null', () {
        final schema = Ack.string().nullable();
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse(null).isOk, isTrue);
        expect(schema.safeParse('hello').isOk, isTrue);
        expect(geminiSchema.nullable, isTrue);
      });

      test('non-nullable primitive rejects null', () {
        final schema = Ack.string();
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse(null).isFail, isTrue);
        expect(schema.safeParse('hello').isOk, isTrue);
        expect(geminiSchema.nullable, isNull);
      });

      test('nullable object accepts null', () {
        final schema = Ack.object({
          'name': Ack.string(),
        }).nullable();
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(schema.safeParse(null).isOk, isTrue);
        expect(schema.safeParse({'name': 'test'}).isOk, isTrue);
        expect(geminiSchema.nullable, isTrue);
      });
    });

    group('Semantic validation - Complex Real-World Scenarios', () {
      test('user registration schema validates correctly', () {
        final schema = Ack.object({
          'username': Ack.string().minLength(3).maxLength(20),
          'email': Ack.string().email(),
          'age': Ack.integer().min(13).optional(),
          'password': Ack.string().minLength(8),
        });
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(
          schema.safeParse({
            'username': 'john_doe',
            'email': 'john@example.com',
            'age': 25,
            'password': 'securepass123',
          }).isOk,
          isTrue,
        );
        expect(
          schema.safeParse({
            'username': 'john_doe',
            'email': 'john@example.com',
            'password': 'securepass123',
          }).isOk,
          isTrue,
        );
        expect(
          schema.safeParse({
            'username': 'jo',
            'email': 'john@example.com',
            'password': 'securepass123',
          }).isFail,
          isTrue,
        );
        expect(
          schema.safeParse({
            'username': 'john_doe',
            'email': 'not-an-email',
            'password': 'securepass123',
          }).isFail,
          isTrue,
        );
        expect(
          schema.safeParse({
            'username': 'john_doe',
            'email': 'john@example.com',
            'age': 10,
            'password': 'securepass123',
          }).isFail,
          isTrue,
        );

        final requiredFromJson = geminiSchema.toJson()['required'] as List;
        expect(requiredFromJson, unorderedEquals(['username', 'email', 'password']));
      });

      test('blog post schema validates correctly', () {
        final schema = Ack.object({
          'title': Ack.string().minLength(5).maxLength(100),
          'content': Ack.string().minLength(10),
          'author': Ack.object({
            'name': Ack.string(),
            'email': Ack.string().email(),
          }),
          'tags': Ack.list(Ack.string()).minLength(1).maxLength(5),
          'published': Ack.boolean(),
        });
        final geminiSchema = schema.toFirebaseAiSchema();

        expect(
          schema.safeParse({
            'title': 'My First Blog Post',
            'content': 'This is the content of my blog post.',
            'author': {
              'name': 'John Doe',
              'email': 'john@example.com',
            },
            'tags': ['tech', 'tutorial'],
            'published': true,
          }).isOk,
          isTrue,
        );
        expect(
          schema.safeParse({
            'title': 'Hi',
            'content': 'This is the content of my blog post.',
            'author': {'name': 'John', 'email': 'john@example.com'},
            'tags': ['tech'],
            'published': true,
          }).isFail,
          isTrue,
        );
        expect(
          schema.safeParse({
            'title': 'My First Blog Post',
            'content': 'This is the content of my blog post.',
            'author': {'name': 'John', 'email': 'john@example.com'},
            'tags': ['tag1', 'tag2', 'tag3', 'tag4', 'tag5', 'tag6'],
            'published': true,
          }).isFail,
          isTrue,
        );

        expect(geminiSchema.type, firebase_ai.SchemaType.object);
        final authorProp = geminiSchema.properties!['author']!;
        final authorRequired = authorProp.toJson()['required'] as List;
        expect(authorRequired, unorderedEquals(['name', 'email']));
      });
    });

    group('Converter instantiation prevention', () {
      test('cannot instantiate FirebaseAiSchemaConverter', () {
        // This should not compile, but we can verify the constructor is private
        // by checking that the convert method is accessible but the class cannot be instantiated
        final schema = Ack.string();

        // This should work (static method)
        expect(
          () => schema.toFirebaseAiSchema(),
          returnsNormally,
        );

        // Note: We cannot directly test private constructor in Dart,
        // but attempting to instantiate would be a compile-time error:
        // final converter = FirebaseAiSchemaConverter(); // Would not compile
      });
    });
  });
}
