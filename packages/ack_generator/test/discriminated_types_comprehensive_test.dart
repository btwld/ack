import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('Discriminated types', () {
    test(
      'generates discriminated schema for a simple sealed hierarchy',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/animals.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'animals.g.dart';

@Schemable(discriminatedKey: 'type')
sealed class Animal {
  const Animal();
}

@Schemable(discriminatedValue: 'cat')
class Cat extends Animal {
  final bool meow;
  final int lives;

  const Cat({required this.meow, this.lives = 9});
}

@Schemable(discriminatedValue: 'dog')
class Dog extends Animal {
  final bool bark;
  final String breed;

  const Dog({required this.bark, required this.breed});
}
''',
          },
          outputs: {
            'test_pkg|lib/animals.g.dart': decodedMatches(
              allOf([
                contains('final animalSchema = Ack.discriminated('),
                contains("discriminatorKey: 'type'"),
                contains("'cat': catSchema"),
                contains("'dog': dogSchema"),
                contains("'type': Ack.literal('cat')"),
                contains("'type': Ack.literal('dog')"),
              ]),
            ),
          },
        );
      },
    );

    test(
      'handles multiple discriminated hierarchies in the same file',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/multi_hierarchy.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'multi_hierarchy.g.dart';

@Schemable(discriminatedKey: 'type')
sealed class Animal {
  const Animal();
}

@Schemable(discriminatedValue: 'cat')
class Cat extends Animal {
  final bool meow;

  const Cat({required this.meow});
}

@Schemable(discriminatedKey: 'kind')
sealed class Shape {
  const Shape();
}

@Schemable(discriminatedValue: 'circle')
class Circle extends Shape {
  final double radius;

  const Circle({required this.radius});
}
''',
          },
          outputs: {
            'test_pkg|lib/multi_hierarchy.g.dart': decodedMatches(
              allOf([
                contains('final animalSchema = Ack.discriminated('),
                contains("discriminatorKey: 'type'"),
                contains("'cat': catSchema"),
                contains('final shapeSchema = Ack.discriminated('),
                contains("discriminatorKey: 'kind'"),
                contains("'circle': circleSchema"),
              ]),
            ),
          },
        );
      },
    );

    test('supports nested models inside discriminated leaves', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/complex_discriminated.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'complex_discriminated.g.dart';

@Schemable()
class Address {
  final String street;
  final String city;

  const Address({required this.street, required this.city});
}

@Schemable(discriminatedKey: 'personType')
sealed class Person {
  const Person();
}

@Schemable(discriminatedValue: 'employee')
class Employee extends Person {
  final String name;
  final Address address;
  final String employeeId;
  final double salary;

  const Employee({
    required this.name,
    required this.address,
    required this.employeeId,
    required this.salary,
  });
}

@Schemable(discriminatedValue: 'customer')
class Customer extends Person {
  final String name;
  final Address address;
  final String customerId;
  final List<String> preferences;

  const Customer({
    required this.name,
    required this.address,
    required this.customerId,
    required this.preferences,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/complex_discriminated.g.dart': decodedMatches(
            allOf([
              contains('final personSchema = Ack.discriminated('),
              contains("'employee': employeeSchema"),
              contains("'customer': customerSchema"),
              contains("'address': addressSchema"),
              contains("'preferences': Ack.list(Ack.string())"),
            ]),
          ),
        },
      );
    });

    test('supports nested sealed discriminated roots', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/deep_hierarchy.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'deep_hierarchy.g.dart';

@Schemable(discriminatedKey: 'vehicleType')
sealed class Vehicle {
  const Vehicle();
}

@Schemable(discriminatedKey: 'landType')
sealed class LandVehicle extends Vehicle {
  const LandVehicle();
}

@Schemable(discriminatedValue: 'car')
class Car extends LandVehicle {
  final int doors;
  final String fuelType;

  const Car({required this.doors, required this.fuelType});
}

@Schemable(discriminatedValue: 'motorcycle')
class Motorcycle extends LandVehicle {
  final bool hasSidecar;
  final int engineSize;

  const Motorcycle({required this.hasSidecar, required this.engineSize});
}

@Schemable(discriminatedValue: 'boat')
class Boat extends Vehicle {
  final double length;
  final String propulsionType;

  const Boat({required this.length, required this.propulsionType});
}
''',
        },
        outputs: {
          'test_pkg|lib/deep_hierarchy.g.dart': decodedMatches(
            allOf([
              contains('final vehicleSchema = Ack.discriminated('),
              contains("discriminatorKey: 'vehicleType'"),
              contains("'car': carSchema"),
              contains("'motorcycle': motorcycleSchema"),
              contains("'boat': boatSchema"),
              contains('final landVehicleSchema = Ack.discriminated('),
              contains("discriminatorKey: 'landType'"),
            ]),
          ),
        },
      );
    });

    test('rejects mutually exclusive discriminator configuration', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await expectLater(
        () => testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/invalid.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(discriminatedKey: 'type', discriminatedValue: 'invalid')
class InvalidModel {
  final String name;

  const InvalidModel({required this.name});
}
''',
          },
          outputs: {'test_pkg|lib/invalid.g.dart': anything},
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('requires discriminated roots to be sealed', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await expectLater(
        () => testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/invalid.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(discriminatedKey: 'type')
class ConcreteWithKey {
  final String name;

  const ConcreteWithKey({required this.name});
}
''',
          },
          outputs: {'test_pkg|lib/invalid.g.dart': anything},
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('requires discriminated leaves to be concrete', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await expectLater(
        () => testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/invalid.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(discriminatedValue: 'abstract')
abstract class AbstractWithValue {
  final String name;

  const AbstractWithValue({required this.name});
}
''',
          },
          outputs: {'test_pkg|lib/invalid.g.dart': anything},
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects sealed roots without annotated leaves', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await expectLater(
        () => testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/invalid.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(discriminatedKey: 'type')
sealed class Base {
  const Base();
}
''',
          },
          outputs: {'test_pkg|lib/invalid.g.dart': anything},
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects duplicate discriminator values', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await expectLater(
        () => testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/invalid.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(discriminatedKey: 'type')
sealed class Base {
  const Base();
}

@Schemable(discriminatedValue: 'duplicate')
class First extends Base {
  final String name;

  const First({required this.name});
}

@Schemable(discriminatedValue: 'duplicate')
class Second extends Base {
  final String description;

  const Second({required this.description});
}
''',
          },
          outputs: {'test_pkg|lib/invalid.g.dart': anything},
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
