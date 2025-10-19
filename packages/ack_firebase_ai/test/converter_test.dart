import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:test/test.dart';

void main() {
  group('FirebaseAiSchemaConverter - Primitives', () {
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

  group('FirebaseAiSchemaConverter - Objects', () {
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
  });

  group('FirebaseAiSchemaConverter - Arrays', () {
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
  });

  group('FirebaseAiSchemaConverter - Complex Scenarios', () {
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

  group('FirebaseAiSchemaConverter - Edge Cases', () {
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

    test('throws on TransformedSchema', () {
      final schema = Ack.string().transform((s) => s!.toUpperCase());

      expect(
        () => schema.toFirebaseAiSchema(),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
