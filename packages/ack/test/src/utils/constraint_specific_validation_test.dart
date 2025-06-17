import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Constraint-Specific Validation Tests', () {
    late Directory tempDir;

    setUpAll(() async {
      await _ensureNodeDependencies();
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ack_constraint_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('String Format Validators', () {
      test('email format constraint generates valid JSON Schema', () async {
        final schema = Ack.object({'email': Ack.string.email()});
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'email-format', tempDir);

        // Verify email format is correctly applied
        final emailProp = _getProperty(jsonSchema, 'email');
        expect(emailProp['format'], equals('email'));
        expect(emailProp['type'], equals('string'));
      });

      test('uuid format constraint generates valid JSON Schema', () async {
        final schema = Ack.object({'id': Ack.string.uuid()});
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'uuid-format', tempDir);

        final idProp = _getProperty(jsonSchema, 'id');
        expect(idProp['format'], equals('uuid'));
      });

      test('dateTime format constraint generates valid JSON Schema', () async {
        final schema = Ack.object({'timestamp': Ack.string.dateTime()});
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'datetime-format', tempDir);

        final timestampProp = _getProperty(jsonSchema, 'timestamp');
        expect(timestampProp['format'], equals('date-time'));
      });

      test('uri format constraint generates valid JSON Schema', () async {
        final schema = Ack.object({'url': Ack.string.uri()});
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'uri-format', tempDir);

        final urlProp = _getProperty(jsonSchema, 'url');
        expect(urlProp['format'], equals('uri'));
      });

      test('multiple format constraints in single schema', () async {
        final schema = Ack.object({
          'email': Ack.string.email(),
          'id': Ack.string.uuid(),
          'created': Ack.string.dateTime(),
          'website': Ack.string.uri().nullable(),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'multiple-formats', tempDir);

        expect(_getProperty(jsonSchema, 'email')['format'], equals('email'));
        expect(_getProperty(jsonSchema, 'id')['format'], equals('uuid'));
        expect(
            _getProperty(jsonSchema, 'created')['format'], equals('date-time'));
        expect(_getProperty(jsonSchema, 'website')['format'], equals('uri'));
      });
    });

    group('String Length Constraints', () {
      test('minLength constraint generates valid JSON Schema', () async {
        final schema = Ack.object({'name': Ack.string.minLength(2)});
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'min-length', tempDir);

        final nameProp = _getProperty(jsonSchema, 'name');
        expect(nameProp['minLength'], equals(2));
      });

      test('maxLength constraint generates valid JSON Schema', () async {
        final schema = Ack.object({'description': Ack.string.maxLength(500)});
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'max-length', tempDir);

        final descProp = _getProperty(jsonSchema, 'description');
        expect(descProp['maxLength'], equals(500));
      });

      test('combined minLength and maxLength constraints', () async {
        final schema =
            Ack.object({'username': Ack.string.minLength(3).maxLength(20)});
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'min-max-length', tempDir);

        final usernameProp = _getProperty(jsonSchema, 'username');
        expect(usernameProp['minLength'], equals(3));
        expect(usernameProp['maxLength'], equals(20));
      });

      test('length constraints with format validators', () async {
        final schema = Ack.object({
          'email': Ack.string.email().maxLength(100),
          'bio': Ack.string.minLength(10).maxLength(500),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'length-with-format', tempDir);

        final emailProp = _getProperty(jsonSchema, 'email');
        expect(emailProp['format'], equals('email'));
        expect(emailProp['maxLength'], equals(100));

        final bioProp = _getProperty(jsonSchema, 'bio');
        expect(bioProp['minLength'], equals(10));
        expect(bioProp['maxLength'], equals(500));
      });
    });

    group('String Pattern Constraints', () {
      test('regex pattern constraint generates valid JSON Schema', () async {
        final schema =
            Ack.object({'code': Ack.string.matches(r'^[A-Z]{3}-\d{3}$')});
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'regex-pattern', tempDir);

        final codeProp = _getProperty(jsonSchema, 'code');
        expect(codeProp['pattern'], equals(r'^[A-Z]{3}-\d{3}$'));
      });

      test('complex regex patterns', () async {
        final schema = Ack.object({
          'phone': Ack.string.matches(r'^\+?[\d\s\-\(\)]+$'),
          'slug': Ack.string.matches(r'^[a-z0-9]+(?:-[a-z0-9]+)*$'),
          'version': Ack.string.matches(r'^\d+\.\d+\.\d+$'),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'complex-patterns', tempDir);

        expect(_getProperty(jsonSchema, 'phone')['pattern'],
            equals(r'^\+?[\d\s\-\(\)]+$'));
        expect(_getProperty(jsonSchema, 'slug')['pattern'],
            equals(r'^[a-z0-9]+(?:-[a-z0-9]+)*$'));
        expect(_getProperty(jsonSchema, 'version')['pattern'],
            equals(r'^\d+\.\d+\.\d+$'));
      });

      test('pattern with length constraints', () async {
        final schema = Ack.object({
          'productCode':
              Ack.string.matches(r'^[A-Z0-9]+$').minLength(5).maxLength(10),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'pattern-with-length', tempDir);

        final productProp = _getProperty(jsonSchema, 'productCode');
        expect(productProp['pattern'], equals(r'^[A-Z0-9]+$'));
        expect(productProp['minLength'], equals(5));
        expect(productProp['maxLength'], equals(10));
      });
    });

    group('String Enum Constraints', () {
      test('enum values constraint generates valid JSON Schema', () async {
        final schema = Ack.object({
          'status': Ack.string.enumValues(['active', 'inactive', 'pending'])
        });
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'enum-values', tempDir);

        final statusProp = _getProperty(jsonSchema, 'status');
        expect(statusProp['enum'], equals(['active', 'inactive', 'pending']));
      });

      test('multiple enum properties', () async {
        final schema = Ack.object({
          'role': Ack.string.enumValues(['admin', 'user', 'guest']),
          'priority':
              Ack.string.enumValues(['low', 'medium', 'high', 'critical']),
          'category': Ack.string.enumValues(['bug', 'feature', 'improvement']),
        });
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'multiple-enums', tempDir);

        expect(_getProperty(jsonSchema, 'role')['enum'],
            equals(['admin', 'user', 'guest']));
        expect(_getProperty(jsonSchema, 'priority')['enum'],
            equals(['low', 'medium', 'high', 'critical']));
        expect(_getProperty(jsonSchema, 'category')['enum'],
            equals(['bug', 'feature', 'improvement']));
      });

      test('literal string constraint generates valid JSON Schema', () async {
        final schema = Ack.object({'type': Ack.string.literal('user')});
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'literal-string', tempDir);

        final typeProp = _getProperty(jsonSchema, 'type');
        expect(typeProp['enum'], equals(['user']));
      });
    });

    group('Nullable String Constraints', () {
      test('nullable string generates correct type array', () async {
        final schema = Ack.object({'description': Ack.string.nullable()});
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'nullable-string', tempDir);

        final descProp = _getProperty(jsonSchema, 'description');
        expect(descProp['type'], equals(['string', 'null']));
      });

      test('nullable string with constraints', () async {
        final schema = Ack.object({
          'bio': Ack.string.maxLength(500).nullable(),
          'website': Ack.string.uri().nullable(),
          'nickname': Ack.string.minLength(2).maxLength(20).nullable(),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'nullable-with-constraints', tempDir);

        final bioProp = _getProperty(jsonSchema, 'bio');
        expect(bioProp['type'], equals(['string', 'null']));
        expect(bioProp['maxLength'], equals(500));

        final websiteProp = _getProperty(jsonSchema, 'website');
        expect(websiteProp['type'], equals(['string', 'null']));
        expect(websiteProp['format'], equals('uri'));

        final nicknameProp = _getProperty(jsonSchema, 'nickname');
        expect(nicknameProp['type'], equals(['string', 'null']));
        expect(nicknameProp['minLength'], equals(2));
        expect(nicknameProp['maxLength'], equals(20));
      });
    });

    group('Numeric Constraints', () {
      test('integer minimum constraint generates valid JSON Schema', () async {
        final schema = Ack.object({'age': Ack.int.min(0)});
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'int-minimum', tempDir);

        final ageProp = _getProperty(jsonSchema, 'age');
        expect(ageProp['minimum'], equals(0));
        expect(ageProp['type'], equals('integer'));
      });

      test('integer maximum constraint generates valid JSON Schema', () async {
        final schema = Ack.object({'score': Ack.int.max(100)});
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'int-maximum', tempDir);

        final scoreProp = _getProperty(jsonSchema, 'score');
        expect(scoreProp['maximum'], equals(100));
      });

      test('integer min/max range constraints', () async {
        final schema = Ack.object({'percentage': Ack.int.min(0).max(100)});
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'int-range', tempDir);

        final percentageProp = _getProperty(jsonSchema, 'percentage');
        expect(percentageProp['minimum'], equals(0));
        expect(percentageProp['maximum'], equals(100));
      });

      test('integer multipleOf constraint generates valid JSON Schema',
          () async {
        final schema = Ack.object({'evenNumber': Ack.int.multipleOf(2)});
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'int-multiple-of', tempDir);

        final evenProp = _getProperty(jsonSchema, 'evenNumber');
        expect(evenProp['multipleOf'], equals(2));
      });

      test('double minimum and maximum constraints', () async {
        final schema = Ack.object({
          'price': Ack.double.min(0.01).max(999.99),
          'rating': Ack.double.min(0.0).max(5.0),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'double-constraints', tempDir);

        final priceProp = _getProperty(jsonSchema, 'price');
        expect(priceProp['minimum'], equals(0.01));
        expect(priceProp['maximum'], equals(999.99));
        expect(priceProp['type'], equals('number'));

        final ratingProp = _getProperty(jsonSchema, 'rating');
        expect(ratingProp['minimum'], equals(0.0));
        expect(ratingProp['maximum'], equals(5.0));
      });

      test('double multipleOf constraint', () async {
        final schema = Ack.object({'increment': Ack.double.multipleOf(0.25)});
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'double-multiple-of', tempDir);

        final incrementProp = _getProperty(jsonSchema, 'increment');
        expect(incrementProp['multipleOf'], equals(0.25));
      });

      test('nullable numeric constraints', () async {
        final schema = Ack.object({
          'optionalAge': Ack.int.min(0).max(150).nullable(),
          'optionalPrice': Ack.double.min(0.0).nullable(),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'nullable-numeric', tempDir);

        final ageProp = _getProperty(jsonSchema, 'optionalAge');
        expect(ageProp['type'], equals(['integer', 'null']));
        expect(ageProp['minimum'], equals(0));
        expect(ageProp['maximum'], equals(150));

        final priceProp = _getProperty(jsonSchema, 'optionalPrice');
        expect(priceProp['type'], equals(['number', 'null']));
        expect(priceProp['minimum'], equals(0.0));
      });
    });

    group('Array Constraints', () {
      test('basic array constraint generates valid JSON Schema', () async {
        final schema = Ack.object({'tags': Ack.list(Ack.string)});
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'basic-array', tempDir);

        final tagsProp = _getProperty(jsonSchema, 'tags');
        expect(tagsProp['type'], equals('array'));
        expect(tagsProp['items']['type'], equals('string'));
      });

      test('array minItems constraint', () async {
        final schema =
            Ack.object({'categories': Ack.list(Ack.string).minItems(1)});
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'array-min-items', tempDir);

        final categoriesProp = _getProperty(jsonSchema, 'categories');
        expect(categoriesProp['minItems'], equals(1));
      });

      test('array maxItems constraint', () async {
        final schema =
            Ack.object({'keywords': Ack.list(Ack.string).maxItems(10)});
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'array-max-items', tempDir);

        final keywordsProp = _getProperty(jsonSchema, 'keywords');
        expect(keywordsProp['maxItems'], equals(10));
      });

      test('array minItems and maxItems constraints', () async {
        final schema =
            Ack.object({'items': Ack.list(Ack.string).minItems(2).maxItems(5)});
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'array-min-max-items', tempDir);

        final itemsProp = _getProperty(jsonSchema, 'items');
        expect(itemsProp['minItems'], equals(2));
        expect(itemsProp['maxItems'], equals(5));
      });

      test('array uniqueItems constraint', () async {
        final schema =
            Ack.object({'uniqueTags': Ack.list(Ack.string).uniqueItems()});
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'array-unique-items', tempDir);

        final uniqueTagsProp = _getProperty(jsonSchema, 'uniqueTags');
        expect(uniqueTagsProp['uniqueItems'], equals(true));
      });

      test('array with complex item constraints', () async {
        final schema = Ack.object({
          'emails': Ack.list(Ack.string.email()).minItems(1).maxItems(3),
          'scores': Ack.list(Ack.int.min(0).max(100)).uniqueItems(),
          'urls': Ack.list(Ack.string.uri()).nullable(),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'array-complex-items', tempDir);

        final emailsProp = _getProperty(jsonSchema, 'emails');
        expect(emailsProp['items']['format'], equals('email'));
        expect(emailsProp['minItems'], equals(1));
        expect(emailsProp['maxItems'], equals(3));

        final scoresProp = _getProperty(jsonSchema, 'scores');
        expect(scoresProp['items']['minimum'], equals(0));
        expect(scoresProp['items']['maximum'], equals(100));
        expect(scoresProp['uniqueItems'], equals(true));

        final urlsProp = _getProperty(jsonSchema, 'urls');
        expect(urlsProp['type'], equals(['array', 'null']));
        expect(urlsProp['items']['format'], equals('uri'));
      });

      test('nested array constraints', () async {
        final schema = Ack.object({
          'matrix': Ack.list(Ack.list(Ack.int.min(0))).minItems(1),
        });
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'nested-arrays', tempDir);

        final matrixProp = _getProperty(jsonSchema, 'matrix');
        expect(matrixProp['type'], equals('array'));
        expect(matrixProp['minItems'], equals(1));
        expect(matrixProp['items']['type'], equals('array'));
        expect(matrixProp['items']['items']['type'], equals('integer'));
        expect(matrixProp['items']['items']['minimum'], equals(0));
      });
    });

    group('Object Constraints', () {
      test('object with required fields constraint', () async {
        final schema = Ack.object({
          'name': Ack.string,
          'email': Ack.string.email(),
          'age': Ack.int.nullable(),
        }, required: [
          'name',
          'email'
        ]);
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'object-required', tempDir);

        expect(jsonSchema['required'], equals(['name', 'email']));
        expect(jsonSchema['type'], equals('object'));
      });

      test('object with additionalProperties false', () async {
        final schema = Ack.object({
          'name': Ack.string,
        }, additionalProperties: false);
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'object-no-additional', tempDir);

        expect(jsonSchema['additionalProperties'], equals(false));
      });

      test('object with additionalProperties true', () async {
        final schema = Ack.object({
          'name': Ack.string,
        }, additionalProperties: true);
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'object-additional', tempDir);

        expect(jsonSchema['additionalProperties'], equals(true));
      });

      test('nested object constraints', () async {
        final schema = Ack.object({
          'user': Ack.object({
            'profile': Ack.object({
              'name': Ack.string.minLength(1),
              'bio': Ack.string.maxLength(500).nullable(),
            }, required: [
              'name'
            ], additionalProperties: false),
            'settings': Ack.object({
              'theme': Ack.string.enumValues(['light', 'dark']),
              'notifications': Ack.boolean,
            }, additionalProperties: false),
          }, required: [
            'profile'
          ], additionalProperties: false),
        }, required: [
          'user'
        ]);
        final jsonSchema =
            await _generateAndValidateSchema(schema, 'nested-objects', tempDir);

        expect(jsonSchema['required'], equals(['user']));
        expect(jsonSchema['additionalProperties'], equals(false));

        final userProp = _getProperty(jsonSchema, 'user');
        expect(userProp['required'], equals(['profile']));
        expect(userProp['additionalProperties'], equals(false));

        final profileProp =
            userProp['properties']['profile'] as Map<String, dynamic>;
        expect(profileProp['required'], equals(['name']));
        expect(profileProp['additionalProperties'], equals(false));
      });
    });

    group('Discriminated Union Constraints', () {
      test('basic discriminated union generates valid JSON Schema', () async {
        final schema = Ack.object({
          'content': Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {
              'text': Ack.object({
                'type': Ack.string.literal('text'),
                'value': Ack.string.minLength(1),
              }, required: [
                'type',
                'value'
              ]),
              'number': Ack.object({
                'type': Ack.string.literal('number'),
                'value': Ack.int,
              }, required: [
                'type',
                'value'
              ]),
            },
          ),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'basic-discriminated', tempDir);

        final contentProp = _getProperty(jsonSchema, 'content');
        expect(contentProp['allOf'], isNotNull);
        expect(contentProp['allOf'], isA<List>());

        final allOfList = contentProp['allOf'] as List;
        expect(allOfList.length, equals(2)); // One for each discriminated type

        // Verify if/then structure for discriminated unions
        for (final item in allOfList) {
          expect(item['if'], isNotNull);
          expect(item['then'], isNotNull);
        }
      });

      test('complex discriminated union with multiple constraints', () async {
        final schema = Ack.object({
          'media': Ack.discriminated(
            discriminatorKey: 'kind',
            schemas: {
              'image': Ack.object({
                'kind': Ack.string.literal('image'),
                'src': Ack.string.uri(),
                'alt': Ack.string.maxLength(200).nullable(),
                'dimensions': Ack.object({
                  'width': Ack.int.min(1),
                  'height': Ack.int.min(1),
                }),
              }, required: [
                'kind',
                'src',
                'dimensions'
              ]),
              'video': Ack.object({
                'kind': Ack.string.literal('video'),
                'src': Ack.string.uri(),
                'duration': Ack.int.min(1),
                'quality': Ack.string.enumValues(['720p', '1080p', '4k']),
              }, required: [
                'kind',
                'src',
                'duration'
              ]),
              'audio': Ack.object({
                'kind': Ack.string.literal('audio'),
                'src': Ack.string.uri(),
                'duration': Ack.int.min(1),
                'bitrate': Ack.int.min(64).max(320),
              }, required: [
                'kind',
                'src',
                'duration'
              ]),
            },
          ),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'complex-discriminated', tempDir);

        final mediaProp = _getProperty(jsonSchema, 'media');
        expect(mediaProp['allOf'], isNotNull);

        final allOfList = mediaProp['allOf'] as List;
        expect(allOfList.length, equals(3)); // One for each media type

        // Verify each discriminated type has proper constraints
        for (final item in allOfList) {
          final ifClause = item['if'] as Map<String, dynamic>;
          final thenClause = item['then'] as Map<String, dynamic>;

          expect(ifClause['properties']['kind']['const'], isNotNull);
          expect(thenClause['properties'], isNotNull);
          expect(thenClause['required'], isNotNull);
        }
      });

      test('nested discriminated unions', () async {
        final schema = Ack.object({
          'notification': Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {
              'email': Ack.object({
                'type': Ack.string.literal('email'),
                'recipient': Ack.string.email(),
                'content': Ack.discriminated(
                  discriminatorKey: 'format',
                  schemas: {
                    'plain': Ack.object({
                      'format': Ack.string.literal('plain'),
                      'text': Ack.string.minLength(1),
                    }, required: [
                      'format',
                      'text'
                    ]),
                    'html': Ack.object({
                      'format': Ack.string.literal('html'),
                      'html': Ack.string.minLength(1),
                      'css': Ack.string.nullable(),
                    }, required: [
                      'format',
                      'html'
                    ]),
                  },
                ),
              }, required: [
                'type',
                'recipient',
                'content'
              ]),
              'sms': Ack.object({
                'type': Ack.string.literal('sms'),
                'phone': Ack.string.matches(r'^\+?[\d\s\-\(\)]+$'),
                'message': Ack.string.minLength(1).maxLength(160),
              }, required: [
                'type',
                'phone',
                'message'
              ]),
            },
          ),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'nested-discriminated', tempDir);

        final notificationProp = _getProperty(jsonSchema, 'notification');
        expect(notificationProp['allOf'], isNotNull);

        // Verify the nested discriminated union structure
        final allOfList = notificationProp['allOf'] as List;
        expect(allOfList.length, equals(2)); // email and sms

        // Find the email branch and verify it has nested discriminated union
        final emailBranch = allOfList.firstWhere((item) {
          final ifClause = item['if'] as Map<String, dynamic>;
          return ifClause['properties']['type']['const'] == 'email';
        });

        final emailThen = emailBranch['then'] as Map<String, dynamic>;
        final contentProp =
            emailThen['properties']['content'] as Map<String, dynamic>;
        expect(contentProp['allOf'], isNotNull); // Nested discriminated union
      });
    });

    group('Constraint Combinations', () {
      test('string with multiple constraints combined', () async {
        final schema = Ack.object({
          'username':
              Ack.string.minLength(3).maxLength(20).matches(r'^[a-zA-Z0-9_]+$'),
          'email': Ack.string.email().maxLength(100),
          'website': Ack.string.uri().nullable(),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'string-combinations', tempDir);

        final usernameProp = _getProperty(jsonSchema, 'username');
        expect(usernameProp['minLength'], equals(3));
        expect(usernameProp['maxLength'], equals(20));
        expect(usernameProp['pattern'], equals(r'^[a-zA-Z0-9_]+$'));

        final emailProp = _getProperty(jsonSchema, 'email');
        expect(emailProp['format'], equals('email'));
        expect(emailProp['maxLength'], equals(100));

        final websiteProp = _getProperty(jsonSchema, 'website');
        expect(websiteProp['format'], equals('uri'));
        expect(websiteProp['type'], equals(['string', 'null']));
      });

      test('numeric with multiple constraints combined', () async {
        final schema = Ack.object({
          'percentage': Ack.int.min(0).max(100).multipleOf(5),
          'price': Ack.double.min(0.01).max(9999.99).multipleOf(0.01),
          'optionalRating': Ack.double.min(1.0).max(5.0).nullable(),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'numeric-combinations', tempDir);

        final percentageProp = _getProperty(jsonSchema, 'percentage');
        expect(percentageProp['minimum'], equals(0));
        expect(percentageProp['maximum'], equals(100));
        expect(percentageProp['multipleOf'], equals(5));

        final priceProp = _getProperty(jsonSchema, 'price');
        expect(priceProp['minimum'], equals(0.01));
        expect(priceProp['maximum'], equals(9999.99));
        expect(priceProp['multipleOf'], equals(0.01));

        final ratingProp = _getProperty(jsonSchema, 'optionalRating');
        expect(ratingProp['type'], equals(['number', 'null']));
        expect(ratingProp['minimum'], equals(1.0));
        expect(ratingProp['maximum'], equals(5.0));
      });

      test('array with multiple constraints combined', () async {
        final schema = Ack.object({
          'tags': Ack.list(Ack.string.minLength(1).maxLength(20))
              .minItems(1)
              .maxItems(10)
              .uniqueItems(),
          'scores': Ack.list(Ack.int.min(0).max(100))
              .minItems(3)
              .uniqueItems()
              .nullable(),
        });
        final jsonSchema = await _generateAndValidateSchema(
            schema, 'array-combinations', tempDir);

        final tagsProp = _getProperty(jsonSchema, 'tags');
        expect(tagsProp['minItems'], equals(1));
        expect(tagsProp['maxItems'], equals(10));
        expect(tagsProp['uniqueItems'], equals(true));
        expect(tagsProp['items']['minLength'], equals(1));
        expect(tagsProp['items']['maxLength'], equals(20));

        final scoresProp = _getProperty(jsonSchema, 'scores');
        expect(scoresProp['type'], equals(['array', 'null']));
        expect(scoresProp['minItems'], equals(3));
        expect(scoresProp['uniqueItems'], equals(true));
        expect(scoresProp['items']['minimum'], equals(0));
        expect(scoresProp['items']['maximum'], equals(100));
      });
    });
  });
}

