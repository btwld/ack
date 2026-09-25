import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

Future<void> _build(
  Map<String, String> sources, {
  required Map<String, Object> outputs,
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {
      for (final entry in sources.entries)
        'test_pkg|lib/${entry.key}': entry.value,
    },
    generateFor: {for (final path in sources.keys) 'test_pkg|lib/$path'},
    readerWriter: readerWriter,
    outputs: outputs,
  );
}

const _imports = '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
''';

void main() {
  test('class-first field docs describe the inferred schema', () async {
    await _build(
      {
        'documented.dart':
            '''
$_imports
part 'documented.ack.dart';
part 'documented.ack.g.dart';

@AckModel()
final class Documented with _\$DocumentedAck {
  const Documented({required this.title});

  /// The item title.
  final String title;
}
''',
      },
      outputs: {
        'test_pkg|lib/documented.ack.dart': decodedMatches(
          contains("'title': Ack.string().describe('The item title.')"),
        ),
      },
    );
  });

  test('class-first format annotations constrain string fields', () async {
    await _build(
      {
        'formats.dart':
            '''
$_imports
import 'package:ack_annotations/format_annotations.dart' as formats;
part 'formats.ack.dart';
part 'formats.ack.g.dart';

@AckModel()
final class Formats with _\$FormatsAck {
  const Formats({
    required this.url,
    required this.uri,
    required this.uuid,
    required this.date,
    required this.timestamp,
  });

  @Url()
  final String url;
  @formats.Uri()
  final String uri;
  @Uuid()
  final String uuid;
  @Date()
  final String date;
  @formats.DateTime()
  final String timestamp;
}
''',
      },
      outputs: {
        'test_pkg|lib/formats.ack.dart': decodedMatches(
          allOf([
            contains("'url': Ack.string().url()"),
            contains("'uri': Ack.string().uri()"),
            contains("'uuid': Ack.string().uuid()"),
            contains("'date': Ack.string().date()"),
            contains("'timestamp': Ack.string().datetime()"),
          ]),
        ),
      },
    );
  });

  test('emits nullable constructor defaults without losing null', () async {
    await _build(
      {
        'defaults.dart':
            '''
$_imports
part 'defaults.ack.dart';
part 'defaults.ack.g.dart';

@AckModel()
final class Defaults with _\$DefaultsAck {
  const Defaults({this.fallback = 'fallback', this.empty = null});

  final String? fallback;
  final String? empty;
}
''',
      },
      outputs: {
        'test_pkg|lib/defaults.ack.dart': decodedMatches(
          allOf([
            contains(
              "'fallback': Ack.string().nullable().withDefault('fallback')",
            ),
            contains("'empty': Ack.string().optional().nullable()"),
            contains("result['fallback'] = null"),
            contains("result['empty'] = null"),
            isNot(contains('withDefault(null)')),
          ]),
        ),
      },
    );
  });

  test('infers Ack.any and Ack.map for open JSON field types', () async {
    await _build(
      {
        'envelope.dart':
            '''
$_imports
part 'envelope.ack.dart';
part 'envelope.ack.g.dart';

@AckModel()
final class Envelope with _\$EnvelopeAck {
  const Envelope({
    required this.kind,
    this.payload,
    required this.items,
    required this.tags,
    required this.values,
    required this.metadata,
    required this.labels,
    required this.groups,
  });

