import 'package:ack_generator/src/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

const _head = '''
import 'package:ack/ack.dart';
import 'types.dart';

part 'model.g.dart';
''';

const _types = r'''
import 'package:ack/ack.dart';

final class Slot {
  const Slot(this.id);
  final String id;

  static final schema = Ack.string().codec<Slot>(
    decode: Slot.new,
    encode: (slot) => slot.id,
  );
}

final class Token {
  const Token(this.value);
  final String value;

  static AckSchema<String, Token> get schema => Ack.string().codec<Token>(
    decode: Token.new,
    encode: (token) => token.value,
  );
}

extension type const WidgetId(String value) implements Object {
  static final schema = Ack.string().codec<WidgetId>(
    decode: WidgetId.new,
    encode: (id) => id.value,
  );
}

enum CompletionAction { complete, skip }

final class Invoke<A extends Object> {
  const Invoke(this.action);
  final A action;

  static AckSchema<String, Invoke<A>> schema<A extends Object>(
    List<A> actions,
  ) => throw UnimplementedError();
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

final class Box<A extends Object> {
  const Box(this.value);
  final A value;

  static AckSchema<Object, Box<A>> schema<A extends Object>(
    AckSchema<Object, A> value,
  ) => value.codec<Box<A>>(decode: Box<A>.new, encode: (box) => box.value);
}

final class Pair<A extends Object, B extends Object> {
  const Pair(this.first, this.second);
  final A first;
  final B second;

  static AckSchema<Object, Pair<A, B>> schema<A extends Object, B extends Object>(
    AckSchema<Object, A> first,
  ) => throw UnimplementedError();
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
''';

/// Compares generated code without formatter whitespace or trailing commas.
Matcher _containsCode(String code) => predicate<String>(
  (output) => _compact(output).contains(_compact(code)),
  'contains code `$code`',
);

String _compact(String code) =>
    code.replaceAll(RegExp(r'\s+'), '').replaceAll(',)', ')');

Future<void> _expectOutput(
  String body,
  Matcher matcher, {
  String head = _head,
  String types = _types,
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {
      'test_pkg|lib/model.dart': '$head\n$body',
      'test_pkg|lib/types.dart': types,
    },
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
    outputs: {'test_pkg|lib/model.g.dart': decodedMatches(matcher)},
  );
}

Future<List<String>> _errors(
  String body, {
  String head = _head,
  String types = _types,
}) async {
  final readerWriter = TestReaderWriter(rootPackage: 'test_pkg');
  await readerWriter.testing.loadIsolateSources();
  final errors = <String>[];
  await testBuilder(
    ackModelBuilder(BuilderOptions.empty),
    {
      'test_pkg|lib/model.dart': '$head\n$body',
      'test_pkg|lib/types.dart': types,
    },
    generateFor: const {'test_pkg|lib/model.dart'},
    readerWriter: readerWriter,
    outputs: const {},
    onLog: (LogRecord log) {
      if (log.level == Level.SEVERE) errors.add(log.message);
    },
  );
  return errors;
}

