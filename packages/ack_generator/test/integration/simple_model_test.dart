import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('Simple Model Integration Tests', () {
    test('generates schema for simple model with primitive fields', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/user.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  final String name;
  final int age;
  final String? email;
  
  User({required this.name, required this.age, this.email});
}
''',
        },
        outputs: {
          'test_pkg|lib/user.g.dart': decodedMatches(
            allOf([
              contains('final userSchema = Ack.object('),
              contains('/// Generated schema for User'),
              contains("'name': Ack.string()"),
              contains("'age': Ack.integer()"),
              contains("'email': Ack.string().optional()"),
              // final syntax doesn't use return
            ]),
          ),
        },
      );
    });

    test('generates schema with custom schema name', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(schemaName: 'CustomUserSchema', description: 'A custom user schema')
class User {
  final String id;
  
  User({required this.id});
}
''',
        },
        outputs: {
          'test_pkg|lib/model.g.dart': decodedMatches(
            allOf([
              contains('final customUserSchema = Ack.object('),
              contains('/// Generated schema for User'),
              contains('/// A custom user schema'),
              contains("'id': Ack.string()"),
            ]),
          ),
        },
      );
    });

    test('handles all primitive types correctly', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/primitives.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class AllPrimitives {
  final String text;
  final int count;
  final double price;
  final num number;
  final bool active;
  
  AllPrimitives({
    required this.text,
    required this.count,
    required this.price,
    required this.number,
    required this.active,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/primitives.g.dart': decodedMatches(
            allOf([
              contains('final allPrimitivesSchema = Ack.object('),
              contains("'text': Ack.string()"),
              contains("'count': Ack.integer()"),
              contains("'price': Ack.double()"),
              contains("'number': Ack.double()"),
              contains("'active': Ack.boolean()"),
            ]),
          ),
        },
      );
    });
  });
}
