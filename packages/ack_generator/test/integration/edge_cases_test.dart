import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('Edge Cases and Error Handling', () {
    test('throws error on abstract class', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      // When generator throws an error, no output should be generated
      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
abstract class AbstractModel {
  String get name;
}
''',
        },
        outputs: {
          // Expect no output files when error is thrown
        },
        onLog: (log) {
          if (log.level.name == 'SEVERE') {
            expect(
                log.message, contains('cannot be applied to abstract classes'));
          }
        },
      );
    });

    test('throws error on non-class element', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      // When generator throws an error, no output should be generated
      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
enum Status { active, inactive }
''',
        },
        outputs: {
          // Expect no output files when error is thrown
        },
        onLog: (log) {
          if (log.level.name == 'SEVERE') {
            expect(log.message, contains('can only be applied to classes'));
          }
        },
      );
    });

    test('ignores classes without AckModel annotation', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
class RegularClass {
  final String name;
  
  RegularClass(this.name);
}
''',
        },
        outputs: {},
      );
    });

    test('handles empty class', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/empty.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Empty {}
''',
        },
        outputs: {
          'test_pkg|lib/empty.ack.g.part': decodedMatches(allOf([
            contains('class EmptySchema extends SchemaModel'),
            contains('Ack.object({})'),
            isNot(contains('required:')),
          ])),
        },
      );
    });

    test('handles class with only static fields', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/constants.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Constants {
  static const String apiUrl = 'https://api.example.com';
  static final int timeout = 30;
}
''',
        },
        outputs: {
          'test_pkg|lib/constants.ack.g.part': decodedMatches(allOf([
            contains('class ConstantsSchema extends SchemaModel'),
            contains('Ack.object({})'),
            isNot(contains('apiUrl')),
            isNot(contains('timeout')),
          ])),
        },
      );
    });

    test('handles inherited fields correctly', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/inheritance.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

class BaseEntity {
  final String id;
  final DateTime createdAt;
  
  BaseEntity({required this.id, required this.createdAt});
}

@AckModel()
class User extends BaseEntity {
  final String name;
  final String email;
  
  User({
    required String id,
    required DateTime createdAt,
    required this.name,
    required this.email,
  }) : super(id: id, createdAt: createdAt);
}
''',
        },
        outputs: {
          'test_pkg|lib/inheritance.ack.g.part': decodedMatches(allOf([
            // Should include inherited fields
            contains("'id': Ack.string"),
            contains(
                "'createdAt': DateTimeSchema().definition"), // DateTime uses schema
            contains("'name': Ack.string"),
            contains("'email': Ack.string"),
            contains("required: ["),
            contains("'id'"),
            contains("'createdAt'"),
            contains("'name'"),
            contains("'email'"),
          ])),
        },
      );
    });

    test('handles generic types gracefully', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/generic.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Response<T> {
  final bool success;
  final String? error;
  final T? data;
  
  Response({
    required this.success,
    this.error,
    this.data,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/generic.ack.g.part': decodedMatches(allOf([
            contains('class ResponseSchema extends SchemaModel'),
            contains("'success': Ack.boolean"),
            contains("'error': Ack.string.nullable()"),
            // Generic type T would be treated as dynamic/any
            contains("'data': TSchema().definition.nullable()"),
          ])),
        },
      );
    });
  });
}
