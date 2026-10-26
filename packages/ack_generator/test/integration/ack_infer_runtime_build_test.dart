// Modern schema-first runtime integration tests.
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

/// Asserts generated parts suppress consumer lints and coverage, then
/// analyzes them without the lint suppression so the harness rules still
/// guard the generated code itself.
Future<void> _expectConsumerSafeParts(
  Directory project,
  Map<String, String> generated,
) async {
  const lintSuppression = '// ignore_for_file: type=lint\n';
  for (final MapEntry(key: path, value: source) in generated.entries) {
    expect(source, contains(lintSuppression), reason: path);
    expect(source, contains('// coverage:ignore-file\n'), reason: path);
    File(
      p.join(project.path, path),
    ).writeAsStringSync(source.replaceFirst(lintSuppression, ''));
  }
  try {
    _expectSuccess(
      await _run(project, ['analyze', '--fatal-infos']),
      'dart analyze --fatal-infos without the generated lint suppression',
    );
  } finally {
    for (final MapEntry(key: path, value: source) in generated.entries) {
      File(p.join(project.path, path)).writeAsStringSync(source);
    }
  }
}

/// Asserts that a wrongly typed `copyWith` argument fails analysis.
Future<void> _expectCopyWithRejects(Directory project, String misuse) async {
  final file = File(p.join(project.path, 'lib', 'copy_with_misuse.dart'))
    ..writeAsStringSync(misuse);
  try {
    final result = await _run(project, [
      'analyze',
      p.join('lib', 'copy_with_misuse.dart'),
    ]);
    expect(result.exitCode, isNot(0), reason: '${result.stdout}');
    expect('${result.stdout}', contains('argument_type_not_assignable'));
  } finally {
    file.deleteSync();
  }
}

