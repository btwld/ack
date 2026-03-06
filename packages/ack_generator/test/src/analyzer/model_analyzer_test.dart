import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_generator/src/analyzer/model_analyzer.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import '../../test_utils/test_assets.dart';

void main() {
  group('ModelAnalyzer', () {
    late ModelAnalyzer analyzer;

    setUp(() {
      analyzer = ModelAnalyzer();
    });

    test('extracts schema name from annotation', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(schemaName: 'CustomSchema')
class TestModel {
  final String name;

  const TestModel({required this.name});
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/model.dart'),
        );
        final classElement = library.classes.firstWhere(
          (element) => element.name3 == 'TestModel',
        );

        final annotation = TypeChecker.typeNamed(
          Schemable,
        ).firstAnnotationOfExact(classElement)!;
        final reader = ConstantReader(annotation);

        final modelInfo = analyzer.analyze(classElement, reader);

        expect(modelInfo.schemaClassName, equals('CustomSchema'));
      });
    });

    test(
      'extracts description from annotation or class doc comments',
      () async {
        final assets = {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

/// Fallback description from a doc comment.
@Schemable()
class User {
  final String name;

  const User({required this.name});
}
''',
        };

        await resolveSources(assets, (resolver) async {
          final library = await resolver.libraryFor(
            AssetId('test_pkg', 'lib/model.dart'),
          );
          final classElement = library.classes.firstWhere(
            (element) => element.name3 == 'User',
          );

          final annotation = TypeChecker.typeNamed(
            Schemable,
          ).firstAnnotationOfExact(classElement)!;
          final reader = ConstantReader(annotation);

          final modelInfo = analyzer.analyze(classElement, reader);

          expect(
            modelInfo.description,
            equals('Fallback description from a doc comment.'),
          );
        });
      },
    );

    test('uses the selected constructor rather than scanning fields', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

class BaseModel {
  final String id;

  const BaseModel({required this.id});
}

@Schemable()
class ExtendedModel extends BaseModel {
  final String name;
  final int age;

  const ExtendedModel._({required super.id, required this.name, required this.age});

  @SchemaConstructor()
  const ExtendedModel.fromApi({
    required super.id,
    required this.name,
  }) : age = 0;
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/model.dart'),
        );
        final classElement = library.classes.firstWhere(
          (element) => element.name3 == 'ExtendedModel',
        );

        final annotation = TypeChecker.typeNamed(
          Schemable,
        ).firstAnnotationOfExact(classElement)!;
        final reader = ConstantReader(annotation);

        final modelInfo = analyzer.analyze(classElement, reader);

        expect(modelInfo.fields.map((field) => field.name), ['id', 'name']);
      });
    });

    test('identifies required fields from constructor parameters', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable()
class Product {
  final String name;
  final double price;
  final String? description;
  final int retries;

  const Product({
    required this.name,
    required this.price,
    this.description,
    this.retries = 3,
  });
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/model.dart'),
        );
        final classElement = library.classes.firstWhere(
          (element) => element.name3 == 'Product',
        );

        final annotation = TypeChecker.typeNamed(
          Schemable,
        ).firstAnnotationOfExact(classElement)!;
        final reader = ConstantReader(annotation);

        final modelInfo = analyzer.analyze(classElement, reader);

        expect(modelInfo.requiredFields, containsAll(['name', 'price']));
        expect(modelInfo.requiredFields, isNot(contains('description')));
        expect(modelInfo.requiredFields, isNot(contains('retries')));
      });
    });

    test('reads class-level caseStyle and provider registrations', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Money {
  final int cents;
  const Money(this.cents);
}

class MoneySchemaProvider implements SchemaProvider<Money> {
  const MoneySchemaProvider();

  @override
  AckSchema<Money> get schema =>
      Ack.object({'cents': Ack.integer()}).transform(
        (value) => Money(value!['cents'] as int),
      );
}

@Schemable(
  caseStyle: CaseStyle.snakeCase,
  useProviders: const [MoneySchemaProvider],
)
class Invoice {
  final Money totalAmount;

  const Invoice({required this.totalAmount});
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/model.dart'),
        );
        final classElement = library.classes.firstWhere(
          (element) => element.name3 == 'Invoice',
        );

        final annotation = TypeChecker.typeNamed(
          Schemable,
        ).firstAnnotationOfExact(classElement)!;
        final reader = ConstantReader(annotation);

        final modelInfo = analyzer.analyze(classElement, reader);

        expect(modelInfo.fields.single.jsonKey, equals('total_amount'));
        expect(
          modelInfo.typeProviders.single.providerTypeName,
          equals('MoneySchemaProvider'),
        );
      });
    });
  });
}
