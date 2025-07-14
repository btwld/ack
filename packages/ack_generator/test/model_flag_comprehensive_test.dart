import 'package:ack_generator/src/generator.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  group('Model Flag Comprehensive Analysis', () {
    group('Basic Functionality', () {
      test('model: false should generate standalone schema file', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class BasicModel {
  final String name;
  BasicModel({required this.name});
}
''';

        await expectGeneratedOutput(source, (result) {
          // Should generate schema variable only
          expect(result, contains('final basicModelSchema = Ack.object({'));
          expect(result, contains("'name': Ack.string()"));

          // Should NOT generate SchemaModel class
          expect(result, isNot(contains('class BasicModelSchemaModel')));
          expect(result, isNot(contains('extends SchemaModel')));

          // Should be standalone file with imports
          expect(result, contains('import \'package:ack/ack.dart\';'));
          expect(result, isNot(contains('part of')));
        });
      });

      test('model: true should generate both schema and SchemaModel', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(model: true)
class ModelClass {
  final String id;
  final int value;
  ModelClass({required this.id, required this.value});
}
''';

        await expectGeneratedOutput(source, (result) {
          // Should generate schema variable
          expect(result, contains('final modelClassSchema = Ack.object({'));
          expect(result, contains("'id': Ack.string()"));
          expect(result, contains("'value': Ack.integer()"));

          // Should generate SchemaModel class
          expect(
              result,
              contains(
                  'class ModelClassSchemaModel extends SchemaModel<ModelClass>'));
          expect(result, contains('factory ModelClassSchemaModel()'));
          expect(result, contains('static final _instance'));
          expect(result, contains('ObjectSchema get schema'));
          expect(result,
              contains('ModelClass createFromMap(Map<String, dynamic> map)'));

          // Should be part file
          expect(result, contains('part of'));
          expect(result, isNot(contains('import \'package:ack/ack.dart\';')));
        });
      });
    });

    group('Complex Field Types', () {
      test('should handle List fields correctly', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(model: true)
class ListModel {
  final String id;
  final List<String> tags;
  final List<int>? scores;
  
  ListModel({required this.id, required this.tags, this.scores});
}
''';

        await expectGeneratedOutput(source, (result) {
          // Schema should handle lists
          expect(result, contains('Ack.list(Ack.string())'));
          expect(result,
              contains('Ack.list(Ack.integer()).optional().nullable()'));

          // createFromMap should handle list casts
          expect(result, contains('(map[\'tags\'] as List).cast<String>()'));
          expect(result, contains('(map[\'scores\'] as List?)?.cast<int>()'));
        });
      });

      test('should handle Map fields correctly', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(model: true)
class MapModel {
  final String id;
  final Map<String, dynamic> metadata;
  final Map<String, String>? labels;
  
  MapModel({required this.id, required this.metadata, this.labels});
}
''';

        await expectGeneratedOutput(source, (result) {
          // Schema should handle maps with additionalProperties
          expect(
              result, contains('Ack.object({}, additionalProperties: true)'));

          // createFromMap should handle map casts
          expect(result, contains('map[\'metadata\'] as Map<String, dynamic>'));
          expect(result, contains('map[\'labels\'] as Map<String, String>?'));
        });
      });

      test('should handle enum fields correctly', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

enum Status { active, inactive, pending }

@AckModel(model: true)
class EnumModel {
  final String id;
  final Status status;
  final Status? optionalStatus;
  
  EnumModel({required this.id, required this.status, this.optionalStatus});
}
''';

        await expectGeneratedOutput(source, (result) {
          // Schema should handle enums as string with enumString constraint
          expect(
              result,
              contains(
                  'Ack.string().enumString([\'active\', \'inactive\', \'pending\'])'));

          // createFromMap should handle enum parsing
          expect(result,
              contains('Status.values.byName(map[\'status\'] as String)'));
        });
      });
    });

    group('Nested Models and Dependencies', () {
      test('should handle nested model references', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(model: true)
class Address {
  final String street;
  final String city;
  Address({required this.street, required this.city});
}

@AckModel(model: true)
class Person {
  final String name;
  final Address address;
  final Address? billingAddress;
  
  Person({required this.name, required this.address, this.billingAddress});
}
''';

        await expectGeneratedOutput(source, (result) {
          // Should generate schemas in dependency order
          final addressSchemaPos = result.indexOf('final addressSchema');
          final personSchemaPos = result.indexOf('final personSchema');
          expect(addressSchemaPos, lessThan(personSchemaPos));

          // Person schema should reference address schema
          expect(result, contains("'address': addressSchema"));
          expect(
              result,
              contains(
                  "'billingAddress': addressSchema.optional().nullable()"));

          // createFromMap should use nested SchemaModel
          expect(
              result, contains('AddressSchemaModel._instance.createFromMap('));
          expect(result, contains('map[\'address\'] as Map<String, dynamic>'));
        });
      });

      test('should handle list of nested models', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(model: true)
class Item {
  final String name;
  final double price;
  Item({required this.name, required this.price});
}

@AckModel(model: true)
class Order {
  final String id;
  final List<Item> items;
  
  Order({required this.id, required this.items});
}
''';

        await expectGeneratedOutput(source, (result) {
          // Schema should handle list of schemas
          expect(result, contains('Ack.list(itemSchema)'));

          // createFromMap should handle list of nested models
          expect(result, contains('(map[\'items\'] as List)'));
          expect(result, contains('ItemSchemaModel._instance.createFromMap'));
        });
      });
    });

    group('Advanced Features', () {
      test('should handle additional properties correctly', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(
  model: true,
  additionalProperties: true,
  additionalPropertiesField: 'extras',
)
class FlexibleModel {
  final String id;
  final String name;
  final Map<String, dynamic> extras;
  
  FlexibleModel({required this.id, required this.name, this.extras = const {}});
}
''';

        await expectGeneratedOutput(source, (result) {
          // Schema should include additionalProperties
          expect(result, contains('additionalProperties: true'));

          // createFromMap should extract additional properties
          expect(result,
              contains('extractAdditionalProperties(map, {\'id\', \'name\'})'));
        });
      });

      test('should handle custom schema names', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(
  schemaName: 'CustomUserSchema',
  model: true,
)
class User {
  final String name;
  User({required this.name});
}
''';

        await expectGeneratedOutput(source, (result) {
          // Should use custom schema name
          expect(result, contains('final customUserSchema = Ack.object({'));

          // SchemaModel should reference custom schema
          expect(result, contains('return customUserSchema;'));
        });
      });

      test('should handle field descriptions', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(
  description: 'A user model with descriptions',
  model: true,
)
class DocumentedUser {
  @AckField(description: 'Unique user identifier')
  final String id;
  
  @AckField(description: 'User display name')
  final String name;
  
  DocumentedUser({required this.id, required this.name});
}
''';

        await expectGeneratedOutput(source, (result) {
          // Should include class description
          expect(result, contains('/// A user model with descriptions'));

          // Should include field descriptions as comments
          expect(result, contains('// Unique user identifier'));
          expect(result, contains('// User display name'));
        });
      });
    });

    group('Edge Cases and Error Scenarios', () {
      test('should handle empty models', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(model: true)
class EmptyModel {
  EmptyModel();
}
''';

        await expectGeneratedOutput(source, (result) {
          // Should generate empty object schema
          expect(result, contains('Ack.object({'));
          expect(result, contains('});'));

          // createFromMap should work with no parameters
          expect(result, contains('return EmptyModel('));
          expect(result, contains(');'));
        });
      });

      test('should handle single field models', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(model: true)
class SingleFieldModel {
  final String value;
  SingleFieldModel({required this.value});
}
''';

        await expectGeneratedOutput(source, (result) {
          expect(result, contains("'value': Ack.string()"));
          expect(result, contains('value: map[\'value\'] as String'));
        });
      });

      test('should handle models with only nullable fields', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(model: true)
class AllNullableModel {
  final String? name;
  final int? age;
  final bool? active;
  
  AllNullableModel({this.name, this.age, this.active});
}
''';

        await expectGeneratedOutput(source, (result) {
          // All fields should be optional and nullable
          expect(result, contains('Ack.string().optional().nullable()'));
          expect(result, contains('Ack.integer().optional().nullable()'));
          expect(result, contains('Ack.boolean().optional().nullable()'));

          // All casts should be nullable
          expect(result, contains('as String?'));
          expect(result, contains('as int?'));
          expect(result, contains('as bool?'));
        });
      });
    });

    group('Code Generation Best Practices', () {
      test('should generate thread-safe singleton pattern', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(model: true)
class ThreadSafeModel {
  final String id;
  ThreadSafeModel({required this.id});
}
''';

        await expectGeneratedOutput(source, (result) {
          // Should use proper singleton pattern
          expect(result, contains('ThreadSafeModelSchemaModel._();'));
          expect(result, contains('factory ThreadSafeModelSchemaModel()'));
          expect(
              result,
              contains(
                  'static final _instance = ThreadSafeModelSchemaModel._();'));
          expect(result, contains('return _instance;'));
        });
      });

      test('should generate proper dartdoc comments', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(
  description: 'A well-documented model class',
  model: true,
)
class DocumentedModel {
  final String name;
  DocumentedModel({required this.name});
}
''';

        await expectGeneratedOutput(source, (result) {
          // Should have proper dartdoc format
          expect(result, contains('/// Generated schema for DocumentedModel'));
          expect(result, contains('/// A well-documented model class'));
          expect(result,
              contains('/// Generated SchemaModel for [DocumentedModel].'));
        });
      });

      test('should maintain consistent naming conventions', () async {
        final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(model: true)
class MySpecialModel {
  final String specialValue;
  MySpecialModel({required this.specialValue});
}
''';

        await expectGeneratedOutput(source, (result) {
          // Schema variable should be camelCase
          expect(result, contains('final mySpecialModelSchema'));

          // Class name should be PascalCase with suffix
          expect(result, contains('class MySpecialModelSchemaModel'));

          // Method names should be camelCase
          expect(result, contains('get schema'));
          expect(result, contains('createFromMap('));
        });
      });
    });
  });
}

