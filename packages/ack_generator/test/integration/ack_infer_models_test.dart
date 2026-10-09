// Modern schema-first model tests.
import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

Future<void> _build(
  Map<String, String> sources, {
  required Map<String, Object> outputs,
  void Function(LogRecord log)? onLog,
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
    onLog: onLog,
  );
}

const _imports = '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';
''';

void main() {
  test(
    'emits empty objects without malformed argument or map commas',
    () async {
      await _build(
        {
          'empty.dart':
              '''
$_imports
part 'empty.g.dart';

@Schemable()
final emptySchema = Ack.object({});
''',
        },
        outputs: {
          'test_pkg|lib/empty.g.dart': decodedMatches(
            allOf([
              contains('Empty()'),
              isNot(contains('generatedJson')),
              contains('static Empty _fromAckRuntime'),
              contains('Map<String, Object?> _toAckRuntime()'),
              isNot(contains('\n  ,')),
            ]),
          ),
        },
      );
    },
  );

  test('evaluates const additionalProperties references', () async {
    await _build(
      {
        'user.dart':
            '''
$_imports
part 'user.g.dart';

const allowExtras = true;

@Schemable()
final userSchema = Ack.object(
  {'name': Ack.string()},
  additionalProperties: allowExtras,
);
''',
      },
      outputs: {
        'test_pkg|lib/user.g.dart': decodedMatches(
          allOf([
            contains('final Map<String, Object?> additionalProperties'),
            contains('additionalProperties.entries'),
            contains(
              'additionalProperties = '
              'deepUnmodifiableJsonMap(additionalProperties)',
            ),
            isNot(contains('_ackImmutableCopyValue')),
            isNot(contains('_ackImmutableCopyMap')),
          ]),
        ),
      },
    );
  });

  test('emits omitted-value copyWith sentinels for nullable fields', () async {
    await _build(
      {
        'user.dart':
            '''
$_imports
part 'user.g.dart';

@Schemable()
final userSchema = Ack.object({
  'name': Ack.string(),
  'nickname': Ack.string().optional(),
});
''',
      },
      outputs: {
        'test_pkg|lib/user.g.dart': decodedMatches(
          allOf([
            contains('final class _UserCopyWithUnset'),
            contains('const _UserCopyWithUnset()'),
            contains('static const _UserCopyWithUnset _ackCopyWithUnset ='),
            contains('Object? nickname = _ackCopyWithUnset'),
            contains('nickname: identical(nickname, _ackCopyWithUnset)'),
            contains(': nickname as String?'),
            isNot(contains('_ackCopyWithOmitted')),
          ]),
        ),
      },
    );
  });

  test(
    'emits enums, num, literals, codecs, and nested immutable lists',
    () async {
      await _build(
        {
          'values.dart':
              '''
$_imports
part 'values.g.dart';

enum Role { admin, member }

@Schemable()
final metricsSchema = Ack.object({
  'amount': Ack.number(),
  'state': Ack.literal('ready'),
  'role': Ack.enumValues(Role.values),
  'dates': Ack.list(Ack.list(Ack.date())),
});
''',
        },
        outputs: {
          'test_pkg|lib/values.g.dart': decodedMatches(
            allOf([
              contains('required this.amount'),
              contains('required this.state'),
              contains('required this.role'),
              contains('required List<List<DateTime>> dates'),
              contains('(item) => List<DateTime>.unmodifiable(item.map'),
            ]),
          ),
        },
      );
    },
  );

  test('resolves direct, prefixed, and re-exported model references', () async {
    await _build(
      {
        'address.dart':
            '''
$_imports
part 'address.g.dart';

@Schemable()
final addressSchema = Ack.object({'city': Ack.string()});
''',
        'exports.dart': "export 'address.dart';",
        'person.dart':
            '''
$_imports
import 'address.dart' as direct;
import 'exports.dart' as exported;
part 'person.g.dart';

@Schemable()
final personSchema = Ack.object({
  'home': direct.addressSchema,
  'history': Ack.list(exported.addressSchema),
});
''',
      },
      outputs: {
        'test_pkg|lib/address.g.dart': decodedMatches(
          contains('final class Address'),
        ),
        'test_pkg|lib/person.g.dart': decodedMatches(
          allOf([
            contains('required this.home'),
            contains('required List<exported.Address> history'),
            contains('static Person _fromAckRuntime'),
            contains(r'direct.Address.$ack.fromRuntime'),
            contains(r'exported.Address.$ack.toRuntime'),
          ]),
        ),
      },
    );
  });

  test('preserves external type qualifiers through prefixed barrels', () async {
    await _build(
      {
        'role.dart': 'enum Role { admin, member }',
        'types.dart': "export 'role.dart';",
        'user.dart':
            '''