void main() {
  test(
    'clean generated models compile and preserve the Schemable runtime contract',
    () async {
      var projectRoot = Directory.current;
      while (!Directory(
        p.join(projectRoot.path, 'packages', 'ack_generator'),
      ).existsSync()) {
        projectRoot = projectRoot.parent;
      }
      final temporary = await Directory.systemTemp.createTemp(
        'ack_ack_infer_runtime_',
      );
      try {
        Directory(p.join(temporary.path, 'lib')).createSync();
        Directory(p.join(temporary.path, 'test')).createSync();
        File(p.join(temporary.path, 'pubspec.yaml')).writeAsStringSync('''
name: ack_ack_infer_runtime
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
        File(p.join(temporary.path, 'analysis_options.yaml')).writeAsStringSync(
          '''
linter:
  rules:
    - avoid_redundant_argument_values
    - prefer_null_aware_operators
''',
        );
        File(p.join(temporary.path, 'lib', 'models.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';

part 'models.g.dart';

final class Box {
  const Box(this.values);
  final List<String> values;
}

final class RuntimeUser {
  const RuntimeUser(this.name);
  final String name;
}

@Schemable(name: 'UserRecord')
final userRecordSchema = Ack.object({
  'name': Ack.string(),
}).codec<RuntimeUser>(
  decode: (value) => RuntimeUser(value['name'] as String),
  encode: (user) => {'name': user.name},
);

@Schemable()
final AckSchema<JsonMap, JsonMap> nodeSchema = Ack.object({
  'label': Ack.string(),
  'children': Ack.list(
    Ack.lazy('node', () => nodeSchema),
  ).optional(),
});

@Schemable()
final AckSchema<JsonMap, JsonMap> authorSchema = Ack.object({
  'books': Ack.list(Ack.lazy('book', () => bookSchema)),
});

@Schemable()
final AckSchema<JsonMap, JsonMap> bookSchema = Ack.object({
  'title': Ack.string(),
  'author': Ack.lazy('author', () => authorSchema).optional(),
});

const allowExtras = true;

@Schemable()
final extrasSchema = Ack.object({
  'name': Ack.string(),
  'maybe': Ack.string().nullable(),
  'nickname': Ack.string().optional(),
  'role': Ack.string().withDefault('member'),
  'numbers': Ack.list(Ack.list(Ack.integer())),
  'box': Ack.list(Ack.string()).codec<Box>(
    decode: Box.new,
    encode: (box) => box.values,
  ),
}, additionalProperties: allowExtras);

@Schemable()
final catSchema = Ack.object({'lives': Ack.integer()});

@Schemable()
final dogSchema = Ack.object({'friendly': Ack.boolean()}).passthrough();

@Schemable()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {'cat': catSchema, 'dog': dogSchema},
);

@Schemable(name: 'MemberType')
final memberSchema = Ack.string();

@Schemable()
final emptySchema = Ack.object({});

@Schemable()
final scoresSchema = Ack.list(Ack.integer());

final looseAny = Ack.any();

@Schemable()
final envelopeSchema = Ack.object({
  'kind': Ack.any(),
  'payload': Ack.any().nullable().optional(),
  'items': Ack.list(Ack.any()),
  'values': Ack.map(Ack.any()),
  'metadata': Ack.map(Ack.any().nullable()),
  'labels': Ack.map(Ack.string()),
  'loose': looseAny.optional(),
});

final nullableLabel = Ack.string().nullable();

@Schemable()
final labelsSchema = Ack.object({
  'byKey': Ack.map(nullableLabel),
  'groups': Ack.map(Ack.list(Ack.string()).nullable()),
});

final optionalLabel = Ack.string().optional();
final optionalLabelAlias = optionalLabel;
StringSchema get nullableLabelAlias => nullableLabel;
final defaultLabel = Ack.string().withDefault('member');
final optionalDefaultLabel = optionalLabel.withDefault('member');
final nullableDefaultLabel = nullableLabel.withDefault('member');

@Schemable()
final flagAliasesSchema = Ack.object({
  'name': optionalLabelAlias,
  'nickname': nullableLabelAlias,
  'role': defaultLabel,
  'forced': optionalLabel.optional(value: false),
  'notNull': nullableLabel.nullable(value: false),
  'codec': optionalDefaultLabel.codec<String>(
    decode: (value) => value,
    encode: (value) => value,
  ),
  'wrapped': nullableDefaultLabel.nullable(value: false),
  'labels': Ack.map(nullableLabel.nullable(value: false)),
});

@Schemable()
final strictPolicySchema = Ack.object(
  {'name': Ack.string()},
  additionalProperties: true,
).passthrough().strict();

@Schemable()
final openPolicySchema = strictPolicySchema.passthrough();

@Schemable()
final resetNullableSchema = Ack.string().nullable().nullable(value: false);

@Schemable()
final keywordFieldsSchema = Ack.object({
  'required': Ack.boolean().withDefault(false),
  'abstract': Ack.string(),
  'as': Ack.string(),
  'late': Ack.string(),
  'operator': Ack.string(),
  'async': Ack.string(),
  'await': Ack.string(),
  'yield': Ack.string(),
});

final choiceOptionSchema = Ack.anyOf([
  Ack.string(),
  Ack.object({'label': Ack.string(), 'value': Ack.string()}),
]);
final choiceOptionsSchema = Ack.preserveBoundary(Ack.list(choiceOptionSchema));

@Schemable()
final choiceFieldSchema = Ack.object({'options': choiceOptionsSchema.optional()});

final opaqueValueSchema = Ack.string().codec<Object>(
  decode: DateTime.parse,
  encode: (value) => (value as DateTime).toIso8601String(),
);

@Schemable()
final opaqueRecordSchema = Ack.object({'value': opaqueValueSchema});
final typedListValueSchema = Ack.string().codec<Object>(
  decode: (_) => <int>[1, 2],
  encode: (value) => (value as List<int>).join(','),
);
final typedMapValueSchema = Ack.string().codec<Object>(
  decode: (_) => <String, List<int>>{'values': <int>[3, 4]},
  encode: (value) => (value as Map<String, List<int>>)['values']!.join(','),
);

@Schemable()
final opaqueCollectionsSchema = Ack.object({
  'value': typedListValueSchema,
  'items': Ack.list(typedListValueSchema),
  'byKey': Ack.map(typedListValueSchema),
  'map': typedMapValueSchema,
  'nullable': typedListValueSchema.nullable(),
});

final answerValueSchema = Ack.anyOf([
  Ack.string(), Ack.number(), Ack.list(Ack.string()),
]);
final answerValuesSchema = Ack.preserveBoundary(Ack.map(answerValueSchema));

@Schemable()
final answerRecordSchema = Ack.object({
  'values': answerValuesSchema,
  'ratio': Ack.preserveBoundary(Ack.double()),
});

final nullableBoundaryValue = Ack.string().nullable();
final nullableBoundaryAlias = nullableBoundaryValue;

@Schemable()
final boundaryFlagsSchema = Ack.object({
  'copiedValues': Ack.preserveBoundary(Ack.map(Ack.string().copyWith(isNullable: true))),
  'configuredValues': Ack.preserveBoundary(Ack.map(Ack.string().withRuntimeConfig(isNullable: true))),
  'clearedValues': Ack.preserveBoundary(Ack.map(nullableBoundaryAlias.nullable(value: false))),
  'items': Ack.preserveBoundary(Ack.list(nullableBoundaryAlias.nullable(value: false))),
  'outer': Ack.preserveBoundary(nullableBoundaryValue).nullable(value: false),
  'outerMap': Ack.preserveBoundary(Ack.map(nullableBoundaryValue).nullable()).nullable(value: false),
});

final nullableBoundaryText = Ack.preserveBoundary(Ack.string().nullable());
final boundaryTextAlias = nullableBoundaryText;
final nullableBoundaryMap = Ack.preserveBoundary(Ack.map(Ack.string().nullable()).nullable());
final boundaryMapAlias = nullableBoundaryMap;

@Schemable()
final boundaryAliasesSchema = Ack.object({
  'text': boundaryTextAlias.nullable(value: false),
  'values': boundaryMapAlias.nullable(value: false),
  'groups': Ack.list(boundaryMapAlias.nullable(value: false)),
  'byName': Ack.map(boundaryMapAlias.nullable(value: false)),
});


@Schemable()
final keywordBranchSchema = Ack.object({'answer': Ack.string()});

@Schemable()
final keywordUnionSchema = Ack.discriminated(
  discriminatorKey: 'required',
  schemas: {'yes': keywordBranchSchema},
);

@Schemable(
  unknownProperties: AckUnknownPropertyPolicy.capture,
  captureField: 'required',
)
final class KeywordCapture with _$KeywordCaptureAck {
  KeywordCapture({Map<String, Object?> required = const {}})
      : required = Map.unmodifiable(required);

  final Map<String, Object?> required;
}

final class Counted {
  Counted(this.value);
  final String value;
  static var decodes = 0;
  static var encodes = 0;
  static Counted decode(String value) {
    decodes += 1;
    return Counted(value);
  }
  static String encode(Counted value) {
    encodes += 1;
    return value.value;
  }
}

@Schemable()
final documentSchema = Ack.object({'schema': Ack.string()});

@Schemable(name: 'Settings')
final schema = Ack.object({'theme': Ack.string()});

@Schemable()
final draftSchema = Ack.object({'body': Ack.string()});

@Schemable()
final revisionSchema = Ack.discriminated(
  discriminatorKey: 'schema',
  schemas: {'draft': draftSchema},
);

@Schemable()
final circleSchema = Ack.object({'radius': Ack.integer()});

@Schemable()
final ruleSchema = Ack.object({'schema': Ack.string()});

@Schemable()
final shapeSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {'circle': circleSchema, 'rule': ruleSchema},
);

@Schemable(name: 'CountedModel')
final countedSchema = Ack.object({
  'item': Ack.string().codec<Counted>(
    decode: Counted.decode,
    encode: Counted.encode,
  ),
  'items': Ack.list(
    Ack.string().codec<Counted>(
      decode: Counted.decode,
      encode: Counted.encode,
    ),
  ),
});
''',
        );
        File(p.join(temporary.path, 'lib', 'address.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';

part 'address.g.dart';

@Schemable()
final addressSchema = Ack.object({'city': Ack.string()});

final optionalLabel = Ack.string().optional();
StringSchema get nullableLabel => Ack.string().nullable();
''',
        );
        File(
          p.join(temporary.path, 'lib', 'exports.dart'),
        ).writeAsStringSync("export 'address.dart';\n");
        File(p.join(temporary.path, 'lib', 'person.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';

import 'address.dart' as direct;
import 'exports.dart' as exported;

part 'person.g.dart';

@Schemable()
final personSchema = Ack.object({
  'home': direct.addressSchema,
  'history': Ack.list(exported.addressSchema),
  'note': direct.optionalLabel,
  'label': exported.nullableLabel,
});
''',
        );
        File(
          p.join(temporary.path, 'test', 'runtime_test.dart'),
        ).writeAsStringSync(r'''
import 'package:ack/ack.dart';
import 'package:ack_ack_infer_runtime/models.dart';
import 'package:ack_ack_infer_runtime/person.dart';
import 'package:test/test.dart';

void main() {
  test('contextual and built-in field names retain their JSON keys', () {
    final json = <String, Object?>{
      'required': true,
      'abstract': 'a',
      'as': 'b',
      'late': 'c',
      'operator': 'd',
      'async': 'e',
      'await': 'f',
      'yield': 'g',
    };
    final fields = KeywordFields.parse(json);
    expect(fields.required, isTrue);
    expect(fields.abstract, 'a');
    expect(fields.as, 'b');
    expect(fields.late, 'c');
    expect(fields.operator, 'd');
    expect(fields.async, 'e');
    expect(fields.await, 'f');
    expect(fields.yield, 'g');
    expect(fields.toJson(), json);
    expect(fields.copyWith(required: false).toJson(), {...json, 'required': false});
    expect(KeywordFields.parse({...json}..remove('required')).required, isFalse);
  });

  test('constructor snapshots Object-valued option maps without validating them', () {
    final option = <String, Object?>{'label': 'Keep', 'value': 'keep'};
    final options = <Object>['skip', option];
    final field = ChoiceField(options: options);
    option['value'] = 'changed';
    options.clear();
    final expected = ChoiceField.parse({
      'options': ['skip', {'label': 'Keep', 'value': 'keep'}],
    });
    expect(field, expected);
    expect(field.hashCode, expected.hashCode);
    expect(field.toJson(), expected.toJson());
    expect(() => field.options!.clear(), throwsUnsupportedError);
    expect(() => (field.options!.last as Map)['value'] = 'changed',
        throwsUnsupportedError);
    expect(ChoiceField(options: [false]).safeToJson().isFail, isTrue);
    expect(ChoiceField(options: [Object()]).safeToJson().isFail, isTrue);
    expect(ChoiceField(options: [<Object?, Object?>{1: 'invalid'}])
        .safeToJson().isFail, isTrue);
  });

  test('direct Object fields and typed collections snapshot nested aliases', () {
    final items = <Object?>['original'];
    final nested = <String, Object?>{'items': items};
    final optional = <Object?>[nested];
    final record = Envelope(
      kind: nested,
      payload: optional,
      items: [nested],
      values: {'key': nested},
      metadata: {'key': nested, 'absent': null},
      labels: const {},
    );
    items.add('changed');
    nested.clear();
    optional.clear();
    const expected = {'items': ['original']};
    expect(record.kind, expected);
    expect(record.payload, [expected]);
    expect(record.items, [expected]);
    expect(record.values, {'key': expected});
    expect(record.metadata, {'key': expected, 'absent': null});
    expect(() => (record.kind as Map).clear(), throwsUnsupportedError);
    expect(() => ((record.kind as Map)['items'] as List).clear(), throwsUnsupportedError);
    expect(() => (record.payload as List).clear(), throwsUnsupportedError);
    expect(() => (record.values['key']! as Map).clear(), throwsUnsupportedError);
    expect(() => (record.metadata['key']! as Map).clear(), throwsUnsupportedError);
  });

  test('Object-valued codecs preserve opaque constructor values', () {
    final value = DateTime.utc(2026, 10, 26);
    final record = OpaqueRecord(value: value);
    expect(record.value, same(value));
    expect(record.toJson(), {'value': value.toIso8601String()});
  });


  test('opaque codec Object collections retain their reified runtime types', () {
    final list = <int>[1, 2];
    final nested = <String, List<int>>{'values': <int>[3, 4]};
    final record = OpaqueCollections(value: list, items: [list], byKey: {'key': list},
        map: nested, nullable: list);
    expect(record.value, same(list));
    expect(record.items.single, same(list));
    expect(record.byKey['key'], same(list));
    expect(record.map, same(nested));
    expect(record.nullable, same(list));
    expect(record.toJson(), {'value': '1,2', 'items': ['1,2'], 'byKey': {'key': '1,2'},
        'map': '3,4', 'nullable': '1,2'});
    final parsed = OpaqueCollections.parse({'value': 'x', 'items': ['x'], 'byKey': {'key': 'x'},
        'map': 'x', 'nullable': 'x'});
    expect(parsed.value, isA<List<int>>());
    expect(parsed.items.single, isA<List<int>>());
    expect(parsed.byKey['key'], isA<List<int>>());
    expect(parsed.map, isA<Map<String, List<int>>>());
    expect(parsed.nullable, isA<List<int>>());
    expect(parsed.copyWith(nullable: null).toJson()['nullable'], isNull);
    expect(parsed.toJson(), record.toJson());
  });

  test('explicit JSON boundary unions encode normalized nested string lists', () {
    final tags = <String>['a', 'b'];
    final values = <String, Object>{'tags': tags, 'title': 'Review', 'count': 2};
    final record = AnswerRecord(values: values, ratio: 0.5);
    tags.add('changed');
    values.clear();
    final expected = <String, Object>{'tags': ['a', 'b'], 'title': 'Review', 'count': 2};
    expect(record.values, expected);
    expect(record.toJson(), {'values': expected, 'ratio': 0.5});
    final double ratio = record.ratio;
    expect(ratio, 0.5);
    expect(AnswerRecord.parse({'values': expected, 'ratio': 0.5}).toJson(),
        {'values': expected, 'ratio': 0.5});
    expect(() => (record.values['tags'] as List).clear(), throwsUnsupportedError);
    expect(AnswerRecord(values: {'invalid': false}, ratio: 0.5).safeToJson().isFail, isTrue);
  });

  test('preserved boundary metadata agrees with generated runtime fields', () {
    final json = <String, Object?>{
      'copiedValues': {'a': null},
      'configuredValues': {'b': null},
      'clearedValues': {'c': 'present'},
      'items': ['present'],
      'outer': 'present',
      'outerMap': {'d': null},
    };
    final record = BoundaryFlags.parse(json);
    final Map<String, String?> copied = record.copiedValues;
    final Map<String, String?> configured = record.configuredValues;
    final Map<String, String> cleared = record.clearedValues;
    final List<String> items = record.items;
    final String outer = record.outer;
    final Map<String, String?> outerMap = record.outerMap;
    expect(copied['a'], isNull);
    expect(configured['b'], isNull);
    expect(cleared['c'], 'present');
    expect(items, ['present']);
    expect(outer, 'present');
    expect(outerMap['d'], isNull);
    expect(record.toJson(), json);
    expect(BoundaryFlags.parse(record.toJson()), record);
    expect(BoundaryFlags.safeParse({...json, 'outer': null}).isFail, isTrue);
    expect(BoundaryFlags.safeParse({...json, 'outerMap': null}).isFail, isTrue);
    expect(BoundaryFlags.safeParse({...json, 'clearedValues': {'c': null}}).isFail, isTrue);
    expect(() => record.copiedValues['a'] = 'changed', throwsUnsupportedError);
  });

  test('preserved boundary aliases clear only their outer nullable type', () {
    final json = <String, Object?>{
      'text': 'present',
      'values': {'a': null},
      'groups': [{'b': null}],
      'byName': {'first': {'c': null}},
    };
    final record = BoundaryAliases.parse(json);
    final String text = record.text;
    final Map<String, String?> values = record.values;
    final List<Map<String, String?>> groups = record.groups;
    final Map<String, Map<String, String?>> byName = record.byName;
    expect(text, 'present');
    expect(values['a'], isNull);
    expect(groups.single['b'], isNull);
    expect(byName['first']!['c'], isNull);
    expect(record.toJson(), json);
    expect(BoundaryAliases.parse(record.toJson()), record);
    expect(BoundaryAliases.safeParse({...json, 'text': null}).isFail, isTrue);
    expect(BoundaryAliases.safeParse({...json, 'values': null}).isFail, isTrue);
    expect(BoundaryAliases.safeParse({...json, 'groups': [null]}).isFail, isTrue);
    expect(BoundaryAliases.safeParse({...json, 'byName': {'first': null}}).isFail, isTrue);
  });

  test('contextual discriminator and capture members retain their wire shape', () {
    final unionJson = <String, Object?>{'required': 'yes', 'answer': 'done'};
    final union = KeywordUnion.parse(unionJson);
    expect(union.required, 'yes');
    expect(union.toJson(), unionJson);

    final capture = KeywordCaptureSchema.parse({'extra': 1});
    expect(capture.required, {'extra': 1});
    expect(capture.toJson(), {'extra': 1});
  });

  test('models expose their model schema as a static shorthand', () {
    final AckSchema<Map<String, Object?>, Node> schema = Node.schema;
    expect(identical(Node.schema, schema), isTrue);
    expect(Node.schema, Node.$ack.modelSchema);
    expect(Node.schema.hashCode, Node.$ack.modelSchema.hashCode);

    final nodes = Ack.list(Node.schema).parse([
      {'label': 'a'},
      {'label': 'b'},
    ])!;
    expect(nodes, [Node(label: 'a'), Node(label: 'b')]);
    expect(Ack.list(Node.schema).encode(nodes), [
      {'label': 'a'},
      {'label': 'b'},
    ]);

    final AckSchema<String, MemberType> member = MemberType.schema;
    expect(member, MemberType.$ack.modelSchema);
    expect(member.parse('admin'), MemberType('admin'));

    expect(Pet.schema, Pet.$ack.modelSchema);
    expect(Pet.schema.parse({'kind': 'cat', 'lives': 9}), isA<Cat>());
    expect(Cat.schema, Cat.$ack.modelSchema);
    expect(Shape.schema.parse({'type': 'circle', 'radius': 1}), isA<Circle>());
    expect(Circle.schema, Circle.$ack.modelSchema);
  });

  test('colliding models keep their members and the adapter schema', () {
    final document = Document.$ack.modelSchema.parse({'schema': 'v1'})!;
    expect(document.schema, 'v1');

    final rule = Shape.schema.parse({'type': 'rule', 'schema': 'v2'});
    expect(rule, isA<Rule>());
    expect((rule as Rule).schema, 'v2');
    expect(Rule.$ack.modelSchema.encode(rule), {'type': 'rule', 'schema': 'v2'});

    final settings = Settings.$ack.modelSchema.parse({'theme': 'dark'})!;
    expect(settings.theme, 'dark');
    // The adapter still reads the top-level `schema` declaration.
    expect(Settings.$ack.schema, same(schema));

    final revision = Revision.$ack.modelSchema.parse({
      'schema': 'draft',
      'body': 'text',
    })!;
    expect(revision, isA<Draft>());
    expect(revision.schema, 'draft');
    expect(Draft.$ack.modelSchema.encode(revision as Draft), {
      'schema': 'draft',
      'body': 'text',
    });
  });

  test('schema-first adapter exposes a model-valued schema', () {
    final schema = Node.$ack.modelSchema;
    final node = schema.parse({'label': 'root'})!;

    expect(node, isA<Node>());
    expect(schema.encode(node), {'label': 'root'});
    expect(schema.safeParse({'label': 42}).isFail, isTrue);
  });

  test('recursion and imported model references round-trip', () {
    final node = Node.parse({
      'label': 'root',
      'children': [
        {'label': 'leaf'},
      ],
    });
    expect(node.children!.single, isA<Node>());
    expect(node.toJson(), {
      'label': 'root',
      'children': [
        {'label': 'leaf'},
      ],
    });
    expect(() => node.children!.add(Node(label: 'other')), throwsUnsupportedError);

    final author = Author.parse({
      'books': [
        {'title': 'Ack'},
      ],
    });
    expect(author.books.single, isA<Book>());
    expect(author.books.single.author, isNull);

    final person = Person.parse({
      'home': {'city': 'New York'},
      'label': null,
      'history': [
        {'city': 'Amsterdam'},
      ],
    });
    expect(person.home.city, 'New York');
    expect(person.history.single.city, 'Amsterdam');
    expect(person.note, isNull);
    expect(person.label, isNull);
    expect(person.toJson()['label'], isNull);
    expect(person.toJson().containsKey('note'), isFalse);
  });

  test('generated list fields use deep equality, hashing, and copyWith', () {
    final left = Node.parse({
      'label': 'root',
      'children': [
        {'label': 'leaf'},
      ],
    });
    final right = Node.parse({
      'label': 'root',
      'children': [
        {'label': 'leaf'},
      ],
    });

    expect(left, right);
    expect(left.hashCode, right.hashCode);
    expect(left.copyWith(), left);
    expect(left.copyWith(label: 'changed'), isNot(left));
  });

  test('field semantics, codecs, and recursive immutability hold', () {
    final extras = Extras.parse({
      'name': 'Ada',
      'maybe': null,
      'nickname': 'Countess',
      'numbers': [
        [1, 2],
      ],
      'box': ['a', 'b'],
      'dynamic': {
        'items': [1, 2],
      },
    });
    expect(extras.role, 'member');
    expect(extras.copyWith().nickname, 'Countess');
    expect(extras.copyWith(nickname: null).nickname, isNull);
    expect(extras.box.values, ['a', 'b']);
    expect(() => extras.numbers.single.add(3), throwsUnsupportedError);
    final dynamic = extras.additionalProperties['dynamic']! as Map;
    expect(() => (dynamic['items']! as List).add(3), throwsUnsupportedError);

    final constructed = Extras(
      name: 'declared',
      maybe: null,
      role: 'member',
      numbers: const [
        [1],
      ],
      box: const Box(['x']),
      additionalProperties: const {
        'name': 'extra',
        'nickname': 'injected',
        'maybe': 'spoofed',
      },
    );
    expect(constructed.additionalProperties, {
      'name': 'extra',
      'nickname': 'injected',
      'maybe': 'spoofed',
    });
    expect(constructed.toJson()['name'], 'declared');
    expect(constructed.toJson().containsKey('nickname'), isFalse);
    expect(constructed.toJson()['maybe'], isNull);
    expect(constructed.toJson().containsKey('maybe'), isTrue);
  });

  final envelopeJson = <String, Object?>{
    'kind': 'event',
    'payload': {
      'nested': [null, 1],
    },
    'items': [
      1,
      {'a': true},
    ],
    'values': {'a': 1},
    'metadata': {'trace': null},
    'labels': {'env': 'prod'},
  };

  for (final invalid in <Map<String, Object?>>[
    {'payload': DateTime(2026)},
    {'kind': null},
    {
      'values': {'a': null},
    },
    {
      'labels': {'env': 1},
    },
  ]) {
    test('Envelope rejects invalid field values: $invalid', () {
      expect(Envelope.safeParse({...envelopeJson, ...invalid}).isFail, isTrue);
    });
  }

  test('Ack.any and Ack.map fields hold immutable JSON values', () {
    final envelope = Envelope.parse(envelopeJson);
    expect(envelope.payload, {
      'nested': [null, 1],
    });
    expect(envelope.metadata, {'trace': null});
    expect(envelope.loose, isNull);
    expect(envelope.toJson(), envelopeJson);
    expect(Envelope.parse(envelopeJson), envelope);
    expect(Envelope.parse(envelopeJson).hashCode, envelope.hashCode);
    expect(
      Envelope.parse({...envelopeJson, 'payload': null}).payload,
      isNull,
    );

    expect(() => (envelope.payload! as Map)['x'] = 1, throwsUnsupportedError);
    expect(() => envelope.metadata['x'] = 1, throwsUnsupportedError);
    expect(() => (envelope.items.last as Map)['x'] = 1, throwsUnsupportedError);

    final constructed = Envelope(
      kind: {
        'a': [1],
      },
      items: const [],
      values: const {},
      metadata: const {},
      labels: const {},
    );
    expect(Envelope.parse(constructed.toJson()), constructed);
    expect(constructed.copyWith(payload: 'x').payload, 'x');
    expect(constructed.copyWith(payload: 'x').copyWith(payload: null).payload,
        isNull);
  });

  test('map values follow nullable variables and nullable collections', () {
    final json = <String, Object?>{
      'byKey': {'a': 'x', 'b': null},
      'groups': {
        'g': ['x'],
        'none': null,
      },
    };

    final labels = Labels.parse(json);

    expect(labels.byKey, {'a': 'x', 'b': null});
    expect(labels.groups['none'], isNull);
    expect(labels.toJson(), json);
  });

  test('aliases and wrapper boundaries preserve field flags', () {
    final json = <String, Object?>{
      'nickname': null,
      'forced': 'present',
      'notNull': 'present',
      'wrapped': null,
      'labels': {'a': 'x'},
    };
    final value = FlagAliases.parse(json);
    expect(value.name, isNull);
    expect(value.nickname, isNull);
    expect(value.role, 'member');
    expect(value.codec, isNull);
    expect(value.wrapped, 'member');
    expect(value.toJson(), {...json, 'role': 'member', 'wrapped': 'member'});
    expect(FlagAliases.parse(value.toJson()), value);
    expect(FlagAliases.safeParse({...json, 'notNull': null}).isFail, isTrue);
    expect(FlagAliases.safeParse({...json, 'labels': {'a': null}}).isFail, isTrue);
    expect(ResetNullable.parse('value').value, 'value');
    expect(ResetNullable.safeParse(null).isFail, isTrue);
  });

  test('strict and passthrough override object policy through aliases', () {
    expect(StrictPolicy.safeParse({'name': 'Ada', 'extra': 1}).isFail, isTrue);
    final open = OpenPolicy.parse({'name': 'Ada', 'extra': 1});
    expect(open.additionalProperties, {'extra': 1});
    expect(open.toJson(), {'name': 'Ada', 'extra': 1});
  });

  test('union discriminators cannot be spoofed through extras', () {
    final dog = Dog(
      friendly: true,
      additionalProperties: const {'kind': 'cat', 'lives': 9},
    );
    expect(dog.additionalProperties['kind'], 'cat');
    expect(dog.toJson(), {'lives': 9, 'kind': 'dog', 'friendly': true});
  });

  test('unions and exact value-root names round-trip', () {
    final pet = Pet.parse({'kind': 'cat', 'lives': 9});
    expect(pet, isA<Cat>());
    expect(pet.toJson(), {'kind': 'cat', 'lives': 9});

    final member = MemberType.parse('admin');
    expect(member.value, 'admin');
    expect(member.toJson(), 'admin');

    final user = UserRecord.parse({'name': 'Ada'});
    expect(user.value.name, 'Ada');
    expect(user.toJson(), {'name': 'Ada'});

    expect(Empty.parse({}).toJson(), isEmpty);
    final scores = Scores.parse([1, 2]);
    expect(scores.value, [1, 2]);
    expect(scores.toJson(), [1, 2]);
    expect(() => scores.value.add(3), throwsUnsupportedError);

    Counted.decodes = 0;
    Counted.encodes = 0;
    final counted = CountedModel.parse({
      'item': 'a',
      'items': ['b', 'c'],
    });
    expect(Counted.decodes, 3);
    expect(counted.item.value, 'a');
    expect(counted.items.map((item) => item.value), ['b', 'c']);
    expect(counted.toJson(), {
      'item': 'a',
      'items': ['b', 'c'],
    });
    expect(Counted.encodes, 3);
    expect(Counted.decodes, 3);
  });
}
''');

        _expectSuccess(
          await _run(temporary, ['pub', 'get', '--offline']),
          'dart pub get --offline',
        );
        _expectSuccess(
          await _run(temporary, ['run', 'build_runner', 'build']),
          'build_runner build',
        );

        final generated = {
          for (final file
              in temporary
                  .listSync(recursive: true)
                  .whereType<File>()
                  .where((file) => file.path.endsWith('.g.dart')))
            p.relative(file.path, from: temporary.path): file
                .readAsStringSync(),
        };
        expect(generated.keys, contains('lib/models.g.dart'));
        expect(
          generated['lib/models.g.dart'],
          contains('static Extras _fromAckRuntime'),
        );
        expect(
          generated['lib/models.g.dart'],
          contains('Map<String, Object?> _toAckRuntime()'),
        );

        _expectSuccess(
          await _run(temporary, ['analyze', '--fatal-infos']),
          'dart analyze --fatal-infos',
        );
        await _expectConsumerSafeParts(temporary, generated);
        await _expectCopyWithRejects(temporary, '''
import 'models.dart';

Extras misuse(Extras extras) => extras.copyWith(nickname: const Object());
''');
        _expectSuccess(await _run(temporary, ['test']), 'dart test');
        _expectSuccess(
          await _run(temporary, ['run', 'build_runner', 'build']),
          'second build_runner build',
        );
        final rebuilt = {
          for (final file
              in temporary
                  .listSync(recursive: true)
                  .whereType<File>()
                  .where((file) => file.path.endsWith('.g.dart')))
            p.relative(file.path, from: temporary.path): file
                .readAsStringSync(),
        };
        expect(rebuilt, generated);
      } finally {
        temporary.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
