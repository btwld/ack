import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

Future<void> _expectFailure(
  String body,
  List<String> messages, {
  String head = _head,
  Map<String, String> extraSources = const {},
  Map<String, Object> allowedOutputs = const {},
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final seen = <String>{};
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {
      'test_pkg|lib/model.dart': '$head\n$body',
      for (final entry in extraSources.entries)
        'test_pkg|lib/${entry.key}': entry.value,
    },
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
    outputs: allowedOutputs,
    onLog: (LogRecord log) {
      if (log.level.name != 'SEVERE') return;
      for (final message in messages) {
        if (log.message.contains(message)) seen.add(message);
      }
    },
  );
  expect(seen, containsAll(messages));
}

Future<void> _expectWarning(String body, List<String> messages) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final seen = <String>{};
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/model.dart': '$_head\n$body'},
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
    outputs: {'test_pkg|lib/model.ack.dart': decodedMatches(contains('mixin'))},
    onLog: (LogRecord log) {
      if (log.level.name != 'WARNING') return;
      for (final message in messages) {
        if (log.message.contains(message)) seen.add(message);
      }
    },
  );
  expect(seen, containsAll(messages));
}

const _head = '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.ack.dart';
part 'model.ack.g.dart';
''';

const _aliasHead = '''
import 'package:ack/ack.dart';
import 'aliases.dart';

part 'model.ack.dart';
part 'model.ack.g.dart';
''';

void main() {
  test('rejects a JsonConverter on a field or class', () async {
    const converter = '''
final class UriText implements JsonConverter<Uri, String> {
  const UriText();
  @override
  Uri fromJson(String json) => Uri.parse(json);
  @override
  String toJson(Uri object) => object.toString();
}
''';
    await _expectFailure(
      '''
$converter
@Schemable()
final class Link with _\$LinkAck {
  const Link({required this.target});

  @UriText()
  final Uri target;
}
''',
      [
        'Link.target uses the JsonConverter UriText, which would bypass Ack '
            'validation in the JSON part. Give the type a static schema or '
            'use @AckField(schema: ...) instead.',
      ],
    );
    await _expectFailure(
      '''
$converter
@Schemable()
@UriText()
final class Link with _\$LinkAck {
  const Link({required this.target});

  final Uri target;
}
''',
      [
        'Link uses the JsonConverter UriText, which would bypass Ack '
            'validation in the JSON part. Give the type a static schema or '
            'use @AckField(schema: ...) instead.',
      ],
    );
  });

  test('rejects non-finite numeric constraint values', () async {
    await _expectFailure(
      '''
@Schemable()
final class Range with _\$RangeAck {
  const Range({required this.limit});

  @Max(double.infinity)
  final double limit;
}
''',
      ['Range.limit has @Max(Infinity); the value must be a finite number.'],
    );
    await _expectFailure(
      '''
@Schemable()
final class Range with _\$RangeAck {
  const Range({required this.step});

  @MultipleOf(double.nan)
  final double step;
}
''',
      ['Range.step has @MultipleOf(NaN); the value must be a finite number.'],
    );
  });

  test('rejects a field type that is visible only through a typedef', () async {
    await _expectFailure(
      '''
@Schemable()
final class Person with _\$PersonAck {
  const Person({required this.home, required this.shade});
  final Addr home;
  final Shade shade;
}
''',
      [
        'Person.home uses Address, which is not visible in this library. '
            'Import package:test_pkg/address.dart.',
      ],
      head: _aliasHead,
      allowedOutputs: {
        'test_pkg|lib/address.ack.dart': decodedMatches(anything),
      },
      extraSources: {
        'aliases.dart': '''
import 'address.dart';
import 'shade.dart';

typedef Addr = Address;
typedef Shade = Color;
''',
        'address.dart': '''
import 'package:ack/ack.dart';

part 'address.ack.dart';
part 'address.ack.g.dart';

@Schemable()
final class Address with _\$AddressAck {
  const Address({required this.city});
  final String city;
}
''',
        'shade.dart': 'enum Color { red, blue }',
      },
    );
    await _expectFailure(
      '''
