import 'package:test/test.dart';
import 'package:build_test/build_test.dart';
import 'package:ack_generator/builder.dart';
import 'dart:io';

import '../test_utils/test_assets.dart';

void main() {
  group('Golden Tests', () {
    test('user schema golden test', () async {
      final builder = ackGenerator(BuilderOptions.empty);
      
      final result = await _generateCode(builder, '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(description: 'Represents a system user')
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
  
  @AckField(jsonKey: 'full_name')
  final String fullName;
  
  @AckField(constraints: ['positive()', 'max(150)'])
  final int? age;
  
  final List<String> roles;
  
  final Address? address;
  
  User({
    required this.username,
    required this.email,
    required this.fullName,
    this.age,
    required this.roles,
    this.address,
  });
}

@AckModel()
class Address {
  final String street;
  final String city;
  final String? zipCode;
  
  Address({
    required this.street,
    required this.city,
    this.zipCode,
  });
}
''');

      // Compare with golden file
      final goldenFile = File('test/golden/user_schema.dart.golden');
      if (goldenFile.existsSync()) {
        final golden = goldenFile.readAsStringSync();
        expect(result, equals(golden));
      } else {
        // Create golden file if it doesn't exist
        await goldenFile.create(recursive: true);
        await goldenFile.writeAsString(result);
        print('Created golden file: ${goldenFile.path}');
      }
    });

    test('complex nested schema golden test', () async {
      final builder = ackGenerator(BuilderOptions.empty);
      
      final result = await _generateCode(builder, '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Order {
  final String id;
  final Customer customer;
  final List<OrderItem> items;
  final ShippingInfo shipping;
  final PaymentInfo? payment;
  final double totalAmount;
  final OrderStatus status;
  
  Order({
    required this.id,
    required this.customer,
    required this.items,
    required this.shipping,
    this.payment,
    required this.totalAmount,
    required this.status,
  });
}

@AckModel()
class Customer {
  final String id;
  final String name;
  final String email;
  
  Customer({
    required this.id,
    required this.name,
    required this.email,
  });
}

@AckModel()
class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  
  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });
}

@AckModel()
class ShippingInfo {
  final Address address;
  final String method;
  final double cost;
  
  ShippingInfo({
    required this.address,
    required this.method,
    required this.cost,
  });
}

@AckModel()
class PaymentInfo {
  final String method;
  final String? transactionId;
  
  PaymentInfo({
    required this.method,
    this.transactionId,
  });
}

@AckModel()
class Address {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  
  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });
}

enum OrderStatus { pending, processing, shipped, delivered, cancelled }
''');

      // Compare with golden file
      final goldenFile = File('test/golden/order_schema.dart.golden');
      if (goldenFile.existsSync()) {
        final golden = goldenFile.readAsStringSync();
        expect(result, equals(golden));
      } else {
        // Create golden file if it doesn't exist
        await goldenFile.create(recursive: true);
        await goldenFile.writeAsString(result);
        print('Created golden file: ${goldenFile.path}');
      }
    });
  });
}

Future<String> _generateCode(dynamic builder, String source) async {
  final srcs = {
    ...allAssets,
    'test_pkg|lib/model.dart': source,
  };

  final writer = InMemoryAssetWriter();
  await testBuilder(
    builder,
    srcs,
    writer: writer,
  );

  final outputId = AssetId('test_pkg', 'lib/model.ack.g.part');
  return String.fromCharCodes(writer.assets[outputId]!);
}