  final Object kind;
  @Optional()
  final Object? payload;
  final List<Object> items;
  final Set<Object> tags;
  final Map<String, Object> values;
  final Map<String, Object?> metadata;
  final Map<String, String?> labels;
  final Map<String, List<Object>> groups;
}
''',
      },
      outputs: {
        'test_pkg|lib/envelope.ack.dart': decodedMatches(
          allOf([
            contains("'kind': Ack.any()"),
            contains("'payload': Ack.any().optional().nullable()"),
            contains("'items': Ack.list(Ack.any())"),
            contains("'tags': Ack.list(Ack.any()).codec<Set<Object>>"),
            contains("'values': Ack.map(Ack.any())"),
            contains("'metadata': Ack.map(Ack.any().nullable())"),
            contains("'labels': Ack.map(Ack.string().nullable())"),
            contains("'groups': Ack.map(Ack.list(Ack.any()))"),
            isNot(contains('value as Object?')),
          ]),
        ),
      },
    );
  });

  test('emits a codec schema, presence semantics, mixin, and bridges', () async {
    await _build(
      {
        'profile.dart':
            '''
$_imports
part 'profile.ack.dart';
part 'profile.ack.g.dart';

@AckModel()
final class Profile with _\$ProfileAck {
  const Profile({
    required this.bio,
    this.website,
    required this.nickname,
    this.role = 'member',
    required this.tags,
  });

  @MinLength(1)
  @MaxLength(500)
  final String bio;
  final Uri? website;
  final String? nickname;
  final String role;
  @MinItems(1)
  @UniqueItems()
  final Set<String> tags;
}
''',
      },
      outputs: {
        'test_pkg|lib/profile.ack.dart': decodedMatches(
          allOf([
            contains('final _profileObject = Ack.object'),
            contains(
              'final _profileWireSchema = '
              'Ack.preserveBoundary(_profileObject)',
            ),
            contains('final _profileSchema = _profileObject.codec<Profile>'),
            contains('get wireSchema'),
            contains('_profileWireSchema;'),
            isNot(contains('final profileSchema =')),
            contains("'bio': Ack.string().minLength(1).maxLength(500)"),
            contains("'website': Ack.uri().optional().nullable()"),
            contains("'nickname': Ack.string().nullable()"),
            contains("'role': Ack.string().withDefault('member')"),
            contains('Ack.list(Ack.string())'),
            contains('.minItems(1)'),
            contains('.unique()'),
            contains('.codec<Set<String>>'),
            contains('.codec<Profile>('),
            contains(r'decode: _$ProfileFromRuntime'),
            contains(r'encode: _$ProfileToRuntime'),
            contains('abstract final class ProfileSchema'),
            contains(
              'static AckSchema<Map<String, Object?>, Profile> get schema',
            ),
            contains('static Profile parse('),
            contains('static SchemaResult<Profile> safeParse('),
            contains(
              'static Profile fromJson(Map<String, dynamic> json) => parse(json)',
            ),
            contains('static Map<String, Object?> encode('),
            contains('static SchemaResult<Map<String, Object?>> safeEncode('),
            contains('static Map<String, Object?> toJsonSchema()'),
            contains('static AckSchemaModel toSchemaModel()'),
            contains('_profileSchema.parse(value, debugName: debugName)!'),
            contains('_profileSchema.encode(value, debugName: debugName)!'),
            contains(r'Profile _$ProfileFromRuntime'),
            contains(r'_$ProfileFromJson'),
            contains(r'Map<String, Object?> _$ProfileToRuntime'),
            contains("result['nickname'] = null"),
            contains(r'mixin _$ProfileAck'),
            contains('Profile copyWith('),
            contains('final class _ProfileCopyWithUnset'),
            contains('const _ProfileCopyWithUnset()'),
            contains('static const _ProfileCopyWithUnset _ackCopyWithUnset ='),
            contains('Object? website = _ackCopyWithUnset'),
            contains('website: identical(website, _ackCopyWithUnset)'),
            contains(': website as Uri?'),
            isNot(contains('_ackCopyWithOmitted')),
            contains('deepEquals('),
            contains('deepHashCode('),
            contains('Map<String, dynamic> toJson()'),
            contains('SchemaResult<Map<String, Object?>> safeToJson()'),
            contains('ProfileSchema.encode(this as Profile)'),
            contains('ProfileSchema.safeEncode(this as Profile)'),
            contains('_ackProfileFromRuntimeBio'),
            contains('_ackProfileToRuntimeTags'),
          ]),
        ),
      },
    );
  });

  test(
    'emits escape-hatch schemas and built-in recursive type coverage',
    () async {
      await _build(
        {
          'types.dart':
              '''
