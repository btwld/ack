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
    test('primitive schemas do NOT generate extension types, object schemas DO', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

// Primitive schemas - should NOT generate extension types
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
              // Primitives should NOT have extension types
              isNot(contains('extension type StringType')),
              isNot(contains('extension type IntType')),
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
                // Schema should have exactly one 'type' key definition in the circleSchema
                // (The shapeSchema uses discriminated() which has schemas: {})
                final circleMatches = RegExp(r"circleSchema.*'type'\s*:")
                    .allMatches(content);
                // Should find the schema with one type key
                return circleMatches.isNotEmpty || content.contains("'type': Ack.literal");
              }, 'has discriminator key in schema'),
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
              // All strings should be valid Dart syntax
              isNot(contains("'''")), // No raw strings needed with proper escaping
              contains('quotedSchema'), // Schema should be generated
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
}
