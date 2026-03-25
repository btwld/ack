import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

Future<void> _expectGenerationFailure({
  required Builder builder,
  required Map<String, String> assets,
  required String expectedMessage,
  Map<String, Object>? expectedOutputs,
}) async {
  var sawExpectedError = false;
  await testBuilder(
    builder,
    assets,
    outputs: expectedOutputs ?? {},
    onLog: (log) {
      if (log.level.name == 'SEVERE' && log.message.contains(expectedMessage)) {
        sawExpectedError = true;
      }
    },
  );
  expect(
    sawExpectedError,
    isTrue,
    reason: 'Expected SEVERE log containing "$expectedMessage"',
  );
}

void main() {
  group('@AckType cross-file schema references', () {
    test(
      'resolves typed nested getters across files (direct import)',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/deck_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final slideSchema = Ack.object({
  'id': Ack.string(),
  'title': Ack.string(),
});
''',
            'test_pkg|lib/deck_tools_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'deck_schemas.dart';

@AckType()
final deckToolArgsSchema = Ack.object({
  'currentSlide': slideSchema,
  'slides': Ack.list(slideSchema),
});
''',
          },
          outputs: {
            'test_pkg|lib/deck_schemas.g.dart': decodedMatches(
              contains('extension type SlideType(Map<String, Object?> _data)'),
            ),
            'test_pkg|lib/deck_tools_schemas.g.dart': decodedMatches(
              allOf([
                contains(
                  'extension type DeckToolArgsType(Map<String, Object?> _data)',
                ),
                contains('SlideType get currentSlide'),
                contains(
                  "SlideType(_data['currentSlide'] as Map<String, Object?>)",
                ),
                contains('List<SlideType> get slides'),
                contains('SlideType(e as Map<String, Object?>)'),
              ]),
            ),
          },
        );
      },
    );

    test('resolves typed nested getters for prefixed schema imports', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/deck_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final slideSchema = Ack.object({
  'id': Ack.string(),
});
''',
          'test_pkg|lib/deck_tools_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'deck_schemas.dart' as deck;

@AckType()
final deckToolArgsSchema = Ack.object({
  'currentSlide': deck.slideSchema,
  'slides': Ack.list(deck.slideSchema),
});
''',
        },
        outputs: {
          'test_pkg|lib/deck_schemas.g.dart': decodedMatches(
            contains('extension type SlideType(Map<String, Object?> _data)'),
          ),
          'test_pkg|lib/deck_tools_schemas.g.dart': decodedMatches(
            allOf([
              contains('deck.SlideType get currentSlide'),
              contains('List<deck.SlideType> get slides'),
            ]),
          ),
        },
      );
    });

    test('resolves typed nested getters through re-exported schemas', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/deck_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final slideSchema = Ack.object({
  'id': Ack.string(),
});
''',
          'test_pkg|lib/deck_schema_exports.dart': '''
export 'deck_schemas.dart';
''',
          'test_pkg|lib/deck_tools_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'deck_schema_exports.dart';

@AckType()
final deckToolArgsSchema = Ack.object({
  'currentSlide': slideSchema,
  'slides': Ack.list(slideSchema),
});
''',
        },
        outputs: {
          'test_pkg|lib/deck_schemas.g.dart': decodedMatches(
            contains('extension type SlideType(Map<String, Object?> _data)'),
          ),
          'test_pkg|lib/deck_tools_schemas.g.dart': decodedMatches(
            allOf([
              contains('SlideType get currentSlide'),
              contains('List<SlideType> get slides'),
            ]),
          ),
        },
      );
    });

    test(
      'resolves transformed schema refs across files and suppresses copyWith',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/palette_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Color {
  final String value;
  const Color(this.value);
}

@AckType()
final colorSchema = Ack.string().transform<Color>((value) => Color(value));
''',
            'test_pkg|lib/theme_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'palette_schemas.dart';

@AckType()
final themeSchema = Ack.object({
  'accent': colorSchema,
  'colors': Ack.list(colorSchema),
});
''',
          },
          outputs: {
            'test_pkg|lib/palette_schemas.g.dart': decodedMatches(
              contains('extension type ColorType(Color _value)'),
            ),
            'test_pkg|lib/theme_schemas.g.dart': decodedMatches(
              allOf([
                contains(
                  'extension type ThemeType(Map<String, Object?> _data)',
                ),
                contains('ColorType get accent'),
                contains("ColorType(_data['accent'] as Color)"),
                contains('List<ColorType> get colors'),
                contains('ColorType(e as Color)'),
                isNot(contains('copyWith(')),
              ]),
            ),
          },
        );
      },
    );

    test(
      'resolves transformed schema refs through re-exported schemas and suppresses copyWith',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/palette_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Color {
  final String value;
  const Color(this.value);
}

@AckType()
final colorSchema = Ack.string().transform<Color>((value) => Color(value));
''',
            'test_pkg|lib/palette_schema_exports.dart': '''
export 'palette_schemas.dart';
''',
            'test_pkg|lib/theme_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'palette_schema_exports.dart';

@AckType()
final themeSchema = Ack.object({
  'accent': colorSchema,
  'colors': Ack.list(colorSchema),
});
''',
          },
          outputs: {
            'test_pkg|lib/palette_schemas.g.dart': decodedMatches(
              contains('extension type ColorType(Color _value)'),
            ),
            'test_pkg|lib/theme_schemas.g.dart': decodedMatches(
              allOf([
                contains(
                  'extension type ThemeType(Map<String, Object?> _data)',
                ),
                contains('ColorType get accent'),
                contains("ColorType(_data['accent'] as Color)"),
                contains('List<ColorType> get colors'),
                contains('ColorType(e as Color)'),
                isNot(contains('copyWith(')),
              ]),
            ),
          },
        );
      },
    );

    test(
      'resolves prefixed transformed schema refs across files and suppresses copyWith',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/palette_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Color {
  final String value;
  const Color(this.value);
}

@AckType()
final colorSchema = Ack.string().transform<Color>((value) => Color(value));
''',
            'test_pkg|lib/theme_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'palette_schemas.dart' as palette;

@AckType()
final themeSchema = Ack.object({
  'accent': palette.colorSchema,
  'colors': Ack.list(palette.colorSchema),
});
''',
          },
          outputs: {
            'test_pkg|lib/palette_schemas.g.dart': decodedMatches(
              contains('extension type ColorType(Color _value)'),
            ),
            'test_pkg|lib/theme_schemas.g.dart': decodedMatches(
              allOf([
                contains('palette.ColorType get accent'),
                contains("palette.ColorType(_data['accent'] as palette.Color)"),
                contains('List<palette.ColorType> get colors'),
                contains('palette.ColorType(e as palette.Color)'),
                isNot(contains('copyWith(')),
              ]),
            ),
          },
        );
      },
    );

    test(
      'resolves prefixed transformed refs without @AckType using visible representation types',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/palette_schemas.dart': '''
import 'package:ack/ack.dart';

class Color {
  final String value;
  const Color(this.value);
}

final colorSchema = Ack.string().transform<Color>((value) => Color(value));
''',
            'test_pkg|lib/theme_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'palette_schemas.dart' as palette;

@AckType()
final themeSchema = Ack.object({
  'accent': palette.colorSchema,
  'colors': Ack.list(palette.colorSchema),
});
''',
          },
          outputs: {
            'test_pkg|lib/theme_schemas.g.dart': decodedMatches(
              allOf([
                contains('palette.Color get accent'),
                contains("_data['accent'] as palette.Color"),
                contains('List<palette.Color> get colors'),
                contains("_\$ackListCast<palette.Color>(_data['colors'])"),
              ]),
            ),
          },
        );
      },
    );

    test(
      'fails for direct-import transformed refs when representation types are not visible',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await _expectGenerationFailure(
          builder: builder,
          expectedMessage: 'is not visible from this library',
          expectedOutputs: {'test_pkg|lib/palette_schemas.g.dart': anything},
          assets: {
            ...allAssets,
            'test_pkg|lib/hidden_types.dart': '''
class HiddenColor {
  final String value;
  const HiddenColor(this.value);
}
''',
            'test_pkg|lib/palette_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

import 'hidden_types.dart';

@AckType()
final hiddenColorSchema = Ack.string()
    .transform<HiddenColor>((value) => HiddenColor(value));
''',
            'test_pkg|lib/theme_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'palette_schemas.dart';

@AckType()
final themeSchema = Ack.object({
  'accent': hiddenColorSchema,
});
''',
          },
        );
      },
    );

    test(
      'resolves prefixed transformed generic refs when representation types are exported',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/palette_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Color {
  final String value;
  const Color(this.value);
}

class Box<T> {
  final T value;
  const Box(this.value);
}

@AckType()
final boxedColorSchema =
    Ack.string().transform<Box<Color>>((value) => Box(Color(value)));
''',
            'test_pkg|lib/theme_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'palette_schemas.dart' as palette;

class Color {
  final String localValue;
  const Color(this.localValue);
}

class Box<T> {
  final T localValue;
  const Box(this.localValue);
}

@AckType()
final themeSchema = Ack.object({
  'accent': palette.boxedColorSchema,
  'colors': Ack.list(palette.boxedColorSchema),
});
''',
          },
          outputs: {
            'test_pkg|lib/palette_schemas.g.dart': decodedMatches(
              contains('extension type BoxedColorType(Box<Color> _value)'),
            ),
            'test_pkg|lib/theme_schemas.g.dart': decodedMatches(
              allOf([
                contains('palette.BoxedColorType get accent'),
                contains(
                  "palette.BoxedColorType(_data['accent'] as palette.Box<palette.Color>)",
                ),
                contains('List<palette.BoxedColorType> get colors'),
                contains(
                  'palette.BoxedColorType(e as palette.Box<palette.Color>)',
                ),
                isNot(contains('copyWith(')),
              ]),
            ),
          },
        );
      },
    );

    test(
      'fails for direct-import transformed refs when representation types collide locally',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await _expectGenerationFailure(
          builder: builder,
          expectedMessage: 'is ambiguous in this library',
          expectedOutputs: {'test_pkg|lib/palette_schemas.g.dart': anything},
          assets: {
            ...allAssets,
            'test_pkg|lib/palette_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Color {
  final String value;
  const Color(this.value);
}

@AckType()
final colorSchema = Ack.string().transform<Color>((value) => Color(value));
''',
            'test_pkg|lib/theme_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'palette_schemas.dart';

class Color {
  final String localValue;
  const Color(this.localValue);
}

@AckType()
final themeSchema = Ack.object({
  'accent': colorSchema,
});
''',
          },
        );
      },
    );

    test(
      'fails for direct-import transformed refs when multiple imports expose the representation type',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await _expectGenerationFailure(
          builder: builder,
          expectedMessage: 'is ambiguous in this library',
          expectedOutputs: {'test_pkg|lib/palette_schemas.g.dart': anything},
          assets: {
            ...allAssets,
            'test_pkg|lib/palette_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Color {
  final String value;
  const Color(this.value);
}

@AckType()
final colorSchema = Ack.string().transform<Color>((value) => Color(value));
''',
            'test_pkg|lib/alt_color_types.dart': '''
class Color {
  final String localValue;
  const Color(this.localValue);
}
''',
            'test_pkg|lib/theme_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'alt_color_types.dart';
import 'palette_schemas.dart';

@AckType()
final themeSchema = Ack.object({
  'accent': colorSchema,
});
''',
          },
        );
      },
    );

    test(
      'fails for prefixed transformed refs when representation types are not visible',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await _expectGenerationFailure(
          builder: builder,
          expectedMessage: 'is not visible from this library',
          expectedOutputs: {'test_pkg|lib/palette_schemas.g.dart': anything},
          assets: {
            ...allAssets,
            'test_pkg|lib/hidden_types.dart': '''
class HiddenColor {
  final String value;
  const HiddenColor(this.value);
}
''',
            'test_pkg|lib/palette_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

import 'hidden_types.dart';

@AckType()
final hiddenColorSchema = Ack.string()
    .transform<HiddenColor>((value) => HiddenColor(value));
''',
            'test_pkg|lib/theme_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'palette_schemas.dart' as palette;

@AckType()
final themeSchema = Ack.object({
  'accent': palette.hiddenColorSchema,
});
''',
          },
        );
      },
    );

    test(
      'fails for cross-file transformed refs that use qualified representation types',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await _expectGenerationFailure(
          builder: builder,
          expectedMessage:
              'uses a qualified type that cannot be referenced across library boundaries',
          expectedOutputs: {'test_pkg|lib/palette_schemas.g.dart': anything},
          assets: {
            ...allAssets,
            'test_pkg|lib/hidden_types.dart': '''
class HiddenColor {
  final String value;
  const HiddenColor(this.value);
}
''',
            'test_pkg|lib/palette_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

import 'hidden_types.dart' as dep;

@AckType()
final hiddenColorSchema = Ack.string()
    .transform<dep.HiddenColor>((value) => dep.HiddenColor(value));
''',
            'test_pkg|lib/theme_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'palette_schemas.dart' as palette;

@AckType()
final themeSchema = Ack.object({
  'accent': palette.hiddenColorSchema,
});
''',
          },
        );
      },
    );

    test('supports @AckType alias schema declarations', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/deck_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final slideSchema = Ack.object({
  'id': Ack.string(),
});
''',
          'test_pkg|lib/deck_tools_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'deck_schemas.dart';

@AckType()
final sharedSlideSchema = slideSchema;

@AckType()
final deckToolArgsSchema = Ack.object({
  'currentSlide': sharedSlideSchema,
});
''',
        },
        outputs: {
          'test_pkg|lib/deck_schemas.g.dart': decodedMatches(
            contains('extension type SlideType(Map<String, Object?> _data)'),
          ),
          'test_pkg|lib/deck_tools_schemas.g.dart': decodedMatches(
            allOf([
              contains('extension type SharedSlideType'),
              contains('SharedSlideType get currentSlide'),
            ]),
          ),
        },
      );
    });

    test(
      'resolves typed nested getters for schema references with optional/nullable modifiers',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/deck_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final slideSchema = Ack.object({
  'id': Ack.string(),
});
''',
            'test_pkg|lib/deck_tools_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'deck_schemas.dart';

@AckType()
final deckToolArgsSchema = Ack.object({
  'currentSlide': slideSchema.optional(),
  'selectedSlide': slideSchema.nullable(),
});
''',
          },
          outputs: {
            'test_pkg|lib/deck_schemas.g.dart': decodedMatches(
              contains('extension type SlideType(Map<String, Object?> _data)'),
            ),
            'test_pkg|lib/deck_tools_schemas.g.dart': decodedMatches(
              allOf([
                contains('SlideType? get currentSlide'),
                contains(
                  "SlideType? get currentSlide => _data['currentSlide'] != null",
                ),
                contains(
                  "? SlideType(_data['currentSlide'] as Map<String, Object?>)",
                ),
                contains('SlideType? get selectedSlide'),
                contains(
                  "SlideType? get selectedSlide => _data['selectedSlide'] != null",
                ),
                contains(
                  "? SlideType(_data['selectedSlide'] as Map<String, Object?>)",
                ),
              ]),
            ),
          },
        );
      },
    );

    test('fails when nested object schema reference is unresolved', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await expectLater(
        () => testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/deck_schemas.dart': '''
import 'package:ack/ack.dart';

final slideSchema = Ack.object({
  'id': Ack.string(),
});
''',
            'test_pkg|lib/deck_tools_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'deck_schemas.dart' as deck;

@AckType()
final deckToolArgsSchema = Ack.object({
  'currentSlide': deck.missingSlideSchema,
});
''',
          },
          outputs: {'test_pkg|lib/deck_tools_schemas.g.dart': anything},
        ),
        // Generator emits: 'Could not resolve schema reference "missingSlideSchema"'
        throwsA(isA<Exception>()),
      );
    });

    test(
      'fails when prefixed schema reference does not exist in that prefix namespace',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await expectLater(
          () => testBuilder(
            builder,
            {
              ...allAssets,
              'test_pkg|lib/a_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final aOnlySchema = Ack.object({
  'id': Ack.string(),
});
''',
              'test_pkg|lib/b_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final slideSchema = Ack.object({
  'id': Ack.string(),
});
''',
              'test_pkg|lib/deck_tools_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'a_schemas.dart' as a;
import 'b_schemas.dart';

@AckType()
final deckToolArgsSchema = Ack.object({
  'currentSlide': a.slideSchema,
  'known': slideSchema,
});
''',
            },
            outputs: {'test_pkg|lib/deck_tools_schemas.g.dart': anything},
          ),
          // Generator emits: 'Could not resolve schema reference "slideSchema"'
          throwsA(isA<Exception>()),
        );
      },
    );

    test('fails when nested object schema reference lacks @AckType', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await expectLater(
        () => testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/deck_schemas.dart': '''
import 'package:ack/ack.dart';

final slideSchema = Ack.object({
  'id': Ack.string(),
});
''',
            'test_pkg|lib/deck_tools_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'deck_schemas.dart';

@AckType()
final deckToolArgsSchema = Ack.object({
  'currentSlide': slideSchema,
  'slides': Ack.list(slideSchema),
});
''',
          },
          outputs: {'test_pkg|lib/deck_tools_schemas.g.dart': anything},
        ),
        // Generator emits: 'references object schema "slideSchema" without @AckType'
        throwsA(isA<Exception>()),
      );
    });

    test(
      'resolves direct-import transformed refs without @AckType using visible representation types',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/palette.dart': '''
import 'package:ack/ack.dart';

class Color {
  final String value;
  const Color(this.value);
}

final colorSchema = Ack.string().transform<Color>((value) => Color(value));
''',
            'test_pkg|lib/theme_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'palette.dart' as palette;

@AckType()
final themeSchema = Ack.object({
  'primary': palette.colorSchema,
  'accents': Ack.list(palette.colorSchema),
});
''',
          },
          outputs: {
            'test_pkg|lib/theme_schemas.g.dart': decodedMatches(
              allOf([
                contains('palette.Color get primary'),
                contains("_data['primary'] as palette.Color"),
                contains('List<palette.Color> get accents'),
                contains("_\$ackListCast<palette.Color>(_data['accents'])"),
              ]),
            ),
          },
        );
      },
    );

    test(
      'fails when Ack.list(schemaRef) object reference lacks @AckType',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await expectLater(
          () => testBuilder(
            builder,
            {
              ...allAssets,
              'test_pkg|lib/deck_schemas.dart': '''
import 'package:ack/ack.dart';

final slideSchema = Ack.object({
  'id': Ack.string(),
});
''',
              'test_pkg|lib/deck_tools_schemas.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'deck_schemas.dart';

@AckType()
final deckToolArgsSchema = Ack.object({
  'slides': Ack.list(slideSchema),
});
''',
            },
            outputs: {'test_pkg|lib/deck_tools_schemas.g.dart': anything},
          ),
          // Generator emits: 'Ack.list(slideSchema) references object schema without @AckType'
          throwsA(isA<Exception>()),
        );
      },
    );
  });
}
