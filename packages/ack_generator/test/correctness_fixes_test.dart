import 'package:ack_generator/builder.dart';
import 'package:ack_generator/src/generator.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

/// Comprehensive tests for the generator fixes implemented in the plan.
void main() {
  group('Phase 1: Extension type redesign', () {
    test('primitive schemas generate extension types alongside object schemas', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

// Primitive schemas - should generate extension types
@AckType()
final stringSchema = Ack.string().minLength(5);

@AckType()
final intSchema = Ack.integer().min(0);

// Object schema - SHOULD generate extension type
@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              // Primitives SHOULD have extension types
              contains('extension type StringType(String _value)'),
              contains('extension type IntType(int _value)'),
              // Object types SHOULD have extension types
              contains('extension type UserType(Map<String, Object?> _data)'),
              contains('String get name'),
              contains('int get age'),
            ]),
          ),
        },
      );
    });
  });

  group('Phase 2: Enum schema generation', () {
    test('enum fields generate Ack.enumValues<T>(T.values)', () async {
      final builder = SharedPartBuilder([AckSchemaGenerator()], 'ack');

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

enum Status { active, inactive, pending }

@AckModel()
class User {
  final String name;
  final Status status;
  User(this.name, this.status);
}
''',
        },
        outputs: {
          'test_pkg|lib/schema.ack.g.part': decodedMatches(
            allOf([
              contains('Ack.enumValues<Status>(Status.values)'),
              isNot(contains("enumString(['active'")),
            ]),
          ),
        },
      );
    });
  });

  group('Phase 2: Nullable and optional getters', () {
    test('optional fields generate nullable getters', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final personSchema = Ack.object({
  'name': Ack.string(),
  'nickname': Ack.string().optional(),
  'email': Ack.string().nullable(),
  'phone': Ack.string().optional().nullable(),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              // Required non-nullable: String
              contains('String get name'),
              // Optional (non-nullable base): String?
              contains('String? get nickname'),
              // Required nullable: String?
              contains('String? get email'),
              // Optional nullable: String?
              contains('String? get phone'),
            ]),
          ),
        },
      );
    });

    test('optional generic fields avoid double-nullable getters', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
@AckType()
class Box<T> {
  final T? payload;
  Box({this.payload});
}
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('Object? get payload'),
              isNot(contains('Object?? get payload')),
            ]),
          ),
        },
      );
    });
  });

  group('Phase 2: Special type conversions', () {
    test('DateTime, Uri, Duration getters convert from raw data', () async {
      final builder = SharedPartBuilder([AckSchemaGenerator()], 'ack');

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
@AckType()
class Event {
  final DateTime timestamp;
  final Uri url;
  final Duration duration;
  Event(this.timestamp, this.url, this.duration);
}
''',
        },
        outputs: {
          'test_pkg|lib/schema.ack.g.part': decodedMatches(
            allOf([
              // DateTime conversion
              contains("DateTime.parse(_data['timestamp'] as String)"),
              // Uri conversion
              contains("Uri.parse(_data['url'] as String)"),
              // Duration conversion
              contains("Duration(milliseconds: _data['duration'] as int)"),
            ]),
          ),
        },
      );
    });

    test('nullable special types have null checks', () async {
      final builder = SharedPartBuilder([AckSchemaGenerator()], 'ack');

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
@AckType()
class OptionalDates {
  final DateTime? optionalDate;
  OptionalDates({this.optionalDate});
}
''',
        },
        outputs: {
          'test_pkg|lib/schema.ack.g.part': decodedMatches(
            allOf([
              contains("_data['optionalDate'] != null"),
              contains('DateTime.parse'),
            ]),
          ),
        },
      );
    });
  });

  group('Phase 2: Discriminated types', () {
    test('subtype schemas do not have duplicate discriminator keys', () async {
      final builder = SharedPartBuilder([AckSchemaGenerator()], 'ack');

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(discriminatedKey: 'type')
abstract class Shape {
  String get type;
}

@AckModel(discriminatedValue: 'circle')
@AckType()
class Circle extends Shape {
  @override
  String get type => 'circle';
  final double radius;
  Circle(this.radius);
}
''',
        },
        outputs: {
          'test_pkg|lib/schema.ack.g.part': decodedMatches(
            allOf([
              // The discriminator key should only appear once in the schema
              // Count occurrences of 'type' as a key
              predicate<String>((content) {
                // Extract the circleSchema definition
                final schemaMatch = RegExp(
                  r'final circleSchema = Ack\.object\(\{([^}]+)\}\)',
                  dotAll: true,
                ).firstMatch(content);
                if (schemaMatch == null) return false;

                final schemaBody = schemaMatch.group(1)!;
                // Count 'type' key occurrences - should be exactly 1
                final typeKeyCount =
                    RegExp(r"'type'\s*:").allMatches(schemaBody).length;
                return typeKeyCount == 1;
              }, 'discriminator key appears exactly once in schema'),
            ]),
          ),
        },
      );
    });

    test('discriminated base uses custom schemaName from subtypes', () async {
      final builder = SharedPartBuilder([AckSchemaGenerator()], 'ack');

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(discriminatedKey: 'kind')
abstract class Animal {
  String get kind;
}

@AckModel(discriminatedValue: 'cat', schemaName: 'CatDataSchema')
@AckType()
class Cat extends Animal {
  @override
  String get kind => 'cat';
  final String name;
  Cat(this.name);
}

@AckModel(discriminatedValue: 'dog', schemaName: 'DogInfoSchema')
@AckType()
class Dog extends Animal {
  @override
  String get kind => 'dog';
  final String breed;
  Dog(this.breed);
}
''',
        },
        outputs: {
          'test_pkg|lib/schema.ack.g.part': decodedMatches(
            allOf([
              // Base class discriminated schema should use custom names
              contains('animalSchema = Ack.discriminated('),
              // Should reference custom schema names, not default names
              contains("'cat': catDataSchema"),
              contains("'dog': dogInfoSchema"),
              // Should NOT use default names
              isNot(contains("'cat': catSchema")),
              isNot(contains("'dog': dogSchema")),
            ]),
          ),
        },
      );
    });
  });

  group('Phase 3: String escaping', () {
    test('descriptions with special characters are properly escaped', () async {
      final builder = SharedPartBuilder([AckSchemaGenerator()], 'ack');

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': r'''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Quoted {
  @AckField(description: "Contains 'single quotes'")
  final String singleQuoted;

  @AckField(description: 'Contains "double quotes"')
  final String doubleQuoted;

  @AckField(description: 'Contains \\ backslash')
  final String backslash;

  Quoted(this.singleQuoted, this.doubleQuoted, this.backslash);
}
''',
        },
        outputs: {
          'test_pkg|lib/schema.ack.g.part': decodedMatches(
            allOf([
              // Schema should be generated
              contains('quotedSchema'),
              // Single quotes should be escaped with backslash
              contains(r"Contains \'single quotes\'"),
              // Double quotes don't need escaping in single-quoted strings
              contains('Contains "double quotes"'),
              // Backslashes should be escaped
              contains(r'Contains \\ backslash'),
              // No raw strings needed with proper escaping
              isNot(contains("'''")),
            ]),
          ),
        },
      );
    });
  });

  group('Phase 4: Nested list schema-variable', () {
    test('Ack.list(schemaRef) resolves to List<T> with proper types', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final addressSchema = Ack.object({
  'street': Ack.string(),
  'city': Ack.string(),
});

@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'addresses': Ack.list(addressSchema),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              // Address type should be generated
              contains('extension type AddressType'),
              // User type should be generated
              contains('extension type UserType'),
            ]),
          ),
        },
      );
    });
  });

  group('Topological sort', () {
    test('cyclic dependencies do not throw', () async {
      final builder = SharedPartBuilder([AckSchemaGenerator()], 'ack');

      // This should not throw due to the cycle
      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
@AckType()
class Node {
  final String value;
  final Node? next; // Self-reference creates a cycle
  Node(this.value, {this.next});
}
''',
        },
        outputs: {
          'test_pkg|lib/schema.ack.g.part': decodedMatches(
            allOf([
              contains('final nodeSchema'),
              contains('extension type NodeType'),
            ]),
          ),
        },
      );
    });
  });

  group('Code review fixes', () {
    test('descriptions with dollar signs are properly escaped', () async {
      final builder = SharedPartBuilder([AckSchemaGenerator()], 'ack');

      await testBuilder(
        builder,
        {
          ...allAssets,
          // Dollar sign in description - tests escaping
          // Using explicit string concatenation to avoid Dart interpreting the $
          'test_pkg|lib/schema.dart': "import 'package:ack_annotations/ack_annotations.dart';\n"
              '\n'
              '@AckModel()\n'
              'class Price {\n'
              "  @AckField(description: 'Price is \\\$100 USD')\n"
              '  final int amount;\n'
              '\n'
              '  Price(this.amount);\n'
              '}\n',
        },
        outputs: {
          'test_pkg|lib/schema.ack.g.part': decodedMatches(
            allOf([
              // Dollar signs should be escaped to prevent interpolation
              contains(r'Price is \$100 USD'),
              // Schema should be generated successfully
              contains('priceSchema'),
            ]),
          ),
        },
      );
    });

    test('regex patterns with single quotes are handled', () async {
      final builder = SharedPartBuilder([AckSchemaGenerator()], 'ack');

      // Pattern containing single quotes - tests the safe quoting mechanism
      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Document {
  @AckField(constraints: ["matches(test'pattern)"])
  final String content;

  Document(this.content);
}
''',
        },
        outputs: {
          'test_pkg|lib/schema.ack.g.part': decodedMatches(
            allOf([
              // Schema should be generated
              contains('documentSchema'),
              // Pattern should use safe quoting
              contains('.matches('),
            ]),
          ),
        },
      );
    });

    test('discriminated subtype getter reads from _data', () async {
      // Use ackGenerator which generates both schemas and extension types
      // Both base class and subtype need @AckType() to be in sortedModels
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(discriminatedKey: 'kind')
@AckType()
abstract class Animal {
  String get kind;
}

@AckModel(discriminatedValue: 'dog')
@AckType()
class Dog extends Animal {
  @override
  String get kind => 'dog';
  final String breed;
  Dog(this.breed);
}
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              // Subtype getter should read from _data, not return hardcoded literal
              contains("_data['kind'] as String"),
              // Should have the discriminator value in schema
              contains("'dog'"),
              // Extension type should be generated for the subtype
              contains('extension type DogType'),
            ]),
          ),
        },
      );
    });
  });
}