$_imports
part 'types.ack.dart';
part 'types.ack.g.dart';

final class Color {
  const Color(this.value);
  final String value;
}

AckSchema<String, Color> colorSchema() => Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.value,
);

AckSchema<Map<String, Object?>, Map<String, int>> scoresSchema() =>
    Ack.object({}, additionalProperties: true).codec<Map<String, int>>(
      decode: (value) => value.map((key, item) => MapEntry(key, item as int)),
      encode: (value) => value,
    );

enum Role { admin, member }

@AckModel()
final class Record with _\$RecordAck {
  const Record({
    required this.color,
    required this.scores,
    required this.role,
    required this.createdAt,
    required this.website,
    required this.timeout,
    required this.names,
  });

  @AckField(schema: colorSchema)
  final Color color;
  @AckField(schema: scoresSchema)
  final Map<String, int> scores;
  final Role role;
  final DateTime createdAt;
  final Uri website;
  final Duration timeout;
  final List<List<String>> names;
}
''',
        },
        outputs: {
          'test_pkg|lib/types.ack.dart': decodedMatches(
            allOf([
              contains("'color': colorSchema()"),
              contains("'scores': scoresSchema()"),
              contains("'role': Ack.enumValues(Role.values)"),
              contains("'createdAt': Ack.datetime()"),
              contains("'website': Ack.uri()"),
              contains("'timeout': Ack.duration()"),
              contains("'names': Ack.list(Ack.list(Ack.string()))"),
              contains('Map<String, int> _ackRecordFromRuntimeScores'),
              contains('List<List<String>> _ackRecordFromRuntimeNames'),
              contains('Map<String, int>.unmodifiable('),
              contains('List<List<String>>.unmodifiable('),
              contains('List<String>.unmodifiable('),
            ]),
          ),
        },
      );
    },
  );

  test('computes case-style and JsonKey schema keys once', () async {
    await _build(
      {
        'account.dart':
            '''
$_imports
part 'account.ack.dart';
part 'account.ack.g.dart';

@AckModel(caseStyle: AckCaseStyle.snake)
final class Account with _\$AccountAck {
  const Account({required this.firstName, required this.imageUrl});

  final String firstName;
  @JsonKey(name: 'avatar')
  final String imageUrl;
}
''',
      },
      outputs: {
        'test_pkg|lib/account.ack.dart': decodedMatches(
          allOf([
            contains("'first_name': Ack.string()"),
            contains("'avatar': Ack.string()"),
            isNot(contains("'firstName':")),
            isNot(contains("'image_url':")),
          ]),
        ),
      },
    );
  });

  test(
    'preserves prefixed field types and same-named import identity',
    () async {
      await _build(
        {
          'a.dart':
              '''
$_imports
part 'a.ack.dart';
part 'a.ack.g.dart';

@AckModel()
final class Address with _\$AddressAck {
  const Address({required this.city});
  final String city;
}
''',
          'b.dart': '''
final class Address {
  const Address();
}
''',
          'order.dart':
              '''
$_imports
import 'a.dart' as a;
import 'b.dart' as b;
part 'order.ack.dart';
part 'order.ack.g.dart';

@AckModel()
final class Order with _\$OrderAck {
  const Order({required this.shipping});
  final a.Address shipping;
}

// Keep the second same-named import semantically used.
const Type otherAddressType = b.Address;
''',
        },
        outputs: {
          'test_pkg|lib/a.ack.dart': decodedMatches(
            allOf([
              contains('final _addressSchema'),
              contains('abstract final class AddressSchema'),
            ]),
          ),
          'test_pkg|lib/order.ack.dart': decodedMatches(
            allOf([
              contains("'shipping': a.AddressSchema.schema"),
              contains('a.Address _ackOrderFromRuntimeShipping'),
              isNot(contains('b.AddressSchema')),
            ]),
          ),
        },
      );
    },
  );

  test(
    'emits raw union branches, public codecs, and exhaustive dispatch',
    () async {
      await _build(
        {
          'pet.dart':
              '''
