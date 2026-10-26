// Modern schema-first graph tests.
import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

Future<void> _expectOutput(String source, Matcher matcher) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/schema.dart': source},
    generateFor: const {'test_pkg|lib/schema.dart'},
    readerWriter: readerWriter,
    outputs: {'test_pkg|lib/schema.g.dart': decodedMatches(matcher)},
  );
}

Future<void> _expectFailure(String source, List<String> messages) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final seen = <String>{};
  final logs = <String>[];
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/schema.dart': source},
    generateFor: const {'test_pkg|lib/schema.dart'},
    readerWriter: readerWriter,
    outputs: const {},
    onLog: (LogRecord log) {
      logs.add('${log.level}: ${log.message}');
      if (log.level.name != 'SEVERE') return;
      for (final message in messages) {
        if (log.message.contains(message)) seen.add(message);
      }
    },
  );
  expect(seen, containsAll(messages), reason: logs.join('\n'));
}

const _head = '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'schema.g.dart';
''';

void main() {
  test(
    'follows field presence and nullability through schema aliases',
    () async {
      await _expectOutput(
        '''
$_head
final optionalName = Ack.string().optional();
final optionalAlias = optionalName;
StringSchema get nullableName => Ack.string().nullable();
final defaultName = Ack.string().withDefault('member');

@Schemable()
final profileSchema = Ack.object({
  'name': optionalAlias,
  'nickname': nullableName,
  'role': defaultName,
});
''',
        allOf([
          contains('final String? name;'),
          contains('this.name'),
          isNot(contains('required this.name')),
          contains('final String? nickname;'),
          contains('required this.nickname'),
          contains('final String role;'),
          contains('required this.role'),
        ]),
      );
    },
  );

  test('honors explicit false and outermost schema flag overrides', () async {
    await _expectOutput(
      '''
$_head
const disabled = false;
final optionalName = Ack.string().optional();
final nullableName = Ack.string().nullable();

@Schemable()
final flagsSchema = Ack.object({
  'name': optionalName.optional(value: disabled),
  'nickname': nullableName.nullable(value: false),
  'labels': Ack.map(nullableName.nullable(value: false)),
  'items': Ack.list(Ack.string().nullable().nullable(value: false)),
  'otherItems': Ack.list(nullableName.nullable(value: false)),
});

@Schemable()
final titleSchema = Ack.string().nullable().nullable(value: false);
''',
      allOf([
        contains('required this.name'),
        contains('final String name;'),
        contains('required this.nickname'),
        contains('final String nickname;'),
        contains('final Map<String, String> labels;'),
        contains('final List<String> items;'),
        contains('final List<String> otherItems;'),
        contains('final class Title'),
      ]),
    );
  });

  for (final omitted in ['null', '(null)', '((null))']) {
    test('treats copyWith null arguments as no-ops: $omitted', () async {
      await _expectOutput(
        '''
$_head
final name = Ack.string().nullable().optional().copyWith(
  isNullable: $omitted, isOptional: $omitted,
);
@Schemable()
final flagsSchema = Ack.object({'name': name});
@Schemable()
final policySchema = Ack.object({}, additionalProperties: true).copyWith(
  additionalProperties: $omitted,
);
''',
        allOf([
          contains('final String? name;'),
          isNot(contains('required this.name')),
          contains('Policy({Map<String, Object?> additionalProperties'),
        ]),
      );
    });
  }

  test('preserved JSON boundaries honor an outer nullable clear', () async {
    await _expectOutput('''
$_head
@Schemable()
final boundaryFlagsSchema = Ack.object({
  'value': Ack.preserveBoundary(Ack.string().nullable()).nullable(value: false),
});
''', allOf([contains('final String value;'), contains('required this.value')]));
  });

  test('preserved JSON boundaries use effective nested flags', () async {
    await _expectOutput(
      '''
