import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('Complex Model Integration Tests', () {
    test('generates schema with parameter constraints', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/user.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable()
class User {
  final String username;
  final String email;
  final int? age;

  const User({
    @MinLength(3)
    @MaxLength(50)
    required this.username,
    @Email()
    required this.email,
    @Positive()
    @Max(150)
    this.age,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/user.g.dart': decodedMatches(
            allOf([
              contains("'username': Ack.string().minLength(3).maxLength(50)"),
              contains("'email': Ack.string().email()"),
              contains("'age': Ack.integer()"),
              contains('.max(150)'),
              contains('.positive()'),
              contains('.optional()'),
              contains('.nullable()'),
            ]),
          ),
        },
      );
    });

    test('generates schema with custom parameter keys', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/api_model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable()
class ApiResponse {
  final String id;
  final String createdAt;
  final bool isSuccessful;

  const ApiResponse({
    @SchemaKey('response_id') required this.id,
    @SchemaKey('created_at') required this.createdAt,
    @SchemaKey('is_successful') required this.isSuccessful,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/api_model.g.dart': decodedMatches(
            allOf([
              contains("'response_id': Ack.string()"),
              contains("'created_at': Ack.string()"),
              contains("'is_successful': Ack.boolean()"),
            ]),
          ),
        },
      );
    });

    test('treats defaulted named parameters as optional', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/product.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable()
class Product {
  final String id;
  final String name;
  final double price;
  final String? description;
  final int? stock;
  final List<String>? tags;
  final bool isActive;

  const Product({
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
          'test_pkg|lib/product.g.dart': decodedMatches(
            allOf([
              contains("'id': Ack.string()"),
              contains("'name': Ack.string()"),
              contains("'price': Ack.double()"),
              contains("'description': Ack.string().optional().nullable()"),
              contains("'stock': Ack.integer().optional().nullable()"),
              contains("'tags': Ack.list(Ack.string()).optional().nullable()"),
              contains("'isActive': Ack.boolean().optional()"),
            ]),
          ),
        },
      );
    });
  });
}