$_imports
import 'types.dart' as types;
part 'user.g.dart';

@Schemable()
final userSchema = Ack.object({
  'role': Ack.enumValues(types.Role.values),
});
''',
      },
      outputs: {
        'test_pkg|lib/user.g.dart': decodedMatches(
          contains('final types.Role role;'),
        ),
      },
    );
  });

  test('allows split imports for a schema and its generated model', () async {
    await _build(
      {
        'address.dart':
            '''
$_imports
part 'address.g.dart';

@Schemable()
final addressSchema = Ack.object({'city': Ack.string()});
''',
        'person.dart':
            '''
$_imports
import 'address.dart' show addressSchema;
import 'address.dart' show Address;
part 'person.g.dart';

@Schemable()
final personSchema = Ack.object({'address': addressSchema});
''',
      },
      outputs: {
        'test_pkg|lib/address.g.dart': decodedMatches(
          contains('final class Address'),
        ),
        'test_pkg|lib/person.g.dart': decodedMatches(
          allOf([
            contains('final Address address'),
            contains(r'Address.$ack.fromRuntime'),
          ]),
        ),
      },
    );
  });

  test(
    'allows split imports for a model and future class-first facade',
    () async {
      await _build(
        {
          'address.dart':
              '''
$_imports
part 'address.g.dart';

@Schemable()
final class Address with _\$AddressAck {
  const Address({required this.city});

  final String city;
}
''',
          'person.dart':
              '''
$_imports
import 'address.dart' show Address;
import 'address.dart' show AddressSchema;
part 'person.g.dart';

@Schemable()
final personSchema = Ack.object({'address': AddressSchema.schema});
''',
        },
        outputs: {
          'test_pkg|lib/address.g.dart': decodedMatches(
            contains('abstract final class AddressSchema'),
          ),
          'test_pkg|lib/person.g.dart': decodedMatches(
            contains('final Address address'),
          ),
        },
      );
    },
  );

  test('rejects a class-first facade hidden by a barrel export', () async {
    final messages = <String>{};
    await _build(
      {
        'address.dart':
            '''
$_imports
part 'address.g.dart';

@Schemable()
final class Address with _\$AddressAck {
  const Address({required this.city});

  final String city;
}
''',
        'exports.dart': "export 'address.dart' show Address;",
        'person.dart':
            '''
$_imports
import 'exports.dart';
part 'person.g.dart';

@Schemable()
final personSchema = Ack.object({'address': AddressSchema.schema});
''',
      },
      outputs: {'test_pkg|lib/address.g.dart': anything},
      onLog: (log) {
        if (log.level.name != 'SEVERE') return;
        for (final message in ['AddressSchema', 'export combinator']) {
          if (log.message.contains(message)) messages.add(message);
        }
      },
    );
    expect(messages, containsAll(['AddressSchema', 'export combinator']));
  });

  test(
    'rejects a cross-library model hidden by an import combinator',
    () async {
      final messages = <String>{};
      await _build(
        {
          'address.dart':
              '''
$_imports
part 'address.g.dart';

@Schemable()
final addressSchema = Ack.object({'city': Ack.string()});
''',
          'person.dart':
              '''
$_imports
import 'address.dart' show addressSchema;
part 'person.g.dart';

@Schemable()
final personSchema = Ack.object({'address': addressSchema});
''',
        },
        outputs: {'test_pkg|lib/address.g.dart': anything},
        onLog: (log) {
          if (log.level.name != 'SEVERE') return;
          for (final message in ['Address', 'import combinator']) {
            if (log.message.contains(message)) messages.add(message);
          }
        },
      );
      expect(messages, containsAll(['Address', 'import combinator']));
    },
  );

  test('rejects a generated model hidden by a barrel export', () async {
    final messages = <String>{};
    await _build(
      {
        'address.dart':
            '''
$_imports
part 'address.g.dart';

@Schemable()
final addressSchema = Ack.object({'city': Ack.string()});
''',
        'exports.dart': "export 'address.dart' show addressSchema;",
        'person.dart':
            '''
$_imports
import 'exports.dart';
part 'person.g.dart';

