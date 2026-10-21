import 'package:test/test.dart';

import 'schema_resolution_support.dart';

void main() {
  test('@Schemable(schemas: [...]) on a class resolves imported schemas, disambiguates local schemas, and overrides DateTime', () async {
    await expectOutput(
      r'''
AckSchema<String, Color> hexColorSchema() => Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.hex,
);

AckSchema<String, Color> altColorSchema() => Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.hex,
);

AckSchema<Object, Object> cellValueSchema() =>
    Ack.anyOf([Ack.string().maxLength(2048), Ack.number(), Ack.boolean()]);

@Schemable(
  schemas: [
    hexColorSchema,
    importedMoneySchema,
    epochDateTimeSchema,
    cellValueSchema,
  ],
)
final class Order {
  const Order({
    required this.color,
    required this.total,
    required this.createdAt,
    required this.timestamps,
    required this.cellValue,
    this.anyJson,
  });

  final Color color;
  final Money total;
  final DateTime createdAt;
  final List<DateTime> timestamps;
  final Object cellValue;
  final Object? anyJson;
}
''',
      allOf(
        containsCode("'color': hexColorSchema(),"),
        containsCode("'total': importedMoneySchema(),"),
        containsCode("'createdAt': epochDateTimeSchema(),"),
        containsCode("'timestamps': Ack.list(epochDateTimeSchema()),"),
        containsCode("'cellValue': cellValueSchema(),"),
        containsCode("'anyJson': Ack.any().optional().nullable()"),
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
  });

  test('@Schemable(schemas: [...]) on a library directive applies across models and imported schema libraries', () async {
    await expectOutput(
      r'''
@Schemable()
final class Palette {
  const Palette({required this.primary, required this.budget});

  final Color primary;
  final Money budget;
}
''',
      allOf(
        containsCode("'primary': libraryColorSchema(),"),
        containsCode("'budget': sharedMoneySchema()"),
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
  });

  test('rejects core primitive types and duplicate runtime types in @Schemable(schemas: [...])', () async {
    final coreErrors = await generationErrors(r'''
AckSchema<String, String> customStringSchema() => Ack.string();

@Schemable(schemas: [customStringSchema])
final class Post {
  const Post({required this.title});

  final String title;
}
''');

    expect(
      coreErrors,
      contains(
        contains(
          'Post @Schemable(schemas: ...) cannot override core type String.',
        ),
      ),
    );

    final duplicateErrors = await generationErrors(
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
final class Theme {
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
  });
}
