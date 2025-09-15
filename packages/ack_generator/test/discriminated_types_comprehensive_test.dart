import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('Discriminated Types Comprehensive Tests', () {
    group('Basic Discriminated Schema Generation', () {
      test('should generate discriminated schema for simple hierarchy',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/animals.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'animals.g.dart';

@AckModel(discriminatedKey: 'type', model: true)
abstract class Animal {
  String get type;
}

@AckModel(discriminatedValue: 'cat', model: true)
class Cat extends Animal {
  @override
  String get type => 'cat';
  
  final bool meow;
  final int lives;
  
  Cat({required this.meow, this.lives = 9});
}

@AckModel(discriminatedValue: 'dog', model: true)
class Dog extends Animal {
  @override
  String get type => 'dog';
  
  final bool bark;
  final String breed;
  
  Dog({required this.bark, required this.breed});
}
''',
          },
          outputs: {
            'test_pkg|lib/animals.g.dart': decodedMatches(allOf([
              // Discriminated schema generation
              contains('final animalSchema = Ack.discriminated('),
              contains("discriminatorKey: 'type'"),
              contains("schemas: {'cat': catSchema, 'dog': dogSchema}"),

              // Individual schemas
              contains('final catSchema = Ack.object({'),
              contains("'meow': Ack.boolean()"),
              contains("'lives': Ack.integer()"),

              contains('final dogSchema = Ack.object({'),
              contains("'bark': Ack.boolean()"),
              contains("'breed': Ack.string()"),

              // Base SchemaModel with switch logic
              contains('class AnimalSchemaModel extends SchemaModel<Animal>'),
              contains('final type = map[\'type\'] as String;'),
              contains('return switch (type) {'),
              contains("'cat' => CatSchemaModel().createFromMap(map)"),
              contains("'dog' => DogSchemaModel().createFromMap(map)"),
              contains('_ => throw ArgumentError('),
              contains(
                  "'Unknown type: \$type. Valid values: \\'cat\\', \\'dog\\'"),

              // Subtype SchemaModels
              contains('class CatSchemaModel extends SchemaModel<Cat>'),
              contains('return Cat('),
              contains('meow: map[\'meow\'] as bool'),
              contains('lives: map[\'lives\'] as int'),

              contains('class DogSchemaModel extends SchemaModel<Dog>'),
              contains('return Dog('),
              contains('bark: map[\'bark\'] as bool'),
              contains('breed: map[\'breed\'] as String'),
            ])),
          },
        );
      });

      test('should handle multiple discriminated hierarchies in same file',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/multi_hierarchy.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'multi_hierarchy.g.dart';

// First hierarchy: Animals
@AckModel(discriminatedKey: 'type')
abstract class Animal {
  String get type;
}

@AckModel(discriminatedValue: 'cat')
class Cat extends Animal {
  @override
  String get type => 'cat';
  final bool meow;
  Cat({required this.meow});
}

// Second hierarchy: Shapes  
@AckModel(discriminatedKey: 'kind')
abstract class Shape {
  String get kind;
}

@AckModel(discriminatedValue: 'circle')
class Circle extends Shape {
  @override
  String get kind => 'circle';
  final double radius;
  Circle({required this.radius});
}
''',
          },
          outputs: {
            'test_pkg|lib/multi_hierarchy.g.dart': decodedMatches(allOf([
              // Two separate discriminated schemas
              contains('final animalSchema = Ack.discriminated('),
              contains("discriminatorKey: 'type'"),
              contains("schemas: {'cat': catSchema}"),

              contains('final shapeSchema = Ack.discriminated('),
              contains("discriminatorKey: 'kind'"),
              contains("schemas: {'circle': circleSchema}"),

              // Individual schemas for each type
              contains('final catSchema = Ack.object({'),
              contains("'meow': Ack.boolean()"),

              contains('final circleSchema = Ack.object({'),
              contains("'radius': Ack.double()"),
            ])),
          },
        );
      });
    });

    group('Complex Discriminated Types', () {
      test('should handle discriminated types with nested models', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/complex_discriminated.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'complex_discriminated.g.dart';

@AckModel()
class Address {
  final String street;
  final String city;
  Address({required this.street, required this.city});
}

@AckModel(discriminatedKey: 'personType', model: true)
abstract class Person {
  String get personType;
  final String name;
  final Address address;
  Person({required this.name, required this.address});
}

@AckModel(discriminatedValue: 'employee', model: true)
class Employee extends Person {
  @override
  String get personType => 'employee';
  
  final String employeeId;
  final double salary;
  
  Employee({
    required super.name,
    required super.address,
    required this.employeeId,
    required this.salary,
  });
}

@AckModel(discriminatedValue: 'customer', model: true)
class Customer extends Person {
  @override
  String get personType => 'customer';
  
  final String customerId;
  final List<String> preferences;
  
  Customer({
    required super.name,
    required super.address,
    required this.customerId,
    required this.preferences,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/complex_discriminated.g.dart': decodedMatches(allOf([
              // Address schema (dependency)
              contains('final addressSchema = Ack.object({'),
              contains("'street': Ack.string()"),
              contains("'city': Ack.string()"),

              // Discriminated person schema
              contains('final personSchema = Ack.discriminated('),
              contains("discriminatorKey: 'personType'"),
              contains(
                  "schemas: {'employee': employeeSchema, 'customer': customerSchema}"),

              // Employee schema with nested address
              contains('final employeeSchema = Ack.object({'),
              contains("'name': Ack.string()"),
              contains("'address': addressSchema"),
              contains("'employeeId': Ack.string()"),
              contains("'salary': Ack.double()"),

              // Customer schema with list
              contains('final customerSchema = Ack.object({'),
              contains("'customerId': Ack.string()"),
              contains("'preferences': Ack.list(Ack.string())"),

              // SchemaModel with complex createFromMap
              contains('class PersonSchemaModel extends SchemaModel<Person>'),
              contains("final personType = map['personType'] as String;"),
              contains(
                  "'employee' => EmployeeSchemaModel().createFromMap(map)"),
              contains(
                  "'customer' => CustomerSchemaModel().createFromMap(map)"),

              // Employee createFromMap with nested model
              contains(
                  'class EmployeeSchemaModel extends SchemaModel<Employee>'),
              contains('return Employee('),
              contains('name: map[\'name\'] as String'),
              contains('address: AddressSchemaModel().createFromMap('),
              contains('employeeId: map[\'employeeId\'] as String'),
              contains('salary: map[\'salary\'] as double'),

              // Customer createFromMap with list
              contains(
                  'class CustomerSchemaModel extends SchemaModel<Customer>'),
              contains('return Customer('),
              contains('customerId: map[\'customerId\'] as String'),
              contains(
                  'preferences: (map[\'preferences\'] as List).cast<String>()'),
            ])),
          },
        );
      });

      test('should handle deeply nested discriminated hierarchies', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/deep_hierarchy.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'deep_hierarchy.g.dart';

@AckModel(discriminatedKey: 'vehicleType')
abstract class Vehicle {
  String get vehicleType;
}

@AckModel(discriminatedKey: 'landType')
abstract class LandVehicle extends Vehicle {
  @override
  String get vehicleType => 'land';
  String get landType;
}

@AckModel(discriminatedValue: 'car')
class Car extends LandVehicle {
  @override
  String get vehicleType => 'land';
  @override
  String get landType => 'car';
  final int doors;
  final String fuelType;
  Car({required this.doors, required this.fuelType});
}

@AckModel(discriminatedValue: 'motorcycle')
class Motorcycle extends LandVehicle {
  @override
  String get vehicleType => 'land';
  @override
  String get landType => 'motorcycle';
  final bool hasSidecar;
  final int engineSize;
  Motorcycle({required this.hasSidecar, required this.engineSize});
}

@AckModel(discriminatedValue: 'boat')
class Boat extends Vehicle {
  @override
  String get vehicleType => 'boat';
  final double length;
  final String propulsionType;
  Boat({required this.length, required this.propulsionType});
}
''',
          },
          outputs: {
            'test_pkg|lib/deep_hierarchy.g.dart': decodedMatches(allOf([
              // Top-level discriminated schema
              contains('final vehicleSchema = Ack.discriminated('),
              contains("discriminatorKey: 'vehicleType'"),
              contains("'car': carSchema"),
              contains("'motorcycle': motorcycleSchema"),
              contains("'boat': boatSchema"),

              // Nested discriminated schema for land vehicles
              contains('final landVehicleSchema = Ack.discriminated('),
              contains("discriminatorKey: 'landType'"),
              contains("'car': carSchema, 'motorcycle': motorcycleSchema"),

              // Leaf schemas
              contains('final carSchema = Ack.object({'),
              contains("'doors': Ack.integer()"),
              contains("'fuelType': Ack.string()"),

              contains('final motorcycleSchema = Ack.object({'),
              contains("'hasSidecar': Ack.boolean()"),
              contains("'engineSize': Ack.integer()"),

              contains('final boatSchema = Ack.object({'),
              contains("'length': Ack.double()"),
              contains("'propulsionType': Ack.string()"),
            ])),
          },
        );
      });
    });

    group('Discriminated Types Validation', () {
      test(
          'should validate discriminatedKey and discriminatedValue are mutually exclusive',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await expectLater(
          () => testBuilder(
            builder,
            {
              ...allAssets,
              'test_pkg|lib/invalid.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(discriminatedKey: 'type', discriminatedValue: 'invalid')
class InvalidModel {
  final String name;
  InvalidModel({required this.name});
}
''',
            },
            outputs: {
              'test_pkg|lib/invalid.g.dart': anything,
            },
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should validate discriminatedKey only on abstract classes',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await expectLater(
          () => testBuilder(
            builder,
            {
              ...allAssets,
              'test_pkg|lib/invalid.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(discriminatedKey: 'type')
class ConcreteWithKey { // Concrete class with discriminatedKey - invalid
  final String name;
  ConcreteWithKey({required this.name});
}
''',
            },
            outputs: {
              'test_pkg|lib/invalid.g.dart': anything,
            },
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should validate discriminatedValue only on concrete classes',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await expectLater(
          () => testBuilder(
            builder,
            {
              ...allAssets,
              'test_pkg|lib/invalid.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(discriminatedValue: 'abstract')
abstract class AbstractWithValue { // Abstract class with discriminatedValue - invalid
  final String name;
  AbstractWithValue({required this.name});
}
''',
            },
            outputs: {
              'test_pkg|lib/invalid.g.dart': anything,
            },
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should validate discriminator field exists in base class',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await expectLater(
          () => testBuilder(
            builder,
            {
              ...allAssets,
              'test_pkg|lib/invalid.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(discriminatedKey: 'missingField')
abstract class BaseWithMissingField { // No field named 'missingField'
  final String name;
  BaseWithMissingField({required this.name});
}
''',
            },
            outputs: {
              'test_pkg|lib/invalid.g.dart': anything,
            },
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should validate duplicate discriminator values', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await expectLater(
          () => testBuilder(
            builder,
            {
              ...allAssets,
              'test_pkg|lib/invalid.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(discriminatedKey: 'type')
abstract class Base {
  String get type;
}

@AckModel(discriminatedValue: 'duplicate')
class First extends Base {
  @override
  String get type => 'duplicate';
  final String name;
  First({required this.name});
}

@AckModel(discriminatedValue: 'duplicate') // Duplicate value - invalid
class Second extends Base {
  @override
  String get type => 'duplicate';
  final String description;
  Second({required this.description});
}
''',
            },
            outputs: {
              'test_pkg|lib/invalid.g.dart': anything,
            },
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