/// Generate schema and validate with AJV, returning the JSON schema
Future<Map<String, dynamic>> _generateAndValidateSchema(
    ObjectSchema schema, String testName, Directory tempDir) async {
  final jsonSchema = JsonSchemaConverter(schema: schema).toSchema();

  final schemaFile = File(path.join(tempDir.path, '$testName.json'));
  await schemaFile.writeAsString(jsonEncode(jsonSchema));

  final result = await _runSchemaValidation(schemaFile.path);
  expect(result['valid'], isTrue,
      reason:
          'Schema $testName should be valid JSON Schema Draft-7. Errors: ${result['errors']}');

  return jsonSchema;
}

/// Get a property from the JSON schema
Map<String, dynamic> _getProperty(
    Map<String, dynamic> jsonSchema, String propertyName) {
  final properties = jsonSchema['properties'] as Map<String, dynamic>;
  return properties[propertyName] as Map<String, dynamic>;
}

/// Run AJV schema validation
Future<Map<String, dynamic>> _runSchemaValidation(String schemaPath) async {
  final projectRoot = _findProjectRoot();
  final validatorScript = path.join(projectRoot, 'tools', 'ajv-validator.js');

  final result = await Process.run(
    'node',
    [validatorScript, 'validate-schema', '--schema', schemaPath, '--json'],
    workingDirectory: projectRoot,
  );

  if (result.exitCode != 0) {
    throw Exception('AJV schema validation failed: ${result.stderr}');
  }

  final lines = result.stdout.toString().split('\n');
  final jsonLine = lines.firstWhere(
    (line) => line.trim().startsWith('{'),
    orElse: () => '{"valid": false, "errors": []}',
  );

  return jsonDecode(jsonLine);
}

/// Ensure Node.js dependencies are installed
Future<void> _ensureNodeDependencies() async {
  final projectRoot = _findProjectRoot();
  final toolsDir = path.join(projectRoot, 'tools');
  final nodeModulesDir = Directory(path.join(toolsDir, 'node_modules'));

  if (!await nodeModulesDir.exists()) {
    final result =
        await Process.run('npm', ['install'], workingDirectory: toolsDir);
    if (result.exitCode != 0) {
      throw Exception(
          'Failed to install Node.js dependencies: ${result.stderr}');
    }
  }
}

/// Find the project root directory
String _findProjectRoot() {
  var current = Directory.current;
  while (current.path != current.parent.path) {
    final melosFile = File(path.join(current.path, 'melos.yaml'));
    if (melosFile.existsSync()) {
      return current.path;
    }
    current = current.parent;
  }
  throw Exception('Could not find project root (melos.yaml not found)');
}