void main() {
  test('a field resolves to the static schema of its type', () async {
    await _expectOutput(
      r'''
@Schemable()
final class Section with _$SectionAck {
  const Section({
    required this.header,
    this.footer,
    required this.token,
    required this.widget,
  });

  final Slot header;
  final Slot? footer;
  final Token token;
  final WidgetId widget;
}
''',
      allOf(
        _containsCode("'header': Slot.schema,"),
        _containsCode("'footer': Slot.schema.optional().nullable(),"),
        _containsCode("'token': Token.schema,"),
        _containsCode("'widget': WidgetId.schema,"),
      ),
    );
  });

  test('a type-owned schema resolves per collection item', () async {
    await _expectOutput(
      r'''
@Schemable()
final class Section with _$SectionAck {
  const Section({
    required this.children,
    required this.unique,
    required this.byName,
  });

  final List<Slot> children;
  final Set<WidgetId> unique;
  final Map<String, Slot> byName;
}
''',
      allOf(
        _containsCode("'children': Ack.list(Slot.schema),"),
        _containsCode(
          "'unique': Ack.list(WidgetId.schema).codec<Set<WidgetId>>(",
        ),
        _containsCode("'byName': Ack.map(Slot.schema),"),
      ),
    );
  });

  test(
    'a generic type resolves through a static generic schema method',
    () async {
      await _expectOutput(
        r'''
@Schemable()
final class Menu with _$MenuAck {
  const Menu({required this.open, required this.history});

  final Command<CompletionAction> open;
  final List<Command<CompletionAction>> history;
}
''',
        allOf(
          _containsCode("'open': Command.schema<CompletionAction>(),"),
          _containsCode(
            "'history': Ack.list(Command.schema<CompletionAction>()),",
          ),
        ),
      );
    },
  );

  test('void, Object? and Null pass through as type arguments', () async {
    await _expectOutput(
      r'''
@Schemable()
final class Panel with _$PanelAck {
  const Panel({
    required this.openAll,
    required this.anything,
    required this.nothing,
    required this.complete,
  });

  final Trigger<void> openAll;
  final Trigger<Object?> anything;
  final Trigger<Null> nothing;
  final Trigger<CompletionAction> complete;
}
''',
      allOf(
        _containsCode("'openAll': Trigger.schema<void>(),"),
        _containsCode("'anything': Trigger.schema<Object?>(),"),
        _containsCode("'nothing': Trigger.schema<Null>(),"),
        _containsCode("'complete': Trigger.schema<CompletionAction>()"),
        contains('Trigger<void>? openAll'),
      ),
    );
  });

  test('a prefixed type keeps its prefix', () async {
    await _expectOutput(
      r'''
@Schemable()
final class Section with _$SectionAck {
  const Section({required this.header});

  final types.Slot header;
}
''',
      _containsCode("Ack.object({'header': types.Slot.schema})"),
      head: '''
import 'package:ack/ack.dart';
import 'types.dart' as types;

part 'model.g.dart';
''',
    );
  });

  test('a static schema with another runtime type is rejected', () async {
    final errors = await _errors(
      r'''
@Schemable()
final class Section with _$SectionAck {
  const Section({required this.header});

  final Label header;
}
''',
      types: '''
import 'package:ack/ack.dart';

final class Label {
  const Label(this.text);
  final String text;

  static final schema = Ack.string();
}
''',
    );

    expect(
      errors,
      contains(
        contains(
          'Section.header resolves to Label.schema, which produces String, '
          'but the field type is Label.',
        ),
      ),
    );
  });

  test('a generic type with a static schema field is rejected', () async {
    final errors = await _errors(
      r'''
@Schemable()
final class Section with _$SectionAck {
  const Section({required this.box});

  final Box<String> box;
}
''',
      types: '''
import 'package:ack/ack.dart';

final class Box<T extends Object> {
  const Box(this.value);
  final T value;

  static final schema = Ack.any().codec<Box<Object>>(
    decode: Box.new,
    encode: (box) => box.value,
  );
}
''',
    );

    expect(
      errors,
      contains(
        contains(
          'Section.box resolves to Box.schema, which produces Box<Object>, '
          'but the field type is Box<String>. A generic type declares '
          'static AckSchema<..., Box<T>> schema<T>() instead.',
        ),
      ),
    );
  });

  test('a generic schema method receives the type argument schemas', () async {
    await _expectOutput(
      r'''
@Schemable()
final class Row with _$RowAck {
  const Row({required this.name});

  final String name;
}

@Schemable()
final class Screen with _$ScreenAck {
  const Screen({
    required this.row,
    required this.title,
    required this.rows,
    required this.boxes,
    required this.nested,
  });

  final Box<Row> row;
  final Box<String> title;
  final Box<List<Row>> rows;
  final List<Box<Row>> boxes;
  final Box<Box<String>> nested;
}
''',
      allOf(
        _containsCode("'row': Box.schema<Row>(RowSchema.schema),"),
        _containsCode("'title': Box.schema<String>(Ack.string()),"),
        _containsCode(
          "'rows': Box.schema<List<Row>>(Ack.list(RowSchema.schema)),",
        ),
        _containsCode("'boxes': Ack.list(Box.schema<Row>(RowSchema.schema)),"),
        _containsCode(
          "'nested': Box.schema<Box<String>>(Box.schema<String>(Ack.string()))",
        ),
      ),
    );
  });

  test('a schema method with too few schema parameters is rejected', () async {
    final errors = await _errors(r'''
@Schemable()
final class Section with _$SectionAck {
  const Section({required this.pair});

  final Pair<String, int> pair;
}
''');

    expect(
      errors,
      contains(
        contains(
          'Section.pair resolves to Pair.schema, which must take no parameters '
          'or one positional AckSchema parameter per type parameter; it takes '
          '1 for 2 type parameters.',
        ),
      ),
    );
  });

  test('a wrongly typed schema parameter is rejected', () async {
    final errors = await _errors(r'''
@Schemable()
final class Section with _$SectionAck {
  const Section({required this.run});

  final Invoke<CompletionAction> run;
}
''');

    expect(
      errors,
      contains(
        contains(
          'Section.run resolves to Invoke.schema, whose parameter actions must '
          'be an AckSchema of CompletionAction; it is List<CompletionAction>.',
        ),
      ),
    );
  });

  test('a type argument without a schema is reported by name', () async {
    final errors = await _errors(
      r'''
@Schemable()
final class Section with _$SectionAck {
  const Section({required this.color});

  final Box<Color> color;
}
''',
      types: '''
import 'package:ack/ack.dart';

final class Color {
  const Color(this.value);
  final int value;
}

final class Box<A extends Object> {
  const Box(this.value);
  final A value;

  static AckSchema<Object, Box<A>> schema<A extends Object>(
    AckSchema<Object, A> value,
  ) => value.codec<Box<A>>(decode: Box<A>.new, encode: (box) => box.value);
}
''',
    );

    expect(errors, contains(contains('Section.color uses unsupported Color.')));
  });

  test('a type without a schema explains how to provide one', () async {
    final errors = await _errors(
      r'''
@Schemable()
final class Section with _$SectionAck {
  const Section({required this.color});

  final Color color;
}
''',
      types: '''
final class Color {
  const Color(this.value);
  final int value;
}
''',
    );

    expect(
      errors,
      contains(
        contains(
          'Section.color uses unsupported Color. Declare a static schema on '
          'Color, or set @AckField(schema: ...) on the field.',
        ),
      ),
    );
  });

  test(
    'a Schemable class may expose its backing schema or facade as a static schema',
    () async {
      await _expectOutput(
        r'''
@Schemable()
final class Habit with _$HabitAck {
  const Habit({required this.name});

  final String name;

  static final schema = _habitSchema;
}

@Schemable()
final class Routine with _$RoutineAck {
  const Routine({required this.habits});

  final List<Habit> habits;
}
''',
        allOf(
          _containsCode("Ack.object({'habits': Ack.list(HabitSchema.schema)})"),
          isNot(contains('Habit.schema')),
        ),
      );
    },
  );

  test('a Schemable class rejects a static schema of another type', () async {
    final errors = await _errors(r'''
@Schemable()
final class Habit with _$HabitAck {
  const Habit({required this.name});

  final String name;

  static final schema = Ack.string();
}
''');

    expect(
      errors,
      contains(
        contains(
          'Habit.schema must be an AckSchema<Map<String, Object?>, Habit>; '
          'it produces String.',
        ),
      ),
    );
  });

  test('a schema-first model references a type-owned schema', () async {
    await _expectOutput(
      '''
@Schemable()
final class Habit with _\$HabitAck {
  const Habit({required this.name});

  final String name;

  static final schema = _habitSchema;
}

@Schemable()
final sectionSchema = Ack.object({
  'header': Slot.schema,
  'children': Ack.list(Slot.schema),
  'open': Command.schema<CompletionAction>().optional(),
  'openAll': Trigger.schema<void>(),
  'habit': Habit.schema,
  'title': Box.schema<String>(Ack.string()),
});
''',
      allOf(
        contains('final Slot header;'),
        contains('final List<Slot> children;'),
        contains('final Command<CompletionAction>? open;'),
        contains('final Trigger<void> openAll;'),
        contains('final Habit habit;'),
        contains('final Box<String> title;'),
      ),
    );
  });

  test('a generic type-owned schema enforces type parameter bounds', () async {
    final errors = await _errors(
      r'''
@Schemable()
final class Section with _$SectionAck {
  const Section({required this.metric});

  final Metric<Object?> metric;
}
''',
      types: '''
import 'package:ack/ack.dart';

final class Metric<A> {
  const Metric(this.value);
  final A value;

  static AckSchema<Object, Metric<A>> schema<A extends num>() =>
      throw UnimplementedError();
}
''',
    );

    expect(
      errors,
      contains(
        contains(
          'Section.metric resolves to Metric.schema, whose type parameter A '
          'requires a subtype of num; received Object?.',
        ),
      ),
    );
  });

  test(
    'a generic type-owned schema enforces parameter boundary types',
    () async {
      final errors = await _errors(
        r'''
@Schemable()
final class Section with _$SectionAck {
  const Section({required this.record});

  final RecordBox<int> record;
}
''',
        types: '''
import 'package:ack/ack.dart';

final class RecordBox<A extends Object> {
  const RecordBox(this.value);
  final A value;

  static AckSchema<Map<String, Object?>, RecordBox<A>> schema<A extends Object>(
    AckSchema<Map<String, Object?>, A> value,
  ) => throw UnimplementedError();
}
''',
      );

      expect(
        errors,
        contains(
          contains(
            'Section.record resolves to RecordBox.schema, whose parameter value '
            'expects boundary type Map<String, Object?>, but the schema '
            'inferred for int has boundary type num.',
          ),
        ),
      );
    },
  );

  test('an enum with a static schema resolves to it', () async {
    await _expectOutput(
      r'''
@Schemable()
final class Task with _$TaskAck {
  const Task({required this.status, required this.plain});

  final Status status;
  final Plain plain;
}
''',
      allOf(
        _containsCode("'status': Status.schema,"),
        _containsCode("'plain': Ack.enumValues(Plain.values)"),
      ),
      types: '''
import 'package:ack/ack.dart';

enum Status {
  active('A'),
  paused('P');

  const Status(this.wire);
  final String wire;

  static final schema = Ack.string().codec<Status>(
    decode: (wire) => values.firstWhere((status) => status.wire == wire),
    encode: (status) => status.wire,
  );
}

enum Plain { one, two }
''',
    );
  });

  test('a static schema whose type does not resolve asks for a type', () async {
    final errors = await _errors(
      r'''
@Schemable()
final class Section with _$SectionAck {
  const Section({required this.routine});

  final Routine routine;
}
''',
      types: '''
final class Routine {
  const Routine();

  static final schema = RoutineSchema.schema;
}
''',
    );

    expect(
      errors,
      contains(
        contains(
          'Section.routine resolves to Routine.schema, whose type does not '
          'resolve yet. Declare the type of Routine.schema explicitly.',
        ),
      ),
    );
  });

  test(
    'automatically detects a unique top-level schema variable, getter, or function in the library',
    () async {
      await _expectOutput(
        r'''
final colorSchema = Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.hex,
);

AckSchema<int, Cents> get centsSchema => Ack.integer().codec<Cents>(
  decode: Cents.new,
  encode: (cents) => cents.amount,
);

AckSchema<String, Slug> slugSchema() => Ack.string().codec<Slug>(
  decode: Slug.new,
  encode: (slug) => slug.value,
);

@Schemable()
final class Theme with _$ThemeAck {
  const Theme({
    required this.primary,
    this.secondary,
    required this.palette,
    required this.swatches,
    required this.namedColors,
    this.maybeColor = const JsonMaybe.absent(),
    required this.boxedColor,
    required this.price,
    required this.slug,
  });

  final Color primary;
  final Color? secondary;
  final List<Color> palette;
  final Set<Color> swatches;
  final Map<String, Color> namedColors;
  final JsonMaybe<Color> maybeColor;
  final Box<Color> boxedColor;
  final Cents price;
  final Slug slug;
}
''',
        allOf([
          _containsCode("'primary': colorSchema,"),
          _containsCode("'secondary': colorSchema.optional().nullable(),"),
          _containsCode("'palette': Ack.list(colorSchema),"),
          _containsCode("'swatches': Ack.list(colorSchema).codec<Set<Color>>("),
          _containsCode("'namedColors': Ack.map(colorSchema),"),
          _containsCode("'maybeColor': colorSchema.optional().nullable(),"),
          _containsCode("'boxedColor': Box.schema<Color>(colorSchema),"),
          _containsCode("'price': centsSchema,"),
          _containsCode("'slug': slugSchema()"),
        ]),
        types: '''
import 'package:ack/ack.dart';

final class Color {
  const Color(this.hex);
  final String hex;
}

final class Cents {
  const Cents(this.amount);
  final int amount;
}

final class Slug {
  const Slug(this.value);
  final String value;
}

final class Box<A extends Object> {
  const Box(this.value);
  final A value;

  static AckSchema<Object, Box<A>> schema<A extends Object>(
    AckSchema<Object, A> value,
  ) => value.codec<Box<A>>(decode: Box<A>.new, encode: (box) => box.value);
}
''',
      );
    },
  );

  test(
    'rejects ambiguous auto-detected top-level schemas for the same type',
    () async {
      final errors = await _errors(
        r'''
final hexColorSchema = Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.hex,
);

final namedColorSchema = Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.hex,
);

@Schemable()
final class Theme with _$ThemeAck {
  const Theme({required this.primary});

  final Color primary;
}
''',
        types: '''
final class Color {
  const Color(this.hex);
  final String hex;
}
''',
      );

      expect(
        errors,
        contains(
          contains(
            'Theme.primary has multiple top-level schemas for Color in this '
            'library (hexColorSchema, namedColorSchema). Disambiguate with '
            '@Schemable(schemas: [...]) or @AckField(schema: ...).',
          ),
        ),
      );
    },
  );

  test(
    'rejects an auto-detected top-level schema that uses a one-way transform',
    () async {
      final errors = await _errors(
        r'''
final colorSchema = Ack.string().transform<Color>(Color.new);

@Schemable()
final class Theme with _$ThemeAck {
  const Theme({required this.primary});

  final Color primary;
}
''',
        types: '''
final class Color {
  const Color(this.hex);
  final String hex;
}
''',
      );

      expect(
        errors,
        contains(
          contains(
            'Theme.primary resolves to top-level schema colorSchema, which '
            'reaches one-way schema transform.',
          ),
        ),
      );
    },
  );

  test(
    '@Schemable(schemas: [...]) on a class resolves imported schemas, disambiguates local schemas, and overrides DateTime',
    () async {
      await _expectOutput(
        r'''
AckSchema<String, Color> hexColorSchema() => Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.hex,
);

AckSchema<String, Color> altColorSchema() => Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.hex,
);

@Schemable(schemas: [hexColorSchema, importedMoneySchema, epochDateTimeSchema])
final class Order with _$OrderAck {
  const Order({
    required this.color,
    required this.total,
    required this.createdAt,
    required this.timestamps,
  });

  final Color color;
  final Money total;
  final DateTime createdAt;
  final List<DateTime> timestamps;
}
''',
        allOf(
          _containsCode("'color': hexColorSchema(),"),
          _containsCode("'total': importedMoneySchema(),"),
          _containsCode("'createdAt': epochDateTimeSchema(),"),
          _containsCode("'timestamps': Ack.list(epochDateTimeSchema())"),
        ),
        types: '''
import 'package:ack/ack.dart';

final class Color {
  const Color(this.hex);
  final String hex;
}

final class Money {
  const Money(this.cents);
  final int cents;
}

AckSchema<int, Money> importedMoneySchema() => Ack.integer().codec<Money>(
  decode: Money.new,
  encode: (money) => money.cents,
);

AckSchema<int, DateTime> epochDateTimeSchema() => Ack.integer().codec<DateTime>(
  decode: DateTime.fromMillisecondsSinceEpoch,
  encode: (dt) => dt.millisecondsSinceEpoch,
);
''',
      );
    },
  );

  test(
    '@Schemable(schemas: [...]) on a library directive applies across models and imported schema libraries',
    () async {
      await _expectOutput(
        r'''
@Schemable()
final class Palette with _$PaletteAck {
  const Palette({required this.primary, required this.budget});

  final Color primary;
  final Money budget;
}
''',
        allOf(
          _containsCode("'primary': libraryColorSchema(),"),
          _containsCode("'budget': sharedMoneySchema()"),
        ),
        head: '''
@Schemable(schemas: [libraryColorSchema])
library;

import 'package:ack/ack.dart';
import 'types.dart';

part 'model.g.dart';

AckSchema<String, Color> libraryColorSchema() => Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.hex,
);
''',
        types: '''
@Schemable(schemas: [sharedMoneySchema])
library;

import 'package:ack/ack.dart';

final class Color {
  const Color(this.hex);
  final String hex;
}

final class Money {
  const Money(this.cents);
  final int cents;
}

AckSchema<int, Money> sharedMoneySchema() => Ack.integer().codec<Money>(
  decode: Money.new,
  encode: (money) => money.cents,
);
''',
      );
    },
  );

  test(
    'rejects core primitive types and duplicate runtime types in @Schemable(schemas: [...])',
    () async {
      final coreErrors = await _errors(r'''
AckSchema<String, String> customStringSchema() => Ack.string();

@Schemable(schemas: [customStringSchema])
final class Post with _$PostAck {
  const Post({required this.title});

  final String title;
}
''');

      expect(
        coreErrors,
        contains(
          contains(
            'Post @Schemable(schemas: ...) cannot override core type String; '
            'use @AckField(schema: customStringSchema) on the specific field '
            'instead.',
          ),
        ),
      );

      final duplicateErrors = await _errors(
        r'''
AckSchema<String, Color> firstColorSchema() => Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.hex,
);

AckSchema<String, Color> secondColorSchema() => Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.hex,
);

@Schemable(schemas: [firstColorSchema, secondColorSchema])
final class Theme with _$ThemeAck {
  const Theme({required this.primary});

  final Color primary;
}
''',
        types: '''
final class Color {
  const Color(this.hex);
  final String hex;
}
''',
      );

      expect(
        duplicateErrors,
        contains(
          contains(
            'Theme @Schemable(schemas: ...) registers multiple schemas for '
            'Color: firstColorSchema and secondColorSchema.',
          ),
        ),
      );
    },
  );
}
