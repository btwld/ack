// Modern schema-first runtime integration tests.
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

void main() {
  test(
    'clean generated models compile and preserve the AckInfer runtime contract',
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
  ack_annotations:
    path: ${p.join(projectRoot.path, 'packages', 'ack_annotations')}
dev_dependencies:
  ack_generator:
    path: ${p.join(projectRoot.path, 'packages', 'ack_generator')}
  build_runner: ^2.15.0
  test: ^1.29.0
dependency_overrides:
  ack:
    path: ${p.join(projectRoot.path, 'packages', 'ack')}
  ack_annotations:
    path: ${p.join(projectRoot.path, 'packages', 'ack_annotations')}
''');
        File(p.join(temporary.path, 'analysis_options.yaml')).writeAsStringSync(
          '''
linter:
  rules:
    - prefer_null_aware_operators
''',
        );
        File(p.join(temporary.path, 'lib', 'models.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'models.ack.dart';
part 'models.ack.g.dart';

final class Box {
  const Box(this.values);
  final List<String> values;
}

final class RuntimeUser {
  const RuntimeUser(this.name);
  final String name;
}

@AckInfer(name: 'UserRecord')
final userRecordSchema = Ack.object({
  'name': Ack.string(),
}).codec<RuntimeUser>(
  decode: (value) => RuntimeUser(value['name'] as String),
  encode: (user) => {'name': user.name},
);

@AckInfer()
final AckSchema<JsonMap, JsonMap> nodeSchema = Ack.object({
  'label': Ack.string(),
  'children': Ack.list(
    Ack.lazy('node', () => nodeSchema),
  ).optional(),
});

@AckInfer()
final AckSchema<JsonMap, JsonMap> authorSchema = Ack.object({
  'books': Ack.list(Ack.lazy('book', () => bookSchema)),
});

@AckInfer()
final AckSchema<JsonMap, JsonMap> bookSchema = Ack.object({
  'title': Ack.string(),
  'author': Ack.lazy('author', () => authorSchema).optional(),
});

const allowExtras = true;

@AckInfer()
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

@AckInfer()
final catSchema = Ack.object({'lives': Ack.integer()});

@AckInfer()
final dogSchema = Ack.object({'friendly': Ack.boolean()}).passthrough();

@AckInfer()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {'cat': catSchema, 'dog': dogSchema},
);

@AckInfer(name: 'MemberType')
final memberSchema = Ack.string();

@AckInfer()
final emptySchema = Ack.object({});

@AckInfer()
final scoresSchema = Ack.list(Ack.integer());

final looseAny = Ack.any();

@AckInfer()
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

@AckInfer()
final labelsSchema = Ack.object({
  'byKey': Ack.map(nullableLabel),
  'groups': Ack.map(Ack.list(Ack.string()).nullable()),
});

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

@AckInfer(name: 'CountedModel')
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
import 'package:ack_annotations/ack_annotations.dart';

part 'address.ack.dart';
part 'address.ack.g.dart';

@AckInfer()
final addressSchema = Ack.object({'city': Ack.string()});
''',
        );
        File(
          p.join(temporary.path, 'lib', 'exports.dart'),
        ).writeAsStringSync("export 'address.dart';\n");
        File(p.join(temporary.path, 'lib', 'person.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

import 'address.dart' as direct;
import 'exports.dart' as exported;

part 'person.ack.dart';
part 'person.ack.g.dart';

@AckInfer()
final personSchema = Ack.object({
  'home': direct.addressSchema,
  'history': Ack.list(exported.addressSchema),
});
''',
        );
        File(
          p.join(temporary.path, 'test', 'runtime_test.dart'),
        ).writeAsStringSync(r'''
import 'package:ack_ack_infer_runtime/models.dart';
import 'package:ack_ack_infer_runtime/person.dart';
import 'package:test/test.dart';

void main() {
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
      'history': [
        {'city': 'Amsterdam'},
      ],
    });
    expect(person.home.city, 'New York');
    expect(person.history.single.city, 'Amsterdam');
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
    expect(
      () => extras.copyWith(nickname: const Object()),
      throwsA(isA<TypeError>()),
    );
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

        _expectSuccess(await _run(temporary, ['pub', 'get']), 'dart pub get');
        _expectSuccess(
          await _run(temporary, ['run', 'build_runner', 'build']),
          'build_runner build',
        );

        final generated = {
          for (final file
              in temporary
                  .listSync(recursive: true)
                  .whereType<File>()
                  .where(
                    (file) =>
                        file.path.endsWith('.ack.dart') ||
                        file.path.endsWith('.ack.g.dart'),
                  ))
            p.relative(file.path, from: temporary.path): file
                .readAsStringSync(),
        };
        expect(
          generated.keys,
          containsAll(['lib/models.ack.dart', 'lib/models.ack.g.dart']),
        );
        expect(
          generated['lib/models.ack.g.dart'],
          contains(r'_$ExtrasFromJson'),
        );
        expect(
          generated['lib/models.ack.g.dart'],
          contains('Extras._ackFromRuntimeName'),
        );
        expect(generated['lib/models.ack.dart'], contains(r'_$ExtrasFromJson'));

        _expectSuccess(
          await _run(temporary, ['analyze', '--fatal-infos']),
          'dart analyze --fatal-infos',
        );
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
                  .where(
                    (file) =>
                        file.path.endsWith('.ack.dart') ||
                        file.path.endsWith('.ack.g.dart'),
                  ))
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
