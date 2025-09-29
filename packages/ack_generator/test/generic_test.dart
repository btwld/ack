import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('Generic Type Support Tests', () {
    test('should handle generic type parameters with Ack.any()', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/generic.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Container<T> {
  final String id;
  final T value;
  
  Container({required this.id, required this.value});
}
''',
        },
        outputs: {
          'test_pkg|lib/generic.g.dart': decodedMatches(allOf([
            contains('final containerSchema = Ack.object('),
            contains("'id': Ack.string()"),
            // Generic type T should use Ack.any() instead of TSchema
            contains("'value': Ack.any()"),
          ])),
        },
      );
    });

    test('should handle nullable generic types', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/nullable_generic.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Response<T> {
  final bool success;
  final T? data;
  
  Response({required this.success, this.data});
}
''',
        },
        outputs: {
          'test_pkg|lib/nullable_generic.g.dart': decodedMatches(allOf([
            contains('final responseSchema = Ack.object('),
            contains("'success': Ack.boolean()"),
            // Nullable generic type should use Ack.any().optional().nullable()
            contains("'data': Ack.any().optional().nullable()"),
          ])),
        },
      );
    });

    test('should handle list of generic types', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/list_generic.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Collection<T> {
  final String name;
  final List<T> items;
  
  Collection({required this.name, required this.items});
}
''',
        },
        outputs: {
          'test_pkg|lib/list_generic.g.dart': decodedMatches(allOf([
            contains('final collectionSchema = Ack.object('),
            contains("'name': Ack.string()"),
            // List of generic type should use Ack.list(Ack.any)
            contains("'items': Ack.list(Ack.any())"),
          ])),
        },
      );
    });
  });
}
