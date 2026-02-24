import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

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
