import 'dart:io';

import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('Golden Tests', () {
    test('user schema golden test', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      // Read the golden file
      final goldenFile =
          File(p.join('test', 'golden', 'user_schema.dart.golden'));
      final expectedContent = await goldenFile.readAsString();

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/user.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class User {
  final String id;
  final String name;
  final String email;
  final int? age;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    this.age,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/user.ack.g.part': decodedMatches(
            predicate<String>(
              (actual) {
                // Normalize whitespace for comparison
                final normalizedActual =
                    actual.trim().replaceAll(RegExp(r'\s+'), ' ');
                final normalizedExpected =
                    expectedContent.trim().replaceAll(RegExp(r'\s+'), ' ');
                return normalizedActual.contains(normalizedExpected.substring(
                  normalizedExpected.indexOf('class UserSchema'),
                ));
              },
              'matches golden file content',
            ),
          ),
        },
      );
    });

    test('complex nested schema golden test', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/order.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class OrderItem {
  final String productId;
  final int quantity;
  final double price;
  
  OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });
}

@AckModel()
class Order {
  final String id;
  final List<OrderItem> items;
  final DateTime createdAt;
  
  Order({
    required this.id,
    required this.items,
    required this.createdAt,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/order.ack.g.part': decodedMatches(
            predicate<String>(
              (actual) {
                // Check that both schemas are present
                final containsOrderItem = actual
                    .contains('class OrderItemSchema extends SchemaModel');
                final containsOrder =
                    actual.contains('class OrderSchema extends SchemaModel');

                // Check key content
                final hasOrderItemFields =
                    actual.contains("'productId': Ack.string") &&
                        actual.contains("'quantity': Ack.integer") &&
                        actual.contains("'price': Ack.double");

                final hasOrderFields = actual.contains("'id': Ack.string") &&
                    actual.contains(
                        "'items': Ack.list(OrderItemSchema().definition)") &&
                    actual.contains("'createdAt': DateTimeSchema().definition");

                return containsOrderItem &&
                    containsOrder &&
                    hasOrderItemFields &&
                    hasOrderFields;
              },
              'matches order golden file content',
            ),
          ),
        },
      );
    });
  });
}
