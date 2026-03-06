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

    test(
      'canonicalizes discriminator keys from transformed subtype fields',
      () async {
        final assets = {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(discriminatedKey: 'eventType')
sealed class Event {
  const Event();
}

@Schemable(discriminatedValue: 'created', caseStyle: CaseStyle.snakeCase)
class CreatedEvent extends Event {
  final String eventType;
  final String payload;

  const CreatedEvent({
    required this.eventType,
    required this.payload,
  });
}

@Schemable(discriminatedValue: 'updated', caseStyle: CaseStyle.snakeCase)
class UpdatedEvent extends Event {
  final String eventType;
  final int version;

  const UpdatedEvent({
    required this.eventType,
    required this.version,
  });
}
''',
        };

        await resolveSources(assets, (resolver) async {
          final library = await resolver.libraryFor(
            AssetId('test_pkg', 'lib/model.dart'),
          );
          final classElements = library.classes.toList();
          final modelInfos = classElements.map((classElement) {
            final annotation = TypeChecker.typeNamed(
              Schemable,
            ).firstAnnotationOfExact(classElement)!;
            return analyzer.analyze(classElement, ConstantReader(annotation));
          }).toList();

          final linkedModels = analyzer.buildDiscriminatorRelationships(
            modelInfos,
            classElements,
          );
          final eventModel = linkedModels.firstWhere(
            (model) => model.className == 'Event',
          );
          final createdModel = linkedModels.firstWhere(
            (model) => model.className == 'CreatedEvent',
          );
          final updatedModel = linkedModels.firstWhere(
            (model) => model.className == 'UpdatedEvent',
          );

          expect(eventModel.discriminatorKey, equals('event_type'));
          expect(createdModel.discriminatorKey, equals('event_type'));
          expect(updatedModel.discriminatorKey, equals('event_type'));
        });
      },
    );

    test('rejects conflicting transformed discriminator keys', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(discriminatedKey: 'eventType')
sealed class Event {
  const Event();
}

@Schemable(discriminatedValue: 'created', caseStyle: CaseStyle.snakeCase)
class CreatedEvent extends Event {
  final String eventType;
  final String payload;

  const CreatedEvent({
    required this.eventType,
    required this.payload,
  });
}

@Schemable(discriminatedValue: 'deleted')
class DeletedEvent extends Event {
  final String eventType;
  final String reason;

  const DeletedEvent({
    @SchemaKey('event-type') required this.eventType,
    required this.reason,
  });
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/model.dart'),
        );
        final classElements = library.classes.toList();
        final modelInfos = classElements.map((classElement) {
          final annotation = TypeChecker.typeNamed(
            Schemable,
          ).firstAnnotationOfExact(classElement)!;
          return analyzer.analyze(classElement, ConstantReader(annotation));
        }).toList();

        expect(
          () => analyzer.buildDiscriminatorRelationships(
            modelInfos,
            classElements,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message.toString(),
              'message',
              allOf([
                contains('conflicting discriminator keys'),
                contains('Event'),
                contains('event_type'),
                contains('event-type'),
              ]),
            ),
          ),
        );
      });
    });
  });
}
