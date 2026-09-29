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
import 'package:ack_annotations/ack_annotations.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model.ack.dart';
part 'model.ack.g.dart';
''';

void main() {
  test(
    'rejects a local declaration named like the copyWith implementation',
    () async {
      await _expectFailure(
        '''
@AckModel()
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

  test('rejects duplicate class description tags at the class', () async {
    await _expectFailure(
      '''
/// @description First.
/// @description Second.
@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
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

@AckModel()
final class User with _\$UserAck {
  const User({required this.name});

  @AckField(schema: Schemas.name)
  final String name;
}
''',
      ['@AckField', 'top-level', 'name'],
    );
  });

  test('rejects an AckField function that does not return AckSchema', () async {
    await _expectFailure(
      '''
String nameSchema() => 'not a schema';

@AckModel()
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

@AckModel()
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

@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
final class _User {
  const _User({required this.name});

  final String name;
}
''',
      ['_User', 'public class'],
    );
  });

  test('requires final concrete AckModel classes', () async {
    await _expectFailure(
      '''
@AckModel()
class User with _\$UserAck {
  const User({required this.name});

  final String name;
}
''',
      ['User', 'final class', 'value semantics'],
    );
  });

  test('requires final concrete union branches', () async {
    await _expectFailure(
      '''
@AckModel(discriminatorKey: 'type')
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
@AckModel()
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
@AckModel()
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
@AckModel(unknownProperties: AckUnknownPropertyPolicy.capture)
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
@AckModel(unknownProperties: AckUnknownPropertyPolicy.capture)
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
@AckModel(
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
@AckModel(captureField: 'args')
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
@AckModel()
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
@AckModel(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet();
}

@AckModel(discriminatorValue: 'pet')
final class Cat extends Pet with _\$CatAck {
  const Cat();
}

@AckModel(discriminatorValue: 'pet')
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
@AckModel(discriminatorKey: 'type')
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
@AckModel(discriminatorKey: 'type')
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
@AckModel(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet();
}

@AckModel(discriminatorValue: 'cat')
final class Cat extends Pet with _\$CatAck {
  const Cat();

  String get type => 'dog';
}
''',
      ['Cat.type', 'cat', 'literal'],
    );
  });

  test('rejects AckModel and JsonSerializable on the same class', () async {
    await _expectFailure(
      '''
@AckModel()
@JsonSerializable()
final class User with _\$UserAck {
  const User({required this.name});

  final String name;
}
''',
      ['User', '@AckModel', '@JsonSerializable'],
    );
  });

  test('rejects every unsupported JsonKey serialization option', () async {
    await _expectFailure(
      '''
enum Role { member, unknown }

Role decodeRole(Object? value) => Role.member;
String encodeRole(Role value) => value.name;
Object? readRole(Map<dynamic, dynamic> map, String key) => map[key];

@AckModel()
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
@AckModel()
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
@AckModel()
final class User with _\$UserAck {
  const User();
}
''',
      ['AckSchemaModelExtension', 'visible'],
      head: '''
import 'package:ack/ack.dart'
    show Ack, AckSchema, AckSchemaModel, SchemaResult;
import 'package:ack_annotations/ack_annotations.dart';

part 'model.ack.dart';
part 'model.ack.g.dart';
''',
    );
  });

  test('rejects duplicate generated schema names', () async {
    await _expectFailure(
      '''
@AckModel(schemaName: 'PersonSchema')
final class User with _\$UserAck {
  const User();
}

@AckModel(schemaName: 'PersonSchema')
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
@AckModel(schemaName: 'personSchema')
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
@AckModel()
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
@AckModel()
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
@AckModel(discriminatorKey: 'type')
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
@AckModel()
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
@AckModel(discriminatorKey: 'type')
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
@AckModel(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet();
}

@AckModel(schemaName: 'UpperCatSchema')
final class Cat extends Pet with _\$CatAck {
  const Cat();
}

@AckModel(schemaName: 'LowerCatSchema')
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
@AckModel()
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
@AckModel()
final class Parent with _\$ParentAck {
  const Parent({required this.child});

  final Child child;
}

@AckModel()
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
@AckModel()
final class Parent with _\$ParentAck {
  const Parent({required this.child});

  final Child child;
}
''',
      ['Child.parent', 'recursive class-first', 'Ack.lazy', 'schema-first'],
      head: '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'child.dart';

part 'model.ack.dart';
part 'model.ack.g.dart';
''',
      extraSources: {
        'child.dart': '''
import 'package:ack_annotations/ack_annotations.dart';
import 'model.dart';

part 'child.ack.dart';
part 'child.ack.g.dart';

@AckModel()
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
@AckModel()
final class Order with _\$OrderAck {
  const Order({required this.address});

  final Address address;
}
''',
        ['AddressSchema', 'hidden', 'show Address, AddressSchema'],
        head: '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'address.dart' show Address;

part 'model.ack.dart';
part 'model.ack.g.dart';
''',
        extraSources: {
          'address.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'address.ack.dart';
part 'address.ack.g.dart';

@AckModel()
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
import 'package:ack_annotations/ack_annotations.dart';
import 'address.dart' show Address;
import 'address.dart' show AddressSchema;

part 'model.ack.dart';
part 'model.ack.g.dart';

@AckModel()
final class Order with _\$OrderAck {
  const Order({required this.address});

  final Address address;
}
''',
        'test_pkg|lib/address.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'address.ack.dart';
part 'address.ack.g.dart';

@AckModel()
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
@AckModel()
final class Order with _\$OrderAck {
  const Order({required this.address});

  final Address address;
}
''',
      ['AddressSchema', 'export combinator'],
      head: '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'exports.dart';

part 'model.ack.dart';
part 'model.ack.g.dart';
''',
      extraSources: {
        'exports.dart': "export 'address.dart' show Address;",
        'address.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'address.ack.dart';
part 'address.ack.g.dart';

@AckModel()
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
@AckModel(caseStyle: AckCaseStyle.snake)
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
@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
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
@AckModel()
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
