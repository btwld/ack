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
    outputs: {'test_pkg|lib/schema.ack.dart': decodedMatches(matcher)},
  );
}

Future<void> _expectFailure(String source, List<String> messages) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final seen = <String>{};
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {'test_pkg|lib/schema.dart': source},
    generateFor: const {'test_pkg|lib/schema.dart'},
    readerWriter: readerWriter,
    outputs: const {},
    onLog: (LogRecord log) {
      if (log.level.name != 'SEVERE') return;
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

part 'schema.ack.dart';
part 'schema.ack.g.dart';
''';

void main() {
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

part 'schema.ack.dart';
part 'schema.ack.g.dart';

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

  test('rejects a .trim() field with the declaration path', () async {
    await _expectFailure(
      '''
$_head
@Schemable()
final userSchema = Ack.object({
  'nick': Ack.string().trim(),
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
final normalized = Ack.string().trim();

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
AckSchema<String, String> normalized() => Ack.string().trim();

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
final normalized = Ack.string().trim();

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
final valueSchema = (Ack.string().trim()).codec<String>(
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