$_imports
part 'pet.ack.dart';
part 'pet.ack.g.dart';

@AckModel(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet({required this.id});
  final String id;
}

@AckModel(discriminatorValue: 'cat')
final class Cat extends Pet with _\$CatAck {
  const Cat({required super.id, required this.lives});
  @Min(1)
  @Max(9)
  final int lives;
}

final class Dog extends Pet with _\$DogAck {
  const Dog({required super.id, required this.breed});
  final String breed;
}
''',
        },
        outputs: {
          'test_pkg|lib/pet.ack.dart': decodedMatches(
            allOf([
              contains('final _catObject = Ack.object'),
              contains("'id': Ack.string()"),
              contains("'lives': Ack.integer().min(1).max(9)"),
              contains('final _catSchema = _catObject.codec<Cat>'),
              contains('final _dogSchema = _dogObject.codec<Dog>'),
              contains('final _petSchema ='),
              contains('abstract final class CatSchema'),
              contains('abstract final class DogSchema'),
              contains('abstract final class PetSchema'),
              isNot(contains('final catSchema =')),
              isNot(contains('final dogSchema =')),
              isNot(contains('final petSchema =')),
              contains('Ack.discriminated('),
              contains("discriminatorKey: 'type'"),
              contains("schemas: {'cat': _catObject, 'Dog': _dogObject}"),
              contains('.codec<Pet>('),
              contains("'cat' => _\$CatFromRuntime(value)"),
              contains("'Dog' => _\$DogFromRuntime(value)"),
              contains('encode: (model) => switch (model)'),
              contains(r'Cat() => _$CatToRuntime(model)'),
              contains(r'Dog() => _$DogToRuntime(model)'),
              contains(r'mixin _$PetAck'),
              contains(r'mixin _$CatAck'),
              contains('Cat copyWith({'),
              contains('id: id ?? self.id'),
              contains('get wireSchema'),
              contains('_petObject'),
              contains('.optional()'),
            ]),
          ),
        },
      );
    },
  );

  test(
    'uses an exact custom facade name with a derived private backing',
    () async {
      await _build(
        {
          'account.dart':
              '''
$_imports
part 'account.ack.dart';
part 'account.ack.g.dart';

@AckModel(schemaName: 'WireAccountSchema')
final class Account with _\$AccountAck {
  const Account({required this.id});
  final String id;
}
''',
        },
        outputs: {
          'test_pkg|lib/account.ack.dart': decodedMatches(
            allOf([
              contains('final _accountObject = Ack.object'),
              contains('final _accountSchema = _accountObject.codec<Account>'),
              contains('abstract final class WireAccountSchema'),
              contains('WireAccountSchema.encode(this as Account)'),
              isNot(contains('abstract final class AccountSchema')),
            ]),
          ),
        },
      );
    },
  );

  test(
    'field presence annotations compose independently of nullability',
    () async {
      await _build(
        {
          'fields.dart':
              '''
$_imports
part 'fields.ack.dart';
part 'fields.ack.g.dart';

@AckModel()
final class Example with _\$ExampleAck {
  const Example({this.label, this.nickname, this.title});

  @Optional()
  @NotNull()
  final String? label;

  @Optional()
  final String? nickname;

  @Optional()
  @NotNull()
  @NotEmpty()
  final String? title;
}

@AckModel()
final class InferredNotNull with _\$InferredNotNullAck {
  const InferredNotNull({this.label});

  @NotNull()
  final String? label;
}

AckSchema<String, String> nullableNameSchema() => Ack.string().nullable();

