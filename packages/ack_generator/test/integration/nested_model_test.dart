import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('Nested Model Integration Tests', () {
    test('generates schema with nested models', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/models.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Address {
  final String street;
  final String city;
  final String zipCode;
  
  Address({
    required this.street,
    required this.city,
    required this.zipCode,
  });
}

@AckModel()
class User {
  final String name;
  final Address address;
  final Address? mailingAddress;
  
  User({
    required this.name,
    required this.address,
    this.mailingAddress,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/models.g.dart': decodedMatches(
            allOf([
              // Address schema
              contains('final addressSchema = Ack.object('),
              contains("'street': Ack.string"),
              contains("'city': Ack.string"),
              contains("'zipCode': Ack.string"),

              // User schema
              contains('final userSchema = Ack.object('),
              contains("'address': addressSchema"),
              contains("'mailingAddress': addressSchema.optional()"),
            ]),
          ),
        },
      );
    });

    test('generates schema with lists of nested models', () async {
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
  final double totalAmount;
  
  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/order.g.dart': decodedMatches(
            allOf([
              contains("'items': Ack.list(orderItemSchema)"),
              contains('final orderItemSchema = Ack.object('),
              contains('final orderSchema = Ack.object('),
            ]),
          ),
        },
      );
    });

    test('handles deeply nested models', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/company.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Contact {
  final String name;
  final String email;
  final String? phone;
  
  Contact({
    required this.name,
    required this.email,
    this.phone,
  });
}

@AckModel()
class Department {
  final String name;
  final Contact manager;
  final List<Contact> employees;
  
  Department({
    required this.name,
    required this.manager,
    required this.employees,
  });
}

@AckModel()
class Company {
  final String name;
  final List<Department> departments;
  
  Company({
    required this.name,
    required this.departments,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/company.g.dart': decodedMatches(
            allOf([
              // Contact schema
              contains('final contactSchema = Ack.object('),
              contains("'phone': Ack.string().optional()"),

              // Department schema
              contains('final departmentSchema = Ack.object('),
              contains("'manager': contactSchema"),
              contains("'employees': Ack.list(contactSchema)"),

              // Company schema
              contains('final companySchema = Ack.object('),
              contains("'departments': Ack.list(departmentSchema)"),
            ]),
          ),
        },
      );
    });
  });
}
