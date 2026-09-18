import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

String _readFromRepo(String path) => File('../../$path').readAsStringSync();

void main() {
  group('documentation source integrity', () {
    test(
      'full-value regex examples are anchored in their literal snippets',
      () {
        final commonRecipes = _readFromRepo('docs/guides/common-recipes.mdx');
        final flutterForms = _readFromRepo(
          'docs/guides/flutter-form-validation.mdx',
        );
        final validation = _readFromRepo('docs/core-concepts/validation.mdx');
        final schemas = _readFromRepo('docs/core-concepts/schemas.mdx');

        expect(commonRecipes, contains(".matches(r'^\\d{5}(-\\d{4})?\$')"));
        expect(flutterForms, contains(".matches(r'^[a-zA-Z0-9_]+\$')"));
        expect(validation, contains(".matches(r'^[a-z0-9_]+\$')"));
        expect(schemas, contains(".matches(r'^[a-zA-Z0-9_]+\$')"));
        expect(schemas, contains(".matches(r'^\\d{5}\$')"));
        expect(schemas, contains(".matches(r'^\\d{4}-\\d{2}-\\d{2}\$')"));
      },
    );

    test('double-schema examples use double inputs', () {
      final customValidation = _readFromRepo(
        'docs/guides/custom-validation.mdx',
      );

      expect(customValidation, contains('safeParse(-5.0)'));
      expect(customValidation, contains('safeParse(-10.0)'));
    });

    test('numeric docs describe cross-platform normalization', () {
      final api = _readFromRepo('docs/api-reference/index.mdx');
      final schemas = _readFromRepo('docs/core-concepts/schemas.mdx');
      final validation = _readFromRepo('docs/core-concepts/validation.mdx');

      expect(api, contains('follow JSON Schema value semantics'));
      expect(schemas, contains('native and web builds'));
      expect(validation, contains('first successful branch'));
      expect(api, isNot(contains('`42.0` fails `Ack.integer()`')));
      expect(validation, isNot(contains('double is not int')));
    });

    test('GitHub response recipe permits undocumented response fields', () {
      final commonRecipes = _readFromRepo('docs/guides/common-recipes.mdx');
      final githubRecipe = RegExp(
        r'final githubUserSchema = Ack\.object\([\s\S]*?Future<void> fetchUser',
      ).firstMatch(commonRecipes)?.group(0);

      expect(githubRecipe, isNotNull);
      expect(githubRecipe, contains('additionalProperties: true'));
    });

    test('JSON serialization covers the outbound JSON path', () {
      final serialization = _readFromRepo(
        'docs/core-concepts/json-serialization.mdx',
      );

      expect(serialization, contains('## Encoding validated data'));
      expect(serialization, contains('jsonEncode(validData)'));
      expect(serialization, contains('[Codecs](./codecs.mdx)'));
    });

    test('primary JSON Schema example is self-contained and valid JSON', () {
      final guide = _readFromRepo('docs/guides/json-schema-integration.mdx');

      expect(guide, contains('enum UserRole { admin, user, guest }'));
      expect(guide, contains('enum Theme { light, dark }'));

      final output = RegExp(
        r'\*\*Output JSON \(JSON Schema Object\):\*\*\s*```json\s*([\s\S]*?)```',
      ).firstMatch(guide)?.group(1);
      expect(output, isNotNull);
      expect(() => jsonDecode(output!), returnsNormally);
    });

    test('date converter README uses the codec runtime invariant', () {
      final readme = _readFromRepo(
        'packages/ack_json_schema_builder/README.md',
      );

      expect(readme, contains('Ack.date().min(DateTime(2026))'));
      expect(readme, isNot(contains('Ack.date().min(DateTime.utc(2026))')));
    });

    test('converter authoring guides are published and navigable', () {
      final docsConfig = jsonDecode(_readFromRepo('docs.json')) as Object?;
      final serializedConfig = jsonEncode(docsConfig);

      expect(
        File('../../docs/guides/schema-converter-quickstart.mdx').existsSync(),
        isTrue,
      );
      expect(
        File(
          '../../docs/guides/creating-schema-converter-packages.mdx',
        ).existsSync(),
        isTrue,
      );
      expect(serializedConfig, contains('/guides/schema-converter-quickstart'));
      expect(
        serializedConfig,
        contains('/guides/creating-schema-converter-packages'),
      );
    });

    test('community health files provide contribution routes', () {
      for (final path in ['CODE_OF_CONDUCT.md', 'SECURITY.md', 'SUPPORT.md']) {
        expect(File('../../$path').existsSync(), isTrue, reason: path);
      }
    });

    test('quickstart delegates advanced failure semantics', () {
      final quickstart = _readFromRepo(
        'docs/getting-started/quickstart-tutorial.mdx',
      );

      expect(
        quickstart,
        isNot(contains('`Error` values from those callbacks are rethrown')),
      );
      expect(quickstart, contains('[Error Handling]'));
    });

    test('configuration documents the main schema-level choices', () {
      final configuration = _readFromRepo(
        'docs/core-concepts/configuration.mdx',
      );

      expect(configuration, contains('### Optional and nullable values'));
      expect(configuration, contains('### Default values'));
      expect(configuration, contains('### Schema metadata'));
      expect(configuration, contains('message:'));
    });

    test('API page distinguishes quick reference from exhaustive API docs', () {
      final apiReference = _readFromRepo('docs/api-reference/index.mdx');

      expect(apiReference, contains('toSchemaModel()'));
      expect(
        apiReference,
        contains('https://pub.dev/documentation/ack/latest/ack/'),
      );
      expect(apiReference, contains('generated API documentation'));
    });
  });
}
