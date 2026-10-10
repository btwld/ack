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

/// Matches generated [code] regardless of formatter line breaks.
///
/// Whitespace and trailing commas are ignored on both sides.
Matcher _containsCode(String code) => predicate<String>(
  (output) => _compact(output).contains(_compact(code)),
  'contains code `$code`',
);

String _compact(String code) => code
    .replaceAll(RegExp(r'\s+'), '')
    .replaceAll(',)', ')')
    .replaceAll(',}', '}');

const _imports = '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';
''';

void main() {
  test(
    'prefixed constraint annotations sit beside same-named app types',
    () async {
      await _build(
        {
          'contact.dart': '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart' as ack;

part 'contact.g.dart';

final class Email {
  const Email(this.address);
  final String address;
}

@Schemable()
final class Contact with _\$ContactAck {
  const Contact({required this.address, required this.id});

  @ack.Email()
  final String address;

  @ack.Uuid()
  final String id;
}
''',
        },
        outputs: {
          'test_pkg|lib/contact.g.dart': decodedMatches(
            _containsCode(
              "Ack.object({'address': Ack.string().email(), "
              "'id': Ack.string().uuid()})",
            ),
          ),
        },
      );
    },
  );

  test('an Ack.map schema function backs a Map field', () async {
    await _build(
      {
        'scores.dart':
            '''
$_imports
part 'scores.g.dart';

MapSchema<int, int> scoresSchema() => Ack.map(Ack.integer().min(0));

@Schemable()
final class Board with _\$BoardAck {
  const Board({required this.scores});

  @AckField(schema: scoresSchema)
  final Map<String, int> scores;
}
''',
      },
      outputs: {
        'test_pkg|lib/scores.g.dart': decodedMatches(
          _containsCode("Ack.object({'scores': scoresSchema()})"),
        ),
      },
    );
  });

  test(
    'collection constraints on a nested Set land on the outer set',
    () async {
      await _build(
        {
          'grid.dart':
              '''
$_imports
part 'grid.g.dart';

@Schemable()
final class Grid with _\$GridAck {
  const Grid({required this.cells});

  @MinItems(2)
  final Set<Set<int>> cells;
}
''',
        },
        outputs: {
          'test_pkg|lib/grid.g.dart': decodedMatches(
            allOf(
              _containsCode(
                'Ack.list(Ack.list(Ack.integer()).codec<Set<int>>('
                'decode: (list) => list.toSet(), '
                'encode: (set) => set.toList(growable: false),'
                ')).minItems(2).unique().codec<Set<Set<int>>>(',
              ),
              isNot(_containsCode('Ack.list(Ack.integer()).minItems(2)')),
            ),
          ),
        },
      );
    },
  );

  test('a field description tag describes the inferred schema', () async {
    await _build(
      {
        'documented.dart':
            '''
$_imports
part 'documented.g.dart';

@Schemable()
final class Documented with _\$DocumentedAck {
  const Documented({required this.title});

  /// The item title.
  /// @description The item title.
  final String title;
}
''',
      },
      outputs: {
        'test_pkg|lib/documented.g.dart': decodedMatches(
          contains("'title': Ack.string().describe('The item title.')"),
        ),
      },
    );
  });

  test('description tags describe the object and its codec', () async {
    const task = r"'A task the person\'s \$team can complete.'";
    await _build(
      {
        'documented.dart':
            '''
$_imports
part 'documented.g.dart';

/// A task the person's \$team can complete.
/// @description A task the person's \$team can complete.
///
/// Shown in the task list.
@Schemable()
final class Task with _\$TaskAck {
  const Task({required this.title});

  /// What to do.
  /// @description What to do.
  final String title;
}

/**
 * A note
 * without fields.
 * @description A note without fields.
 */
@Schemable()
final class Note with _\$NoteAck {
  const Note();
}
''',
      },
      outputs: {
        'test_pkg|lib/documented.g.dart': decodedMatches(
          allOf(
            _containsCode(
              'final _taskObject = Ack.object({'
              "'title': Ack.string().describe('What to do.'),"
              '}).describe($task);',
            ),
            _containsCode(
              'final _taskSchema = _taskObject.codec<Task>('
              r'decode: _$TaskFromRuntime, encode: _$TaskToRuntime,'
              ').describe($task);',
            ),
            _containsCode(
              "final _noteObject = Ack.object({}).describe('A note without "
              "fields.');",
            ),
            _containsCode(
              r'encode: _$NoteToRuntime,'
              ").describe('A note without fields.');",
            ),
          ),
        ),
      },
    );
  });

  test('untagged prose and line comments emit no description', () async {
    await _build(
      {
        'plain.dart':
            '''
$_imports
part 'plain.g.dart';

/// Ordinary class prose is not schema data.
@Schemable()
final class Plain with _\$PlainAck {
  const Plain({required this.title, this.note});

  /// Ordinary field prose is not schema data.
  final String title;

  // @description Line comments are not documentation.
  final String? note;
}
''',
      },
      outputs: {
        'test_pkg|lib/plain.g.dart': decodedMatches(
          isNot(contains('.describe(')),
        ),
      },
    );
  });

  test('explicit descriptions escape control characters', () async {
    await _build(
      {
        'escaped.dart':
            '''
$_imports
part 'escaped.g.dart';

@Schemable(description: 'First\\nsecond')
final class Escaped with _\$EscapedAck {
  const Escaped({required this.value});

  @AckField(description: 'A\\tB')
  final String value;
}
''',
      },
      outputs: {
        'test_pkg|lib/escaped.g.dart': decodedMatches(
          allOf([
            contains(r".describe('First\u000asecond')"),
            contains(r".describe('A\u0009B')"),
          ]),
        ),
      },
    );
  });

  test('union bases and branches carry their own description tags', () async {
    await _build(
      {
        'shapes.dart':
            '''
$_imports
part 'shapes.g.dart';

/// A shape to draw.
/// @description A shape to draw.
@Schemable(discriminatorKey: 'kind')
sealed class Shape with _\$ShapeAck {
  const Shape();
}

/// A circle.
/// @description A circle.
@Schemable(discriminatorValue: 'circle')
final class Circle extends Shape with _\$CircleAck {
  const Circle({required this.radius});

  final double radius;
}

final class Square extends Shape with _\$SquareAck {
  const Square({required this.side});

  final double side;
}
''',
      },
      outputs: {
        'test_pkg|lib/shapes.g.dart': decodedMatches(
          allOf(
            _containsCode("'radius': Ack.double(),}).describe('A circle.');"),
            _containsCode(
              r'encode: _$CircleToRuntime,'
              ").describe('A circle.');",
            ),
            _containsCode("'side': Ack.double(),});"),
            _containsCode(r'encode: _$SquareToRuntime,);'),
            _containsCode(
              "schemas: {'circle': _circleObject, 'Square': _squareObject},"
              ").describe('A shape to draw.');",
            ),
            _containsCode(
              r'Square() => _$SquareToRuntime(model),},'
              ").describe('A shape to draw.');",
            ),
          ),
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
import 'package:ack/format_annotations.dart' as formats;
part 'formats.g.dart';

@Schemable()
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
        'test_pkg|lib/formats.g.dart': decodedMatches(
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
part 'defaults.g.dart';

@Schemable()
final class Defaults with _\$DefaultsAck {
  const Defaults({this.fallback = 'fallback', this.empty = null});

  final String? fallback;
  final String? empty;
}
''',
      },
      outputs: {
        'test_pkg|lib/defaults.g.dart': decodedMatches(
          allOf([
            contains(
              "'fallback': Ack.string().nullable().withDefault('fallback')",
            ),
            contains("'empty': Ack.string().optional().nullable()"),
            contains("'fallback': model.fallback"),
            contains("'empty': model.empty"),
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
part 'envelope.g.dart';

@Schemable()
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
        'test_pkg|lib/envelope.g.dart': decodedMatches(
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

  test(
    'emits a codec schema, presence semantics, mixin, and direct decode/encode',
    () async {
      await _build(
        {
          'profile.dart':
              '''
$_imports
part 'profile.g.dart';

@Schemable()
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
  final Set<String> tags;
}
''',
        },
        outputs: {
          'test_pkg|lib/profile.g.dart': decodedMatches(
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
              contains(
                RegExp(
                  r'\.minItems\(1\)[\s\S]*\.unique\(\)[\s\S]*\.codec<Set<String>>',
                ),
              ),
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
              contains(r'Map<String, Object?> _$ProfileToRuntime'),
              contains("'nickname': model.nickname"),
              contains(r'mixin _$ProfileAck'),
              contains(r'$ProfileCopyWith<Profile> get copyWith'),
              contains('final class _ProfileCopyWithUnset'),
              contains('const _ProfileCopyWithUnset()'),
              contains(
                'static const _ProfileCopyWithUnset _ackCopyWithUnset =',
              ),
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
            ]),
          ),
        },
      );
    },
  );

  test(
    'emits escape-hatch schemas and built-in recursive type coverage',
    () async {
      await _build(
        {
          'types.dart':
              '''
$_imports
part 'types.g.dart';

final class Color {
  const Color(this.value);
  final String value;
}

AckSchema<String, Color> colorSchema() => Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.value,
).describe('Authored color.');

AckSchema<Map<String, Object?>, Map<String, int>> scoresSchema() =>
    Ack.object({}, additionalProperties: true).codec<Map<String, int>>(
      decode: (value) => value.map((key, item) => MapEntry(key, item as int)),
      encode: (value) => value,
    );

enum Role { admin, member }

@Schemable()
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

  /// Untagged field prose does not replace the authored description.
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
          'test_pkg|lib/types.g.dart': decodedMatches(
            allOf([
              contains("'color': colorSchema()"),
              isNot(contains("'color': colorSchema().describe(")),
              contains("'scores': scoresSchema()"),
              contains("'role': Ack.enumValues(Role.values)"),
              contains("'createdAt': Ack.datetime()"),
              contains("'website': Ack.uri()"),
              contains("'timeout': Ack.duration()"),
              contains("'names': Ack.list(Ack.list(Ack.string()))"),
              contains('Map<String, int>.unmodifiable('),
              contains('List<List<String>>.unmodifiable('),
              contains('List<String>.unmodifiable('),
            ]),
          ),
        },
      );
    },
  );

  test(
    'computes case-style, AckField(name:), and JsonKey schema keys once',
    () async {
      await _build(
        {
          'account.dart':
              '''
$_imports
import 'package:json_annotation/json_annotation.dart' show JsonKey;
part 'account.g.dart';

@Schemable(caseStyle: AckCaseStyle.snake)
final class Account with _\$AccountAck {
  const Account({
    required this.firstName,
    required this.imageUrl,
    required this.handleName,
  });

  final String firstName;
  @JsonKey(name: 'avatar')
  final String imageUrl;
  @AckField(name: 'handle')
  final String handleName;
}
''',
        },
        outputs: {
          'test_pkg|lib/account.g.dart': decodedMatches(
            allOf([
              contains("'first_name': Ack.string()"),
              contains("'avatar': Ack.string()"),
              contains("'handle': Ack.string()"),
              isNot(contains("'firstName':")),
              isNot(contains("'image_url':")),
              isNot(contains("'handle_name':")),
            ]),
          ),
        },
      );
    },
  );

  test(
    'preserves prefixed field types and same-named import identity',
    () async {
      await _build(
        {
          'a.dart':
              '''
$_imports
part 'a.g.dart';

@Schemable()
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
part 'order.g.dart';

@Schemable()
final class Order with _\$OrderAck {
  const Order({required this.shipping});
  final a.Address shipping;
}

// Keep the second same-named import semantically used.
const Type otherAddressType = b.Address;
''',
        },
        outputs: {
          'test_pkg|lib/a.g.dart': decodedMatches(
            allOf([
              contains('final _addressSchema'),
              contains('abstract final class AddressSchema'),
            ]),
          ),
          'test_pkg|lib/order.g.dart': decodedMatches(
            allOf([
              contains("'shipping': a.AddressSchema.schema"),
              contains("shipping: value['shipping'] as a.Address"),
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
part 'pet.g.dart';

@Schemable(discriminatorKey: 'type')
sealed class Pet with _\$PetAck {
  const Pet({required this.id});
  final String id;
}

@Schemable(discriminatorValue: 'cat')
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
          'test_pkg|lib/pet.g.dart': decodedMatches(
            allOf([
              contains('final _catObject = Ack.object'),
              contains("'id': Ack.string()"),
              contains("'lives': Ack.integer().min(1).max(9)"),
              contains('final _catSchema = _catObject.codec<Cat>'),
              contains('final _dogSchema = _dogObject.codec<Dog>'),
              contains('final _petSchema ='),
              contains('/// Parses, validates, and encodes [Cat] values.'),
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
              contains(r"'cat' => _$CatFromRuntime(value)"),
              contains(r"'Dog' => _$DogFromRuntime(value)"),
              contains('encode: (model) => switch (model)'),
              contains(r'Cat() => _$CatToRuntime(model)'),
              contains(r'Dog() => _$DogToRuntime(model)'),
              contains(r'mixin _$PetAck'),
              contains(r'mixin _$CatAck'),
              contains('Cat call({'),
              contains('id: id ?? _source.id'),
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
part 'account.g.dart';

@Schemable(schemaName: 'WireAccountSchema')
final class Account with _\$AccountAck {
  const Account({required this.id});
  final String id;
}
''',
        },
        outputs: {
          'test_pkg|lib/account.g.dart': decodedMatches(
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
part 'fields.g.dart';

@Schemable()
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

@Schemable()
final class InferredNotNull with _\$InferredNotNullAck {
  const InferredNotNull({this.label});

  @NotNull()
  final String? label;
}

AckSchema<String, String> nullableNameSchema() => Ack.string().nullable();

@Schemable()
final class OverrideNotNull with _\$OverrideNotNullAck {
  const OverrideNotNull({this.name});

  @NotNull()
  @AckField(schema: nullableNameSchema)
  final String? name;
}

@Schemable()
final class RequiredNotNull with _\$RequiredNotNullAck {
  const RequiredNotNull({this.value});

  @Required()
  @NotNull()
  final String? value;
}

@Schemable()
final class Forced with _\$ForcedAck {
  const Forced({this.summary});

  @Required()
  final String? summary;
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

@Schemable()
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
          'test_pkg|lib/fields.g.dart': decodedMatches(
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
              contains("'parameters': parameterMapSchema().optional()"),
              isNot(contains('parameterMapSchema().optional().nullable(')),
              contains('Map<String, ParameterEntry>? parameters'),
              contains('parameters: parameters ?? _source.parameters'),
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
import 'package:ack/annotations.dart' as annotations
    show Schemable;

part 'account.g.dart';

@annotations.Schemable()
final class Account with _\$AccountAck {
  const Account();
}
''',
      },
      outputs: {
        'test_pkg|lib/account.g.dart': decodedMatches(
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

  test(
    '@Check.* constraints work with single package:ack/ack.dart import alongside same-named types and constructor parameters',
    () async {
      await _build(
        {
          'check_models.dart': '''
import 'package:ack/ack.dart';

part 'check_models.g.dart';

final class Email {
  const Email(this.address);
  final String address;
}

final class Uuid {
  const Uuid(this.value);
  final String value;
}

@Schemable()
final class CheckedRecord with _\$CheckedRecordAck {
  const CheckedRecord({
    required this.email,
    required this.id,
    required this.website,
    required this.resourceUri,
    required this.birthDate,
    required this.createdAt,
    required this.clientIp,
    required this.v4,
    required this.v6,
    required this.code,
    required this.score,
    required this.debt,
    required this.tags,
    @Check.minLength(2) @Check.maxLength(20) required this.handle,
  });

  @Check.email()
  final String email;

  @Check.uuid()
  final String id;

  @Check.url()
  final String website;

  @Check.uri()
  final String resourceUri;

  @Check.date()
  final String birthDate;

  @Check.dateTime()
  final String createdAt;

  @Check.ip(version: 4)
  final String clientIp;

  @Check.ipv4()
  final String v4;

  @Check.ipv6()
  final String v6;

  @Check.notEmpty()
  @Check.matches(r'^[A-Z]+\$')
  final String code;

  @Check.min(0)
  @Check.max(100)
  @Check.multipleOf(5)
  @Check.positive()
  final int score;

  @Check.negative()
  final double debt;

  @Check.minItems(1)
  @Check.maxItems(5)
  @Check.uniqueItems()
  final List<String> tags;

  final String handle;
}
''',
        },
        outputs: {
          'test_pkg|lib/check_models.g.dart': decodedMatches(
            allOf([
              _containsCode("'email': Ack.string().email()"),
              _containsCode("'id': Ack.string().uuid()"),
              _containsCode("'website': Ack.string().url()"),
              _containsCode("'resourceUri': Ack.string().uri()"),
              _containsCode("'birthDate': Ack.string().date()"),
              _containsCode("'createdAt': Ack.string().datetime()"),
              _containsCode("'clientIp': Ack.string().ip(version: 4)"),
              _containsCode("'v4': Ack.string().ipv4()"),
              _containsCode("'v6': Ack.string().ipv6()"),
              _containsCode(
                r"'code': Ack.string().notEmpty().matches('^[A-Z]+\$')",
              ),
              _containsCode(
                "'score': Ack.integer().min(0).max(100).multipleOf(5).positive()",
              ),
              _containsCode("'debt': Ack.double().negative()"),
              _containsCode(
                "'tags': Ack.list(Ack.string()).minItems(1).maxItems(5).unique()",
              ),
              _containsCode(
                "'handle': Ack.string().minLength(2).maxLength(20)",
              ),
            ]),
          ),
        },
      );
    },
  );

  test(
    'emits JsonMaybe<T> decode and encode presence checks for PATCH models',
    () async {
      await _build(
        {
          'patch_models.dart': r'''
import 'package:ack/ack.dart';

part 'patch_models.g.dart';

@Schemable()
final class UserPatch with _$UserPatchAck {
  const UserPatch({
    required this.nickname,
    this.title = const JsonMaybe.absent(),
    this.tags = const JsonMaybe.absent(),
  });

  final JsonMaybe<String> nickname;

  @NotNull()
  @Check.notEmpty()
  final JsonMaybe<String> title;

  final JsonMaybe<List<String>> tags;
}
''',
        },
        outputs: {
          'test_pkg|lib/patch_models.g.dart': decodedMatches(
            allOf([
              _containsCode("'nickname': Ack.string().optional().nullable()"),
              _containsCode(
                "'title': Ack.string().notEmpty().optional().nullable(value: false)",
              ),
              _containsCode(
                "'tags': Ack.list(Ack.string()).optional().nullable()",
              ),
              _containsCode("value.containsKey('nickname')"),
              _containsCode(
                "JsonMaybe<String>.value(value['nickname'] as String?)",
              ),
              _containsCode('const JsonMaybe<String>.absent()'),
              _containsCode('const JsonMaybe.absent()'),
              _containsCode(
                "if (model.nickname case JsonValue(:final value)) 'nickname': value",
              ),
              _containsCode(
                "if (model.title case JsonValue(:final value)) 'title': value",
              ),
              contains('JsonMaybe<String>? nickname'),
            ]),
          ),
        },
      );
    },
  );
}
