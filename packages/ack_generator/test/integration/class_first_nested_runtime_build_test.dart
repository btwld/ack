@Tags(['integration'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Future<ProcessResult> _run(Directory directory, List<String> arguments) =>
    Process.run('dart', arguments, workingDirectory: directory.path);

void _expectSuccess(ProcessResult result, String command) {
  expect(
    result.exitCode,
    0,
    reason:
        '$command failed\nSTDOUT:\n${result.stdout}\nSTDERR:\n${result.stderr}',
  );
}

Map<String, String> _generatedFiles(Directory directory) => {
  for (final file
      in directory
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.ack.dart') ||
                file.path.endsWith('.ack.g.dart'),
          ))
    p.relative(file.path, from: directory.path): file.readAsStringSync(),
};

void main() {
  test(
    'class-first facades compose across libraries from a clean build',
    () async {
      var projectRoot = Directory.current;
      while (!Directory(
        p.join(projectRoot.path, 'packages', 'ack_generator'),
      ).existsSync()) {
        projectRoot = projectRoot.parent;
      }
      final temporary = await Directory.systemTemp.createTemp(
        'ack_class_first_nested_',
      );
      try {
        Directory(p.join(temporary.path, 'lib')).createSync();
        Directory(p.join(temporary.path, 'test')).createSync();
        File(p.join(temporary.path, 'pubspec.yaml')).writeAsStringSync('''
name: ack_class_first_nested
publish_to: none
environment:
  sdk: '>=3.9.0 <4.0.0'
dependencies:
  ack:
    path: ${p.join(projectRoot.path, 'packages', 'ack')}
dev_dependencies:
  ack_generator:
    path: ${p.join(projectRoot.path, 'packages', 'ack_generator')}
  build_runner: ^2.15.0
  test: ^1.29.0
dependency_overrides:
  ack:
    path: ${p.join(projectRoot.path, 'packages', 'ack')}
''');
        File(p.join(temporary.path, 'lib', 'address.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';

part 'address.ack.dart';
part 'address.ack.g.dart';

@AckModel(schemaName: 'PostalAddressSchema')
final class Address with _$AddressAck {
  const Address({required this.city});

  final String city;

  static final fromJson = PostalAddressSchema.fromJson;
}

@AckModel()
final class AddressBook with _$AddressBookAck {
  const AddressBook({required this.primary, this.secondary});

  final Address primary;
  final Address? secondary;
}
''',
        );
        File(p.join(temporary.path, 'lib', 'customer.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';

import 'address.dart' show Address, PostalAddressSchema;

part 'customer.ack.dart';
part 'customer.ack.g.dart';

@AckModel()
final class Customer with _$CustomerAck {
  const Customer({
    this.primary = const Address(city: 'Default City'),
    this.secondary,
  });

  final Address primary;
  final Address? secondary;
}
''',
        );
        File(
          p.join(temporary.path, 'lib', 'models.dart'),
        ).writeAsStringSync("export 'address.dart';\n");
        File(p.join(temporary.path, 'lib', 'parcel.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';

import 'models.dart' as models;

part 'parcel.ack.dart';
part 'parcel.ack.g.dart';

@AckModel()
final class Parcel with _$ParcelAck {
  const Parcel({required this.destination});

  final models.Address destination;
}
''',
        );
        File(p.join(temporary.path, 'lib', 'north.dart')).writeAsStringSync(r'''
import 'package:ack/ack.dart';

part 'north.ack.dart';
part 'north.ack.g.dart';

@AckModel()
final class Place with _$PlaceAck {
  const Place({required this.name});

  final String name;
}
''');
        File(p.join(temporary.path, 'lib', 'south.dart')).writeAsStringSync(r'''
import 'package:ack/ack.dart';

part 'south.ack.dart';
part 'south.ack.g.dart';

@AckModel()
final class Place with _$PlaceAck {
  const Place({required this.name});

  final String name;
}
''');
        File(p.join(temporary.path, 'lib', 'itinerary.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';

import 'north.dart' as north;
import 'south.dart' as south;

part 'itinerary.ack.dart';
part 'itinerary.ack.g.dart';

@AckModel()
final class Itinerary with _$ItineraryAck {
  const Itinerary({required this.start, required this.finish});

  final north.Place start;
  final south.Place finish;
}
''',
        );
        File(p.join(temporary.path, 'lib', 'pet.dart')).writeAsStringSync(r'''
import 'package:ack/ack.dart';

part 'pet.ack.dart';
part 'pet.ack.g.dart';

@AckModel(discriminatorKey: 'type')
sealed class Pet with _$PetAck {
  const Pet({required this.id});

  final String id;
}

final class Cat extends Pet with _$CatAck {
  const Cat({required super.id, required this.lives});

  final int lives;
}
''');
        File(p.join(temporary.path, 'lib', 'order.dart')).writeAsStringSync(r'''
import 'package:ack/ack.dart';

import 'address.dart' as address;
import 'pet.dart' as pets;

part 'order.ack.dart';
part 'order.ack.g.dart';

@AckModel()
final class Order with _$OrderAck {
  const Order({
    required this.shipping,
    required this.history,
    required this.uniqueAddresses,
    required this.pet,
    required this.cat,
  });

  final address.Address shipping;
  final List<List<address.Address>> history;
  final Set<address.Address> uniqueAddresses;
  final pets.Pet pet;
  final pets.Cat cat;
}
''');
        File(p.join(temporary.path, 'lib', 'legacy.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';

part 'legacy.ack.dart';
part 'legacy.ack.g.dart';

@AckInfer(name: 'LegacyAddress')
final legacyAddressContract = Ack.object({'city': Ack.string()});
''',
        );
        File(p.join(temporary.path, 'lib', 'holder.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';

import 'legacy.dart' as legacy;

part 'holder.ack.dart';
part 'holder.ack.g.dart';

@AckModel()
final class Holder with _$HolderAck {
  const Holder({
    required this.primary,
    this.optional,
    required this.history,
    required this.matrix,
    required this.unique,
  });

  final legacy.LegacyAddress primary;
  final legacy.LegacyAddress? optional;
  final List<legacy.LegacyAddress> history;
  final List<List<legacy.LegacyAddress>> matrix;
  final Set<legacy.LegacyAddress> unique;
}
''',
        );
        File(
          p.join(temporary.path, 'lib', 'address_envelope.dart'),
        ).writeAsStringSync(r'''
import 'package:ack/ack.dart';

import 'address.dart' as address;

part 'address_envelope.ack.dart';
part 'address_envelope.ack.g.dart';

@AckInfer()
final addressEnvelopeSchema = Ack.object({
  'primary': address.PostalAddressSchema.schema,
  'optional': address.PostalAddressSchema.schema.optional(),
  'nullable': address.PostalAddressSchema.schema.nullable(),
  'history': Ack.list(address.PostalAddressSchema.schema),
  'unique': Ack.list(address.PostalAddressSchema.schema).codec<Set<address.Address>>(
    decode: (items) => items.toSet(),
    encode: (items) => items.toList(growable: false),
  ),
});
''');
        File(
          p.join(temporary.path, 'test', 'nested_test.dart'),
        ).writeAsStringSync(r'''
import 'package:ack_class_first_nested/address.dart';
import 'package:ack_class_first_nested/address_envelope.dart';
import 'package:ack_class_first_nested/customer.dart';
import 'package:ack_class_first_nested/holder.dart';
import 'package:ack_class_first_nested/itinerary.dart';
import 'package:ack_class_first_nested/order.dart';
import 'package:ack_class_first_nested/parcel.dart';
import 'package:ack_class_first_nested/pet.dart';
import 'package:test/test.dart';

void main() {
  test('nested models parse, encode, and export through facades', () {
    final order = OrderSchema.parse({
      'shipping': {'city': 'Amsterdam'},
      'history': [
        [
          {'city': 'Lisbon'},
        ],
      ],
      'uniqueAddresses': [
        {'city': 'Paris'},
      ],
      'pet': {'type': 'Cat', 'id': 'p1', 'lives': 9},
      'cat': {'type': 'Cat', 'id': 'c1', 'lives': 8},
    });

    expect(order.shipping.city, 'Amsterdam');
    expect(order.history.single.single.city, 'Lisbon');
    expect(order.uniqueAddresses.single.city, 'Paris');
    expect(order.pet, isA<Cat>());
    expect(order.cat.lives, 8);
    expect(order.toJson(), {
      'shipping': {'city': 'Amsterdam'},
      'history': [
        [
          {'city': 'Lisbon'},
        ],
      ],
      'uniqueAddresses': [
        {'city': 'Paris'},
      ],
      'pet': {'type': 'Cat', 'id': 'p1', 'lives': 9},
      'cat': {'type': 'Cat', 'id': 'c1', 'lives': 8},
    });
    expect(PostalAddressSchema.schema, isNotNull);
    expect(PetSchema.toJsonSchema()['x-transformed'], isTrue);
    expect(CatSchema.toJsonSchema()['x-transformed'], isTrue);

    final book = AddressBookSchema.parse({
      'primary': {'city': 'Delft'},
    });
    expect(book.primary.city, 'Delft');
    expect(book.secondary, isNull);

    final customer = CustomerSchema.parse({});
    expect(customer.primary.city, 'Default City');
    expect(customer.secondary, isNull);

    final parcel = ParcelSchema.parse({
      'destination': {'city': 'Utrecht'},
    });
    expect(parcel.destination.city, 'Utrecht');

    final itinerary = ItinerarySchema.parse({
      'start': {'name': 'North'},
      'finish': {'name': 'South'},
    });
    expect(itinerary.start.name, 'North');
    expect(itinerary.finish.name, 'South');
  });

  test('schema-first and class-first models reuse each other', () {
    final holder = HolderSchema.parse({
      'primary': {'city': 'Rome'},
      'history': [
        {'city': 'Oslo'},
      ],
      'matrix': [
        [
          {'city': 'Tokyo'},
        ],
      ],
      'unique': [
        {'city': 'Lima'},
      ],
    });
    expect(holder.primary.city, 'Rome');
    expect(holder.optional, isNull);
    expect(holder.history.single.city, 'Oslo');
    expect(holder.matrix.single.single.city, 'Tokyo');
    expect(holder.unique.single.city, 'Lima');

    final envelope = AddressEnvelope.parse({
      'primary': {'city': 'Berlin'},
      'nullable': null,
      'history': [
        {'city': 'Prague'},
      ],
      'unique': [
        {'city': 'Vienna'},
      ],
    });
    expect(envelope.primary.city, 'Berlin');
    expect(envelope.optional, isNull);
    expect(envelope.nullable, isNull);
    expect(envelope.history.single.city, 'Prague');
    expect(envelope.unique.single.city, 'Vienna');
    expect(envelope.toJson(), {
      'primary': {'city': 'Berlin'},
      'nullable': null,
      'history': [
        {'city': 'Prague'},
      ],
      'unique': [
        {'city': 'Vienna'},
      ],
    });
  });

  test('wire schemas preserve nested boundary values', () {
    final input = {
      'shipping': {'city': 'Amsterdam'},
      'history': [
        [
          {'city': 'Lisbon'},
        ],
      ],
      'uniqueAddresses': [
        {'city': 'Paris'},
      ],
      'pet': {'type': 'Cat', 'id': 'p1', 'lives': 9},
      'cat': {'type': 'Cat', 'id': 'c1', 'lives': 8},
    };

    final wire = OrderSchema.wireSchema.parse(input)!;

    expect(wire, input);
    expect(wire['shipping'], isA<Map<String, Object?>>());
    expect(wire['uniqueAddresses'], isA<List<Object?>>());
    expect(wire['pet'], isA<Map<String, Object?>>());
    expect(
      OrderSchema.wireSchema.safeParse({
        ...input,
        'shipping': {'city': 1},
      }).isFail,
      isTrue,
    );
  });
}
''');

        _expectSuccess(await _run(temporary, ['pub', 'get']), 'dart pub get');
        _expectSuccess(
          await _run(temporary, ['run', 'build_runner', 'build']),
          'clean build_runner build',
        );
        final generated = _generatedFiles(temporary);
        final orderOutput = generated['lib/order.ack.dart'];
        expect(orderOutput, contains('address.PostalAddressSchema.schema'));
        expect(orderOutput, contains('pets.PetSchema.schema'));
        expect(orderOutput, contains('pets.CatSchema.schema'));
        expect(orderOutput, isNot(contains('address.addressSchema')));
        expect(
          generated['lib/address.ack.dart'],
          contains("'primary': PostalAddressSchema.schema"),
        );
        expect(
          generated['lib/customer.ack.dart'],
          contains("'primary': PostalAddressSchema.schema.withDefault"),
        );
        expect(
          generated['lib/parcel.ack.dart'],
          contains('models.PostalAddressSchema.schema'),
        );
        expect(
          generated['lib/itinerary.ack.dart'],
          allOf(
            contains('north.PlaceSchema.schema'),
            contains('south.PlaceSchema.schema'),
          ),
        );
        expect(
          generated['lib/holder.ack.dart'],
          contains(r'legacy.LegacyAddress.$ack.schema'),
        );
        expect(
          generated['lib/address_envelope.ack.dart'],
          contains('address.Address'),
        );
        _expectSuccess(
          await _run(temporary, ['analyze', '--fatal-infos']),
          'dart analyze --fatal-infos',
        );
        _expectSuccess(await _run(temporary, ['test']), 'dart test');
        _expectSuccess(
          await _run(temporary, ['run', 'build_runner', 'build']),
          'outputs-present build_runner build',
        );
        expect(_generatedFiles(temporary), generated);
      } finally {
        temporary.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
