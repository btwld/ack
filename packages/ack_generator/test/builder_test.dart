import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaModelBuilder', () {
    final builder = schemaModelBuilder(BuilderOptions.empty);

    test('generates schema for a simple product model', () async {
      const productModel = '''
import 'package:ack_generator/ack_generator.dart';

@Schema(
  description: 'A product model with validation',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class Product {
  @IsNotEmpty()
  final String id;
  
  @IsNotEmpty()
  final String name;
  
  @IsNotEmpty()
  final String description;
  
  final double price;
  
  @Nullable()
  final String? imageUrl;
  
  @Required()
  final Category category;
  
  final Map<String, dynamic> metadata;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    this.metadata = const {},
  });
}

@Schema(
  description: 'A category for organizing products',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class Category {
  @IsNotEmpty()
  final String id;
  
  @IsNotEmpty()
  final String name;
  
  @Nullable()
  final String? description;
  
  final Map<String, dynamic> metadata;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.metadata = const {},
  });
}
''';

      await testBuilder(
        builder,
        {
          'a|lib/product_model.dart': productModel,
        },
        outputs: {
          'a|lib/product_model.g.dart': decodedMatches(
            allOf([
              contains('class ProductSchema extends SchemaModel<Product>'),
              contains('class CategorySchema extends SchemaModel<Category>'),
              contains("'id': Ack.string.isNotEmpty()"),
              contains("'name': Ack.string.isNotEmpty()"),
              contains("'price': Ack.double"),
              contains("'imageUrl': Ack.string.nullable()"),
              contains('Product parse(Object? input, {String? debugName})'),
              contains('Product? tryParse(Object? input, {String? debugName})'),
              predicate(
                (String content) =>
                    content.contains(
                      "required: ['id', 'name', 'description', 'price', 'category']",
                    ) &&
                    content.contains('additionalProperties: true'),
                'contains required fields and additionalProperties',
              ),
            ]),
          ),
        },
        reader: await PackageAssetReader.currentIsolate(),
      );
    });

    test('generates schema with validation constraints', () async {
      const userModel = '''
import 'package:ack_generator/ack_generator.dart';

@Schema(
  description: 'A user model with validation',
)
class User {
  @IsEmail()
  final String email;
  
  @IsNotEmpty()
  @MinLength(3)
  final String name;
  
  @Min(18)
  final int age;
  
  User({
    required this.email,
    required this.name,
    required this.age,
  });
}
''';

      await testBuilder(
        builder,
        {
          'a|lib/user_model.dart': userModel,
        },
        outputs: {
          'a|lib/user_model.g.dart': decodedMatches(
            allOf([
              contains('class UserSchema extends SchemaModel<User>'),
              contains("'email': Ack.string.isEmail()"),
              contains("'name': Ack.string.isNotEmpty().minLength(3)"),
              contains("'age': Ack.int.min(18)"),
              contains("required: ['email', 'name', 'age']"),
              contains('User parse(Object? input, {String? debugName})'),
              contains('User? tryParse(Object? input, {String? debugName})'),
            ]),
          ),
        },
        reader: await PackageAssetReader.currentIsolate(),
      );
    });

    test('no output for model without Schema annotation', () async {
      const plainModel = '''
class SimpleProduct {
  final String id;
  final String name;
  final double price;

  SimpleProduct({
    required this.id,
    required this.name,
    required this.price,
  });
}
''';

      await testBuilder(
        builder,
        {
          'a|lib/simple_product.dart': plainModel,
        },
        outputs: {}, // No outputs expected
        reader: await PackageAssetReader.currentIsolate(),
      );
    });

    test('validates that annotated element is a class', () async {
      const invalidUsage = '''
import 'package:ack_generator/ack_generator.dart';

@Schema(description: 'This is invalid')
void invalidFunction() {}
''';

      // For invalid usage we expect a build error to be logged
      expect(
        () async {
          await testBuilder(
            builder,
            {
              'a|lib/invalid.dart': invalidUsage,
            },
            outputs: {},
            reader: await PackageAssetReader.currentIsolate(),
          );
        },
        throwsA(anything),
      );
    });
  });
}
