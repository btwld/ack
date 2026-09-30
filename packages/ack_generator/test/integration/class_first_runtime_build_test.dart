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
                file.path.endsWith('.g.dart'),
          ))
    p.relative(file.path, from: directory.path): file.readAsStringSync(),
};

/// Asserts modern generated parts suppress consumer lints and coverage, then
/// analyzes them without the lint suppression so the harness rules still
/// guard the generated code itself. Frozen `@AckType()` parts are excluded.
Future<void> _expectConsumerSafeParts(
  Directory project,
  Map<String, String> generated,
) async {
  const lintSuppression = '// ignore_for_file: type=lint\n';
  final modern = {
    for (final MapEntry(key: path, value: source) in generated.entries)
      if (path.endsWith('.ack.dart') || path.endsWith('.ack.g.dart'))
        path: source,
  };
  expect(modern, isNotEmpty);
  for (final MapEntry(key: path, value: source) in modern.entries) {
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
    for (final MapEntry(key: path, value: source) in modern.entries) {
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
    'class-first models compile and preserve the runtime contract',
    () async {
      var projectRoot = Directory.current;
      while (!Directory(
        p.join(projectRoot.path, 'packages', 'ack_generator'),
      ).existsSync()) {
        projectRoot = projectRoot.parent;
      }
      final temporary = await Directory.systemTemp.createTemp(
        'ack_class_first_runtime_',
      );
      try {
        Directory(p.join(temporary.path, 'lib')).createSync();
        Directory(p.join(temporary.path, 'test')).createSync();
        File(p.join(temporary.path, 'pubspec.yaml')).writeAsStringSync('''
name: ack_class_first_runtime
publish_to: none
environment:
  sdk: '>=3.9.0 <4.0.0'
dependencies:
  ack:
    path: ${p.join(projectRoot.path, 'packages', 'ack')}
  ack_annotations:
    path: ${p.join(projectRoot.path, 'packages', 'ack_annotations')}
  json_annotation: ^4.11.0
dev_dependencies:
  ack_generator:
    path: ${p.join(projectRoot.path, 'packages', 'ack_generator')}
  build_runner: ^2.15.0
  json_serializable: ^6.14.1
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
    - avoid_redundant_argument_values
    - prefer_null_aware_operators
''',
        );
        File(p.join(temporary.path, 'build.yaml')).writeAsStringSync('''
targets:
  \$default:
    builders:
      ack_generator:ack_generator:
        generate_for:
          - lib/coexist.dart
      source_gen:combining_builder:
        generate_for:
          - lib/models.dart
''');
        File(p.join(temporary.path, 'lib', 'alpha.dart')).writeAsStringSync(
          'final class Item { const Item(this.value); final String value; }\n',
        );
        File(p.join(temporary.path, 'lib', 'beta.dart')).writeAsStringSync(
          'final class Item { const Item(this.value); final int value; }\n',
        );
        File(p.join(temporary.path, 'lib', 'coexist.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'coexist.g.dart';
part 'coexist.ack.dart';
part 'coexist.ack.g.dart';

// ignore: deprecated_member_use
@AckType()
final frozenSchema = Ack.object({'id': Ack.string()});

@AckInfer()
final modernSchema = Ack.object({'name': Ack.string()});

@AckModel()
final class Handwritten with _$HandwrittenAck {
  const Handwritten({required this.enabled});

  final bool enabled;
}

@AckModel(description: 'A habit entry.')
abstract class HabitDto with _$HabitDtoAck {
  const HabitDto._();

  const factory HabitDto({
    required String name,
    @AckField(description: 'The day the habit was recorded.')
    required DateTime date,
    String? note,
  }) = _HabitDto;
}
''',
        );
        File(p.join(temporary.path, 'lib', 'models.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'package:json_annotation/json_annotation.dart' show JsonSerializable;

import 'alpha.dart' as alpha;
import 'beta.dart' as beta;

part 'models.ack.dart';
part 'models.ack.g.dart';
part 'models.g.dart';

final class Color {
  const Color(this.hex);
  final String hex;

  @override
  bool operator ==(Object other) => other is Color && other.hex == hex;

  @override
  int get hashCode => hex.hashCode;
}

AckSchema<String, Color> colorSchema() => Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.hex,
);

AckSchema<String, alpha.Item> alphaItemSchema() => Ack.string()
    .codec<alpha.Item>(decode: alpha.Item.new, encode: (item) => item.value);

AckSchema<int, beta.Item> betaItemSchema() => Ack.integer()
    .codec<beta.Item>(decode: beta.Item.new, encode: (item) => item.value);

AckSchema<Map<String, Object?>, Map<String, List<String>>> groupsSchema() =>
    Ack.object({}, additionalProperties: true)
        .codec<Map<String, List<String>>>(
          decode: (value) => value.map(
            (key, item) => MapEntry(key, (item! as List).cast<String>()),
          ),
          encode: (value) => value,
        );

@AckModel()
final class Profile with _$ProfileAck {
  const Profile({
    required this.name,
    this.website,
    required this.nickname,
    this.role = 'member',
    required this.tags,
    required this.color,
  });

  final String name;
  final Uri? website;
  final String? nickname;
  final String role;
  @UniqueItems()
  final Set<String> tags;
  @AckField(schema: colorSchema)
  final Color color;

  static final fromJson = ProfileSchema.fromJson;
}

@AckModel(caseStyle: AckCaseStyle.snake)
final class Account with _$AccountAck {
  const Account({required this.firstName, required this.imageUrl});
  final String firstName;
  @JsonKey(name: 'avatar')
  final Uri imageUrl;

  static final fromJson = AccountSchema.fromJson;
}

@AckModel(unknownProperties: AckUnknownPropertyPolicy.capture)
final class Config with _$ConfigAck {
  const Config({
    required this.name,
    this.additionalProperties = const {},
  });
  final String name;
  final Map<String, Object?> additionalProperties;
}

@AckModel(
  caseStyle: AckCaseStyle.snake,
  unknownProperties: AckUnknownPropertyPolicy.capture,
  captureField: 'extraValues',
)
final class CaseStyledExtras with _$CaseStyledExtrasAck {
  const CaseStyledExtras({
    required this.displayName,
    this.extraValues = const {},
  });
  final String displayName;
  final Map<String, Object?> extraValues;
}

@AckModel(unknownProperties: AckUnknownPropertyPolicy.discard)
final class Loose with _$LooseAck {
  const Loose({required this.name});
  final String name;
}

@AckModel()
final class Normalized with _$NormalizedAck {
  const Normalized(String? value) : value = value ?? '';

  @Optional()
  final String value;
}

@AckModel()
final class NullableDefault with _$NullableDefaultAck {
  const NullableDefault({this.label = 'fallback'});

  final String? label;
}

@AckModel()
final class NullDefault with _$NullDefaultAck {
  const NullDefault({this.label = null});

  final String? label;
}

@AckModel()
final class ImportedPair with _$ImportedPairAck {
  const ImportedPair({required this.left, required this.right});
  @AckField(schema: alphaItemSchema)
  final alpha.Item left;
  @AckField(schema: betaItemSchema)
  final beta.Item right;
}

@AckModel()
final class ImmutableCollections with _$ImmutableCollectionsAck {
  const ImmutableCollections({
    required this.matrix,
    required this.labels,
    required this.groups,
  });

  final List<List<String>> matrix;
  @UniqueItems()
  final Set<String> labels;
  @AckField(schema: groupsSchema)
  final Map<String, List<String>> groups;
}

@AckModel()
final class Example with _$ExampleAck {
  const Example({this.label, this.title});

  @Optional()
  @NotNull()
  final String? label;

  @Optional()
  @NotNull()
  @NotEmpty()
  final String? title;

  static final fromJson = ExampleSchema.fromJson;
}

@AckModel()
final class ExampleHolder with _$ExampleHolderAck {
  const ExampleHolder({required this.example});

  final Example example;
}

@AckModel()
final class OptionalNullable with _$OptionalNullableAck {
  const OptionalNullable({this.note});

  @Optional()
  final String? note;
}

@AckModel()
final class InferredNotNull with _$InferredNotNullAck {
  const InferredNotNull({this.label});

  @NotNull()
  final String? label;
}

AckSchema<String, String> nullableNameSchema() => Ack.string().nullable();

@AckModel()
final class OverrideNotNull with _$OverrideNotNullAck {
  const OverrideNotNull({this.name});

  @NotNull()
  @AckField(schema: nullableNameSchema)
  final String? name;
}

@AckModel()
final class RequiredNotNull with _$RequiredNotNullAck {
  const RequiredNotNull({this.value});

  @Required()
  @NotNull()
  final String? value;
}

final class ParameterEntry {
  const ParameterEntry(this.value);
  final String value;
}

AckSchema<Map<String, Object?>, Map<String, ParameterEntry>>
parameterMapSchema() =>
    Ack.object({}, additionalProperties: true).codec<Map<String, ParameterEntry>>(
      decode: (value) => {
        for (final entry in value.entries)
          entry.key: ParameterEntry(entry.value! as String),
      },
      encode: (value) => {
        for (final entry in value.entries) entry.key: entry.value.value,
      },
    );

@AckModel()
final class CapabilityBinding with _$CapabilityBindingAck {
  CapabilityBinding({
    required this.name,
    Map<String, ParameterEntry> parameters = const {},
  }) : parameters = Map.unmodifiable(parameters);

  final String name;

  @Optional()
  @AckField(schema: parameterMapSchema)
  final Map<String, ParameterEntry> parameters;

  static final fromJson = CapabilityBindingSchema.fromJson;
}

AckSchema<Map<String, int?>, Map<String, int?>> scoresSchema() =>
    Ack.map(Ack.integer().min(0));

@AckModel()
final class Envelope with _$EnvelopeAck {
  const Envelope({
    required this.kind,
    this.payload,
    this.strict,
    required this.items,
    required this.values,
    required this.metadata,
    required this.labels,
    required this.scores,
  });

  final Object kind;
  @Optional()
  final Object? payload;
  @Optional()
  @NotNull()
  final Object? strict;
  final List<Object> items;
  final Map<String, Object> values;
  final Map<String, Object?> metadata;
  final Map<String, String> labels;
  @AckField(schema: scoresSchema)
  final Map<String, int> scores;
}

@AckModel()
final class Declined with _$DeclinedAck {
  const Declined();
}

@AckModel()
final class OptionalCollections with _$OptionalCollectionsAck {
  const OptionalCollections({this.headers, this.aliases, this.tags});

  final Map<String, String>? headers;
  final List<String>? aliases;
  final Set<String>? tags;
}

@AckModel(discriminatorKey: 'type')
sealed class Pet with _$PetAck {
  const Pet({required this.id});
  final String id;
}

@AckModel(discriminatorValue: 'cat')
final class Cat extends Pet with _$CatAck {
  const Cat({required super.id, required this.lives});
  final int lives;
}

final class Dog extends Pet with _$DogAck {
  const Dog({required super.id, required this.breed});
  final String breed;
  String get type => 'Dog';
}

@AckModel(discriminatorKey: 'type')
sealed class Animal with _$AnimalAck {
  const Animal({required this.id});
  final String id;
}

final class Rabbit extends Animal with _$RabbitAck {
  const Rabbit({required super.id, required this.lives});
  final int lives;
}

final class BabyRabbit extends Rabbit with _$BabyRabbitAck {
  const BabyRabbit({required super.id, required super.lives, this.note});
  final String? note;
}

@AckModel()
final class Parent with _$ParentAck {
  const Parent({required this.id});
  final String id;
}

@AckModel()
final class Child extends Parent with _$ChildAck {
  const Child({required super.id, this.note});
  final String? note;
}

@AckModel()
final class ImplementingChild with _$ImplementingChildAck implements Parent {
  const ImplementingChild({required this.id, this.note});
  final String id;
  final String? note;
}

/// A task the person can complete.
/// @description This tag has lower priority.
@AckModel(description: 'A task the person can complete.')
final class Task with _$TaskAck {
  const Task({required this.id, required this.title});

  final String id;

  /// What to do.
  /// @description What to do.
  final String title;
}

/**
 * A board that groups
 * related tasks.
 * @description A board that groups related tasks.
 */
@AckModel()
final class Board with _$BoardAck {
  const Board({required this.focus, required this.backlog, this.pinned});

  /// The task to do next.
  /// @description This tag has lower priority.
  @AckField(description: 'The task to do next.')
  final Task focus;
  final List<Task> backlog;
  final Task? pinned;
}

@AckModel()
final class Undocumented with _$UndocumentedAck {
  const Undocumented({required this.value});

  /// Ordinary field prose does not become schema data.
  final String value;
}

/// A shape to draw.
/// @description A shape to draw.
@AckModel(discriminatorKey: 'kind')
sealed class Shape with _$ShapeAck {
  const Shape();
}

/// A circle, sized by its radius.
@AckModel(
  discriminatorValue: 'circle',
  description: 'A circle, sized by its radius.',
)
final class Circle extends Shape with _$CircleAck {
  const Circle({required this.radius});

  final double radius;
}

final class Square extends Shape with _$SquareAck {
  const Square({required this.side});

  final double side;
}

@AckInfer()
final legacySchema = Ack.object({'enabled': Ack.boolean()});

@JsonSerializable()
final class PlainJson {
  const PlainJson({required this.value});
  factory PlainJson.fromJson(Map<String, dynamic> json) =>
      _$PlainJsonFromJson(json);
  final String value;
  Map<String, dynamic> toJson() => _$PlainJsonToJson(this);
}
''',
        );
        File(
          p.join(temporary.path, 'test', 'runtime_test.dart'),
        ).writeAsStringSync(r'''
import 'dart:convert';

import 'package:ack_class_first_runtime/alpha.dart' as alpha;
import 'package:ack_class_first_runtime/beta.dart' as beta;
import 'package:ack_class_first_runtime/coexist.dart';
import 'package:ack_class_first_runtime/models.dart';
import 'package:ack/ack.dart';
import 'package:test/test.dart';

final envelopeJson = <String, Object?>{
  'kind': 'event',
  'items': [
    1,
    'two',
    {
      'three': [null, 3],
    },
  ],
  'values': {
    'a': 1,
    'b': [true],
  },
  'metadata': {
    'trace': null,
    'nested': {
      'x': [null, 1],
    },
  },
  'labels': {'env': 'prod'},
  'scores': {'a': 1},
};

void main() {
  test('redirecting factory models generate a private implementation', () {
    final habit = HabitDtoSchema.parse({
      'name': 'Read',
      'date': '2026-09-30T00:00:00.000Z',
    });
    expect(habit, isA<HabitDto>());
    expect(habit.name, 'Read');
    expect(habit.date, DateTime.parse('2026-09-30T00:00:00.000Z'));
    expect(habit.toJson(), {
      'name': 'Read',
      'date': '2026-09-30T00:00:00.000Z',
    });
    expect(habit.copyWith(name: 'Write').name, 'Write');
    expect(habit.copyWith(note: null).note, isNull);
    expect(HabitDtoSchema.toJsonSchema()['description'], 'A habit entry.');
  });

  test('presence, defaults, collections, and escape hatches round-trip', () {
    final profile = Profile.fromJson({
      'name': 'Ada',
      'website': null,
      'nickname': null,
      'tags': ['schema', 'dart'],
      'color': '#fff',
    });
    expect(profile.website, isNull);
    expect(profile.nickname, isNull);
    expect(profile.role, 'member');
    expect(profile.tags, {'schema', 'dart'});
    expect(profile.color.hex, '#fff');
    expect(profile.toJson(), {
      'name': 'Ada',
      'nickname': null,
      'role': 'member',
      'tags': ['schema', 'dart'],
      'color': '#fff',
    });
    expect(
      () => ProfileSchema.parse({'name': 'Ada'}),
      throwsA(isA<AckException>()),
    );
    expect(ProfileSchema.safeParse({'name': 'Ada'}).isFail, isTrue);
    expect(ProfileSchema.toJsonSchema()['x-transformed'], isTrue);
    expect(
      ProfileSchema.toSchemaModel().toJsonSchema(),
      ProfileSchema.toJsonSchema(),
    );
    expect(ProfileSchema.encode(profile), profile.toJson());
    expect(ProfileSchema.safeEncode(profile).isOk, isTrue);
  });

  test('case style and JsonKey use one wire-key mapping', () {
    final account = Account.fromJson({
      'first_name': 'Ada',
      'avatar': 'https://example.com/avatar.png',
    });
    expect(account.firstName, 'Ada');
    expect(account.imageUrl.host, 'example.com');
    expect(account.toJson(), {
      'first_name': 'Ada',
      'avatar': 'https://example.com/avatar.png',
    });
  });

  test('additional properties decode and encode extras first', () {
    final config = ConfigSchema.parse({
      'name': 'declared',
      'theme': 'dark',
      'nested': {
        'items': [1, 2],
      },
    });
    expect(config.additionalProperties, {
      'theme': 'dark',
      'nested': {
        'items': [1, 2],
      },
    });
    expect(
      () => config.additionalProperties['new'] = true,
      throwsUnsupportedError,
    );
    final nested = config.additionalProperties['nested']! as Map;
    expect(() => nested['new'] = true, throwsUnsupportedError);
    final items = nested['items']! as List;
    expect(() => items.add(3), throwsUnsupportedError);
    final spoofed = Config(
      name: 'declared',
      additionalProperties: const {'name': 'spoofed', 'theme': 'dark'},
    );
    expect(spoofed.toJson(), {'theme': 'dark', 'name': 'declared'});
  });

  test('parsed class-first collections are recursively unmodifiable', () {
    final model = ImmutableCollectionsSchema.parse({
      'matrix': [
        ['a'],
      ],
      'labels': ['a'],
      'groups': {
        'primary': ['a'],
      },
    });

    expect(() => model.matrix.add(const []), throwsUnsupportedError);
    expect(() => model.matrix.single.add('b'), throwsUnsupportedError);
    expect(() => model.labels.add('b'), throwsUnsupportedError);
    expect(
      () => model.groups['secondary'] = const ['b'],
      throwsUnsupportedError,
    );
    expect(() => model.groups['primary']!.add('b'), throwsUnsupportedError);
  });

  test('custom capture fields honor the configured case style', () {
    final model = CaseStyledExtrasSchema.parse({
      'display_name': 'Ada',
      'theme': 'dark',
    });
    expect(model.extraValues, {'theme': 'dark'});
    expect(model.toJson(), {'theme': 'dark', 'display_name': 'Ada'});
  });

  test('discard accepts extras without storing them', () {
    final loose = LooseSchema.parse({'name': 'n', 'extra': true});
    expect(loose.toJson(), {'name': 'n'});
    expect(
      () => ProfileSchema.parse({
        'name': 'Ada',
        'nickname': null,
        'tags': ['schema'],
        'color': '#fff',
        'extra': true,
      }),
      throwsA(isA<AckException>()),
    );
  });

  test('optional wire fields feed nullable normalization parameters', () {
    expect(NormalizedSchema.parse({}).value, '');
    expect(NormalizedSchema.parse({'value': 'set'}).value, 'set');
  });

  test('nullable constructor defaults apply to missing and null values', () {
    expect(NullableDefaultSchema.parse({}).label, 'fallback');
    expect(NullableDefaultSchema.parse({'label': null}).label, 'fallback');
    expect(NullableDefaultSchema.parse({'label': 'set'}).label, 'set');

    final explicitNull = NullableDefault(label: null);
    expect(explicitNull.toJson(), {'label': null});
    expect(NullableDefault().copyWith().label, 'fallback');
    expect(NullableDefault().copyWith(label: null).label, isNull);

    final nullDefault = NullDefault();
    expect(NullDefaultSchema.parse({}), nullDefault);
    expect(NullDefaultSchema.parse({'label': null}), nullDefault);
    expect(nullDefault.toJson(), {'label': null});
    expect(NullDefaultSchema.parse(nullDefault.toJson()), nullDefault);
  });

  test('copyWith distinguishes omitted values from explicit null', () {
    final profile = Profile.fromJson({
      'name': 'Ada',
      'nickname': 'Countess',
      'tags': ['schema', 'dart'],
      'color': '#fff',
    });
    final renamed = profile.copyWith(name: 'Grace');
    expect(renamed.name, 'Grace');
    expect(renamed.nickname, 'Countess');
    expect(profile.copyWith(nickname: null).nickname, isNull);
    expect(renamed.role, 'member');
    expect(renamed.tags, {'schema', 'dart'});
    expect(profile.copyWith(), profile);
    expect(profile.hashCode, profile.copyWith().hashCode);
    expect(
      Profile.fromJson({
        'name': 'Ada',
        'nickname': 'Countess',
        'tags': ['schema', 'dart'],
        'color': '#fff',
      }),
      profile,
    );
  });

  test('copyWith remains compatible across model inheritance', () {
    final Parent child = Child(id: 'one', note: 'saved');
    final updated = child.copyWith(id: 'two');
    expect(updated, isA<Child>());
    expect(updated.id, 'two');
    expect((updated as Child).note, 'saved');
    expect((child as Child).copyWith(note: null).note, isNull);

    final Parent implementing = ImplementingChild(id: 'one', note: 'saved');
    final implementedCopy = implementing.copyWith(id: 'two');
    expect(implementedCopy, isA<ImplementingChild>());
    expect((implementedCopy as ImplementingChild).note, 'saved');
  });

  test('copyWith remains compatible with implicit union branch inheritance', () {
    final Rabbit rabbit = BabyRabbit(id: 'one', lives: 3, note: 'saved');
    expect(AnimalSchema.encode(rabbit), {
      'type': 'BabyRabbit',
      'id': 'one',
      'lives': 3,
      'note': 'saved',
    });
    final copy = rabbit.copyWith(id: 'two');
    expect(copy, isA<BabyRabbit>());
    expect(copy.id, 'two');
    expect((copy as BabyRabbit).note, 'saved');
    expect(copy.copyWith(note: null).note, isNull);
  });

  test('optional not-null fields omit keys and reject explicit null', () {
    expect(ExampleSchema.parse({}).label, isNull);
    expect(ExampleSchema.parse({'label': 'hello'}).label, 'hello');
    expect(ExampleSchema.safeParse({'label': null}).isFail, isTrue);
    expect(
      () => ExampleSchema.parse({'label': null}),
      throwsA(isA<AckException>()),
    );
    expect(Example.fromJson({}).label, isNull);
    expect(Example.fromJson({'label': 'hello'}).label, 'hello');
    expect(Example().toJson(), {});
    expect(Example(label: 'hello').toJson(), {'label': 'hello'});
    expect(ExampleSchema.encode(Example()), {});
    expect(ExampleSchema.safeEncode(Example()).isOk, isTrue);
    expect(
      ExampleSchema.encode(Example(label: 'hello')),
      {'label': 'hello'},
    );
    expect(Example(label: 'hello').copyWith(label: null).toJson(), {});

    final jsonSchema = ExampleSchema.toJsonSchema();
    expect(jsonSchema['required'] ?? const <Object?>[], isNot(contains('label')));
    expect(
      (jsonSchema['properties'] as Map)['label'],
      isNot(containsPair('type', ['string', 'null'])),
    );
    expect(
      ((jsonSchema['properties'] as Map)['label'] as Map)['type'],
      'string',
    );
    expect(
      ExampleSchema.toSchemaModel().toJsonSchema(),
      ExampleSchema.toJsonSchema(),
    );

    expect(ExampleHolderSchema.parse({'example': {}}).example.label, isNull);
    expect(
      ExampleHolderSchema.safeParse({
        'example': {'label': null},
      }).isFail,
      isTrue,
    );
    expect(ExampleHolderSchema.parse({'example': {}}).toJson(), {
      'example': {},
    });
    expect(
      ExampleHolderSchema.toSchemaModel().toJsonSchema(),
      ExampleHolderSchema.toJsonSchema(),
    );
  });

  test('optional nullable fields still accept explicit JSON null', () {
    expect(OptionalNullableSchema.parse({}).note, isNull);
    expect(OptionalNullableSchema.parse({'note': null}).note, isNull);
    expect(OptionalNullableSchema.parse({'note': 'n'}).note, 'n');
  });

  test('NotNull alone on an inferred optional String? rejects JSON null', () {
    expect(InferredNotNullSchema.parse({}).label, isNull);
    expect(InferredNotNullSchema.parse({'label': 'hello'}).label, 'hello');
    expect(InferredNotNullSchema.safeParse({'label': null}).isFail, isTrue);
    expect(InferredNotNull().toJson(), {});
  });

  test('NotNull wins over a nullable AckField schema override', () {
    expect(OverrideNotNullSchema.parse({}).name, isNull);
    expect(OverrideNotNullSchema.parse({'name': 'ada'}).name, 'ada');
    expect(OverrideNotNullSchema.safeParse({'name': null}).isFail, isTrue);
    expect(OverrideNotNull().toJson(), {});
  });

  test('Required plus NotNull rejects JSON null and does not emit it', () {
    expect(RequiredNotNullSchema.safeParse({}).isFail, isTrue);
    expect(RequiredNotNullSchema.parse({'value': 'ok'}).value, 'ok');
    expect(RequiredNotNullSchema.safeParse({'value': null}).isFail, isTrue);
    expect(RequiredNotNullSchema.safeEncode(RequiredNotNull()).isFail, isTrue);
    expect(
      RequiredNotNullSchema.encode(const RequiredNotNull(value: 'ok')),
      {'value': 'ok'},
    );
  });

  test('NotEmpty still rejects an empty supplied optional not-null value', () {
    expect(ExampleSchema.safeParse({'title': ''}).isFail, isTrue);
    expect(ExampleSchema.parse({'title': 'ok'}).title, 'ok');
    expect(ExampleSchema.parse({}).title, isNull);
    expect(ExampleSchema.safeParse({'title': null}).isFail, isTrue);
  });

  test('optional non-nullable map codecs default and copy without null', () {
    expect(CapabilityBindingSchema.parse({'name': 'bind'}).parameters, isEmpty);
    expect(
      CapabilityBindingSchema.parse({
        'name': 'bind',
        'parameters': {'a': 'v'},
      }).parameters['a']!.value,
      'v',
    );
    expect(
      CapabilityBindingSchema.safeParse({
        'name': 'bind',
        'parameters': null,
      }).isFail,
      isTrue,
    );

    final binding = CapabilityBinding(name: 'bind');
    expect(binding.copyWith().parameters, isEmpty);
    expect(
      binding.copyWith(
        parameters: {'a': const ParameterEntry('v')},
      ).parameters['a']!.value,
      'v',
    );
    expect(binding.copyWith().toJson(), {'name': 'bind', 'parameters': {}});
  });

  test('Object fields accept JSON values with String? presence rules', () {
    final envelope = EnvelopeSchema.parse(envelopeJson);
    expect(envelope.kind, 'event');
    expect(envelope.payload, isNull);
    expect(envelope.items, [
      1,
      'two',
      {
        'three': [null, 3],
      },
    ]);
    expect(envelope.metadata['trace'], isNull);
    expect(envelope.toJson(), envelopeJson);

    expect(
      EnvelopeSchema.parse({...envelopeJson, 'payload': null}).payload,
      isNull,
    );
    final withPayload = EnvelopeSchema.parse({
      ...envelopeJson,
      'payload': {
        'nested': [null, 1],
      },
    });
    expect(withPayload.payload, {
      'nested': [null, 1],
    });
    expect(withPayload.toJson()['payload'], {
      'nested': [null, 1],
    });

    expect(EnvelopeSchema.parse({...envelopeJson, 'strict': 1}).strict, 1);
    expect(
      EnvelopeSchema.safeParse({...envelopeJson, 'strict': null}).isFail,
      isTrue,
    );
    expect(
      EnvelopeSchema.safeParse({...envelopeJson, 'kind': null}).isFail,
      isTrue,
    );
    expect(
      EnvelopeSchema.safeParse(
        Map<String, Object?>.of(envelopeJson)..remove('kind'),
      ).isFail,
      isTrue,
    );
  });

  for (final invalid in <Map<String, Object?>>[
    {'payload': DateTime(2026)},
    {
      'items': [DateTime(2026)],
    },
    {
      'values': {'a': null},
    },
    {
      'metadata': {
        'nested': {'at': DateTime(2026)},
      },
    },
    {
      'labels': {'env': 1},
    },
    {
      'scores': {'a': -1},
    },
  ]) {
    test('Envelope rejects invalid field values: $invalid', () {
      expect(
        EnvelopeSchema.safeParse({...envelopeJson, ...invalid}).isFail,
        isTrue,
      );
    });
  }

  test('Object fields reject non-JSON encodes and maps export schemas', () {
    final envelope = EnvelopeSchema.parse(envelopeJson);
    expect(
      EnvelopeSchema.safeEncode(
        envelope.copyWith(payload: DateTime(2026)),
      ).isFail,
      isTrue,
    );
    expect(
      (EnvelopeSchema.toJsonSchema()['properties']! as Map)['labels'],
      {
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      },
    );
  });

  test('parsed Object and map values are recursively unmodifiable', () {
    final envelope = EnvelopeSchema.parse({
      ...envelopeJson,
      'payload': {
        'nested': [1],
      },
    });
    final payload = envelope.payload! as Map;
    expect(() => payload['x'] = 1, throwsUnsupportedError);
    expect(() => (payload['nested']! as List).add(2), throwsUnsupportedError);
    expect(() => (envelope.items.last as Map)['x'] = 1, throwsUnsupportedError);
    expect(() => envelope.metadata['x'] = 1, throwsUnsupportedError);
    expect(
      () => (envelope.metadata['nested']! as Map)['x'] = 1,
      throwsUnsupportedError,
    );
    expect(() => envelope.scores['b'] = 2, throwsUnsupportedError);
  });

  test('fieldless models generate working value members', () {
    expect(DeclinedSchema.parse({}), const Declined());
    expect(const Declined().copyWith(), const Declined());
    expect(const Declined().hashCode, const Declined().hashCode);
    expect(const Declined().toString(), 'Declined()');
    expect(const Declined().toJson(), isEmpty);
  });

  test('optional collections round-trip through null-aware bridges', () {
    final empty = OptionalCollectionsSchema.parse({});
    expect(empty.headers, isNull);
    expect(empty.toJson(), isEmpty);

    final full = OptionalCollectionsSchema.parse({
      'headers': {'a': 'b'},
      'aliases': ['x'],
      'tags': ['t'],
    });
    expect(full.headers, {'a': 'b'});
    expect(full.tags, {'t'});
    expect(full.toJson(), {
      'headers': {'a': 'b'},
      'aliases': ['x'],
      'tags': ['t'],
    });
  });

  test('sealed unions use super parameters and discriminator rules', () {
    final cat = PetSchema.parse({'type': 'cat', 'id': 'c1', 'lives': 9});
    expect(cat, isA<Cat>());
    expect(cat.toJson(), {'type': 'cat', 'id': 'c1', 'lives': 9});
    final dog = PetSchema.parse({'type': 'Dog', 'id': 'd1', 'breed': 'lab'});
    expect(dog, isA<Dog>());
    expect(dog.toJson(), {'type': 'Dog', 'id': 'd1', 'breed': 'lab'});
    expect((cat as Cat).copyWith(lives: 8).id, 'c1');
    final direct = CatSchema.parse({'id': 'c2', 'lives': 7});
    expect(direct.toJson(), {'type': 'cat', 'id': 'c2', 'lives': 7});
    expect(PetSchema.safeParse({'id': 'c2', 'lives': 7}).isFail, isTrue);
  });

  test('explicit descriptions and tags describe class-first object schemas', () {
    const task = 'A task the person can complete.';
    expect(TaskSchema.toJsonSchema()['description'], task);
    expect(TaskSchema.schema.description, task);
    expect(TaskSchema.wireSchema.description, task);
    expect(TaskSchema.toSchemaModel().toJsonSchema()['description'], task);
    final taskProperties =
        TaskSchema.toJsonSchema()['properties'] as Map<String, Object?>;
    expect(
      (taskProperties['title'] as Map<String, Object?>)['description'],
      'What to do.',
    );
    expect(
      (taskProperties['id'] as Map<String, Object?>)['description'],
      isNull,
    );

    expect(
      BoardSchema.schema.description,
      'A board that groups related tasks.',
    );
    final board = BoardSchema.toJsonSchema();
    final boardProperties = board['properties'] as Map<String, Object?>;
    expect(
      (boardProperties['focus'] as Map<String, Object?>)['description'],
      'The task to do next.',
    );
    expect(
      ((boardProperties['backlog'] as Map<String, Object?>)['items']
          as Map<String, Object?>)['description'],
      task,
    );
    expect(jsonEncode(boardProperties['pinned']), contains(task));

    expect(UndocumentedSchema.toJsonSchema().containsKey('description'), isFalse);
    expect(UndocumentedSchema.schema.description, isNull);
    expect(UndocumentedSchema.wireSchema.description, isNull);
  });

  test('union base and branch descriptions describe their schemas', () {
    expect(ShapeSchema.schema.description, 'A shape to draw.');
    expect(ShapeSchema.toJsonSchema()['description'], 'A shape to draw.');
    expect(CircleSchema.schema.description, 'A circle, sized by its radius.');
    expect(SquareSchema.schema.description, isNull);
    final branches = (ShapeSchema.toJsonSchema()['anyOf'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(branches.map((branch) => branch['description']), [
      'A circle, sized by its radius.',
      null,
    ]);
    expect(
      ShapeSchema.parse({'kind': 'circle', 'radius': 2}),
      const Circle(radius: 2),
    );
  });

  test('prefixed same-named imported types preserve identity', () {
    final pair = ImportedPairSchema.parse({'left': 'a', 'right': 2});
    expect(pair.left, isA<alpha.Item>());
    expect(pair.right, isA<beta.Item>());
    expect(pair.toJson(), {'left': 'a', 'right': 2});
  });

  test('class-first, schema-first, and plain JSON coexist', () {
    expect(Legacy.parse({'enabled': true}).enabled, isTrue);
    final plain = PlainJson.fromJson({'value': 'plain'});
    expect(plain.toJson(), {'value': 'plain'});
  });

  test('all three Ack model generators coexist in one build-runner library', () {
    expect(FrozenType.parse({'id': 'frozen'}).id, 'frozen');
    expect(Modern.parse({'name': 'modern'}).name, 'modern');
    expect(HandwrittenSchema.parse({'enabled': true}).enabled, isTrue);
  });
}
''');

        _expectSuccess(await _run(temporary, ['pub', 'get']), 'dart pub get');
        _expectSuccess(
          await _run(temporary, ['run', 'build_runner', 'build']),
          'build_runner build',
        );
        final generated = _generatedFiles(temporary);
        expect(
          generated.keys,
          containsAll([
            'lib/coexist.g.dart',
            'lib/coexist.ack.dart',
            'lib/coexist.ack.g.dart',
            'lib/models.ack.dart',
            'lib/models.ack.g.dart',
            'lib/models.g.dart',
          ]),
        );
        expect(
          generated['lib/models.ack.g.dart'],
          contains('_ackProfileFromRuntimeName'),
        );
        expect(
          generated['lib/models.g.dart'],
          contains(r'_$PlainJsonFromJson'),
        );
        expect(generated['lib/models.ack.dart'], contains('class Legacy'));
        expect(
          generated['lib/models.ack.dart'],
          contains(r'mixin _$ProfileAck'),
        );
        expect(
          generated['lib/models.ack.dart'],
          contains(r'implements $ParentCopyWith<$Result>'),
        );
        expect(
          generated['lib/models.ack.dart'],
          contains(r'implements $RabbitCopyWith<$Result>'),
        );
        expect(
          generated['lib/models.ack.dart'],
          contains('abstract final class ProfileSchema'),
        );
        expect(
          generated['lib/models.ack.dart'],
          contains('final _profileSchema'),
        );
        expect(
          generated['lib/coexist.g.dart'],
          contains('extension type FrozenType'),
        );
        expect(generated['lib/coexist.ack.dart'], contains('class Modern'));
        expect(
          generated['lib/coexist.ack.dart'],
          contains(r'mixin _$HandwrittenAck'),
        );
        expect(
          generated['lib/models.ack.dart'],
          isNot(contains('final profileSchema =')),
        );
        expect(
          generated['lib/models.ack.dart'],
          contains('parameters: parameters ?? _source.parameters'),
        );
        expect(
          generated['lib/models.ack.dart'],
          isNot(contains('parameters as Map<String, ParameterEntry>?')),
        );

        _expectSuccess(
          await _run(temporary, ['analyze', '--fatal-infos']),
          'dart analyze --fatal-infos',
        );
        await _expectConsumerSafeParts(temporary, generated);
        await _expectCopyWithRejects(temporary, '''
import 'models.dart';

Profile misuse(Profile profile) => profile.copyWith(nickname: const Object());
''');
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