@Schemable()
final class Swatch with _\$SwatchAck {
  const Swatch({required this.shade});
  final Shade shade;
}
''',
      [
        'Swatch.shade uses Color, which is not visible in this library. '
            'Import package:test_pkg/shade.dart.',
      ],
      head: _aliasHead,
      extraSources: {
        'aliases.dart': '''
import 'shade.dart';

typedef Shade = Color;
''',
        'shade.dart': 'enum Color { red, blue }',
      },
    );
  });

  test('rejects @Schemable(name:) on a class', () async {
    await _expectFailure(
      '''
@Schemable(name: 'IgnoredName')
final class Account with _\$AccountAck {
  const Account({required this.id});
  final String id;
}
''',
      [
        'Account sets @Schemable(name: ...), which applies only to top-level '
            'schemas. Use schemaName to name the generated schema facade.',
      ],
    );
  });

  test(
    'rejects a local declaration named like the copyWith implementation',
    () async {
      await _expectFailure(
        '''
@Schemable()
final class User with _\$UserAck {
  const User({required this.name});

  final String name;
}

final class _\$UserCopyWith {}
''',
        [r'Generated helper "_$UserCopyWith" conflicts'],
      );
    },
  );

  test('rejects blank annotation descriptions', () async {
    await _expectFailure(
      '''
@Schemable(description: ' ')
final class Item with _\$ItemAck {
  const Item({required this.value});
  final String value;
}
''',
      ['Item @Schemable.description must not be blank.'],
    );
    await _expectFailure(
      '''
@Schemable()
final class Item with _\$ItemAck {
  const Item({required this.value});
  @AckField(description: '')
  final String value;
}
''',
      ['value @AckField.description must not be blank.'],
    );
  });

  test('rejects duplicate class description tags at the class', () async {
    await _expectFailure(
      '''
/// @description First.
/// @description Second.
@Schemable()
final class Item with _\$ItemAck {
  const Item({required this.value});
  final String value;
}
''',
      ['Item', 'Duplicate @description tags.'],
    );
  });

  test('rejects a blank field description tag at the field', () async {
    await _expectFailure(
      '''
