import 'package:ack_generator/src/generator.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  group('Model Flag Generation', () {
    test('should generate only schema variable when model: false (default)',
        () async {
      final source = '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  final String id;
  final String name;
  
  User({required this.id, required this.name});
}
''';

      await expectGeneratedOutput(source, (result) {
        // Should generate schema variable
        expect(result, contains('final userSchema = Ack.object({'));
        expect(result, contains("'id': Ack.string()"));
        expect(result, contains("'name': Ack.string()"));

        // Should NOT generate SchemaModel class
        expect(result, isNot(contains('class UserSchemaModel')));
        expect(result, isNot(contains('extends SchemaModel<User>')));

        // Should generate standalone file with imports
        expect(result, contains('import \'package:ack/ack.dart\';'));
        expect(result, isNot(contains('part of')));
      });
    });

    test(
        'should generate both schema variable and SchemaModel when model: true',
        () async {
      final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(model: true)
class Product {
  final String id;
  final String name;
  final double price;
  
  Product({required this.id, required this.name, required this.price});
}
''';

      await expectGeneratedOutput(source, (result) {
        // Should generate schema variable
        expect(result, contains('final productSchema = Ack.object({'));
        expect(result, contains("'id': Ack.string()"));
        expect(result, contains("'name': Ack.string()"));
        expect(result, contains("'price': Ack.double()"));

        // Should also generate SchemaModel class
        expect(result,
            contains('class ProductSchemaModel extends SchemaModel<Product>'));
        expect(result, contains('factory ProductSchemaModel()'));
        expect(result, contains('ObjectSchema get schema'));
        expect(result, contains('createFromMap(Map<String, dynamic> map)'));

        // Should generate as part file
        expect(result, contains('part of'));
        expect(result, isNot(contains('import \'package:ack/ack.dart\';')));
      });
    });

    test('should handle additional properties with model: true', () async {
      final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(
  model: true,
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class FlexibleModel {
  final String id;
  final Map<String, dynamic> metadata;
  
  FlexibleModel({required this.id, this.metadata = const {}});
}
''';

      await expectGeneratedOutput(source, (result) {
        // Schema should have additionalProperties: true
        expect(result, contains('additionalProperties: true'));

        // SchemaModel should use extractAdditionalProperties
        expect(result,
            contains('metadata: extractAdditionalProperties(map, {\'id\'})'));
      });
    });

    test('should respect custom schema name with model flag', () async {
      final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(
  schemaName: 'CustomSchema',
  model: true,
)
class MyClass {
  final String value;
  
  MyClass({required this.value});
}
''';

      await expectGeneratedOutput(source, (result) {
        // Should use custom schema name
        expect(result, contains('final customSchema = Ack.object({'));

        // SchemaModel should reference the custom schema variable
        expect(result, contains('return customSchema;'));
      });
    });

    test('should handle nested models with model flag', () async {
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
  
  Person({required this.name, required this.address});
}
''';

      await expectGeneratedOutput(source, (result) {
        // Should generate both schema variables
        expect(result, contains('final addressSchema = Ack.object({'));
        expect(result, contains('final personSchema = Ack.object({'));

        // Person schema should reference address schema
        expect(result, contains("'address': addressSchema"));

        // SchemaModel should handle nested model
        expect(result, contains('AddressSchemaModel._instance.createFromMap('));
      });
    });

    test('should handle nullable fields correctly', () async {
      final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(model: true)
class OptionalFields {
  final String id;
  final String? description;
  final int? count;
  
  OptionalFields({required this.id, this.description, this.count});
}
''';

      await expectGeneratedOutput(source, (result) {
        // Schema should mark fields as optional and nullable
        expect(result, contains('Ack.string().optional().nullable()'));
        expect(result, contains('Ack.integer().optional().nullable()'));

        // createFromMap should handle nullable casts
        expect(result, contains('as String?'));
        expect(result, contains('as int?'));
      });
    });

    test(
        'should generate correct order: schema variables first, then SchemaModel classes',
        () async {
      final source = '''
import 'package:ack_annotations/ack_annotations.dart';

part 'test.g.dart';

@AckModel(model: true)
class First {
  final String id;
  First({required this.id});
}

@AckModel(model: true)
class Second {
  final First first;
  Second({required this.first});
}
''';

      await expectGeneratedOutput(source, (result) {
        // Find positions of generated elements
        final firstSchemaPos = result.indexOf('final firstSchema');
        final secondSchemaPos = result.indexOf('final secondSchema');
        final firstModelPos = result.indexOf('class FirstSchemaModel');
        final secondModelPos = result.indexOf('class SecondSchemaModel');

        // Schema variables should come before SchemaModel classes
        expect(firstSchemaPos, lessThan(firstModelPos));
        expect(secondSchemaPos, lessThan(secondModelPos));

        // Schema variables should be in order
        expect(firstSchemaPos, lessThan(secondSchemaPos));

        // SchemaModel classes should be in order
        expect(firstModelPos, lessThan(secondModelPos));
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
  }) : assert(
         discriminatedKey == null || discriminatedValue == null,
         'discriminatedKey and discriminatedValue cannot be used together',
       );
}
''',
      'ack|lib/ack.dart': '''
class Ack {
  static ObjectSchema object(Map<String, dynamic> fields, {bool additionalProperties = false}) => 
    ObjectSchema(fields, additionalProperties: additionalProperties);
  static StringSchema string() => StringSchema();
  static NumberSchema double() => NumberSchema();
  static NumberSchema integer() => NumberSchema();
}

class ObjectSchema {}
class StringSchema {
  StringSchema optional() => this;
  StringSchema nullable() => this;
}
class NumberSchema {
  NumberSchema optional() => this;
  NumberSchema nullable() => this;
}

abstract class SchemaModel<T> {
  ObjectSchema get schema;
  T createFromMap(Map<String, dynamic> map);
  Map<String, dynamic> extractAdditionalProperties(Map<String, dynamic> map, Set<String> knownFields) => {};
}
''',
      'test|lib/test.dart': source,
    },
    outputs: {
      'test|lib/test.g.dart': decodedMatches((dynamic content) {
        capturedOutput = content as String;
        return true;
      }),
    },
  );

  if (capturedOutput != null) {
    verifyOutput(capturedOutput!);
  }
}