@AckModel()
final class OverrideNotNull with _\$OverrideNotNullAck {
  const OverrideNotNull({this.name});

  @NotNull()
  @AckField(schema: nullableNameSchema)
  final String? name;
}

@AckModel()
final class RequiredNotNull with _\$RequiredNotNullAck {
  const RequiredNotNull({this.value});

  @Required()
  @NotNull()
  final String? value;
}

@AckModel()
final class Forced with _\$ForcedAck {
  const Forced({this.summary});

  @Required()
  final String? summary;
}

@AckModel()
final class LegacyOptional with _\$LegacyOptionalAck {
  const LegacyOptional({this.note});

  @AckField(presence: AckFieldPresence.optional)
  final String? note;
}

final class ParameterEntry {
  const ParameterEntry(this.value);
  final String value;
}

AckSchema<Map<String, Object?>, Map<String, ParameterEntry>>
parameterMapSchema() =>
    Ack.object({}, additionalProperties: true)
        .codec<Map<String, ParameterEntry>>(
          decode: (value) => {
            for (final entry in value.entries)
              entry.key: ParameterEntry(entry.value! as String),
          },
          encode: (value) => {
            for (final entry in value.entries) entry.key: entry.value.value,
          },
        );

@AckModel()
final class CapabilityBinding with _\$CapabilityBindingAck {
  CapabilityBinding({
    required this.name,
    Map<String, ParameterEntry> parameters = const {},
  }) : parameters = Map.unmodifiable(parameters);

  final String name;

  @Optional()
  @AckField(schema: parameterMapSchema)
  final Map<String, ParameterEntry> parameters;
}
''',
        },
        outputs: {
          'test_pkg|lib/fields.ack.dart': decodedMatches(
            allOf([
              contains(
                "'label': Ack.string().optional().nullable(value: false)",
              ),
              contains("'nickname': Ack.string().optional().nullable()"),
              isNot(
                contains(
                  "'nickname': Ack.string().optional().nullable(value: false)",
                ),
              ),
              contains(
                "'title': Ack.string().notEmpty().optional().nullable(value: false)",
              ),
              contains(
                'nullableNameSchema().optional().nullable(value: false)',
              ),
              contains("'value': Ack.string().nullable(value: false)"),
              isNot(contains("'value': Ack.string().optional()")),
              contains("'summary': Ack.string().nullable()"),
              contains("'note': Ack.string().optional().nullable()"),
              contains("'parameters': parameterMapSchema().optional()"),
              isNot(contains('parameterMapSchema().optional().nullable(')),
              contains('Map<String, ParameterEntry>? parameters'),
              contains('parameters: parameters ?? self.parameters'),
              isNot(contains('parameters as Map<String, ParameterEntry>?')),
              contains('Object? label = _ackCopyWithUnset'),
              contains(': label as String?'),
            ]),
          ),
        },
      );
    },
  );

  test('qualifies facade APIs through a prefixed Ack import', () async {
    await _build(
      {
        'account.dart': '''
import 'package:ack/ack.dart' as ack
    show Ack, AckSchema, AckSchemaModel, AckSchemaModelExtension, SchemaResult,
        deepEquals, deepHashCode;
import 'package:ack_annotations/ack_annotations.dart' as annotations
    show AckModel;

part 'account.ack.dart';
part 'account.ack.g.dart';

@annotations.AckModel()
final class Account with _\$AccountAck {
  const Account();
}
''',
      },
      outputs: {
        'test_pkg|lib/account.ack.dart': decodedMatches(
          allOf([
            contains('ack.Ack.object'),
            contains('ack.AckSchema<Map<String, Object?>, Account>'),
            contains('ack.SchemaResult<Account>'),
            contains('ack.AckSchemaModel toSchemaModel()'),
            contains('ack.AckSchemaModelExtension(_accountSchema)'),
          ]),
        ),
      },
    );
  });
}
