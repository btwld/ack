import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('Map and Set Support Tests', () {
    test('should generate schema for Map types', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/config.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Config {
  final Map<String, dynamic> settings;
  final Map<String, int> counts;
  final Map<String, List<String>> groupedData;
  
  Config({
    required this.settings,
    required this.counts,
    required this.groupedData,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/config.g.dart': decodedMatches(allOf([
            contains('final configSchema = Ack.object('),
            contains("'settings': Ack.map(Ack.any())"),
            contains("'counts': Ack.map(Ack.integer())"),
            contains("'groupedData': Ack.map(Ack.list(Ack.string()))"),
            contains("required: ['settings', 'counts', 'groupedData']"),
          ])),
        },
      );
    });

    test('should generate schema for Set types', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/unique_data.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class UniqueData {
  final Set<String> tags;
  final Set<int> ids;
  final Set<dynamic> mixed;
  
  UniqueData({
    required this.tags,
    required this.ids,
    required this.mixed,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/unique_data.g.dart': decodedMatches(allOf([
            contains('final uniqueDataSchema = Ack.object('),
            contains("'tags': Ack.list(Ack.string()).unique()"),
            contains("'ids': Ack.list(Ack.integer()).unique()"),
            contains("'mixed': Ack.list(Ack.any()).unique()"),
            contains("required: ['tags', 'ids', 'mixed']"),
          ])),
        },
      );
    });

    test('should handle nullable Map and Set types', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/nullable_collections.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class NullableCollections {
  final Map<String, String>? metadata;
  final Set<String>? categories;
  
  NullableCollections({
    this.metadata,
    this.categories,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/nullable_collections.g.dart': decodedMatches(allOf([
            contains('final nullableCollectionsSchema = Ack.object('),
            contains("'metadata': Ack.map(Ack.string()).nullable()"),
            contains("'categories': Ack.list(Ack.string()).unique().nullable()"),
            isNot(contains("required:")), // No required fields means no required parameter
          ])),
        },
      );
    });

    test('should handle complex nested collection types', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/complex_collections.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class ComplexModel {
  final List<List<String>> matrix;
  final Map<String, List<int>> grouped;
  final Set<String> unique;
  final Map<String, Map<String, dynamic>> nested;
  final List<Map<String, Set<int>>> superComplex;
  
  ComplexModel({
    required this.matrix,
    required this.grouped,
    required this.unique,
    required this.nested,
    required this.superComplex,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/complex_collections.g.dart': decodedMatches(allOf([
            contains('final complexModelSchema = Ack.object('),
            contains("'matrix': Ack.list(Ack.list(Ack.string()))"),
            contains("'grouped': Ack.map(Ack.list(Ack.integer()))"),
            contains("'unique': Ack.list(Ack.string()).unique()"),
            contains("'nested': Ack.map(Ack.map(Ack.any()))"),
            contains("'superComplex': Ack.list(Ack.map(Ack.list(Ack.integer()).unique()))"),
          ])),
        },
      );
    });
  });
}