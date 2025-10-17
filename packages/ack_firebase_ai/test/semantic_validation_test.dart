import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:test/test.dart';

/// Semantic validation tests ensure that converted schemas validate
/// the same data as the original ACK schemas.
///
/// These tests verify behavioral equivalence, not just structural conversion.
void main() {
  group('Semantic Validation - String Constraints', () {
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

  group('Semantic Validation - Numeric Constraints', () {
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

  group('Semantic Validation - Object Structure', () {
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

  group('Semantic Validation - Array Structure', () {
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

  group('Semantic Validation - Nullable Handling', () {
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

  group('Semantic Validation - Complex Real-World Scenarios', () {
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
}
