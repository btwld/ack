import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  group('Schema generation using build_runner', () {
    test('generates schema files for annotated classes', () async {
      // Simulate the input Dart file content with annotated classes
      const productModelContent = '''
import 'package:ack/ack.dart';

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

      // Instantiate the builder with empty options
      final builder = schemaModelBuilder(BuilderOptions.empty);

      // Run the test using build_test to simulate the build process
      await testBuilder(
        builder,
        {
          'a|lib/product_model.dart': productModelContent,
        },
        outputs: {
          'a|lib/product_model.g.dart': decodedMatches(
            allOf(
              contains('class ProductSchema extends SchemaModel<Product>'),
              contains('class CategorySchema extends SchemaModel<Category>'),
              contains("'id': Ack.string.isNotEmpty()"),
              contains("'name': Ack.string.isNotEmpty()"),
              contains("'imageUrl': Ack.string.nullable()"),
              contains(
                "required: ['id', 'name', 'description', 'price', 'category']",
              ),
              contains('additionalProperties: true'),
            ),
          ),
        },
        reader: await PackageAssetReader.currentIsolate(),
      );
    });
  });
}
