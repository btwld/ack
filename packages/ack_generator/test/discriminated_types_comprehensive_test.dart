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

    test(
      'canonicalizes transformed discriminator keys across aligned subtypes',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/transformed_discriminator.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'transformed_discriminator.g.dart';

@Schemable(discriminatedKey: 'eventType')
sealed class Event {
  const Event();
}

@Schemable(discriminatedValue: 'created', caseStyle: CaseStyle.snakeCase)
class CreatedEvent extends Event {
  final String eventType;
  final String payload;

  const CreatedEvent({
    required this.eventType,
    required this.payload,
  });
}

@Schemable(discriminatedValue: 'updated', caseStyle: CaseStyle.snakeCase)
class UpdatedEvent extends Event {
  final String eventType;
  final int version;

  const UpdatedEvent({
    required this.eventType,
    required this.version,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/transformed_discriminator.g.dart': decodedMatches(
              allOf([
                contains('final eventSchema = Ack.discriminated('),
                contains("discriminatorKey: 'event_type'"),
                contains("'event_type': Ack.literal('created')"),
                contains("'event_type': Ack.literal('updated')"),
                predicate<String>((content) {
                  final createdSchemaMatch = RegExp(
                    r'final createdEventSchema = Ack\.object\(\{([^}]+)\}\)',
                    dotAll: true,
                  ).firstMatch(content);
                  final updatedSchemaMatch = RegExp(
                    r'final updatedEventSchema = Ack\.object\(\{([^}]+)\}\)',
                    dotAll: true,
                  ).firstMatch(content);
                  if (createdSchemaMatch == null ||
                      updatedSchemaMatch == null) {
                    return false;
                  }

                  final createdSchema = createdSchemaMatch.group(1)!;
                  final updatedSchema = updatedSchemaMatch.group(1)!;
                  final transformedKeyCount =
                      RegExp(
                        r"'event_type'\s*:",
                      ).allMatches(createdSchema).length +
                      RegExp(
                        r"'event_type'\s*:",
                      ).allMatches(updatedSchema).length;
                  final rawKeyCount =
                      RegExp(
                        r"'eventType'\s*:",
                      ).allMatches(createdSchema).length +
                      RegExp(
                        r"'eventType'\s*:",
                      ).allMatches(updatedSchema).length;

                  return transformedKeyCount == 2 && rawKeyCount == 0;
                }, 'uses only canonical transformed discriminator keys'),
              ]),
            ),
          },
        );
      },
    );

    test(
      'canonicalizes transformed keys across getter-only and transformed leaves',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/getter_and_transformed_discriminator.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'getter_and_transformed_discriminator.g.dart';

@Schemable(discriminatedKey: 'eventType')
sealed class Event {
  const Event();

  String get eventType;
}

@Schemable(discriminatedValue: 'created')
class CreatedEvent extends Event {
  @override
  String get eventType => 'created';

  final String payload;

  const CreatedEvent({required this.payload});
}

@Schemable(discriminatedValue: 'updated', caseStyle: CaseStyle.snakeCase)
class UpdatedEvent extends Event {
  final String eventType;
  final int version;

  const UpdatedEvent({
    required this.eventType,
    required this.version,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/getter_and_transformed_discriminator.g.dart':
                decodedMatches(
                  allOf([
                    contains('final eventSchema = Ack.discriminated('),
                    contains("discriminatorKey: 'event_type'"),
                    contains("'event_type': Ack.literal('created')"),
                    contains("'event_type': Ack.literal('updated')"),
                    predicate<String>((content) {
                      final createdSchemaMatch = RegExp(
                        r'final createdEventSchema = Ack\.object\(\{([^}]+)\}\)',
                        dotAll: true,
                      ).firstMatch(content);
                      final updatedSchemaMatch = RegExp(
                        r'final updatedEventSchema = Ack\.object\(\{([^}]+)\}\)',
                        dotAll: true,
                      ).firstMatch(content);
                      if (createdSchemaMatch == null ||
                          updatedSchemaMatch == null) {
                        return false;
                      }

                      final createdSchema = createdSchemaMatch.group(1)!;
                      final updatedSchema = updatedSchemaMatch.group(1)!;
                      final transformedKeyCount =
                          RegExp(
                            r"'event_type'\s*:",
                          ).allMatches(createdSchema).length +
                          RegExp(
                            r"'event_type'\s*:",
                          ).allMatches(updatedSchema).length;
                      final rawKeyCount =
                          RegExp(
                            r"'eventType'\s*:",
                          ).allMatches(createdSchema).length +
                          RegExp(
                            r"'eventType'\s*:",
                          ).allMatches(updatedSchema).length;

                      return transformedKeyCount == 2 && rawKeyCount == 0;
                    }, 'uses only canonical transformed discriminator keys'),
                  ]),
                ),
          },
        );
      },
    );

    test(
      'canonicalizes transformed keys across getter-only and annotated leaves',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/getter_and_annotated_discriminator.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'getter_and_annotated_discriminator.g.dart';

@Schemable(discriminatedKey: 'eventType')
sealed class Event {
  const Event();

  String get eventType;
}

@Schemable(discriminatedValue: 'created')
class CreatedEvent extends Event {
  @override
  String get eventType => 'created';

  final String payload;

  const CreatedEvent({required this.payload});
}

@Schemable(discriminatedValue: 'updated')
class UpdatedEvent extends Event {
  final String eventType;
  final int version;

  const UpdatedEvent({
    @SchemaKey('event_type') required this.eventType,
    required this.version,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/getter_and_annotated_discriminator.g.dart':
                decodedMatches(
                  allOf([
                    contains('final eventSchema = Ack.discriminated('),
                    contains("discriminatorKey: 'event_type'"),
                    contains("'event_type': Ack.literal('created')"),
                    contains("'event_type': Ack.literal('updated')"),
                    isNot(contains("'eventType': Ack.literal('created')")),
                    isNot(contains("'eventType': Ack.literal('updated')")),
                  ]),
                ),
          },
        );
      },
    );

    test(
      'preserves declared discriminator key when all leaves are getter-only',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/getter_only_discriminator.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

part 'getter_only_discriminator.g.dart';

@Schemable(discriminatedKey: 'eventType')
sealed class Event {
  const Event();

  String get eventType;
}

@Schemable(discriminatedValue: 'created')
class CreatedEvent extends Event {
  @override
  String get eventType => 'created';

  final String payload;

  const CreatedEvent({required this.payload});
}

@Schemable(discriminatedValue: 'updated')
class UpdatedEvent extends Event {
  @override
  String get eventType => 'updated';

  final int version;

  const UpdatedEvent({required this.version});
}
''',
          },
          outputs: {
            'test_pkg|lib/getter_only_discriminator.g.dart': decodedMatches(
              allOf([
                contains('final eventSchema = Ack.discriminated('),
                contains("discriminatorKey: 'eventType'"),
                contains("'eventType': Ack.literal('created')"),
                contains("'eventType': Ack.literal('updated')"),
                isNot(contains("'event_type': Ack.literal('created')")),
                isNot(contains("'event_type': Ack.literal('updated')")),
              ]),
            ),
          },
        );
      },
    );

    test('rejects conflicting transformed discriminator keys', () async {
      final builder = ackGenerator(BuilderOptions.empty);
      var sawExpectedError = false;

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/invalid.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(discriminatedKey: 'eventType')
sealed class Event {
  const Event();
}

@Schemable(discriminatedValue: 'created', caseStyle: CaseStyle.snakeCase)
class CreatedEvent extends Event {
  final String eventType;
  final String payload;

  const CreatedEvent({
    required this.eventType,
    required this.payload,
  });
}

@Schemable(discriminatedValue: 'deleted')
class DeletedEvent extends Event {
  final String eventType;
  final String reason;

  const DeletedEvent({
    @SchemaKey('event-type') required this.eventType,
    required this.reason,
  });
}
''',
        },
        outputs: const {},
        onLog: (log) {
          if (log.level.name == 'SEVERE' &&
              log.message.contains('conflicting discriminator keys') &&
              log.message.contains('event_type') &&
              log.message.contains('event-type')) {
            sawExpectedError = true;
          }
        },
      );

      expect(sawExpectedError, isTrue);
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
