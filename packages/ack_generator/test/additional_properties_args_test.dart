import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('Additional Properties Args Getter', () {

    test('generates args getter for schema variable with .passthrough()',
        () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
}).passthrough();
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('Map<String, Object?> get args =>'),
              contains("e.key != 'name' && e.key != 'age'"),
            ]),
          ),
        },
      );
    });

    test(
        'generates args getter for schema variable with explicit additionalProperties: true',
        () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
}, additionalProperties: true);
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('Map<String, Object?> get args =>'),
              contains("e.key != 'name' && e.key != 'age'"),
            ]),
          ),
        },
      );
    });

    test('does not generate args getter for schema variable without additionalProperties',
        () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            isNot(contains('Map<String, Object?> get args')),
          ),
        },
      );
    });

    test('generates args getter with no conditions when there are no fields',
        () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/empty.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final emptySchema = Ack.object({}, additionalProperties: true);
''',
        },
        outputs: {
          'test_pkg|lib/empty.g.dart': decodedMatches(
            allOf([
              contains('Map<String, Object?> get args =>'),
              contains('_data'),
              // Should not have filter conditions when no fields exist
              isNot(contains('where')),
            ]),
          ),
        },
      );
    });

    test('generates correct filter for single field', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/single.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final singleFieldSchema = Ack.object({
  'name': Ack.string(),
}).passthrough();
''',
        },
        outputs: {
          'test_pkg|lib/single.g.dart': decodedMatches(
            allOf([
              contains('Map<String, Object?> get args =>'),
              contains("e.key != 'name'"),
              // Should not have && when there's only one field
              isNot(contains(' && ')),
            ]),
          ),
        },
      );
    });

    test('generates correct filter for three fields', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/three.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final threeFieldsSchema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
  'email': Ack.string(),
}).passthrough();
''',
        },
        outputs: {
          'test_pkg|lib/three.g.dart': decodedMatches(
            allOf([
              contains('Map<String, Object?> get args =>'),
              contains("e.key != 'name'"),
              contains("e.key != 'age'"),
              contains("e.key != 'email'"),
              contains(' && '),
            ]),
          ),
        },
      );
    });
  });
}
