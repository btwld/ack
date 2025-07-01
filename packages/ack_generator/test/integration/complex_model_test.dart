import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('Complex Model Integration Tests', () {
    test('generates schema with field constraints', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/user.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  @AckField(
    required: true,
    constraints: ['notEmpty()', 'minLength(3)', 'maxLength(50)'],
  )
  final String username;
  
  @AckField(
    required: true,
    constraints: ['email()'],
  )
  final String email;
  
  @AckField(
    constraints: ['positive()', 'max(150)'],
  )
  final int? age;
  
  User({
    required this.username,
    required this.email,
    this.age,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/user.g.dart': decodedMatches(allOf([
            contains('ObjectSchema userSchema()'),
            contains(
                "'username': Ack.string().notEmpty().minLength(3).maxLength(50)"),
            contains("'email': Ack.string().email()"),
            contains("'age': Ack.integer().positive().max(150).nullable()"),
            contains("required: ['username', 'email']"),
          ])),
        },
      );
    });

    test('generates schema with custom JSON keys', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/api_model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class ApiResponse {
  @AckField(jsonKey: 'response_id')
  final String id;
  
  @AckField(jsonKey: 'created_at')
  final String createdAt;
  
  @AckField(jsonKey: 'is_successful')
  final bool isSuccessful;
  
  ApiResponse({
    required this.id,
    required this.createdAt,
    required this.isSuccessful,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/api_model.g.dart': decodedMatches(allOf([
            contains('ObjectSchema apiResponseSchema()'),
            contains("'response_id': Ack.string()"),
            contains("'created_at': Ack.string()"),
            contains("'is_successful': Ack.boolean()"),
            contains("required: ['response_id', 'created_at', 'is_successful']"),
          ])),
        },
      );
    });

    test('generates schema with lists', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/collection.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Collection {
  final List<String> tags;
  final List<int> scores;
  final List<String>? categories;
  
  Collection({
    required this.tags,
    required this.scores,
    this.categories,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/collection.g.dart': decodedMatches(allOf([
            contains('ObjectSchema collectionSchema()'),
            contains("'tags': Ack.list(Ack.string())"),
            contains("'scores': Ack.list(Ack.integer())"),
            contains("'categories': Ack.list(Ack.string()).nullable()"),
            contains("required: ['tags', 'scores']"),
          ])),
        },
      );
    });

    test('handles mixed required and optional fields', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/product.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Product {
  final String id;
  final String name;
  final double price;
  final String? description;
  final int? stock;
  final List<String>? tags;
  final bool isActive;
  
  Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.stock,
    this.tags,
    this.isActive = true,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/product.g.dart': decodedMatches(allOf([
            contains('ObjectSchema productSchema()'),
            contains("required: ['id', 'name', 'price', 'isActive']"),
            contains("'description': Ack.string().nullable()"),
            contains("'stock': Ack.integer().nullable()"),
            contains("'tags': Ack.list(Ack.string()).nullable()"),
          ])),
        },
      );
    });
  });
}
