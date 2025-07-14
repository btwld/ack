import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  group('Enhanced Error Messages', () {
    group('Annotation Field Errors', () {
      test('should fail build with missing discriminated type fields',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        // Build should fail when using old annotation format
        await expectLater(
          () => testBuilder(
            builder,
            {
              // Old annotation without discriminated fields
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

  const AckModel({
    this.schemaName,
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.model = false,
  });
}
''',
              'ack|lib/ack.dart': '''
class Ack {
  static ObjectSchema object(Map<String, dynamic> fields) => ObjectSchema();
  static StringSchema string() => StringSchema();
}
class ObjectSchema {}
class StringSchema {}
''',
              'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class TestModel {
  final String name;
  TestModel({required this.name});
}
''',
            },
            outputs: {
              'test_pkg|lib/model.g.dart': anything,
            },
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should fail build with missing model field', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        // Build should fail when using old annotation format with model: true
        await expectLater(
          () => testBuilder(
            builder,
            {
              // Annotation missing model field
              'ack_annotations|lib/ack_annotations.dart': '''
export 'src/ack_model.dart';
''',
              'ack_annotations|lib/src/ack_model.dart': '''
class AckModel {
  final String? schemaName;
  final String? description;
  final bool additionalProperties;
  final String? additionalPropertiesField;
  // Missing: final bool model;

  const AckModel({
    this.schemaName,
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
  });
}
''',
              'ack|lib/ack.dart': '''
class Ack {
  static ObjectSchema object(Map<String, dynamic> fields) => ObjectSchema();
  static StringSchema string() => StringSchema();
}
class ObjectSchema {}
class StringSchema {}
''',
              'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(model: true)
class TestModel {
  final String name;
  TestModel({required this.name});
}
''',
            },
            outputs: {
              'test_pkg|lib/model.g.dart': anything,
            },
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Schema Generation Validation', () {
      test('should handle supported types correctly (DateTime example)',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        // DateTime should be handled as a string in schema generation
        await testBuilder(
          builder,
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
  });
}
''',
            'ack|lib/ack.dart': '''
class Ack {
  static ObjectSchema object(Map<String, dynamic> fields) => ObjectSchema();
  static StringSchema string() => StringSchema();
}
class ObjectSchema {}
class StringSchema {}
''',
            'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class TestModel {
  final DateTime timestamp; // Should be treated as string
  TestModel({required this.timestamp});
}
''',
          },
          outputs: {
            'test_pkg|lib/model.g.dart': isNotEmpty,
          },
        );
      });
    });

    group('Validation Error Messages', () {
      test('should fail for abstract class without discriminatedKey', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        // Abstract class without discriminatedKey should fail
        await expectLater(
          () => testBuilder(
            builder,
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
  });
}
''',
              'ack|lib/ack.dart': '''
class Ack {
  static ObjectSchema object(Map<String, dynamic> fields) => ObjectSchema();
  static StringSchema string() => StringSchema();
}
class ObjectSchema {}
class StringSchema {}
''',
              'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
abstract class AbstractModel { // Abstract without discriminatedKey
  final String name;
  AbstractModel({required this.name});
}
''',
            },
            outputs: {
              'test_pkg|lib/model.g.dart': anything,
            },
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
