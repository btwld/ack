import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('@AckType transform support', () {
    test(
      'supports top-level transformed schemas and direct transformed factories',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Color {
  final String value;
  const Color(this.value);
}

class TagList {
  final List<String> value;
  const TagList(this.value);
}

@AckType()
final colorSchema = Ack.string().transform<Color>((value) => Color(value));

@AckType()
final aliasColorSchema = colorSchema.transform<Color>((value) => value);

@AckType()
final uriSchema = Ack.uri();

@AckType()
final dateSchema = Ack.date();

@AckType()
final datetimeSchema = Ack.datetime();

@AckType()
final durationSchema = Ack.duration();

@AckType()
final validatedStringSchema = Ack.string().uri();
''',
          },
          outputs: {
            'test_pkg|lib/schema.g.dart': decodedMatches(
              allOf([
                // Representation-first: store wire types
                contains('extension type ColorType(String _value)'),
                contains('extension type AliasColorType(String _value)'),
                contains('extension type UriType(String _value)'),
                contains('extension type DateType(String _value)'),
                contains('extension type DatetimeType(String _value)'),
                contains('extension type DurationType(int _value)'),
                contains('extension type ValidatedStringType(String _value)'),
                // toJson returns representation type
                contains('String toJson() => _value;'),
                // Parsed getters for transformed types
                contains('Color get parsed'),
                contains('Uri get parsed'),
                contains('DateTime get parsed'),
                contains('Duration get parsed'),
                // Uses parseRepresentationAs
                contains('parseRepresentationAs'),
                isNot(contains('Color toJson()')),
                isNot(contains('Uri toJson()')),
                isNot(contains('DateTime toJson()')),
                isNot(contains('Duration toJson()')),
              ]),
            ),
          },
        );
      },
    );

    test('supports nested transformed fields, refs, and list elements', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Color {
  final String value;
  const Color(this.value);
}

class TagList {
  final List<String> value;
  const TagList(this.value);
}

@AckType()
final colorSchema = Ack.string().transform<Color>((value) => Color(value));

final baseColorSchema = Ack.string();

@AckType()
final profileSchema = Ack.object({
  'homepage': Ack.uri(),
  'birthday': Ack.date(),
  'lastLogin': Ack.datetime().optional().nullable(),
  'timeout': Ack.duration(),
  'links': Ack.list(Ack.uri()),
  'nestedLinks': Ack.list(Ack.list(Ack.uri())),
  'favoriteColor': Ack.string().transform<Color>((value) => Color(value)),
  'slug': Ack.string().transform<String>((value) => value + '#'),
  'accent': colorSchema,
  'colors': Ack.list(colorSchema),
  'customColors': Ack.list(
    baseColorSchema.transform<Color>((value) => Color(value)),
  ),
  'tagList': Ack.list(Ack.string()).transform<TagList>((value) => TagList(value)),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              // Representation-first wrapper
              contains('extension type ColorType(String _value)'),
              contains(
                'extension type ProfileType(Map<String, Object?> _data)',
              ),
              // Primary getters return representation types
              contains("String get homepage => _data['homepage'] as String"),
              contains("String get birthday => _data['birthday'] as String"),
              contains(
                "String? get lastLogin => _data['lastLogin'] as String?",
              ),
              contains("int get timeout => _data['timeout'] as int"),
              // Parsed getters for built-in transforms
              contains('Uri get homepageParsed'),
              contains('DateTime get birthdayParsed'),
              contains('DateTime? get lastLoginParsed'),
              contains('Duration get timeoutParsed'),
              // Lists use representation element types
              contains('List<String> get links'),
              contains("_\$ackListCast<String>(_data['links'])"),
              contains('List<List<String>> get nestedLinks'),
              contains("_\$ackListCast<List<String>>(_data['nestedLinks'])"),
              // Inline transform: primary = representation, parsed accessor
              contains(
                "String get favoriteColor => _data['favoriteColor'] as String",
              ),
              contains('Color get favoriteColorParsed'),
              // No-op transform (String→String): no Parsed getter needed
              contains("String get slug => _data['slug'] as String"),
              isNot(contains('slugParsed')),
              // Named ref: wraps in extension type
              contains('ColorType get accent'),
              contains("ColorType(_data['accent'] as String)"),
              // Named ref Parsed getter
              contains('Color get accentParsed'),
              // List of named refs
              contains('List<ColorType> get colors'),
              contains('ColorType(e as String)'),
              // List of named refs Parsed getter
              contains('List<Color> get colorsParsed'),
              // List of inline transforms
              contains('List<String> get customColors'),
              contains("_\$ackListCast<String>(_data['customColors'])"),
              // tagList: top-level list transform, type is representation (List<String>)
              contains('List<String> get tagList'),
              contains("_\$ackListCast<String>(_data['tagList'])"),
              contains('TagList get tagListParsed'),
              contains('Map<String, Object?> toJson() => _data;'),
              // copyWith is now enabled for representation-first wrappers
              contains('copyWith('),
              isNot(contains('Uri.parse(')),
              isNot(contains('DateTime.parse(')),
              isNot(contains('Duration(milliseconds:')),
            ]),
          ),
        },
      );
    });

    test('supports transformed getter schemas', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Color {
  final String value;
  const Color(this.value);
}

AckSchema<String> get baseColorSchema => Ack.string();

@AckType()
AckSchema<Color> get colorSchema =>
    baseColorSchema.transform<Color>((value) => Color(value));
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type ColorType(String _value)'),
              contains('return colorSchema.parseRepresentationAs('),
            ]),
          ),
        },
      );
    });

    test('supports top-level list schema with chained modifiers', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final uniqueTagsSchema = Ack.list(Ack.string()).unique();

@AckType()
final describedTagsSchema = Ack.list(Ack.string()).describe('A list of tags');
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type UniqueTagsType(List<String> _value)'),
              contains('extension type DescribedTagsType(List<String> _value)'),
            ]),
          ),
        },
      );
    });

    test('supports transformed refs through re-exported schemas', () async {
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
            contains('extension type ColorType(String _value)'),
          ),
          'test_pkg|lib/theme_schemas.g.dart': decodedMatches(
            allOf([
              contains('ColorType get accent'),
              contains("ColorType(_data['accent'] as String)"),
              contains('List<ColorType> get colors'),
              contains('ColorType(e as String)'),
              // copyWith is now enabled
              contains('copyWith('),
            ]),
          ),
        },
      );
    });

    test('non-transformed object schemas still generate copyWith', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final profileSchema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains(
                'extension type ProfileType(Map<String, Object?> _data)',
              ),
              contains('ProfileType copyWith({String? name, int? age})'),
            ]),
          ),
        },
      );
    });

    test('rejects transform without an explicit output type', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await expectLater(
        () => testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Color {
  final String value;
  const Color(this.value);
}

@AckType()
final colorSchema = Ack.string().transform((value) => Color(value));
''',
          },
          outputs: {'test_pkg|lib/schema.g.dart': anything},
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects transformed object and discriminated schemas', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await expectLater(
        () => testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final objectSchema = Ack.object({
  'name': Ack.string(),
}).transform<String>((value) => 'name');

@AckType()
final discriminatedSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {
    'user': Ack.string(),
  },
).transform<String>((value) => 'user');
''',
          },
          outputs: {'test_pkg|lib/schema.g.dart': anything},
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