@Schemable()
final personSchema = Ack.object({'address': addressSchema});
''',
      },
      outputs: {'test_pkg|lib/address.g.dart': anything},
      onLog: (log) {
        if (log.level.name != 'SEVERE') return;
        for (final message in ['Address', 'export combinator']) {
          if (log.message.contains(message)) messages.add(message);
        }
      },
    );
    expect(messages, containsAll(['Address', 'export combinator']));
  });

  test('emits sealed unions with final same-library branches', () async {
    await _build(
      {
        'pet.dart':
            '''
$_imports
part 'pet.g.dart';

@Schemable()
final catSchema = Ack.object({'kind': Ack.literal('cat'), 'lives': Ack.integer()});

@Schemable()
final dogSchema = Ack.object({'bark': Ack.boolean()}).passthrough();

@Schemable()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {'cat': catSchema, 'dog': dogSchema},
);
''',
      },
      outputs: {
        'test_pkg|lib/pet.g.dart': decodedMatches(
          allOf([
            contains('sealed class Pet'),
            contains('final class Cat extends Pet'),
            contains('final class Dog extends Pet'),
            isNot(contains('generatedJson')),
            contains("String get kind => 'cat';"),
            contains("'kind': 'dog'"),
            contains('additionalProperties.entries'),
            contains('static Cat _fromAckRuntime'),
            contains('static Dog _fromAckRuntime'),
          ]),
        ),
      },
    );
  });

  test('rejects generated member collisions with paths', () async {
    final messages = <String>{};
    await _build(
      {
        'bad.dart':
            '''
$_imports
part 'bad.g.dart';

@Schemable()
final badSchema = Ack.object({'toJson': Ack.string()});
''',
      },
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE') messages.add(log.message);
      },
    );
    expect(messages.single, contains('badSchema.toJson'));
  });

  test(
    'rejects a local declaration named like the copyWith interface',
    () async {
      final messages = <String>{};
      await _build(
        {
          'bad.dart':
              '''
$_imports
part 'bad.g.dart';

@Schemable()
final userSchema = Ack.object({'name': Ack.string()});

final class \$UserCopyWith {}
''',
        },
        outputs: const {},
        onLog: (log) {
          if (log.level.name == 'SEVERE') messages.add(log.message);
        },
      );
      expect(
        messages.single,
        contains(r'Generated helper "$UserCopyWith" conflicts'),
      );
    },
  );

  test('rejects Dart keywords used as generated field names', () async {
    final messages = <String>{};
    await _build(
      {
        'bad.dart':
            '''
$_imports
part 'bad.g.dart';

@Schemable()
final badSchema = Ack.object({'class': Ack.string()});
''',
      },
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE') messages.add(log.message);
      },
    );
    expect(messages.single, contains('badSchema.class'));
  });

  test(
    'rejects union discriminators that collide with generated APIs',
    () async {
      final messages = <String>{};
      await _build(
        {
          'bad.dart':
              '''
$_imports
part 'bad.g.dart';

@Schemable()
final catSchema = Ack.object({'lives': Ack.integer()});

@Schemable()
final petSchema = Ack.discriminated(
  discriminatorKey: 'toJson',
  schemas: {'cat': catSchema},
);
''',
        },
        outputs: const {},
        onLog: (log) {
          if (log.level.name == 'SEVERE') messages.add(log.message);
        },
      );
      expect(messages.single, contains('petSchema.toJson'));
    },
  );

  test('rejects broad union discriminator fields', () async {
    final messages = <String>{};
    await _build(
      {
        'bad.dart':
            '''
$_imports
part 'bad.g.dart';

@Schemable()
final catSchema = Ack.object({
  'kind': Ack.string(),
  'lives': Ack.integer(),
});

@Schemable()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {'cat': catSchema},
);
''',
      },
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE') messages.add(log.message);
      },
    );
    expect(messages.single, contains('catSchema.kind'));
  });

  test('does not reserve obsolete passthrough helper names', () async {
    await _build(
      {
        'bad.dart':
            '''
$_imports
part 'bad.g.dart';

Object? _ackImmutableCopyValue(Object? value) => value;

@Schemable()
final bagSchema = Ack.object({}).passthrough();
''',
      },
      outputs: {
        'test_pkg|lib/bad.g.dart': decodedMatches(
          allOf([
            contains('deepUnmodifiableJsonMap(additionalProperties)'),
            isNot(contains('Object? _ackImmutableCopyValue')),
          ]),
        ),
      },
    );
  });

  test('preserves Ack runtime qualifiers through prefixed barrels', () async {
    await _build(
      {
        'support.dart': '''
export 'package:ack/ack.dart';
export 'package:ack/annotations.dart';
''',
        'schema.dart': '''
import 'support.dart' as support;

part 'schema.g.dart';

