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

@AckType()
final colorSchema = Ack.string().transform<Color>((value) => Color(value!));

@AckType()
final aliasColorSchema = colorSchema.transform<Color>((value) => value!);

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
                contains('extension type ColorType(Color _value)'),
                contains('extension type AliasColorType(Color _value)'),
                contains('extension type UriType(Uri _value)'),
                contains('extension type DateType(DateTime _value)'),
                contains('extension type DatetimeType(DateTime _value)'),
                contains('extension type DurationType(Duration _value)'),
                contains('extension type ValidatedStringType(String _value)'),
                contains('Color toJson() => _value;'),
                contains('Uri toJson() => _value;'),
                contains('DateTime toJson() => _value;'),
                contains('Duration toJson() => _value;'),
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

@AckType()
final colorSchema = Ack.string().transform<Color>((value) => Color(value!));

final baseColorSchema = Ack.string();

@AckType()
final profileSchema = Ack.object({
  'homepage': Ack.uri(),
  'birthday': Ack.date(),
  'lastLogin': Ack.datetime().optional().nullable(),
  'timeout': Ack.duration(),
  'favoriteColor': Ack.string().transform<Color>((value) => Color(value!)),
  'accent': colorSchema,
  'colors': Ack.list(colorSchema),
  'customColors': Ack.list(
    baseColorSchema.transform<Color>((value) => Color(value!)),
  ),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type ColorType(Color _value)'),
              contains(
                'extension type ProfileType(Map<String, Object?> _data)',
              ),
              contains('Uri get homepage => _data[\'homepage\'] as Uri'),
              contains(
                'DateTime get birthday => _data[\'birthday\'] as DateTime',
              ),
              contains(
                'DateTime? get lastLogin => _data[\'lastLogin\'] as DateTime?',
              ),
              contains(
                'Duration get timeout => _data[\'timeout\'] as Duration',
              ),
              contains(
                'Color get favoriteColor => _data[\'favoriteColor\'] as Color',
              ),
              contains('ColorType get accent'),
              contains("ColorType(_data['accent'] as Color)"),
              contains('List<ColorType> get colors'),
              contains('ColorType(e as Color)'),
              contains('List<Color> get customColors'),
              contains('_\$ackListCast<Color>(_data[\'customColors\'])'),
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
    baseColorSchema.transform<Color>((value) => Color(value!));
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type ColorType(Color _value)'),
              contains('return colorSchema.parseAs('),
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
final colorSchema = Ack.string().transform((value) => Color(value!));
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
