import 'package:test/test.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:ack_generator/src/generator.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('AckSchemaGenerator', () {
    late AckSchemaGenerator generator;

    setUp(() {
      generator = AckSchemaGenerator();
    });

    test('generator has correct annotation type', () {
      expect(generator.typeChecker.toString(), contains('AckModel'));
    });

    test('processes multiple annotated classes in single file', () async {
      final builder = SharedPartBuilder([generator], 'ack_generator');
      
      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/models.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  final String name;
  User(this.name);
}

@AckModel()
class Product {
  final String title;
  Product(this.title);
}

// Not annotated - should be ignored
class Other {
  final int value;
  Other(this.value);
}
''',
        },
        outputs: {
          'test_pkg|lib/models.ack.g.part': allOf([
            contains('class UserSchema extends SchemaModel'),
            contains('class ProductSchema extends SchemaModel'),
            isNot(contains('class OtherSchema')),
          ]),
        },
      );
    });

    test('handles imports correctly', () async {
      final builder = SharedPartBuilder([generator], 'ack_generator');
      
      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/address.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Address {
  final String street;
  Address(this.street);
}
''',
          'test_pkg|lib/user.dart': '''
import 'package:ack_annotations/ack_annotations.dart';
import 'address.dart';

@AckModel()
class User {
  final Address address;
  User(this.address);
}
''',
        },
        outputs: {
          'test_pkg|lib/user.ack.g.part': contains('AddressSchema().definition'),
        },
      );
    });

    test('generates part directive comment', () async {
      final builder = SharedPartBuilder([generator], 'ack_generator');
      
      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'model.ack.g.dart';

@AckModel()
class Model {
  final String id;
  Model(this.id);
}
''',
        },
        outputs: {
          'test_pkg|lib/model.ack.g.part': contains('// GENERATED CODE - DO NOT MODIFY BY HAND'),
        },
      );
    });

    test('preserves formatting', () async {
      final builder = SharedPartBuilder([generator], 'ack_generator');
      
      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/formatted.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class WellFormatted {
  final String firstName;
  final String lastName;
  final int age;
  
  WellFormatted({
    required this.firstName,
    required this.lastName,
    required this.age,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/formatted.ack.g.part': (content) {
            // Check proper indentation
            expect(content, isNot(contains('\t'))); // No tabs
            expect(content, contains('  ')); // Uses spaces
            // Check no trailing whitespace
            final lines = content.split('\n');
            for (final line in lines) {
              expect(line, isNot(endsWith(' ')));
            }
            return true;
          },
        },
      );
    });

    test('error messages include helpful context', () async {
      final builder = SharedPartBuilder([generator], 'ack_generator');
      
      expect(
        () => testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/bad.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
abstract class BadModel {
  String get name;
}
''',
          },
        ),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (e) => e.todo,
            'todo',
            contains('Check that all fields have supported types'),
          ),
        ),
      );
    });
  });
}
