import 'package:test/test.dart';

import 'schema_resolution_support.dart';

void main() {
  test('automatically detects a unique top-level schema variable, getter, or function in the library', () async {
    await expectOutput(
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
final class Theme {
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
        containsCode("'primary': colorSchema,"),
        containsCode("'secondary': colorSchema.optional().nullable(),"),
        containsCode("'palette': Ack.list(colorSchema),"),
        containsCode("'swatches': Ack.list(colorSchema).codec<Set<Color>>("),
        containsCode("'namedColors': Ack.map(colorSchema),"),
        containsCode("'maybeColor': colorSchema.optional().nullable(),"),
        containsCode("'boxedColor': Box.schema<Color>(colorSchema),"),
        containsCode("'price': centsSchema,"),
        containsCode("'slug': slugSchema()"),
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
  });

  test(
    'rejects ambiguous auto-detected top-level schemas for the same type',
    () async {
      final errors = await generationErrors(
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
        errors,
        contains(
          contains(
            'Theme.primary has multiple top-level schemas for Color in this '
            'library (hexColorSchema, namedColorSchema). Disambiguate with '
            '@Schemable(schemas: [...]).',
          ),
        ),
      );
    },
  );

  test(
    'rejects an auto-detected top-level schema that uses a one-way transform',
    () async {
      final errors = await generationErrors(
        r'''
final colorSchema = Ack.string().transform<Color>(Color.new);

@Schemable()
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
}