// Helper function to test code generation
Future<void> expectGeneratedOutput(
    String source, void Function(String) verifyOutput) async {
  final generator = AckSchemaGenerator();
  String? capturedOutput;

  await testBuilder(
    LibraryBuilder(generator, generatedExtension: '.g.dart'),
    {
      'ack_annotations|lib/ack_annotations.dart': '''
export 'src/ack_model.dart';
export 'src/ack_field.dart';
''',
      'ack_annotations|lib/src/ack_model.dart': '''
class AckModel {
  final String? schemaName;
  final String? description;
  final bool additionalProperties;
  final String? additionalPropertiesField;
  final bool model;
  final String? discriminatedKey;
  final String? discriminatedValue;

  const AckModel({
    this.schemaName,
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.model = false,
    this.discriminatedKey,
    this.discriminatedValue,
  });
}
''',
      'ack_annotations|lib/src/ack_field.dart': '''
class AckField {
  final bool required;
  final String? jsonKey;
  final String? description;
  final List<String> constraints;
  
  const AckField({
    this.required = false,
    this.jsonKey,
    this.description,
    this.constraints = const [],
  });
}
''',
      'test_pkg|lib/test.dart': source,
    },
    outputs: {
      'test_pkg|lib/test.g.dart': decodedMatches((dynamic content) {
        capturedOutput = content as String;
        return true;
      }),
    },
  );

  if (capturedOutput != null) {
    verifyOutput(capturedOutput!);
  } else {
    fail('No output was generated');
  }
}
