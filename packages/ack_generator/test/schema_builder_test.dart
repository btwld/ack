import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaModelBuilder', () {
    test('generates schema for a product model', () async {
      final builder = schemaModelBuilder(BuilderOptions.empty);

      const productModel = '''
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

      await testBuilder(
        builder,
        {
          'a|lib/product_model.dart': productModel,
        },
        outputs: {
          'a|lib/product_model.g.dart': decodedMatches(
            allOf([
              contains('ProductSchema'),
              contains('Product parse(Object? input, {String? debugName})'),
              contains('Product? tryParse(Object? input, {String? debugName})'),
            ]),
          ),
        },
        reader: await PackageAssetReader.currentIsolate(),
      );
    });

    test('no output for model without Schema annotation', () async {
      final builder = schemaModelBuilder(BuilderOptions.empty);

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
  });
}
