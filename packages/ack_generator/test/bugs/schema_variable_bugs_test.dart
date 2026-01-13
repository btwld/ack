/// Regression tests for schema variable type extraction.
///
/// These tests verify correct behavior for previously reported issues:
/// - Issue #1: List type extraction (simple primitives)
/// - Issue #2: Nested schema references
/// - Issue #3: Method chain walker safety
/// - Issue #4: List elements with method chain modifiers
/// - Issue #5: Nested object lists with method chain modifiers
/// - Issue #6: Schema variable references with method chain modifiers
library;

import 'package:ack_generator/src/analyzer/schema_ast_analyzer.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('List type extraction', () {
    test('extracts String from Ack.list(Ack.string())', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final listSchema = Ack.object({
  'tags': Ack.list(Ack.string()),
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables
            .whereType<TopLevelVariableElement2>()
            .firstWhere((e) => e.name3 == 'listSchema');

        final analyzer = SchemaAstAnalyzer();
        final modelInfo = analyzer.analyzeSchemaVariable(schemaVar);

        expect(modelInfo, isNotNull);

        final tagsField = modelInfo!.fields.firstWhere(
          (f) => f.name == 'tags',
          orElse: () => throw StateError('tags field not found'),
        );

        expect(tagsField.type.isDartCoreList, isTrue);

        final listType = tagsField.type as InterfaceType;
        expect(listType.typeArguments.length, 1);

        final elementType = listType.typeArguments.first;
        expect(
          elementType.isDartCoreString,
          isTrue,
          reason: 'Expected String, got '
              '${elementType.getDisplayString(withNullability: false)}',
        );
      });
    });

    test('extracts int from Ack.list(Ack.integer())', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final listSchema = Ack.object({
  'numbers': Ack.list(Ack.integer()),
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables.firstWhere(
          (e) => e.name3 == 'listSchema',
        );

        final analyzer = SchemaAstAnalyzer();
        final modelInfo = analyzer.analyzeSchemaVariable(schemaVar);

        final numbersField = modelInfo!.fields.firstWhere(
          (f) => f.name == 'numbers',
        );

        final listType = numbersField.type as InterfaceType;
        final elementType = listType.typeArguments.first;

        expect(
          elementType.isDartCoreInt,
          isTrue,
          reason: 'Expected int, got '
              '${elementType.getDisplayString(withNullability: false)}',
        );
      });
    });

    test('handles nested lists (List<List<int>>)', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final nestedListSchema = Ack.object({
  'matrix': Ack.list(Ack.list(Ack.integer())),
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables.firstWhere(
          (e) => e.name3 == 'nestedListSchema',
        );

        final analyzer = SchemaAstAnalyzer();
        final modelInfo = analyzer.analyzeSchemaVariable(schemaVar);

        final matrixField = modelInfo!.fields.firstWhere(
          (f) => f.name == 'matrix',
        );

        final outerListType = matrixField.type as InterfaceType;
        expect(outerListType.isDartCoreList, isTrue);

        final innerType = outerListType.typeArguments.first;
        expect(
          innerType.isDartCoreList,
          isTrue,
          reason: 'Expected List<int>, got '
              '${innerType.getDisplayString(withNullability: false)}',
        );

        if (innerType is InterfaceType && innerType.isDartCoreList) {
          final innerElementType = innerType.typeArguments.first;
          expect(
            innerElementType.isDartCoreInt,
            isTrue,
            reason: 'Expected int, got '
                '${innerElementType.getDisplayString(withNullability: false)}',
          );
        }
      });
    });
  });

  group('Nested schema references', () {
    test('resolves schema variable reference', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final addressSchema = Ack.object({
  'street': Ack.string(),
  'city': Ack.string(),
});

@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'address': addressSchema,
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables.firstWhere(
          (e) => e.name3 == 'userSchema',
        );

        final analyzer = SchemaAstAnalyzer();
        final modelInfo = analyzer.analyzeSchemaVariable(schemaVar);

        expect(modelInfo, isNotNull);

        final addressField = modelInfo!.fields.firstWhere(
          (f) => f.name == 'address',
          orElse: () => throw StateError('address field not found'),
        );

        expect(
          addressField.type.isDartCoreMap,
          isTrue,
          reason: 'Expected Map type for nested schema reference',
        );
      });
    });

    test('handles multiple schema references', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final addressSchema = Ack.object({'street': Ack.string()});

@AckType()
final phoneSchema = Ack.object({'number': Ack.string()});

@AckType()
final contactSchema = Ack.object({
  'name': Ack.string(),
  'address': addressSchema,
  'phone': phoneSchema,
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables.firstWhere(
          (e) => e.name3 == 'contactSchema',
        );

        final analyzer = SchemaAstAnalyzer();
        final modelInfo = analyzer.analyzeSchemaVariable(schemaVar);

        expect(
          modelInfo!.fields.length,
          3,
          reason: 'Expected 3 fields (name, address, phone), '
              'got ${modelInfo.fields.map((f) => f.name).join(", ")}',
        );
      });
    });
  });

  group('Method chain walker', () {
    test('handles normal method chains correctly', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final chainedSchema = Ack.object({
  'optionalNullable': Ack.string().optional().nullable(),
  'nullableOptional': Ack.string().nullable().optional(),
  'required': Ack.string(),
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables.firstWhere(
          (e) => e.name3 == 'chainedSchema',
        );

        final analyzer = SchemaAstAnalyzer();
        final modelInfo = analyzer.analyzeSchemaVariable(schemaVar);

        expect(modelInfo, isNotNull);

        // Verify optional().nullable()
        final optNullField = modelInfo!.fields.firstWhere(
          (f) => f.name == 'optionalNullable',
        );
        expect(optNullField.isRequired, isFalse);
        expect(optNullField.isNullable, isTrue);

        // Verify nullable().optional() (different order, same result)
        final nullOptField = modelInfo.fields.firstWhere(
          (f) => f.name == 'nullableOptional',
        );
        expect(nullOptField.isRequired, isFalse);
        expect(nullOptField.isNullable, isTrue);
      });
    });

    test('handles deeply nested chains without hanging', () async {
      // Create a chain with 25 .optional() calls to test depth limits
      final deepChain = List.generate(25, (_) => 'optional()').join('.');

      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final deepSchema = Ack.object({
  'field': Ack.string().$deepChain,
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables.firstWhere(
          (e) => e.name3 == 'deepSchema',
        );

        final analyzer = SchemaAstAnalyzer();

        // Should complete without hanging
        expect(
          () => analyzer.analyzeSchemaVariable(schemaVar),
          returnsNormally,
        );
      });
    });
  });

  group('List elements with method chain modifiers', () {
    test('extracts String from Ack.list(Ack.string().describe(...))', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final testSchema = Ack.object({
  'colors': Ack.list(Ack.string().describe('A hex color value')),
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables
            .whereType<TopLevelVariableElement2>()
            .firstWhere((e) => e.name3 == 'testSchema');

        final analyzer = SchemaAstAnalyzer();
        final modelInfo = analyzer.analyzeSchemaVariable(schemaVar);

        final colorsField =
            modelInfo!.fields.firstWhere((f) => f.name == 'colors');
        final listType = colorsField.type as InterfaceType;
        final elementType = listType.typeArguments.first;

        expect(
          elementType.isDartCoreString,
          isTrue,
          reason: 'Expected String, got '
              '${elementType.getDisplayString(withNullability: false)}',
        );
      });
    });

    test('extracts String from Ack.list(Ack.string().enumString(...))',
        () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final testSchema = Ack.object({
  'styles': Ack.list(Ack.string().enumString(['bold', 'italic', 'underline'])),
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables
            .whereType<TopLevelVariableElement2>()
            .firstWhere((e) => e.name3 == 'testSchema');

        final analyzer = SchemaAstAnalyzer();
        final modelInfo = analyzer.analyzeSchemaVariable(schemaVar);

        final stylesField =
            modelInfo!.fields.firstWhere((f) => f.name == 'styles');
        final listType = stylesField.type as InterfaceType;
        final elementType = listType.typeArguments.first;

        expect(
          elementType.isDartCoreString,
          isTrue,
          reason: 'Expected String, got '
              '${elementType.getDisplayString(withNullability: false)}',
        );
      });
    });

    test('extracts int from Ack.list(Ack.integer().min(0).max(100))', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final testSchema = Ack.object({
  'scores': Ack.list(Ack.integer().min(0).max(100)),
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables
            .whereType<TopLevelVariableElement2>()
            .firstWhere((e) => e.name3 == 'testSchema');

        final analyzer = SchemaAstAnalyzer();
        final modelInfo = analyzer.analyzeSchemaVariable(schemaVar);

        final scoresField =
            modelInfo!.fields.firstWhere((f) => f.name == 'scores');
        final listType = scoresField.type as InterfaceType;
        final elementType = listType.typeArguments.first;

        expect(
          elementType.isDartCoreInt,
          isTrue,
          reason: 'Expected int, got '
              '${elementType.getDisplayString(withNullability: false)}',
        );
      });
    });
  });

  group('Nested object lists with method chain modifiers', () {
    test('extracts Map from Ack.list(Ack.object({...}).describe(...))', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final testSchema = Ack.object({
  'items': Ack.list(Ack.object({
    'name': Ack.string(),
  }).describe('An item')),
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables
            .whereType<TopLevelVariableElement2>()
            .firstWhere((e) => e.name3 == 'testSchema');

        final analyzer = SchemaAstAnalyzer();
        final modelInfo = analyzer.analyzeSchemaVariable(schemaVar);

        final itemsField =
            modelInfo!.fields.firstWhere((f) => f.name == 'items');
        final listType = itemsField.type as InterfaceType;
        final elementType = listType.typeArguments.first;

        expect(
          elementType.isDartCoreMap,
          isTrue,
          reason: 'Expected Map<String, Object?>, got '
              '${elementType.getDisplayString(withNullability: false)}',
        );
      });
    });

    test('extracts Map from Ack.list(Ack.object({...}).optional())', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final testSchema = Ack.object({
  'records': Ack.list(Ack.object({
    'id': Ack.integer(),
  }).optional()),
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables
            .whereType<TopLevelVariableElement2>()
            .firstWhere((e) => e.name3 == 'testSchema');

        final analyzer = SchemaAstAnalyzer();
        final modelInfo = analyzer.analyzeSchemaVariable(schemaVar);

        final recordsField =
            modelInfo!.fields.firstWhere((f) => f.name == 'records');
        final listType = recordsField.type as InterfaceType;
        final elementType = listType.typeArguments.first;

        expect(
          elementType.isDartCoreMap,
          isTrue,
          reason: 'Expected Map<String, Object?>, got '
              '${elementType.getDisplayString(withNullability: false)}',
        );
      });
    });
  });

  group('Schema variable references with method chain modifiers', () {
    test('extracts Map from Ack.list(schemaRef.optional())', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final itemSchema = Ack.object({
  'name': Ack.string(),
});

@AckType()
final containerSchema = Ack.object({
  'items': Ack.list(itemSchema.optional()),
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables
            .whereType<TopLevelVariableElement2>()
            .firstWhere((e) => e.name3 == 'containerSchema');

        final analyzer = SchemaAstAnalyzer();
        final modelInfo = analyzer.analyzeSchemaVariable(schemaVar);

        final itemsField =
            modelInfo!.fields.firstWhere((f) => f.name == 'items');
        final listType = itemsField.type as InterfaceType;
        final elementType = listType.typeArguments.first;

        expect(
          elementType.isDartCoreMap,
          isTrue,
          reason: 'Expected Map<String, Object?>, got '
              '${elementType.getDisplayString(withNullability: false)}',
        );
      });
    });

    test('extracts Map from Ack.list(schemaRef.describe(...))', () async {
      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final addressSchema = Ack.object({
  'street': Ack.string(),
});

@AckType()
final userSchema = Ack.object({
  'addresses': Ack.list(addressSchema.describe('User address')),
});
''',
      };

      await resolveSources(assets, (resolver) async {
        final library = await resolver.libraryFor(
          AssetId('test_pkg', 'lib/schema.dart'),
        );
        final schemaVar = library.topLevelVariables
            .whereType<TopLevelVariableElement2>()
            .firstWhere((e) => e.name3 == 'userSchema');

        final analyzer = SchemaAstAnalyzer();
        final modelInfo = analyzer.analyzeSchemaVariable(schemaVar);

        final addressesField =
            modelInfo!.fields.firstWhere((f) => f.name == 'addresses');
        final listType = addressesField.type as InterfaceType;
        final elementType = listType.typeArguments.first;

        expect(
          elementType.isDartCoreMap,
          isTrue,
          reason: 'Expected Map<String, Object?>, got '
              '${elementType.getDisplayString(withNullability: false)}',
        );
      });
    });
  });
}
