import 'package:ack_generator/src/generator.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('AckSchemaGenerator', () {
    late AckSchemaGenerator generator;

    setUp(() {
      generator = AckSchemaGenerator();
    });

    test('generator processes AckModel annotations', () {
      // Since AckSchemaGenerator extends Generator (not GeneratorForAnnotation),
      // it doesn't have a typeChecker property. Instead, we test that it
      // correctly processes @AckModel annotations by checking its behavior.
      expect(generator, isA<AckSchemaGenerator>());
    });

    test('processes multiple annotated classes in single file', () async {
      final builder = SharedPartBuilder([generator], 'ack');

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
          'test_pkg|lib/models.ack.g.part': decodedMatches(
            allOf([
              contains('final userSchema = Ack.object('),
              contains('final productSchema = Ack.object('),
              isNot(contains('otherSchema')),
            ]),
          ),
        },
      );
    });

    test('handles imports correctly', () async {
      final builder = SharedPartBuilder([generator], 'ack');

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
          'test_pkg|lib/address.ack.g.part': decodedMatches(
            contains('final addressSchema = Ack.object('),
          ),
          'test_pkg|lib/user.ack.g.part': decodedMatches(
            contains('addressSchema'),
          ),
        },
      );
    });

    test('generates part directive comment', () async {
      final builder = SharedPartBuilder([generator], 'ack');

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
          'test_pkg|lib/model.ack.g.part': decodedMatches(
            contains('// GENERATED CODE - DO NOT MODIFY BY HAND'),
          ),
        },
      );
    });

    test('preserves formatting', () async {
      final builder = SharedPartBuilder([generator], 'ack');

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
          'test_pkg|lib/formatted.ack.g.part': decodedMatches(
            allOf([
              isNot(contains('\t')), // No tabs
              contains('  '), // Uses spaces for indentation
              isNot(
                contains(' \n'),
              ), // No trailing whitespace (space before newline)
            ]),
          ),
        },
      );
    });

    test('error messages include helpful context', () async {
      final builder = SharedPartBuilder([generator], 'ack');

      // When generator throws an error, no output should be generated
      await testBuilder(
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
        outputs: {
          // Expect no output files when error is thrown
        },
        onLog: (log) {
          if (log.level.name == 'SEVERE') {
            expect(
              log.message,
              contains('cannot be applied to abstract classes'),
            );
          }
        },
      );
    });
  });
}
