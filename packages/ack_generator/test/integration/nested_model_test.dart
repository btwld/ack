import 'package:test/test.dart';
import 'package:build_test/build_test.dart';
import 'package:ack_generator/builder.dart';

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
        generates: {
          'test_pkg|lib/models.ack.g.part': allOf([
            // Address schema
            contains('class AddressSchema extends SchemaModel'),
            contains("'street': Ack.string"),
            contains("'city': Ack.string"),
            contains("'zipCode': Ack.string"),
            
            // User schema
            contains('class UserSchema extends SchemaModel'),
            contains("'address': AddressSchema().definition"),
            contains("'mailingAddress': AddressSchema().definition.nullable()"),
            
            // Nested getters
            contains('AddressSchema get address {'),
            contains("final data = getValue<Map<String, Object?>>('address');"),
            contains('return AddressSchema().parse(data);'),
            
            contains('AddressSchema? get mailingAddress {'),
            contains("final data = getValueOrNull<Map<String, Object?>>('mailingAddress');"),
            contains('return data != null ? AddressSchema().parse(data) : null;'),
          ]),
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
        generates: {
          'test_pkg|lib/order.ack.g.part': allOf([
            contains("'items': Ack.list(OrderItemSchema().definition)"),
            contains('List<OrderItemSchema> get items {'),
            contains("getValue<List>('items')"),
            contains('.cast<Map<String, Object?>>()'),
            contains('.map((item) => OrderItemSchema().parse(item))'),
            contains('.toList();'),
          ]),
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
        generates: {
          'test_pkg|lib/company.ack.g.part': allOf([
            // Contact schema
            contains('class ContactSchema extends SchemaModel'),
            
            // Department schema  
            contains('class DepartmentSchema extends SchemaModel'),
            contains("'manager': ContactSchema().definition"),
            contains("'employees': Ack.list(ContactSchema().definition)"),
            
            // Company schema
            contains('class CompanySchema extends SchemaModel'),
            contains("'departments': Ack.list(DepartmentSchema().definition)"),
            
            // Nested list getter
            contains('List<DepartmentSchema> get departments'),
          ]),
        },
      );
    });
  });
}
