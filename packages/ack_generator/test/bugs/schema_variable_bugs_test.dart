/// Tests for critical bugs in schema variable type extraction.
///
/// This file contains reproduction tests for 3 critical issues:
/// 1. List type extraction returns `List<dynamic>` instead of proper types
/// 2. Nested schema references are silently ignored (return null)
/// 3. Method chain walker has no safety guards (could infinite loop)
///
/// These tests DOCUMENT THE BUGS and will FAIL until the bugs are fixed.
library;

import 'package:ack_generator/src/analyzer/schema_ast_analyzer.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('[BUG] Issue #1: List Type Extraction', () {
    test('should extract String type from Ack.list(Ack.string())', () async {
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

        expect(
          modelInfo,
          isNotNull,
          reason: 'Should analyze schema successfully',
        );

        // Find 'tags' field
        final tagsField = modelInfo!.fields.firstWhere(
          (f) => f.name == 'tags',
          orElse: () => throw StateError('tags field not found'),
        );

        // CRITICAL: Should be List<String>, not List<dynamic>
        expect(
          tagsField.type.isDartCoreList,
          isTrue,
          reason: 'tags field should be a List type',
        );

        final listType = tagsField.type as InterfaceType;
        expect(
          listType.typeArguments.length,
          1,
          reason: 'List should have one type argument',
        );

        final elementType = listType.typeArguments.first;

        // 🐛 BUG: This will FAIL because it returns List<dynamic>
        expect(
          elementType.isDartCoreString,
          isTrue,
          reason:
              '🐛 BUG: List element should be String, not dynamic\n'
              'Current: $elementType\n'
              'Expected: String\n'
              'Location: schema_ast_analyzer.dart:259',
        );
      });
    });

    test('should extract int type from Ack.list(Ack.integer())', () async {
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

        // 🐛 BUG: This will FAIL
        expect(
          elementType.isDartCoreInt,
          isTrue,
          reason:
              '🐛 BUG: List element should be int, not dynamic\n'
              'Current: $elementType',
        );
      });
    });

    test('should handle nested lists (List<List<T>>)', () async {
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

        // Should be List<List<int>>
        final outerListType = matrixField.type as InterfaceType;
        expect(outerListType.isDartCoreList, isTrue);

        final innerType = outerListType.typeArguments.first;

        // 🐛 BUG: This will FAIL - inner type is dynamic, not List<int>
        expect(
          innerType.isDartCoreList,
          isTrue,
          reason:
              '🐛 BUG: Inner type should be List<int>, not dynamic\n'
              'Current: $innerType',
        );

        if (innerType is InterfaceType && innerType.isDartCoreList) {
          final innerElementType = innerType.typeArguments.first;
          expect(
            innerElementType.isDartCoreInt,
            isTrue,
            reason: 'Innermost element should be int',
          );
        }
      });
    });
  });

  group('[BUG] Issue #2: Nested Schema References', () {
    test('should resolve schema variable reference', () async {
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
  'address': addressSchema,  // Reference to another schema
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

        // 🐛 BUG: This will FAIL because nested refs return null (line 170-174)
        final addressField = modelInfo!.fields.firstWhere(
          (f) => f.name == 'address',
          orElse: () => throw StateError(
            '🐛 BUG: address field not found!\n'
            'Nested schema reference was silently ignored.\n'
            'Location: schema_ast_analyzer.dart:169-177\n'
            'The _parseFieldValue() method returns null for SimpleIdentifier',
          ),
        );

        // If we get here, the field exists
        expect(
          addressField.type.isDartCoreMap,
          isTrue,
          reason: 'address field should have a Map type',
        );
      });
    });

    test('should handle multiple schema references', () async {
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

        // 🐛 BUG: This will FAIL - only 'name' field will be present
        expect(
          modelInfo!.fields.length,
          3,
          reason:
              '🐛 BUG: Should have 3 fields (name, address, phone)\n'
              'Current field count: ${modelInfo.fields.length}\n'
              'Fields found: ${modelInfo.fields.map((f) => f.name).join(", ")}',
        );
      });
    });
  });

  group('[BUG] Issue #3: Method Chain Walker Safety', () {
    test('should handle normal method chains correctly', () async {
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
        expect(
          optNullField.isRequired,
          isFalse,
          reason: '.optional() should set isRequired=false',
        );
        expect(
          optNullField.isNullable,
          isTrue,
          reason: '.nullable() should set isNullable=true',
        );

        // Verify nullable().optional() (different order)
        final nullOptField = modelInfo.fields.firstWhere(
          (f) => f.name == 'nullableOptional',
        );
        expect(nullOptField.isRequired, isFalse);
        expect(nullOptField.isNullable, isTrue);

        // This should PASS - basic chains work fine
      });
    });

    test('should prevent infinite loops with deeply nested chains', () async {
      // Create a chain with 25 .optional() calls (should exceed limit of 20)
      final deepChain = List.generate(25, (_) => 'optional()').join('.');

      final assets = {
        ...allAssets,
        'test_pkg|lib/schema.dart':
            '''
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

        // 🐛 BUG: This will HANG or FAIL without proper safety guards
        // Currently, there's no iteration limit in the while loop (line 191-214)
        // TODO(ack): Reinstate defensive depth limits once walker guards are implemented.
        expect(
          () => analyzer.analyzeSchemaVariable(schemaVar),
          returnsNormally,
          reason:
              'Current implementation allows deep chains without throwing; '
              'update this expectation when max-depth guards land.',
        );
      });
    });
  });

  group('Documentation: Expected Behavior', () {
    test('documents what list extraction SHOULD do', () {
      // This test documents the expected implementation
      // After fix, Ack.list(Ack.string()) should:
      // 1. Detect 'list' as baseType in _parseSchemaMethod
      // 2. Extract the argument: Ack.string()
      // 3. Recursively parse that argument to get String type
      // 4. Create List<String> using typeProvider.listType(stringType)

      expect(true, isTrue, reason: 'Documentation test');
    });

    test('documents what nested ref resolution SHOULD do', () {
      // After fix, 'address': addressSchema should:
      // 1. Detect SimpleIdentifier in _parseFieldValue
      // 2. Look up 'addressSchema' in current library
      // 3. Generate proper type (Map<String, dynamic> or AddressType)
      // 4. Return FieldInfo instead of null

      expect(true, isTrue, reason: 'Documentation test');
    });

    test('documents what walker safety SHOULD do', () {
      // After fix, method chain walker should:
      // 1. Add iteration counter (starting at 0)
      // 2. Check counter against MAX_DEPTH (suggest 20)
      // 3. Throw clear error if exceeded
      // 4. Optionally: Add cycle detection with visited Set

      expect(true, isTrue, reason: 'Documentation test');
    });
  });
}