@Schemable()
final class Item with _\$ItemAck {
  const Item({required this.value});
  /// @description
  final String value;
}
''',
      ['value', '@description requires text'],
    );
  });

  test('rejects numeric sugar on a String field', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  const User({required this.name});

  @Min(1)
  final String name;
}
''',
      ['@Min', 'String', '@MinLength'],
    );
  });

  test('rejects string sugar on a numeric field', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  const User({required this.age});

  @MinLength(1)
  final int age;
}
''',
      ['@MinLength', 'int', '@Min'],
    );
  });

  test('rejects collection sugar on a scalar field', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  const User({required this.name});

  @UniqueItems()
  final String name;
}
''',
      ['@UniqueItems', 'String', 'List or Set'],
    );
  });

  test(
    'rejects nullable List elements instead of narrowing the field',
    () async {
      await _expectFailure(
        '''
@Schemable()
final class User with _\$UserAck {
  const User({required this.tags});

  final List<String?> tags;
}
''',
        ['User.tags', 'nullable collection elements', 'Ack.list'],
      );
    },
  );

  test(
    'rejects nullable Set elements instead of narrowing the field',
    () async {
      await _expectFailure(
        '''
@Schemable()
final class User with _\$UserAck {
  const User({required this.tags});

  final Set<String?> tags;
}
''',
        ['User.tags', 'nullable collection elements', 'Ack.list'],
      );
    },
  );

  test('rejects a static-method AckField escape hatch', () async {
    await _expectFailure(
      '''
final class Schemas {
  static AckSchema<String, String> name() => Ack.string();
}

@Schemable()
final class User with _\$UserAck {
  const User({required this.name});

  @AckField(schema: Schemas.name)
  final String name;
}
''',
      ['@AckField', 'top-level', 'name'],
    );
  });

  test(
    'rejects an AckField schema whose runtime type is not the field type',
    () async {
      await _expectFailure(
        '''
AckSchema<int, int> countSchema() => Ack.integer();

@Schemable()
final class User with _\$UserAck {
  const User({required this.name});

  @AckField(schema: countSchema)
  final String name;
}
''',
        [
          'User.name @AckField schema function countSchema produces int, but '
              'the field type is String.',
        ],
      );
    },
  );

  test('rejects a generic AckField schema function', () async {
    await _expectFailure(
      '''
final class Box<T> {
  const Box(this.value);
  final T value;
}

AckSchema<Object, Box<T>> boxSchema<T extends Object>() =>
    Ack.any().codec<Box<T>>(
      decode: (value) => Box(value as T),
      encode: (box) => box.value,
    );

@Schemable()
final class User with _\$UserAck {
  const User({required this.box});

  @AckField(schema: boxSchema<String>)
  final Box<String> box;
}
''',
      [
        'User.box @AckField schema function boxSchema is generic, and the '
            'generated call cannot keep its type arguments.',
      ],
    );
  });

  test('rejects an AckField function that does not return AckSchema', () async {
    await _expectFailure(
      '''
String nameSchema() => 'not a schema';

@Schemable()
final class User with _\$UserAck {
  const User({required this.name});

  @AckField(schema: nameSchema)
  final String name;
}
''',
      ['@AckField', 'AckSchema', 'name'],
    );
  });

  test('rejects a one-way transform returned by AckField', () async {
    await _expectFailure(
      '''
AckSchema<String, String> normalizedSchema() => Ack.string().trim();

@Schemable()
final class User with _\$UserAck {
  const User({required this.name});

  @AckField(schema: normalizedSchema)
  final String name;
}
''',
      ['User.name', 'normalizedSchema', '.transform()'],
    );
  });

  test('rejects a referenced one-way transform returned by AckField', () async {
    await _expectFailure(
      '''
final normalized = Ack.string().trim();
AckSchema<String, String> normalizedSchema() => normalized;

@Schemable()
final class User with _\$UserAck {
  const User({required this.name});

  @AckField(schema: normalizedSchema)
  final String name;
}
''',
      ['User.name', 'normalizedSchema', 'normalized', '.transform()'],
    );
  });

  test('rejects dynamic map values and points to Object?', () async {
    await _expectFailure(
      '''
@Schemable()
final class Stats with _\$StatsAck {
  const Stats({required this.values});

  final Map<String, dynamic> values;
}
''',
      ['Stats.values', 'dynamic', 'Object?'],
    );
  });

  test('rejects nullable Object list elements', () async {
    await _expectFailure(
      '''
@Schemable()
final class Envelope with _\$EnvelopeAck {
  const Envelope({required this.items});

  final List<Object?> items;
}
''',
      ['Envelope.items', 'nullable collection elements', 'Ack.list'],
    );
  });

  test('rejects nested non-String map keys', () async {
    await _expectFailure(
      '''
@Schemable()
final class Stats with _\$StatsAck {
  const Stats({required this.scores});

  final List<Map<int, String>> scores;
}
''',
      ['Stats.scores', 'Map<String, V>', 'Map<int, String>'],
    );
  });

  test('rejects non-String map keys', () async {
    await _expectFailure(
      '''
@Schemable()
final class Stats with _\$StatsAck {
  const Stats({required this.scores});

  final Map<int, String> scores;
}
''',
      ['Stats.scores', 'Map<String, V>', 'Map<int, String>'],
    );
  });

  test('rejects dynamic fields and points to Object?', () async {
    await _expectFailure(
      '''
@Schemable()
final class Payload with _\$PayloadAck {
  const Payload({required this.value});

  final dynamic value;
}
''',
      ['Payload.value', 'dynamic', 'concrete type', 'Object?'],
    );
  });

  test('rejects private annotated classes', () async {
    await _expectFailure(
      '''
@Schemable()
final class _User {
  const _User({required this.name});

  final String name;
}
''',
      ['_User', 'public class'],
    );
  });

  test('requires final concrete Schemable classes', () async {
    await _expectFailure(
      '''
@Schemable()
class User with _\$UserAck {
  const User({required this.name});

  final String name;
}
''',
      ['User', 'final class', 'value semantics'],
    );
  });

  test('rejects a redirecting private-factory model', () async {
    await _expectFailure(
      '''
@Schemable()
abstract class HabitDto with _\$HabitDtoAck {
  const HabitDto._();
  const factory HabitDto({required String name}) = _HabitDto;
}
''',
      [
        '@Schemable HabitDto redirects its unnamed constructor to _HabitDto. '
            'Redirecting factory models are not supported; declare a final '
            'class whose unnamed generative constructor initializes its '
            'fields.',
      ],
    );
  });

  test('requires final concrete union branches', () async {
    await _expectFailure(
      '''
@Schemable(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet();
}

class Cat extends Pet with _\$CatAck {
  const Cat();
}
''',
      ['Cat', 'final class', 'value semantics'],
    );
  });

  test('rejects mutable stored fields', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  User({required this.name});

  String name;
}
''',
      ['User.name', 'final', 'value semantics'],
    );
  });

  test('rejects private constructor-backed fields', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  const User({required this._secret});

  final String _secret;
}
''',
      ['User._secret', 'private'],
    );
  });

  test('requires the default capture field when capture is enabled', () async {
    await _expectFailure(
      '''
@Schemable(unknownProperties: AckUnknownPropertyPolicy.capture)
final class Config with _\$ConfigAck {
  const Config({required this.name});

  final String name;
}
''',
      ['Config.additionalProperties', 'Map<String, Object?>'],
    );
  });

  test('requires the exact capture field type', () async {
    await _expectFailure(
      '''
@Schemable(unknownProperties: AckUnknownPropertyPolicy.capture)
final class Config with _\$ConfigAck {
  const Config({required this.additionalProperties});

  final Map<String, Object> additionalProperties;
}
''',
      ['Config.additionalProperties', 'Map<String, Object?>'],
    );
  });

  test('names invalid unknown-property capture fields correctly', () async {
    await _expectFailure(
      '''
@Schemable(
  unknownProperties: AckUnknownPropertyPolicy.capture,
  captureField: '_extras',
)
final class Config with _\$ConfigAck {
  const Config({required this.name});

  final String name;
}
''',
      ['Config._extras', 'unknown-property capture field'],
    );
  });

  test('rejects captureField without the capture policy', () async {
    await _expectFailure(
      '''
@Schemable(captureField: 'args')
final class Config with _\$ConfigAck {
  const Config({required this.name});

  final String name;
}
''',
      ['Config.captureField', 'AckUnknownPropertyPolicy.capture'],
    );
  });

  test('requires discriminatorKey on annotated sealed classes', () async {
    await _expectFailure(
      '''
@Schemable()
sealed class Pet with _\$PetAck {
  const Pet();
}

final class Cat extends Pet with _\$CatAck {
  const Cat();
}
''',
      ['Pet', 'discriminatorKey'],
    );
  });

  test('rejects duplicate branch discriminator values', () async {
    await _expectFailure(
      '''
@Schemable(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet();
}

@Schemable(discriminatorValue: 'pet')
final class Cat extends Pet with _\$CatAck {
  const Cat();
}

@Schemable(discriminatorValue: 'pet')
final class Dog extends Pet with _\$DogAck {
  const Dog();
}
''',
      ['Pet', 'duplicate discriminatorValue', 'pet'],
    );
  });

  test('rejects abstract intermediate union branches', () async {
    await _expectFailure(
      '''
@Schemable(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet();
}

abstract base class Mammal extends Pet {
  const Mammal();
}

final class Cat extends Mammal {
  const Cat();
}
''',
      ['Mammal', 'abstract intermediate'],
    );
  });

  test('rejects wrong-typed declared discriminator members', () async {
    await _expectFailure(
      '''
@Schemable(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet();
}

final class Cat extends Pet with _\$CatAck {
  const Cat();

  int get type => 1;
}
''',
      ['Cat.type', 'String'],
    );
  });

  test('rejects mismatched literal discriminator members', () async {
    await _expectFailure(
      '''
@Schemable(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet();
}

@Schemable(discriminatorValue: 'cat')
final class Cat extends Pet with _\$CatAck {
  const Cat();

  String get type => 'dog';
}
''',
      ['Cat.type', 'cat', 'literal'],
    );
  });

  test('rejects Schemable and JsonSerializable on the same class', () async {
    await _expectFailure(
      '''
@Schemable()
@JsonSerializable()
final class User with _\$UserAck {
  const User({required this.name});

  final String name;
}
''',
      ['User', '@Schemable', '@JsonSerializable'],
    );
  });

  test('rejects every unsupported JsonKey serialization option', () async {
    await _expectFailure(
      '''
enum Role { member, unknown }

Role decodeRole(Object? value) => Role.member;
String encodeRole(Role value) => value.name;
Object? readRole(Map<dynamic, dynamic> map, String key) => map[key];

@Schemable()
final class User with _\$UserAck {
  const User({required this.role});

  @JsonKey(
    name: 'wire_role',
    defaultValue: Role.member,
    disallowNullValue: true,
    explicitJsonNullWhenNonNullField: true,
    fromJson: decodeRole,
    ignore: true,
    includeFromJson: false,
    includeIfNull: false,
    includeToJson: false,
    readValue: readRole,
    required: true,
    toJson: encodeRole,
    unknownEnumValue: Role.unknown,
  )
  final Role role;
}
''',
      [
        'User.role',
        '@JsonKey',
        'defaultValue',
        'disallowNullValue',
        'explicitJsonNullWhenNonNullField',
        'fromJson',
        'ignore',
        'includeFromJson',
        'includeIfNull',
        'includeToJson',
        'readValue',
        'required',
        'toJson',
        'unknownEnumValue',
      ],
    );
  });

  test('requires JsonKey name overrides on the field', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  const User({@JsonKey(name: 'wire_name') required this.name});

  final String name;
}
''',
      ['User.name', '@JsonKey', 'constructor parameter', 'field'],
    );
  });

  test('requires the schema-model extension to be visible', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  const User();
}
''',
      ['AckSchemaModelExtension', 'visible'],
      head: '''
import 'package:ack/ack.dart'
    show Ack, AckSchema, AckSchemaModel, SchemaResult;
import 'package:ack/annotations.dart';

part 'model.ack.dart';
part 'model.ack.g.dart';
''',
    );
  });

  test('rejects duplicate generated schema names', () async {
    await _expectFailure(
      '''
@Schemable(schemaName: 'PersonSchema')
final class User with _\$UserAck {
  const User();
}

@Schemable(schemaName: 'PersonSchema')
final class Admin with _\$AdminAck {
  const Admin();
}
''',
      ['PersonSchema', 'conflicts'],
    );
  });

  test('rejects a lower-camel schema facade override', () async {
    await _expectFailure(
      '''
@Schemable(schemaName: 'personSchema')
final class User with _\$UserAck {
  const User();
}
''',
      ['personSchema', 'UpperCamel', 'facade'],
    );
  });

  test('rejects a local schema facade collision', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  const User();
}