@support.Schemable()
final userSchema = support.Ack.object({'name': support.Ack.string()});
''',
      },
      outputs: {
        'test_pkg|lib/schema.g.dart': decodedMatches(
          allOf([
            contains('support.AckModelAdapter'),
            contains('support.SchemaResult<User>'),
          ]),
        ),
      },
    );
  });

  test('rejects non-string map keys in generated runtime types', () async {
    final messages = <String>{};
    await _build(
      {
        'bad.dart':
            '''
$_imports
part 'bad.g.dart';

@Schemable()
final valuesSchema = Ack.string().codec<Map<int, String>>(
  decode: (value) => {1: value},
  encode: (value) => value.values.single,
);
''',
      },
      outputs: const {},
      onLog: (log) {
        if (log.level.name == 'SEVERE') messages.add(log.message);
      },
    );
    expect(messages.single, contains('Map<String, T>'));
  });

  test(
    'rejects an unsupported cross-library unannotated schema variable',
    () async {
      final messages = <String>{};
      await _build(
        {
          'other.dart': '''
import 'package:ack/ack.dart';

final payloadUnion = Ack.anyOf([Ack.string(), Ack.integer()]);
''',
          'user.dart':
              '''
$_imports
import 'other.dart';
part 'user.g.dart';

@Schemable()
final userSchema = Ack.object({
  'payload': payloadUnion,
});
''',
        },
        outputs: const {},
        onLog: (log) {
          if (log.level.name == 'SEVERE') messages.add(log.message);
        },
      );
      expect(messages.single, contains('userSchema.payload'));
      expect(messages.single, contains('payloadUnion'));
      expect(messages.single, contains('Ack.anyOf()'));
    },
  );

  test(
    'follows a cross-library Ack.any() variable to an Object field',
    () async {
      await _build(
        {
          'other.dart': '''
import 'package:ack/ack.dart';

final payloadAny = Ack.any();
''',
          'user.dart':
              '''
$_imports
import 'other.dart';
part 'user.g.dart';

@Schemable()
final userSchema = Ack.object({
  'payload': payloadAny.nullable(),
});
''',
        },
        outputs: {
          'test_pkg|lib/user.g.dart': decodedMatches(
            contains('final Object? payload;'),
          ),
        },
      );
    },
  );

  test('rejects a cross-library @Schemable alias root', () async {
    final messages = <String>{};
    await _build(
      {
        'user.dart':
            '''
$_imports
part 'user.g.dart';

@Schemable()
final userSchema = Ack.object({'name': Ack.string()});
''',
        'admin.dart':
            '''
$_imports
import 'user.dart' as other;
part 'admin.g.dart';

@Schemable()
final adminSchema = other.userSchema;
''',
      },
      outputs: {
        'test_pkg|lib/user.g.dart': decodedMatches(
          contains('final class User'),
        ),
      },
      onLog: (log) {
        if (log.level.name == 'SEVERE') messages.add(log.message);
      },
    );
    expect(messages, isNotEmpty);
    expect(messages.join('\n'), contains('adminSchema'));
    expect(messages.join('\n'), contains('cross-library'));
  });

  test('rejects a cross-library discriminated branch with the path', () async {
    final messages = <String>{};
    await _build(
      {
        'cat.dart':
            '''
$_imports
part 'cat.g.dart';

@Schemable()
final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'lives': Ack.integer(),
});
''',
        'pet.dart':
            '''
$_imports
import 'cat.dart';
part 'pet.g.dart';

@Schemable()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {'cat': catSchema},
);
''',
      },
      outputs: {
        'test_pkg|lib/cat.g.dart': decodedMatches(
          contains('final class Cat'),
        ),
      },
      onLog: (log) {
        if (log.level.name == 'SEVERE') messages.add(log.message);
      },
    );
    expect(messages, isNotEmpty);
    expect(messages.join('\n'), contains('petSchema.cat'));
    expect(messages.join('\n'), contains('cross-library'));
  });

  test('emits multi-line descriptions as one doc line each', () async {
    await _build(
      {
        'doc.dart':
            '''
$_imports
part 'doc.g.dart';

@Schemable()
final docSchema = Ack.object({
  'note': Ack.string().describe('First line.\\nSecond line.'),
}).describe('Model line one.\\r\\nModel line two.');
''',
      },
      outputs: {
        'test_pkg|lib/doc.g.dart': decodedMatches(
          allOf(
            contains('/// Model line one.\n/// Model line two.\nfinal class Doc'),
            contains('/// First line.\n  /// Second line.\n  final String note;'),
          ),
        ),
      },
    );
  });
}