$_head
final nullableValue = Ack.string().nullable();
final nullableAlias = nullableValue;
@Schemable()
final boundaryFlagsSchema = Ack.object({
  'copiedValues': Ack.preserveBoundary(Ack.map(Ack.string().copyWith(isNullable: true))),
  'configuredValues': Ack.preserveBoundary(Ack.map(Ack.string().withRuntimeConfig(isNullable: true))),
  'clearedValues': Ack.preserveBoundary(Ack.map(nullableAlias.nullable(value: false))),
  'items': Ack.preserveBoundary(Ack.list(nullableAlias.nullable(value: false))),
  'outerMap': Ack.preserveBoundary(Ack.map(nullableValue).nullable()).nullable(value: false),
});
''',
      allOf([
        contains('final Map<String, String?> copiedValues;'),
        contains('final Map<String, String?> configuredValues;'),
        contains('final Map<String, String> clearedValues;'),
        contains('final List<String> items;'),
        contains('final Map<String, String?> outerMap;'),
      ]),
    );
  });

  test('rejects actually nullable preserved boundary list items', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final boundaryFlagsSchema = Ack.object({
  'items': Ack.preserveBoundary(Ack.list(Ack.string().nullable())),
});
''',
      ['boundaryFlagsSchema.items', 'cannot prove a native JSON boundary'],
    );
  });

  test('preserves wrapper flag and outer default semantics', () async {
    await _expectOutput(
      '''
$_head
final optionalDefault = Ack.string().optional().withDefault('member');
final codec = optionalDefault.codec<String>(
  decode: (value) => value,
  encode: (value) => value,
);
final nullableDefault = Ack.string().nullable().withDefault('member');

@Schemable()
final wrappersSchema = Ack.object({
  'name': codec,
  'nickname': nullableDefault.nullable(value: false),
});
''',
      allOf([
        contains('final String? name;'),
        isNot(contains('required this.name')),
        contains('required this.nickname'),
        contains('final String? nickname;'),
      ]),
    );
  });

  test('rejects nullable roots reached through unannotated aliases', () async {
    await _expectFailure(
      '''
$_head
final nullableName = Ack.string().nullable();
@Schemable()
final titleSchema = nullableName;
''',
      ['titleSchema', 'nullable root'],
    );
  });

  test('rejects schema flags that are not statically constant', () async {
    await _expectFailure(
      '''
$_head
bool get enabled => true;
@Schemable()
final flagsSchema = Ack.object({'name': Ack.string().optional(value: enabled)});
''',
      ['flagsSchema.name', 'optional', 'bool literal or const'],
    );
  });

  for (final modifier in [
    "extend({'age': Ack.integer()})",
    'partial()',
    "merge(Ack.object({'age': Ack.integer()}))",
    "pick(['name'])",
    "omit(['name'])",
    'copyWith(properties: {})',
  ]) {
    test('rejects unsupported object shape operation $modifier', () async {
      await _expectFailure(
        '''
$_head
@Schemable()
final userSchema = Ack.object({'name': Ack.string()}).$modifier;
''',
        ['userSchema', modifier.split('(').first, 'shape', 'literal'],
      );
    });
  }

  test('strict and passthrough use the outermost object policy', () async {
    await _expectOutput(
      '''
$_head
bool get extras => true;
@Schemable()
final strictSchema = Ack.object({}, additionalProperties: extras).passthrough().strict();
@Schemable()
final aliasSchema = strictSchema.passthrough();
''',
      allOf([
        contains('Strict()'),
        isNot(contains('Strict({')),
        contains('Alias({Map<String, Object?> additionalProperties'),
      ]),
    );
  });

  test('rejects shape-changing discriminated copyWith arguments', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final catSchema = Ack.object({'name': Ack.string()});
@Schemable()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind', schemas: {'cat': catSchema},
).copyWith(discriminatorKey: 'type');
''',
      ['petSchema', 'copyWith', 'shape', 'literal'],
    );
  });

  test('rejects annotated object results that are no longer schemas', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final userSchema = Ack.object({'name': Ack.string()}).toJsonSchema();
''',
      ['userSchema', 'does not resolve to AckSchema'],
    );
  });

  test('permits shape operations behind an outer value codec', () async {
    await _expectOutput('''
$_head
bool get extras => true;
@Schemable()
final titleSchema = Ack.object({}, additionalProperties: extras).extend({'title': Ack.string()}).codec<String>(
  decode: (value) => value['title'] as String,
  encode: (value) => {'title': value},
);
''', allOf([contains('final class Title'), contains('final String value;')]));
  });

  test('rejects a codec type the library cannot name', () async {
    final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
    await readerWriter.testing.loadIsolateSources();
    final errors = <String>[];
    await testBuilder(
      ackModelBuilder(BuilderOptions.empty),
      {
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'money_schema.dart';

part 'schema.g.dart';

@Schemable()
final orderSchema = Ack.object({'price': moneySchema});
''',
        'test_pkg|lib/money_schema.dart': '''
import 'package:ack/ack.dart';
import 'money.dart';

final moneySchema = Ack.integer().codec<Money>(
  decode: Money.new,
  encode: (money) => money.cents,
);
''',
        'test_pkg|lib/money.dart': '''
class Money {
  const Money(this.cents);
  final int cents;
}
''',
      },
      generateFor: const {'test_pkg|lib/schema.dart'},
      readerWriter: readerWriter,
      outputs: const {},
      onLog: (LogRecord log) {
        if (log.level == Level.SEVERE) errors.add(log.message);
      },
    );

    expect(
      errors,
      contains(
        contains(
          'orderSchema.price(→ moneySchema) uses Money, which is not visible '
          'in this library. Import package:test_pkg/money.dart.',
        ),
      ),
    );
  });

  test('rejects @Schemable options that apply only to classes', () async {
    await _expectFailure(
      '''
$_head
@Schemable(
  caseStyle: AckCaseStyle.snake,
  description: 'A user.',
  schemaName: 'UserWire',
)
final userSchema = Ack.object({'firstName': Ack.string()});
''',
      [
        'userSchema sets @Schemable options that apply only to classes: '
            'schemaName, description, caseStyle.',
        'Configure a top-level schema in its Ack expression; describe it '
            'with .describe(...).',
      ],
    );
  });

  test('rejects dynamic additionalProperties expressions', () async {
    await _expectFailure(
      '''
$_head
bool get allowExtras => true;

@Schemable()
final userSchema = Ack.object(
  {'name': Ack.string()},
  additionalProperties: allowExtras,
);
''',
      ['userSchema', 'additionalProperties', 'const variable'],
    );
  });

  test(
    'models custom bidirectional codecs from generic schema types',
    () async {
      await _expectOutput(
        '''
$_head
final class UserId {
  const UserId(this.value);
  final int value;
}

final class TagList {
  const TagList(this.values);
  final List<String> values;
}

@Schemable(name: 'UserIdModel')
final userIdSchema = Ack.integer().codec<UserId>(
  decode: UserId.new,
  encode: (id) => id.value,
);

@Schemable()
final profileSchema = Ack.object({
  'tags': Ack.list(Ack.string()).codec<TagList>(
    decode: TagList.new,
    encode: (tags) => tags.values,
  ),
});
''',
        allOf([
          contains('final class UserIdModel'),
          contains('final UserId value;'),
          contains('factory UserIdModel.fromJson(int json)'),
          contains('int toJson()'),
          contains('required this.tags'),
        ]),
      );
    },
  );

  test('treats object roots with an outer codec as value models', () async {
    await _expectOutput(
      '''
$_head
final class UserRecord {
  const UserRecord(this.name);
  final String name;
}

@Schemable()
final userSchema = Ack.object({
  'name': Ack.string(),
}).codec<UserRecord>(
  decode: (value) => UserRecord(value['name'] as String),
  encode: (user) => {'name': user.name},
);
''',
      allOf([
        contains('final class User'),
        contains('User(this.value)'),
        contains('final UserRecord value;'),
        contains('factory User.fromJson(Map<String, Object?> json)'),
        contains('Map<String, Object?> toJson()'),
      ]),
    );
  });

  test('resolves named lazy self recursion through model adapters', () async {
    await _expectOutput(
      '''
$_head
@Schemable()
final AckSchema<JsonMap, JsonMap> nodeSchema = Ack.object({
  'name': Ack.string(),
  'children': Ack.list(
    Ack.lazy('node', () => nodeSchema),
  ),
});
''',
      allOf([
        contains('final List<Node> children;'),
        contains(r'Node.$ack.fromRuntime'),
        contains(r'Node.$ack.toRuntime'),
      ]),
    );
  });

  test('models mutually recursive lazy schemas', () async {
    await _expectOutput(
      '''
$_head
@Schemable()
final AckSchema<JsonMap, JsonMap> authorSchema = Ack.object({
  'books': Ack.list(Ack.lazy('book', () => bookSchema)),
});

@Schemable()
final AckSchema<JsonMap, JsonMap> bookSchema = Ack.object({
  'author': Ack.lazy('author', () => authorSchema),
});
''',
      allOf([
        contains('final List<Book> books;'),
        contains('final Author author;'),
      ]),
    );
  });

  test('rejects unsupported dynamic roots with the declaration path', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final payloadSchema = Ack.any();
''',
      ['payloadSchema', 'Ack.any()'],
    );
  });

  for (final unsupported in {
    'Ack.anyOf([Ack.string(), Ack.integer()])': 'Ack.anyOf()',
    'Ack.instance<Object>()': 'bare Ack.instance<T>()',
    'Ack.string().nullable()': 'nullable root',
  }.entries) {
    test('rejects unsupported root ${unsupported.key}', () async {
      await _expectFailure(
        '''
$_head
@Schemable()
final payloadSchema = ${unsupported.key};
''',
        ['payloadSchema', unsupported.value],
      );
    });
  }

  for (final boundary in [
    'Ack.instance<Object>()',
    'Ack.anyOf([Ack.string(), Ack.instance<Object>()])',
  ]) {
    test('rejects opaque JSON boundary inference for $boundary', () async {
      await _expectFailure(
        '''
$_head
@Schemable()
final boundaryRecordSchema = Ack.object({
  'value': Ack.preserveBoundary($boundary),
});
''',
        ['boundaryRecordSchema.value', 'cannot prove a native JSON boundary'],
      );
    });
  }

  test('rejects a .transform() field with the declaration path', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final userSchema = Ack.object({
  'nick': Ack.string().transform((v) => v.trim()),
});
''',
      ['userSchema.nick', '.transform()'],
    );
  });

  test(
    'rejects a local one-way transform field and names the variable',
    () async {
      await _expectFailure(
        '''
$_head
final ageFromString = Ack.string().transform(int.parse);

@Schemable()
final userSchema = Ack.object({
  'age': ageFromString,
});
''',
        ['userSchema.age', 'ageFromString', '.transform()'],
      );
    },
  );

  test('rejects a local one-way transform used as an annotated root', () async {
    await _expectFailure(
      '''
$_head
final ageFromString = Ack.string().transform(int.parse);

@Schemable()
final ageSchema = ageFromString;
''',
      ['ageSchema', 'ageFromString', '.transform()'],
    );
  });

  test('rejects a referenced one-way transform below a codec', () async {
    await _expectFailure(
      '''
$_head
final normalized = Ack.string().transform((v) => v.trim());

@Schemable()
final valueSchema = normalized.codec<String>(
  decode: (value) => value,
  encode: (value) => value,
);
''',
      ['valueSchema', 'normalized', '.transform()'],
    );
  });

  test('rejects a function-backed one-way transform below a codec', () async {
    await _expectFailure(
      '''
$_head
AckSchema<String, String> normalized() =>
    Ack.string().transform((v) => v.trim());

@Schemable()
final valueSchema = normalized().codec<String>(
  decode: (value) => value,
  encode: (value) => value,
);
''',
      ['valueSchema', 'normalized', '.transform()'],
    );
  });

  test('rejects a parenthesized one-way transform below a codec', () async {
    await _expectFailure(
      '''
$_head
final normalized = Ack.string().transform((v) => v.trim());

@Schemable()
final valueSchema = (normalized).codec<String>(
  decode: (value) => value,
  encode: (value) => value,
);
''',
      ['valueSchema', 'normalized', '.transform()'],
    );
  });

  test(
    'rejects a direct parenthesized one-way transform below a codec',
    () async {
      await _expectFailure(
        '''
$_head
@Schemable()
final valueSchema = (Ack.string().transform((v) => v.trim())).codec<String>(
  decode: (value) => value,
  encode: (value) => value,
);
''',
        ['valueSchema', '.transform()'],
      );
    },
  );

  test('infers Object and Map fields from Ack.any() and Ack.map()', () async {
    await _expectOutput(
      '''
$_head
final payloadAny = Ack.any();

@Schemable()
final userSchema = Ack.object({
  'payload': payloadAny,
  'kind': Ack.any(),
  'note': Ack.any().nullable(),
  'items': Ack.list(Ack.any()),
  'values': Ack.map(Ack.any()),
  'metadata': Ack.map(Ack.any().nullable()),
  'labels': Ack.map(Ack.string()),
});
''',
      allOf([
        contains('final Object payload;'),
        contains('final Object kind;'),
        contains('final Object? note;'),
        contains('final List<Object> items;'),
        contains('final Map<String, Object> values;'),
        contains('final Map<String, Object?> metadata;'),
        contains('final Map<String, String> labels;'),
        isNot(contains('value as Object?')),
      ]),
    );
  });

  test('infers nullable map values through a nullable variable', () async {
    await _expectOutput('''
$_head
final nullableAny = Ack.any().nullable();

@Schemable()
final userSchema = Ack.object({'metadata': Ack.map(nullableAny)});
''', contains('final Map<String, Object?> metadata;'));
  });

  test('rejects nullable Ack.any() list items', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final userSchema = Ack.object({
  'items': Ack.list(Ack.any().nullable()),
});
''',
      ['userSchema.items', 'nullable collection elements'],
    );
  });

  test('rejects an Ack.any() root reached through a variable', () async {
    await _expectFailure(
      '''
$_head
final payloadAny = Ack.any();

@Schemable()
final payloadSchema = payloadAny;
''',
      ['payloadSchema', 'Ack.any()'],
    );
  });

  for (final source in [
    'Ack.map(Ack.integer())',
    'Ack.map(Ack.any().nullable()).describe("extras")',
  ]) {
    test('rejects Ack.map() root $source', () async {
      await _expectFailure(
        '''
$_head
@Schemable()
final scoresSchema = $source;
''',
        ['scoresSchema', 'Ack.map() root'],
      );
    });
  }

  test('rejects an Ack.map() root reached through a variable', () async {
    await _expectFailure(
      '''
$_head
final scoresMap = Ack.map(Ack.integer());

@Schemable()
final scoresSchema = scoresMap;
''',
      ['scoresSchema', 'Ack.map() root'],
    );
  });

  test('rejects an unannotated named Ack.object field', () async {
    await _expectFailure(
      '''
$_head
final address = Ack.object({'city': Ack.string()});

@Schemable()
final userSchema = Ack.object({
  'home': address,
});
''',
      ['userSchema.home', "'address'", '@Schemable'],
    );
  });

  test('rejects a leading-underscore JSON key', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final userSchema = Ack.object({
  '_id': Ack.string(),
});
''',
      ['userSchema._id', "cannot start with '_'"],
    );
  });

  test('rejects a leading-underscore discriminator key', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final catSchema = Ack.object({'lives': Ack.integer()});

@Schemable()
final petSchema = Ack.discriminated(
  discriminatorKey: '_kind',
  schemas: {'cat': catSchema},
);
''',
      ['petSchema._kind', "cannot start with '_'"],
    );
  });

  test('rejects an anonymous inline object field with the path', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final userSchema = Ack.object({
  'home': Ack.object({'city': Ack.string()}),
});
''',
      ['userSchema.home', 'anonymous inline'],
    );
  });

  test('rejects an anonymous inline object inside Ack.list', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final bagSchema = Ack.object({
  'items': Ack.list(Ack.object({'n': Ack.string()})),
});
''',
      ['bagSchema.items[]', 'anonymous inline'],
    );
  });

  test('rejects a direct nullable Ack.list item schema', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final tagsSchema = Ack.list(Ack.string().nullable());
''',
      ['tagsSchema[]', 'nullable collection elements', 'Ack.list'],
    );
  });

  test('rejects a referenced nullable Ack.list item schema', () async {
    await _expectFailure(
      '''
$_head
final itemSchema = Ack.string().nullable();

@Schemable()
final tagsSchema = Ack.list(itemSchema);
''',
      [
        'tagsSchema[]',
        'itemSchema',
        'nullable collection elements',
        'Ack.list',
      ],
    );
  });

  test('rejects a dynamic factory root with the declaration path', () async {
    await _expectFailure(
      '''
$_head
AckSchema make() => Ack.string();

@Schemable()
final payloadSchema = make();
''',
      ['payloadSchema', 'unresolvable dynamic schema factory'],
    );
  });

  test('rejects a generated-class-name collision', () async {
    await _expectFailure(
      '''
$_head
@Schemable(name: 'User')
final firstSchema = Ack.object({'a': Ack.string()});

@Schemable(name: 'User')
final secondSchema = Ack.object({'b': Ack.string()});
''',
      ['User', 'Multiple @Schemable'],
    );
  });

  test('follows local bidirectional codec and list variables', () async {
    await _expectOutput(
      '''
$_head
final class Color {
  const Color(this.value);
  final String value;
}

final color = Ack.string().codec<Color>(
  decode: Color.new,
  encode: (c) => c.value,
);

final tags = Ack.list(Ack.string());

@Schemable()
final profileSchema = Ack.object({
  'color': color,
  'tags': tags,
});
''',
      allOf([
        contains('required this.color'),
        contains('final Color color'),
        contains('required List<String> tags'),
        contains('final List<String> tags'),
      ]),
    );
  });

  test('generates codec fields whose outputSchema is InstanceSchema', () async {
    await _expectOutput('''
$_head
final class Color {
  const Color(this.value);
  final String value;
}

@Schemable()
final userSchema = Ack.object({
  'color': Ack.string().codec<Color>(
    decode: Color.new,
    encode: (c) => c.value,
  ),
});
''', allOf([contains('required this.color'), contains('final Color color')]));
  });

  test('rejects ordinary alias cycles', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final firstSchema = secondSchema;

@Schemable()
final secondSchema = firstSchema;
''',
      ['alias cycle', 'firstSchema'],
    );
  });
}
