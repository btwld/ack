import 'package:ack/ack.dart';
import 'package:test/test.dart';

// Test enum for EnumSchema testing
enum Color { red, green, blue }

enum Size { small, medium, large }

void main() {
  group('Comprehensive JSON Schema Tests', () {
    group('Basic Schema Types', () {
      group('StringSchema', () {
        test('should validate basic string', () {
          final schema = Ack.string();
          expect(schema.safeParse('hello').isOk, isTrue);
          expect(
            schema.safeParse(123).isOk,
            isTrue,
          ); // Type coercion: 123 -> "123"
        });

        test('should validate with constraints', () {
          final schema = Ack.string().minLength(3).maxLength(10);
          expect(schema.safeParse('hello').isOk, isTrue);
          expect(schema.safeParse('hi').isOk, isFalse);
          expect(schema.safeParse('this is too long').isOk, isFalse);
        });

        test('should validate email format', () {
          final schema = Ack.string().email();
          expect(schema.safeParse('test@example.com').isOk, isTrue);
          expect(schema.safeParse('invalid-email').isOk, isFalse);
        });

        test('should validate URL format', () {
          final schema = Ack.string().url();
          expect(schema.safeParse('https://example.com').isOk, isTrue);
          expect(schema.safeParse('not-a-url').isOk, isFalse);
        });

        test('should validate UUID format', () {
          final schema = Ack.string().uuid();
          expect(
            schema.safeParse('123e4567-e89b-12d3-a456-426614174000').isOk,
            isTrue,
          );
          expect(schema.safeParse('not-a-uuid').isOk, isFalse);
        });

        test('should validate literal values', () {
          final schema = Ack.string().literal('exact');
          expect(schema.safeParse('exact').isOk, isTrue);
          expect(schema.safeParse('different').isOk, isFalse);
        });

        test('should validate using Ack.literal factory', () {
          final schema = Ack.literal('exact');
          expect(schema.safeParse('exact').isOk, isTrue);
          expect(schema.safeParse('different').isOk, isFalse);
        });

        test('should handle nullable string', () {
          final schema = Ack.string().nullable();
          expect(schema.safeParse('hello').isOk, isTrue);
          expect(schema.safeParse(null).isOk, isTrue);
        });

        test('should handle default values', () {
          final schema = Ack.string().withDefault('default');
          expect(schema.safeParse(null).getOrNull(), equals('default'));
          expect(schema.safeParse('custom').getOrNull(), equals('custom'));
        });

        test('should generate correct JSON schema', () {
          final schema = Ack.string().minLength(5).maxLength(50).email();
          final jsonSchema = schema.toJsonSchema();

          expect(jsonSchema['type'], equals('string'));
          expect(jsonSchema['minLength'], equals(5));
          expect(jsonSchema['maxLength'], equals(50));
          expect(jsonSchema['format'], equals('email'));
        });
      });

      group('IntegerSchema', () {
        test('should validate basic integer', () {
          final schema = Ack.integer();
          expect(schema.safeParse(42).isOk, isTrue);
          expect(schema.safeParse(3.14).isOk, isFalse);
          expect(schema.safeParse('not-a-number').isOk, isFalse);
        });

        test('should validate with numeric constraints', () {
          final schema = Ack.integer().min(10).max(100);
          expect(schema.safeParse(50).isOk, isTrue);
          expect(schema.safeParse(5).isOk, isFalse);
          expect(schema.safeParse(150).isOk, isFalse);
        });

        test('should validate positive integers', () {
          final schema = Ack.integer().positive();
          expect(schema.safeParse(5).isOk, isTrue);
          expect(schema.safeParse(0).isOk, isFalse);
          expect(schema.safeParse(-5).isOk, isFalse);
        });

        test('should handle type coercion from string', () {
          final schema = Ack.integer();
          expect(schema.safeParse('42').getOrNull(), equals(42));
          expect(schema.safeParse('not-a-number').isOk, isFalse);
        });

        test('should handle type coercion from double', () {
          final schema = Ack.integer();
          expect(schema.safeParse(42.0).getOrNull(), equals(42));
          expect(schema.safeParse(42.5).isOk, isFalse);
        });

        test('should generate correct JSON schema', () {
          final schema = Ack.integer().min(0).max(100);
          final jsonSchema = schema.toJsonSchema();

          expect(jsonSchema['type'], equals('integer'));
          expect(jsonSchema['minimum'], equals(0));
          expect(jsonSchema['maximum'], equals(100));
        });
      });

      group('DoubleSchema', () {
        test('should validate basic double', () {
          final schema = Ack.double();
          expect(schema.safeParse(3.14).isOk, isTrue);
          expect(schema.safeParse(42).isOk, isTrue); // int to double coercion
          expect(schema.safeParse('not-a-number').isOk, isFalse);
        });

        test('should validate with numeric constraints', () {
          final schema = Ack.double().min(0.0).max(100.0);
          expect(schema.safeParse(50.5).isOk, isTrue);
          expect(schema.safeParse(-1.0).isOk, isFalse);
          expect(schema.safeParse(101.0).isOk, isFalse);
        });

        test('should handle type coercion from string', () {
          final schema = Ack.double();
          expect(schema.safeParse('3.14').getOrNull(), equals(3.14));
          expect(schema.safeParse('not-a-number').isOk, isFalse);
        });
      });

      group('BooleanSchema', () {
        test('should validate basic boolean', () {
          final schema = Ack.boolean();
          expect(schema.safeParse(true).isOk, isTrue);
          expect(schema.safeParse(false).isOk, isTrue);
          expect(schema.safeParse('true').isOk, isTrue);
          expect(schema.safeParse('false').isOk, isTrue);
          expect(schema.safeParse(1).isOk, isFalse);
        });

        test('should handle strict parsing', () {
          final schema = Ack.boolean().strictParsing();
          expect(schema.safeParse(true).isOk, isTrue);
          expect(schema.safeParse('true').isOk, isFalse);
        });

        group('Case-insensitive string parsing', () {
          test('should parse uppercase strings correctly', () {
            final schema = Ack.boolean();
            expect(schema.safeParse('TRUE').isOk, isTrue);
            expect(schema.safeParse('TRUE').getOrNull(), isTrue);
            expect(schema.safeParse('FALSE').isOk, isTrue);
            expect(schema.safeParse('FALSE').getOrNull(), isFalse);
          });

          test('should parse mixed case strings correctly', () {
            final schema = Ack.boolean();
            expect(schema.safeParse('True').isOk, isTrue);
            expect(schema.safeParse('True').getOrNull(), isTrue);
            expect(schema.safeParse('False').isOk, isTrue);
            expect(schema.safeParse('False').getOrNull(), isFalse);
            expect(schema.safeParse('tRuE').isOk, isTrue);
            expect(schema.safeParse('tRuE').getOrNull(), isTrue);
            expect(schema.safeParse('fAlSe').isOk, isTrue);
            expect(schema.safeParse('fAlSe').getOrNull(), isFalse);
          });

          test(
            'should maintain case-insensitive behavior after optimization',
            () {
              final schema = Ack.boolean();
              // Test various case combinations that would break if toLowerCase() optimization fails
              final trueCases = [
                'true',
                'TRUE',
                'True',
                'tRuE',
                'TrUe',
                'TRue',
                'trUE',
                'TRUe',
              ];
              final falseCases = [
                'false',
                'FALSE',
                'False',
                'fAlSe',
                'FaLsE',
                'FALse',
                'falSE',
                'FALsE',
              ];

              for (final testCase in trueCases) {
                expect(
                  schema.safeParse(testCase).isOk,
                  isTrue,
                  reason: 'Failed for: $testCase',
                );
                expect(
                  schema.safeParse(testCase).getOrNull(),
                  isTrue,
                  reason: 'Wrong value for: $testCase',
                );
              }

              for (final testCase in falseCases) {
                expect(
                  schema.safeParse(testCase).isOk,
                  isTrue,
                  reason: 'Failed for: $testCase',
                );
                expect(
                  schema.safeParse(testCase).getOrNull(),
                  isFalse,
                  reason: 'Wrong value for: $testCase',
                );
              }
            },
          );

          test('should reject invalid string values', () {
            final schema = Ack.boolean();
            final invalidCases = [
              'yes',
              'no',
              '1',
              '0',
              'on',
              'off',
              'truee',
              'fals',
            ];

            for (final testCase in invalidCases) {
              expect(
                schema.safeParse(testCase).isOk,
                isFalse,
                reason: 'Should reject: $testCase',
              );
            }
          });

          test('should handle whitespace-padded valid values', () {
            final schema = Ack.boolean();
            // These should pass after trimming
            expect(schema.safeParse(' true').isOk, isTrue);
            expect(schema.safeParse('true ').isOk, isTrue);
            expect(schema.safeParse('  true  ').isOk, isTrue);
            expect(schema.safeParse(' false').isOk, isTrue);
            expect(schema.safeParse('false ').isOk, isTrue);
            expect(schema.safeParse(' TRUE ').isOk, isTrue);
            expect(schema.safeParse(' FALSE ').isOk, isTrue);
          });

          test('should handle empty and whitespace-only strings', () {
            final schema = Ack.boolean();
            expect(schema.safeParse('').isOk, isFalse);
            expect(schema.safeParse(' ').isOk, isFalse);
            expect(schema.safeParse('  ').isOk, isFalse);
            expect(schema.safeParse('\t').isOk, isFalse);
            expect(schema.safeParse('\n').isOk, isFalse);
          });

          test('should not parse strings with strict parsing enabled', () {
            final schema = Ack.boolean().strictParsing();
            final stringCases = [
              'true',
              'false',
              'TRUE',
              'FALSE',
              'True',
              'False',
            ];

            for (final testCase in stringCases) {
              expect(
                schema.safeParse(testCase).isOk,
                isFalse,
                reason: 'Should reject with strict parsing: $testCase',
              );
            }
          });
        });
      });

      group('EnumSchema', () {
        test('should validate enum values', () {
          final schema = Ack.enumValues(Color.values);
          expect(schema.safeParse(Color.red).isOk, isTrue);
          expect(schema.safeParse('red').isOk, isTrue);
          expect(schema.safeParse(0).isOk, isTrue); // index
          expect(schema.safeParse('purple').isOk, isFalse);
        });

        test('should validate by name', () {
          final schema = Ack.enumValues(Color.values);
          expect(schema.safeParse('green').getOrNull(), equals(Color.green));
        });

        test('should validate by index', () {
          final schema = Ack.enumValues(Color.values);
          expect(schema.safeParse(2).getOrNull(), equals(Color.blue));
        });

        test('should generate correct JSON schema', () {
          final schema = Ack.enumValues(Color.values);
          final jsonSchema = schema.toJsonSchema();

          expect(jsonSchema['type'], equals('string'));
          expect(jsonSchema['enum'], equals(['red', 'green', 'blue']));
        });
      });
    });

    group('Complex Schema Types', () {
      group('ListSchema', () {
        test('should validate basic list', () {
          final schema = Ack.list(Ack.string());
          expect(schema.safeParse(['hello', 'world']).isOk, isTrue);
          expect(
            schema.safeParse([1, 2, 3]).isOk,
            isTrue,
          ); // Type coercion: numbers -> strings
        });

        test('should validate with list constraints', () {
          final schema = Ack.list(Ack.integer()).minItems(2).maxItems(5);
          expect(schema.safeParse([1, 2, 3]).isOk, isTrue);
          expect(schema.safeParse([1]).isOk, isFalse);
          expect(schema.safeParse([1, 2, 3, 4, 5, 6]).isOk, isFalse);
        });

        test('should validate nested lists', () {
          final schema = Ack.list(Ack.list(Ack.integer()));
          expect(
            schema.safeParse([
              [1, 2],
              [3, 4],
            ]).isOk,
            isTrue,
          );
          expect(
            schema.safeParse([
              ['not', 'numbers'],
            ]).isOk,
            isFalse,
          );
        });

        test('should validate unique items', () {
          final schema = Ack.list(Ack.string()).unique();
          expect(schema.safeParse(['a', 'b', 'c']).isOk, isTrue);
          expect(schema.safeParse(['a', 'b', 'a']).isOk, isFalse);
        });
      });

      group('ObjectSchema', () {
        test('should validate basic object', () {
          final schema = Ack.object({
            'name': Ack.string(),
            'age': Ack.integer(),
          });

          expect(schema.safeParse({'name': 'John', 'age': 30}).isOk, isTrue);
          expect(
            schema.safeParse({'name': 'John', 'age': 'thirty'}).isOk,
            isFalse,
          );
        });

        test('should validate required properties', () {
          final schema = Ack.object({
            'name': Ack.string(),
            'age': Ack.integer().optional(),
          });

          expect(schema.safeParse({'name': 'John', 'age': 30}).isOk, isTrue);
          expect(schema.safeParse({'age': 30}).isOk, isFalse);
          expect(schema.safeParse({'name': 'John'}).isOk, isTrue);
        });

        test('should handle additional properties', () {
          final schema = Ack.object({
            'name': Ack.string(),
          }, additionalProperties: true);

          expect(
            schema.safeParse({'name': 'John', 'extra': 'value'}).isOk,
            isTrue,
          );

          final strictSchema = Ack.object({
            'name': Ack.string(),
          }, additionalProperties: false);

          expect(
            strictSchema.safeParse({'name': 'John', 'extra': 'value'}).isOk,
            isFalse,
          );
        });

        test('should validate nested objects', () {
          final schema = Ack.object({
            'user': Ack.object({
              'name': Ack.string(),
              'email': Ack.string().email(),
            }),
            'posts': Ack.list(
              Ack.object({'title': Ack.string(), 'content': Ack.string()}),
            ),
          });

          final validData = {
            'user': {'name': 'John', 'email': 'john@example.com'},
            'posts': [
              {'title': 'First Post', 'content': 'Hello World'},
              {'title': 'Second Post', 'content': 'Another post'},
            ],
          };

          expect(schema.safeParse(validData).isOk, isTrue);
        });
      });

      group('DiscriminatedObjectSchema', () {
        late ObjectSchema carSchema;
        late ObjectSchema bikeSchema;
        late DiscriminatedObjectSchema vehicleSchema;

        setUp(() {
          carSchema = Ack.object({
            'type': Ack.string(),
            'doors': Ack.integer(),
            'engine': Ack.string(),
          });

          bikeSchema = Ack.object({
            'type': Ack.string(),
            'wheels': Ack.integer(),
            'pedals': Ack.boolean(),
          });

          vehicleSchema = Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {'car': carSchema, 'bike': bikeSchema},
          );
        });

        test('should validate car correctly', () {
          final carData = {'type': 'car', 'doors': 4, 'engine': 'V6'};

          expect(vehicleSchema.safeParse(carData).isOk, isTrue);
        });

        test('should validate bike correctly', () {
          final bikeData = {'type': 'bike', 'wheels': 2, 'pedals': true};

          expect(vehicleSchema.safeParse(bikeData).isOk, isTrue);
        });

        test('should fail for unknown discriminator', () {
          final unknownVehicle = {'type': 'plane', 'wings': 2};

          expect(vehicleSchema.safeParse(unknownVehicle).isOk, isFalse);
        });

        test('should fail for missing discriminator', () {
          final invalidData = {'doors': 4, 'engine': 'V6'};

          expect(vehicleSchema.safeParse(invalidData).isOk, isFalse);
        });

        test('should validate nested discriminated objects', () {
          final complexSchema = Ack.object({
            'id': Ack.string(),
            'vehicle': vehicleSchema,
            'owner': Ack.object({
              'name': Ack.string(),
              'license': Ack.string(),
            }),
          });

          final complexData = {
            'id': 'vehicle-001',
            'vehicle': {'type': 'car', 'doors': 4, 'engine': 'V8'},
            'owner': {'name': 'John Doe', 'license': 'ABC123'},
          };

          expect(complexSchema.safeParse(complexData).isOk, isTrue);
        });

        test('should generate correct JSON schema', () {
          final jsonSchema = vehicleSchema.toJsonSchema();

          // Discriminated unions use anyOf (not oneOf) in JSON Schema
          expect(jsonSchema['anyOf'], isNotNull);
          expect((jsonSchema['anyOf'] as List).length, equals(2));
        });
      });

      group('AnyOfSchema', () {
        test('should validate string or integer', () {
          final schema = Ack.anyOf([Ack.string(), Ack.integer()]);

          expect(schema.safeParse('hello').isOk, isTrue);
          expect(schema.safeParse(42).isOk, isTrue);
          expect(
            schema.safeParse(true).isOk,
            isTrue,
          ); // Type coercion: true -> "true"
        });

        test('should validate complex anyOf schemas', () {
          final schema = Ack.anyOf([
            Ack.object({'type': Ack.literal('user'), 'name': Ack.string()}),
            Ack.object({
              'type': Ack.literal('admin'),
              'permissions': Ack.list(Ack.string()),
            }),
            Ack.string().email(),
          ]);

          expect(
            schema.safeParse({'type': 'user', 'name': 'John'}).isOk,
            isTrue,
          );

          expect(
            schema.safeParse({
              'type': 'admin',
              'permissions': ['read', 'write'],
            }).isOk,
            isTrue,
          );

          expect(schema.safeParse('admin@example.com').isOk, isTrue);

          expect(
            schema.safeParse({'type': 'guest', 'name': 'Anonymous'}).isOk,
            isFalse,
          );
        });

        test('should validate nested anyOf schemas', () {
          final schema = Ack.object({
            'value': Ack.anyOf([
              Ack.string(),
              Ack.integer(),
              Ack.list(Ack.string()),
            ]),
          });

          expect(schema.safeParse({'value': 'text'}).isOk, isTrue);
          expect(schema.safeParse({'value': 42}).isOk, isTrue);
          expect(
            schema.safeParse({
              'value': ['a', 'b', 'c'],
            }).isOk,
            isTrue,
          );
          expect(
            schema.safeParse({'value': true}).isOk,
            isTrue,
          ); // Type coercion: true -> "true"
        });

        test('should generate correct JSON schema', () {
          final schema = Ack.anyOf([Ack.string(), Ack.integer()]);

          final jsonSchema = schema.toJsonSchema();

          expect(jsonSchema['anyOf'], isNotNull);
          expect((jsonSchema['anyOf'] as List).length, equals(2));
        });
      });
    });

    group('Real-World Complex Scenarios', () {
      test('should validate API response schema', () {
        final apiResponseSchema = Ack.object({
          'status': Ack.integer().min(100).max(599),
          'data': Ack.anyOf([
            Ack.object({
              'users': Ack.list(
                Ack.object({
                  'id': Ack.string().uuid(),
                  'name': Ack.string().minLength(1),
                  'email': Ack.string().email(),
                  'age': Ack.integer().min(0).max(150),
                  'roles': Ack.list(Ack.enumValues(Size.values)),
                }),
              ),
              'total': Ack.integer().min(0),
            }),
            Ack.object({'error': Ack.string(), 'code': Ack.string()}),
          ]),
          'timestamp': Ack.string(),
        });

        final successResponse = {
          'status': 200,
          'data': {
            'users': [
              {
                'id': '123e4567-e89b-12d3-a456-426614174000',
                'name': 'John Doe',
                'email': 'john@example.com',
                'age': 30,
                'roles': ['medium', 'large'],
              },
            ],
            'total': 1,
          },
          'timestamp': '2023-01-01T00:00:00Z',
        };

        final errorResponse = {
          'status': 404,
          'data': {'error': 'Not Found', 'code': 'NOT_FOUND'},
          'timestamp': '2023-01-01T00:00:00Z',
        };

        expect(apiResponseSchema.safeParse(successResponse).isOk, isTrue);
        expect(apiResponseSchema.safeParse(errorResponse).isOk, isTrue);
      });

      test('should validate e-commerce order schema', () {
        final orderSchema = Ack.object({
          'orderId': Ack.string().uuid(),
          'customer': Ack.object({
            'id': Ack.string(),
            'name': Ack.string().minLength(1),
            'email': Ack.string().email(),
            'address': Ack.object({
              'street': Ack.string(),
              'city': Ack.string(),
              'country': Ack.string().length(2), // ISO country code
              'zipCode': Ack.string(),
            }),
          }),
          'items': Ack.list(
            Ack.object({
              'productId': Ack.string(),
              'name': Ack.string(),
              'quantity': Ack.integer().min(1),
              'price': Ack.double().min(0),
              'category': Ack.enumValues(
                Color.values,
              ), // Using Color as category
            }),
          ).minItems(1),
          'total': Ack.double().min(0),
          'status': Ack.anyOf([
            Ack.literal('pending'),
            Ack.literal('processing'),
            Ack.literal('shipped'),
            Ack.literal('delivered'),
            Ack.literal('cancelled'),
          ]),
          'paymentMethod': Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {
              'credit_card': Ack.object({
                'type': Ack.string(),
                'cardNumber': Ack.string().length(16),
                'expiryMonth': Ack.integer().min(1).max(12),
                'expiryYear': Ack.integer().min(2023),
              }),
              'paypal': Ack.object({
                'type': Ack.string(),
                'email': Ack.string().email(),
              }),
            },
          ),
        });

        final validOrder = {
          'orderId': '123e4567-e89b-12d3-a456-426614174000',
          'customer': {
            'id': 'cust_001',
            'name': 'Jane Smith',
            'email': 'jane@example.com',
            'address': {
              'street': '123 Main St',
              'city': 'New York',
              'country': 'US',
              'zipCode': '10001',
            },
          },
          'items': [
            {
              'productId': 'prod_001',
              'name': 'Widget',
              'quantity': 2,
              'price': 29.99,
              'category': 'red',
            },
          ],
          'total': 59.98,
          'status': 'processing',
          'paymentMethod': {
            'type': 'credit_card',
            'cardNumber': '1234567890123456',
            'expiryMonth': 12,
            'expiryYear': 2025,
          },
        };

        expect(orderSchema.safeParse(validOrder).isOk, isTrue);
      });
    });

    group('Error Handling and Edge Cases', () {
      test(
        'should provide detailed error messages for nested validation failures',
        () {
          final schema = Ack.object({
            'user': Ack.object({
              'profile': Ack.object({'email': Ack.string().email()}),
            }),
          });

          final invalidData = {
            'user': {
              'profile': {'email': 'invalid-email'},
            },
          };

          final result = schema.safeParse(invalidData);
          expect(result.isOk, isFalse);

          final error = result.getError();
          expect(error, isA<SchemaNestedError>());
        },
      );

      test('should handle null values correctly in complex schemas', () {
        final schema = Ack.object({
          'optional': Ack.string().optional().nullable(),
          'required': Ack.string(),
          'nested': Ack.object({
            'nullableField': Ack.integer().optional().nullable(),
          }).optional().nullable(),
        });

        final validData = {
          'optional': null,
          'required': 'present',
          'nested': null,
        };

        expect(schema.safeParse(validData).isOk, isTrue);
      });
    });

    group('JSON Schema Generation', () {
      test('should generate complete JSON schemas for all types', () {
        final Map<String, AckSchema> schemas = {
          'string': Ack.string().minLength(1).maxLength(100),
          'integer': Ack.integer().min(0).max(1000),
          'double': Ack.double().min(0.0).max(100.0),
          'boolean': Ack.boolean(),
          'enum': Ack.enumValues(Color.values),
          'list': Ack.list(Ack.string()).minItems(1),
          'object': Ack.object({'key': Ack.string()}),
          'anyOf': Ack.anyOf([Ack.string(), Ack.integer()]),
        };

        for (final entry in schemas.entries) {
          final jsonSchema = entry.value.toJsonSchema();
          expect(
            jsonSchema,
            isNotNull,
            reason: '${entry.key} should generate JSON schema',
          );
          expect(
            jsonSchema,
            isA<Map<String, Object?>>(),
            reason: '${entry.key} should be a Map',
          );
        }
      });

      test('should handle nullable schemas in JSON generation', () {
        final nullableString = Ack.string().nullable();
        final jsonSchema = nullableString.toJsonSchema();

        // Nullable schemas use anyOf pattern with null type
        expect(jsonSchema.containsKey('anyOf'), isTrue);
        final anyOfList = jsonSchema['anyOf'] as List;
        expect(anyOfList.length, equals(2));
        final types = anyOfList.map((s) => (s as Map)['type']).toSet();
        expect(types, containsAll(['string', 'null']));
      });

      test('should handle default values in JSON generation', () {
        final schemaWithDefault = Ack.string().withDefault('default_value');
        final jsonSchema = schemaWithDefault.toJsonSchema();

        expect(jsonSchema['default'], equals('default_value'));
      });
    });

    group('Fluent API Chaining', () {
      test('should chain multiple constraints fluently', () {
        final schema = Ack.string()
            .minLength(5)
            .maxLength(50)
            .email()
            .nullable()
            .withDescription('User email address');

        expect(schema.safeParse('user@example.com').isOk, isTrue);
        expect(schema.safeParse(null).isOk, isTrue);
        expect(schema.safeParse('short').isOk, isFalse);
        expect(schema.safeParse('not-an-email').isOk, isFalse);
      });

      test('should chain numeric constraints fluently', () {
        final schema = Ack.integer()
            .min(0)
            .max(100)
            .positive()
            .withDescription('Percentage value');

        expect(schema.safeParse(50).isOk, isTrue);
        expect(schema.safeParse(0).isOk, isFalse); // not positive
        expect(schema.safeParse(-5).isOk, isFalse);
        expect(schema.safeParse(150).isOk, isFalse);
      });

      test('should chain list constraints fluently', () {
        final schema = Ack.list(Ack.string().minLength(1))
            .minItems(1)
            .maxItems(10)
            .unique()
            .withDescription('List of unique non-empty strings');

        expect(schema.safeParse(['a', 'b', 'c']).isOk, isTrue);
        expect(schema.safeParse([]).isOk, isFalse); // too short
        expect(schema.safeParse(['a', 'b', 'a']).isOk, isFalse); // not unique
        expect(
          schema.safeParse(['a', '']).isOk,
          isFalse,
        ); // contains empty string
      });
    });

    group('Performance and Scalability Tests', () {
      test('should handle large objects efficiently', () {
        final largeObjectSchema = Ack.object(
          Map.fromEntries(
            List.generate(50, (i) => MapEntry('field$i', Ack.string())),
          ),
        );

        final largeObject = Map.fromEntries(
          List.generate(50, (i) => MapEntry('field$i', 'value$i')),
        );

        expect(largeObjectSchema.safeParse(largeObject).isOk, isTrue);
      });

      test('should handle deeply nested schemas', () {
        AckSchema createNestedSchema(int depth) {
          if (depth <= 0) {
            return Ack.string();
          }
          return Ack.object({
            'level': Ack.integer(),
            'nested': createNestedSchema(depth - 1),
          });
        }

        final deepSchema = createNestedSchema(5);

        dynamic createNestedData(int depth) {
          if (depth <= 0) {
            return 'leaf';
          }
          return {'level': depth, 'nested': createNestedData(depth - 1)};
        }

        final deepData = createNestedData(5);
        expect(deepSchema.safeParse(deepData).isOk, isTrue);
      });
    });
  });
}
