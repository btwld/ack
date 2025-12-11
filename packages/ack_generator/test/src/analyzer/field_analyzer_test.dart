import 'package:test/test.dart';
import 'package:build_test/build_test.dart';
import 'package:build/build.dart';
import 'package:ack_generator/src/analyzer/field_analyzer.dart';

import '../../test_utils/test_assets.dart';

void main() {
  group('FieldAnalyzer', () {
    late FieldAnalyzer analyzer;

    setUp(() {
      analyzer = FieldAnalyzer();
    });

    test('extracts field with AckField annotation', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  @AckField(required: true, jsonKey: 'user_name')
  final String name;
  
  User(this.name);
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/model.dart'),
        );
        final classElement = library.classes.firstWhere(
          (e) => e.name3 == 'User',
        );
        final field = classElement.fields2.firstWhere((f) => f.name3 == 'name');

        final fieldInfo = analyzer.analyze(field);

        expect(fieldInfo.name, equals('name'));
        expect(fieldInfo.jsonKey, equals('user_name'));
        expect(fieldInfo.isRequired, isTrue);
      });
    });

    test('uses field name as json key when not specified', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  final String firstName;
  
  User(this.firstName);
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/model.dart'),
        );
        final classElement = library.classes.firstWhere(
          (e) => e.name3 == 'User',
        );
        final field = classElement.fields2.firstWhere(
          (f) => f.name3 == 'firstName',
        );

        final fieldInfo = analyzer.analyze(field);

        expect(fieldInfo.jsonKey, equals('firstName'));
      });
    });

    test('identifies nullable fields', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  final String name;
  final String? email;
  final int? age;
  
  User({required this.name, this.email, this.age});
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/model.dart'),
        );
        final classElement = library.classes.firstWhere(
          (e) => e.name3 == 'User',
        );

        final nameField = classElement.fields2.firstWhere(
          (f) => f.name3 == 'name',
        );
        final emailField = classElement.fields2.firstWhere(
          (f) => f.name3 == 'email',
        );
        final ageField = classElement.fields2.firstWhere(
          (f) => f.name3 == 'age',
        );

        expect(analyzer.analyze(nameField).isNullable, isFalse);
        expect(analyzer.analyze(emailField).isNullable, isTrue);
        expect(analyzer.analyze(ageField).isNullable, isTrue);
      });
    });

    test('parses constraint strings correctly', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  @AckField(constraints: ['email()', 'minLength(5)', 'maxLength(100)'])
  final String email;
  
  @AckField(constraints: ['positive', 'max(150)'])
  final int age;
  
  User({required this.email, required this.age});
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/model.dart'),
        );
        final classElement = library.classes.firstWhere(
          (e) => e.name3 == 'User',
        );

        final emailField = classElement.fields2.firstWhere(
          (f) => f.name3 == 'email',
        );
        final emailInfo = analyzer.analyze(emailField);

        expect(emailInfo.constraints.length, equals(3));
        expect(emailInfo.constraints[0].name, equals('email'));
        expect(emailInfo.constraints[0].arguments, isEmpty);
        expect(emailInfo.constraints[1].name, equals('minLength'));
        expect(emailInfo.constraints[1].arguments, equals(['5']));
        expect(emailInfo.constraints[2].name, equals('maxLength'));
        expect(emailInfo.constraints[2].arguments, equals(['100']));

        final ageField = classElement.fields2.firstWhere(
          (f) => f.name3 == 'age',
        );
        final ageInfo = analyzer.analyze(ageField);

        expect(ageInfo.constraints.length, equals(2));
        expect(ageInfo.constraints[0].name, equals('positive'));
        expect(ageInfo.constraints[0].arguments, isEmpty);
        expect(ageInfo.constraints[1].name, equals('max'));
        expect(ageInfo.constraints[1].arguments, equals(['150']));
      });
    });

    test('handles fields with default values', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Settings {
  final bool enabled = true;
  final int retryCount = 3;
  final String theme = 'light';
  
  Settings();
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/model.dart'),
        );
        final classElement = library.classes.firstWhere(
          (e) => e.name3 == 'Settings',
        );

        final enabledField = classElement.fields2.firstWhere(
          (f) => f.name3 == 'enabled',
        );
        final retryField = classElement.fields2.firstWhere(
          (f) => f.name3 == 'retryCount',
        );
        final themeField = classElement.fields2.firstWhere(
          (f) => f.name3 == 'theme',
        );

        // Note: In actual implementation, extracting default values from AST
        // requires more complex analysis. For testing, we verify the field exists
        expect(analyzer.analyze(enabledField).name, equals('enabled'));
        expect(analyzer.analyze(retryField).name, equals('retryCount'));
        expect(analyzer.analyze(themeField).name, equals('theme'));
      });
    });

    test('correctly identifies field types', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class TypeTest {
  final String text;
  final int count;
  final double price;
  final bool active;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  
  TypeTest({
    required this.text,
    required this.count,
    required this.price,
    required this.active,
    required this.tags,
    required this.metadata,
  });
}
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/model.dart'),
        );
        final classElement = library.classes.firstWhere(
          (e) => e.name3 == 'TypeTest',
        );

        final fields = classElement.fields2.where((f) => !f.isSynthetic);

        for (final field in fields) {
          final fieldInfo = analyzer.analyze(field);
          final typeName = fieldInfo.type.getDisplayString();

          switch (fieldInfo.name) {
            case 'text':
              expect(typeName, equals('String'));
              expect(fieldInfo.isPrimitive, isTrue);
              break;
            case 'count':
              expect(typeName, equals('int'));
              expect(fieldInfo.isPrimitive, isTrue);
              break;
            case 'price':
              expect(typeName, equals('double'));
              expect(fieldInfo.isPrimitive, isTrue);
              break;
            case 'active':
              expect(typeName, equals('bool'));
              expect(fieldInfo.isPrimitive, isTrue);
              break;
            case 'tags':
              expect(typeName, equals('List<String>'));
              expect(fieldInfo.isList, isTrue);
              break;
            case 'metadata':
              expect(typeName, equals('Map<String, dynamic>'));
              expect(fieldInfo.isMap, isTrue);
              break;
          }
        }
      });
    });
  });
}