abstract final class UserSchema {}
''',
      ['UserSchema', 'conflicts'],
    );
  });

  test('rejects a local private backing schema collision', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  const User();
}

final _userSchema = Ack.string();
''',
      ['_userSchema', 'conflicts'],
    );
  });

  test('rejects an implicit union branch facade collision', () async {
    await _expectFailure(
      '''
@Schemable(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet();
}

final class Cat extends Pet with _\$CatAck {
  const Cat();
}

abstract final class CatSchema {}
''',
      ['CatSchema', 'conflicts'],
    );
  });

  for (final collision in <({String name, String declaration})>[
    (
      name: r'_$UserFromRuntime',
      declaration:
          r'User _$UserFromRuntime(Map<String, Object?> value) => throw 0;',
    ),
    (
      name: r'_$UserToRuntime',
      declaration:
          r'Map<String, Object?> _$UserToRuntime(User value) => throw 0;',
    ),
    (
      name: '_ackUserFromRuntimeName',
      declaration: 'String _ackUserFromRuntimeName(Object? value) => "";',
    ),
    (
      name: '_ackUserToRuntimeName',
      declaration: 'Object? _ackUserToRuntimeName(String value) => value;',
    ),
    (
      name: r'_$UserFromJson',
      declaration:
          r'User _$UserFromJson(Map<String, dynamic> value) => throw 0;',
    ),
    (
      name: r'_$UserToJson',
      declaration: r'Map<String, dynamic> _$UserToJson(User value) => throw 0;',
    ),
    (name: r'_$UserAck', declaration: r'mixin _$UserAck {}'),
    (name: r'_userObject', declaration: r'final _userObject = Ack.object({});'),
    (
      name: r'_userWireSchema',
      declaration: r'final _userWireSchema = Ack.string();',
    ),
  ]) {
    test('rejects local ${collision.name} helper collisions', () async {
      await _expectFailure(
        '''
@Schemable()
final class User with _\$UserAck {
  const User({required this.name});

  final String name;
}

${collision.declaration}
''',
        [collision.name, 'conflicts'],
      );
    });
  }

  test('rejects a local raw union object helper collision', () async {
    await _expectFailure(
      '''
@Schemable(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet();
}

final class Cat extends Pet with _\$CatAck {
  const Cat();
}

final _catObject = Ack.object({});
''',
      ['_catObject', 'conflicts'],
    );
  });

  test('rejects case-only branch backing schema collisions', () async {
    await _expectFailure(
      '''
@Schemable(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet();
}

@Schemable(schemaName: 'UpperCatSchema')
final class Cat extends Pet with _\$CatAck {
  const Cat();
}

@Schemable(schemaName: 'LowerCatSchema')
final class cat extends Pet with _\$catAck {
  const cat();
}
''',
      ['_catSchema', 'conflicts'],
    );
  });

  test('rejects a directly recursive class-first model', () async {
    await _expectFailure(
      '''
@Schemable()
final class Node with _\$NodeAck {
  const Node({this.child});

  final Node? child;
}
''',
      ['Node.child', 'recursive class-first', 'Ack.lazy', 'schema-first'],
    );
  });

  test('rejects mutually recursive class-first models', () async {
    await _expectFailure(
      '''
@Schemable()
final class Parent with _\$ParentAck {
  const Parent({required this.child});

  final Child child;
}

@Schemable()
final class Child with _\$ChildAck {
  const Child({required this.parent});

  final Parent parent;
}
''',
      ['Child.parent', 'recursive class-first', 'Ack.lazy', 'schema-first'],
    );
  });

  test('rejects class-first cycles across libraries', () async {
    await _expectFailure(
      '''
@Schemable()
final class Parent with _\$ParentAck {
  const Parent({required this.child});

  final Child child;
}
''',
      ['Child.parent', 'recursive class-first', 'Ack.lazy', 'schema-first'],
      head: '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';
import 'child.dart';

part 'model.ack.dart';
part 'model.ack.g.dart';
''',
      extraSources: {
        'child.dart': '''
import 'package:ack/annotations.dart';
import 'model.dart';

part 'child.ack.dart';
part 'child.ack.g.dart';

@Schemable()
final class Child with _\$ChildAck {
  const Child({required this.parent});

  final Parent parent;
}
''',
      },
    );
  });

  test(
    'rejects an imported class-first model whose facade is hidden',
    () async {
      await _expectFailure(
        '''
@Schemable()
final class Order with _\$OrderAck {
  const Order({required this.address});

  final Address address;
}
''',
        ['AddressSchema', 'hidden', 'show Address, AddressSchema'],
        head: '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';
import 'address.dart' show Address;

part 'model.ack.dart';
part 'model.ack.g.dart';
''',
        extraSources: {
          'address.dart': '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'address.ack.dart';
part 'address.ack.g.dart';

@Schemable()
final class Address with _\$AddressAck {
  const Address({required this.city});

  final String city;
}
''',
        },
        allowedOutputs: {
          'test_pkg|lib/address.ack.dart': decodedMatches(anything),
        },
      );
    },
  );

  test('allows split imports for a class-first model and its facade', () async {
    final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
    await readerWriter.testing.loadIsolateSources();
    await testBuilder(
      ackModelBuilder(BuilderOptions.empty),
      {
        'test_pkg|lib/model.dart': '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';
import 'address.dart' show Address;
import 'address.dart' show AddressSchema;

part 'model.ack.dart';
part 'model.ack.g.dart';

@Schemable()
final class Order with _\$OrderAck {
  const Order({required this.address});

  final Address address;
}
''',
        'test_pkg|lib/address.dart': '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'address.ack.dart';
part 'address.ack.g.dart';

@Schemable()
final class Address with _\$AddressAck {
  const Address({required this.city});

  final String city;
}
''',
      },
      generateFor: const {
        'test_pkg|lib/model.dart',
        'test_pkg|lib/address.dart',
      },
      readerWriter: readerWriter,
      outputs: {
        'test_pkg|lib/address.ack.dart': decodedMatches(anything),
        'test_pkg|lib/model.ack.dart': decodedMatches(
          contains('AddressSchema.schema'),
        ),
      },
    );
  });

  test('rejects a class-first facade hidden by a barrel export', () async {
    await _expectFailure(
      '''
@Schemable()
final class Order with _\$OrderAck {
  const Order({required this.address});

  final Address address;
}
''',
      ['AddressSchema', 'export combinator'],
      head: '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';
import 'exports.dart';

part 'model.ack.dart';
part 'model.ack.g.dart';
''',
      extraSources: {
        'exports.dart': "export 'address.dart' show Address;",
        'address.dart': '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'address.ack.dart';
part 'address.ack.g.dart';

@Schemable()
final class Address with _\$AddressAck {
  const Address({required this.city});

  final String city;
}
''',
      },
      allowedOutputs: {
        'test_pkg|lib/address.ack.dart': decodedMatches(anything),
      },
    );
  });

  test('rejects case-style key collisions', () async {
    await _expectFailure(
      '''
@Schemable(caseStyle: AckCaseStyle.snake)
final class Collision with _\$CollisionAck {
  const Collision({required this.fooBar, required this.foo_bar});

  final String fooBar;
  final String foo_bar;
}
''',
      ['Collision.foo_bar', 'foo_bar', 'JSON key'],
    );
  });

  test('rejects a missing generated mixin', () async {
    await _expectFailure(
      '''
@Schemable()
final class User {
  const User({required this.name});

  final String name;
}
''',
      ['User', r'_$UserAck'],
    );
  });

  test('rejects a no-op AckField', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  const User({required this.name});

  @AckField()
  final String name;
}
''',
      ['User.name', '@AckField()', 'no-op'],
    );
  });

  test(
    'rejects optional presence on a required constructor parameter',
    () async {
      await _expectFailure(
        '''
@Schemable()
final class User with _\$UserAck {
  const User({required this.name});

  @AckField(presence: AckFieldPresence.optional)
  final String name;
}
''',
        ['User.name', 'optional', 'constructor'],
      );
    },
  );

  test('rejects @Optional() on a required constructor parameter', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  const User({required this.name});

  @Optional()
  final String name;
}
''',
      ['User.name', 'optional', 'constructor'],
    );
  });

  test('rejects combining @Optional() and @Required()', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  const User({this.name});

  @Optional()
  @Required()
  final String? name;
}
''',
      ['User.name', '@Optional()', '@Required()'],
    );
  });

  test('rejects conflicting legacy and new presence declarations', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  const User({this.name});

  @Optional()
  @AckField(presence: AckFieldPresence.required)
  final String? name;
}
''',
      ['User.name', 'conflicting', 'presence'],
    );
  });

  test('warns when legacy AckField presence is used', () async {
    await _expectWarning(
      '''
@Schemable()
final class User with _\$UserAck {
  const User({this.name});

  @AckField(presence: AckFieldPresence.optional)
  final String? name;
}
''',
      ['User.name', '@AckField(presence:', '@Optional()', '2.0.0'],
    );
  });

  test(
    'warns when matching legacy and new presence declarations coexist',
    () async {
      await _expectWarning(
        '''
@Schemable()
final class User with _\$UserAck {
  const User({this.name});

  @Optional()
  @AckField(presence: AckFieldPresence.optional)
  final String? name;
}
''',
        ['User.name', '@AckField(presence:', '2.0.0'],
      );
    },
  );

  test('rejects an unmapped constructor parameter', () async {
    await _expectFailure(
      '''
@Schemable()
final class User with _\$UserAck {
  const User(this.name, String extra) : label = extra;

  final String name;
  final String label;
}
''',
      ['User', 'extra', 'mapped'],
    );
  });
}
