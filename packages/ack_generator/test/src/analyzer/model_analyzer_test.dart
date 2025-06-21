import 'package:test/test.dart';
import 'package:build_test/build_test.dart';
import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:ack_generator/src/analyzer/model_analyzer.dart';

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

@AckModel(schemaName: 'CustomSchema')
class TestModel {
  final String name;
  TestModel(this.name);
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(AssetId('test_pkg', 'lib/model.dart'));
        final classElement = library.topLevelElements
            .whereType<ClassElement>()
            .firstWhere((e) => e.name == 'TestModel');
        
        final annotation = TypeChecker.fromRuntime(AckModel)
            .firstAnnotationOfExact(classElement)!;
        final reader = ConstantReader(annotation);
        
        final modelInfo = analyzer.analyze(classElement, reader);
        
        expect(modelInfo.schemaClassName, equals('CustomSchema'));
      });
    });

    test('generates default schema name when not specified', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class UserProfile {
  final String name;
  UserProfile(this.name);
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(AssetId('test_pkg', 'lib/model.dart'));
        final classElement = library.topLevelElements
            .whereType<ClassElement>()
            .firstWhere((e) => e.name == 'UserProfile');
        
        final annotation = TypeChecker.fromRuntime(AckModel)
            .firstAnnotationOfExact(classElement)!;
        final reader = ConstantReader(annotation);
        
        final modelInfo = analyzer.analyze(classElement, reader);
        
        expect(modelInfo.schemaClassName, equals('UserProfileSchema'));
      });
    });

    test('extracts description from annotation', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(description: 'A user model for testing')
class User {
  final String name;
  User(this.name);
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(AssetId('test_pkg', 'lib/model.dart'));
        final classElement = library.topLevelElements
            .whereType<ClassElement>()
            .firstWhere((e) => e.name == 'User');
        
        final annotation = TypeChecker.fromRuntime(AckModel)
            .firstAnnotationOfExact(classElement)!;
        final reader = ConstantReader(annotation);
        
        final modelInfo = analyzer.analyze(classElement, reader);
        
        expect(modelInfo.description, equals('A user model for testing'));
      });
    });

    test('analyzes all fields including inherited ones', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

class BaseModel {
  final String id;
  BaseModel(this.id);
}

@AckModel()
class ExtendedModel extends BaseModel {
  final String name;
  final int age;
  
  ExtendedModel(String id, this.name, this.age) : super(id);
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(AssetId('test_pkg', 'lib/model.dart'));
        final classElement = library.topLevelElements
            .whereType<ClassElement>()
            .firstWhere((e) => e.name == 'ExtendedModel');
        
        final annotation = TypeChecker.fromRuntime(AckModel)
            .firstAnnotationOfExact(classElement)!;
        final reader = ConstantReader(annotation);
        
        final modelInfo = analyzer.analyze(classElement, reader);
        
        expect(modelInfo.fields.length, equals(3));
        expect(modelInfo.fields.map((f) => f.name), 
            containsAll(['id', 'name', 'age']));
      });
    });

    test('identifies required fields correctly', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Product {
  final String name;
  final double price;
  final String? description;
  
  Product({required this.name, required this.price, this.description});
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(AssetId('test_pkg', 'lib/model.dart'));
        final classElement = library.topLevelElements
            .whereType<ClassElement>()
            .firstWhere((e) => e.name == 'Product');
        
        final annotation = TypeChecker.fromRuntime(AckModel)
            .firstAnnotationOfExact(classElement)!;
        final reader = ConstantReader(annotation);
        
        final modelInfo = analyzer.analyze(classElement, reader);
        
        expect(modelInfo.requiredFields, containsAll(['name', 'price']));
        expect(modelInfo.requiredFields, isNot(contains('description')));
      });
    });
  });
}
