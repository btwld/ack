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

void main() {
  test(
    'type-owned schemas build, analyze, and round-trip',
    () async {
      var projectRoot = Directory.current;
      while (!Directory(
        p.join(projectRoot.path, 'packages', 'ack_generator'),
      ).existsSync()) {
        projectRoot = projectRoot.parent;
      }
      final temporary = await Directory.systemTemp.createTemp(
        'ack_type_owned_',
      );
      try {
        Directory(p.join(temporary.path, 'lib')).createSync();
        Directory(p.join(temporary.path, 'test')).createSync();
        File(p.join(temporary.path, 'pubspec.yaml')).writeAsStringSync('''
name: ack_type_owned
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
        File(p.join(temporary.path, 'lib', 'types.dart')).writeAsStringSync(r'''
import 'package:ack/ack.dart';

final class Slot {
  const Slot(this.id);

  final String id;

  static final schema = Ack.string().codec<Slot>(
    decode: Slot.new,
    encode: (slot) => slot.id,
  );

  @override
  bool operator ==(Object other) => other is Slot && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

extension type const WidgetId(String value) implements Object {
  static final schema = Ack.string().codec<WidgetId>(
    decode: WidgetId.new,
    encode: (id) => id.value,
  );
}

enum CompletionAction { complete, skip }

final class Box<A extends Object> {
  const Box(this.value);

  final A value;

  static AckSchema<Object, Box<A>> schema<A extends Object>(
    AckSchema<Object, A> value,
  ) => value.codec<Box<A>>(decode: Box<A>.new, encode: (box) => box.value);
}

final class Trigger<A> {
  const Trigger(this.name);

  final String name;

  static AckSchema<String, Trigger<A>> schema<A>() =>
      Ack.string().codec<Trigger<A>>(
        decode: Trigger<A>.new,
        encode: (trigger) => trigger.name,
      );
}

final class Command<A extends Object> {
  const Command(this.name);

  final String name;

  static AckSchema<String, Command<A>> schema<A extends Object>() =>
      Ack.string().codec<Command<A>>(
        decode: Command<A>.new,
        encode: (command) => command.name,
      );
}
''');
        File(p.join(temporary.path, 'lib', 'models.dart')).writeAsStringSync(
          r'''
import 'package:ack/ack.dart';

import 'types.dart';

part 'models.g.dart';

@Schemable()
final class Habit with _$HabitAck {
  const Habit({required this.name});

  final String name;

  static final schema = HabitSchema.schema;
}

@Schemable()
final class Section with _$SectionAck {
  const Section({
    required this.header,
    this.footer,
    required this.children,
    required this.widgets,
    required this.byName,
    required this.open,
    required this.habits,
  });

  final Slot header;
  final Slot? footer;
  final List<Slot> children;
  final Set<WidgetId> widgets;
  final Map<String, Slot> byName;
  final Command<CompletionAction> open;
  final List<Habit> habits;
}

@Schemable()
final class Toolbar with _$ToolbarAck {
  const Toolbar({
    required this.openAll,
    required this.anything,
    required this.complete,
  });

  final Trigger<void> openAll;
  final Trigger<Object?> anything;
  final Trigger<CompletionAction> complete;
}

@Schemable()
final class Shelf with _$ShelfAck {
  const Shelf({
    required this.habit,
    required this.title,
    required this.habits,
    required this.boxes,
    required this.nested,
  });

  final Box<Habit> habit;
  final Box<String> title;
  final Box<List<Habit>> habits;
  final List<Box<Habit>> boxes;
  final Box<Box<int>> nested;
}

@Schemable()
final panelSchema = Ack.object({
  'header': Slot.schema,
  'commands': Ack.list(Command.schema<CompletionAction>()),
  'habit': Habit.schema.optional(),
});
''',
        );
        File(
          p.join(temporary.path, 'test', 'type_owned_test.dart'),
        ).writeAsStringSync(r'''
import 'package:ack_type_owned/models.dart';
import 'package:ack_type_owned/types.dart';
import 'package:test/test.dart';

void main() {
  test('class-first fields decode through their types', () {
    final json = {
      'header': 'top',
      'children': ['a', 'b'],
      'widgets': ['w1'],
      'byName': {'x': 'slot-x'},
      'open': 'open-menu',
      'habits': [
        {'name': 'read'},
      ],
    };

    final section = SectionSchema.parse(json);

    expect(section.header, const Slot('top'));
    expect(section.footer, isNull);
    expect(section.children, const [Slot('a'), Slot('b')]);
    expect(section.widgets, {const WidgetId('w1')});
    expect(section.byName['x'], const Slot('slot-x'));
    expect(section.open, isA<Command<CompletionAction>>());
    expect(section.open.name, 'open-menu');
    expect(section.habits.single.name, 'read');
    expect(section.toJson(), json);
  });

  test('a model exposes its facade as a static schema', () {
    expect(Habit.schema.parse({'name': 'walk'}), const Habit(name: 'walk'));
  });

  test('void and Object? type arguments reach the type-owned schema', () {
    final toolbar = ToolbarSchema.parse({
      'openAll': 'open',
      'anything': 'any',
      'complete': 'done',
    });

    expect(toolbar.openAll, isA<Trigger<void>>());
    expect(toolbar.anything, isA<Trigger<Object?>>());
    expect(toolbar.complete, isA<Trigger<CompletionAction>>());
    expect(toolbar.toJson(), {
      'openAll': 'open',
      'anything': 'any',
      'complete': 'done',
    });
  });

  test('generic schemas receive the schemas of their type arguments', () {
    final json = {
      'habit': {'name': 'read'},
      'title': 'Today',
      'habits': [
        {'name': 'walk'},
      ],
      'boxes': [
        {'name': 'run'},
      ],
      'nested': 3,
    };

    final shelf = ShelfSchema.parse(json);

    expect(shelf.habit.value, const Habit(name: 'read'));
    expect(shelf.title.value, 'Today');
    expect(shelf.habits.value.single.name, 'walk');
    expect(shelf.boxes.single.value.name, 'run');
    expect(shelf.nested.value.value, 3);
    expect(shelf.toJson(), json);
    expect(
      ShelfSchema.safeParse({...json, 'habit': {'name': 1}}).isOk,
      isFalse,
    );
  });

  test('schema-first models type fields from type-owned schemas', () {
    final panel = Panel.parse({
      'header': 'h',
      'commands': ['go'],
      'habit': {'name': 'run'},
    });

    expect(panel.header, const Slot('h'));
    expect(panel.commands.single, isA<Command<CompletionAction>>());
    expect(panel.habit, const Habit(name: 'run'));
  });
}
''');

        _expectSuccess(await _run(temporary, ['pub', 'get']), 'dart pub get');
        _expectSuccess(
          await _run(temporary, ['run', 'build_runner', 'build']),
          'build_runner build',
        );
        final generated = File(
          p.join(temporary.path, 'lib', 'models.g.dart'),
        ).readAsStringSync();
        expect(generated, contains('Command.schema<CompletionAction>()'));
        expect(generated, contains('Trigger.schema<void>()'));
        expect(generated, contains('Box.schema<Habit>(HabitSchema.schema)'));
        expect(generated, contains('Ack.map(Slot.schema)'));
        _expectSuccess(
          await _run(temporary, ['analyze', '--fatal-infos']),
          'dart analyze --fatal-infos',
        );
        _expectSuccess(await _run(temporary, ['test']), 'dart test');
      } finally {
        temporary.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
