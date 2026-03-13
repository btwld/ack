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
      'accepts providers that inherit schema getter from a generic base class',
      () async {
        final assets = {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Money {
  final int cents;
  const Money(this.cents);
}

abstract class BaseSchemaProvider<T extends Object>
    implements SchemaProvider<T> {
  const BaseSchemaProvider();

  AckSchema<T> createSchema();

  @override
  AckSchema<T> get schema => createSchema();
}

class MoneySchemaProvider extends BaseSchemaProvider<Money> {
  const MoneySchemaProvider();

  @override
  AckSchema<Money> createSchema() =>
      Ack.object({'cents': Ack.integer()}).transform(
        (value) => Money(value!['cents'] as int),
      );
}

@Schemable(useProviders: const [MoneySchemaProvider])
class Invoice {
  final Money total;

  const Invoice({required this.total});
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

          expect(
            modelInfo.typeProviders.single.providerTypeName,
            equals('MoneySchemaProvider'),
          );
        });
      },
    );

    test('accepts providers that inherit schema getter from a mixin', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Money {
  final int cents;
  const Money(this.cents);
}

mixin MoneySchemaProviderMixin implements SchemaProvider<Money> {
  @override
  AckSchema<Money> get schema =>
      Ack.object({'cents': Ack.integer()}).transform(
        (value) => Money(value!['cents'] as int),
      );
}

class MoneySchemaProvider
    with MoneySchemaProviderMixin
    implements SchemaProvider<Money> {
  const MoneySchemaProvider();
}

@Schemable(useProviders: const [MoneySchemaProvider])
class Invoice {
  final Money total;

  const Invoice({required this.total});
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

        expect(
          modelInfo.typeProviders.single.providerTypeName,
          equals('MoneySchemaProvider'),
        );
      });
    });

    test('rejects providers that target schemable types', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@Schemable()
class Money {
  final int cents;

  const Money({required this.cents});
}

class MoneySchemaProvider implements SchemaProvider<Money> {
  const MoneySchemaProvider();

  @override
  AckSchema<Money> get schema => Ack.object({
    'cents': Ack.integer(),
  }).transform((value) => Money(cents: value!['cents'] as int));
}

@Schemable(useProviders: const [MoneySchemaProvider])
class Invoice {
  final Money total;

  const Invoice({required this.total});
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

        expect(
          () => analyzer.analyze(classElement, reader),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message.toString(),
              'message',
              allOf([
                contains('MoneySchemaProvider'),
                contains('cannot target Money'),
                contains('already has a generated schema'),
              ]),
            ),
          ),
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

@Schemable(discriminatorKey: 'eventType')
sealed class Event {
  const Event();
}

@Schemable(discriminatorValue: 'created', caseStyle: CaseStyle.snakeCase)
class CreatedEvent extends Event {
  final String eventType;
  final String payload;

  const CreatedEvent({
    required this.eventType,
    required this.payload,
  });
}

@Schemable(discriminatorValue: 'updated', caseStyle: CaseStyle.snakeCase)
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

    test(
      'canonicalizes discriminator keys from getter-only and transformed leaves',
      () async {
        final assets = {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(discriminatorKey: 'eventType')
sealed class Event {
  const Event();

  String get eventType;
}

@Schemable(discriminatorValue: 'created')
class CreatedEvent extends Event {
  @override
  String get eventType => 'created';

  final String payload;

  const CreatedEvent({required this.payload});
}

@Schemable(discriminatorValue: 'updated', caseStyle: CaseStyle.snakeCase)
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

    test(
      'canonicalizes discriminator keys from getter-only and annotated leaves',
      () async {
        final assets = {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(discriminatorKey: 'eventType')
sealed class Event {
  const Event();

  String get eventType;
}

@Schemable(discriminatorValue: 'created')
class CreatedEvent extends Event {
  @override
  String get eventType => 'created';

  final String payload;

  const CreatedEvent({required this.payload});
}

@Schemable(discriminatorValue: 'updated')
class UpdatedEvent extends Event {
  final String eventType;
  final int version;

  const UpdatedEvent({
    @SchemaKey('event_type') required this.eventType,
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

    test(
      'falls back to declared discriminator key for getter-only hierarchies',
      () async {
        final assets = {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(discriminatorKey: 'eventType')
sealed class Event {
  const Event();

  String get eventType;
}

@Schemable(discriminatorValue: 'created')
class CreatedEvent extends Event {
  @override
  String get eventType => 'created';

  final String payload;

  const CreatedEvent({required this.payload});
}

@Schemable(discriminatorValue: 'updated')
class UpdatedEvent extends Event {
  @override
  String get eventType => 'updated';

  final int version;

  const UpdatedEvent({required this.version});
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

          expect(eventModel.discriminatorKey, equals('eventType'));
          expect(createdModel.discriminatorKey, equals('eventType'));
          expect(updatedModel.discriminatorKey, equals('eventType'));
        });
      },
    );

    test('rejects conflicting transformed discriminator keys', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(discriminatorKey: 'eventType')
sealed class Event {
  const Event();
}

@Schemable(discriminatorValue: 'created', caseStyle: CaseStyle.snakeCase)
class CreatedEvent extends Event {
  final String eventType;
  final String payload;

  const CreatedEvent({
    required this.eventType,
    required this.payload,
  });
}

@Schemable(discriminatorValue: 'deleted')
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
