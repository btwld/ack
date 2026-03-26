import 'package:ack/ack.dart';
import 'package:test/test.dart';

class Color {
  final String value;
  const Color(this.value);
}

void main() {
  group('representation parsing', () {
    void expectRepresentationUnavailable<T extends Object>(SchemaResult<T> result) {
      bool hasRepresentationUnavailable(SchemaError error) {
        if (error is SchemaValidationError) {
          return error.message.contains('Representation parsing is unavailable');
        }

        if (error is SchemaNestedError) {
          return error.errors.any(hasRepresentationUnavailable);
        }

        return false;
      }

      expect(result.isFail, isTrue);
      final error = result.getError();
      expect(hasRepresentationUnavailable(error), isTrue, reason: '$error');
    }

    test('transformed schema keeps wire representation and parsed output', () {
      final schema = Ack.string().transform<Color>((value) => Color(value));

      expect(schema.parseRepresentation('red'), 'red');
      expect(
        schema.parse('red'),
        isA<Color>().having((color) => color.value, 'value', 'red'),
      );
    });

    test('built-in transformed schema returns raw wire value', () {
      final schema = Ack.uri();

      expect(
        schema.parseRepresentation('https://example.com'),
        'https://example.com',
      );
      expect(
        schema.parse('https://example.com'),
        isA<Uri>().having(
          (uri) => uri.toString(),
          'value',
          'https://example.com',
        ),
      );
    });

    test(
      'object representation parsing preserves transformed field values',
      () {
        final schema = Ack.object({
          'homepage': Ack.uri(),
          'favoriteColor': Ack.string().transform<Color>(
            (value) => Color(value),
          ),
          'timeout': Ack.duration(),
        });

        final parsed =
            schema.parseRepresentation({
                  'homepage': 'https://example.com',
                  'favoriteColor': 'red',
                  'timeout': 1500,
                })
                as Map<String, Object?>;

        expect(parsed, {
          'homepage': 'https://example.com',
          'favoriteColor': 'red',
          'timeout': 1500,
        });
      },
    );

    test('list representation parsing preserves transformed elements', () {
      final schema = Ack.list(Ack.uri());

      expect(
        schema.parseRepresentation([
          'https://example.com',
          'https://example.com/docs',
        ]),
        ['https://example.com', 'https://example.com/docs'],
      );
    });

    test('object representation parsing preserves raw default values', () {
      final schema = Ack.object({
        'homepage': Ack.uri(),
        'timeout': Ack.duration(),
      }).copyWith(
        defaultValue: {
          'homepage': 'https://example.com',
          'timeout': 1500,
        },
      );

      expect(schema.parseRepresentation(null), {
        'homepage': 'https://example.com',
        'timeout': 1500,
      });
    });

    test('list representation parsing preserves raw list defaults', () {
      final schema = Ack.list(Ack.string()).copyWith(
        defaultValue: ['https://example.com', 'https://example.com/docs'],
      );

      expect(schema.parseRepresentation(null), [
        'https://example.com',
        'https://example.com/docs',
      ]);
    });

    test('discriminated representation parsing preserves raw branch defaults', () {
      final catSchema = Ack.object({
        'type': Ack.literal('cat'),
        'homepage': Ack.uri(),
      });
      final animalSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {'cat': catSchema},
      ).copyWith(
        defaultValue: {
          'type': 'cat',
          'homepage': 'https://example.com',
        },
      );

      expect(animalSchema.parseRepresentation(null), {
        'type': 'cat',
        'homepage': 'https://example.com',
      });
    });

    test('representation parsing fails for transformed defaults', () {
      final schema = Ack.string()
          .transform<Color>((value) => Color(value))
          .copyWith(defaultValue: const Color('red'));

      expectRepresentationUnavailable(schema.safeParseRepresentation(null));
    });

    test(
      'object representation parsing fails for optional transformed defaults',
      () {
        final schema = Ack.object({
          'favoriteColor': Ack.string()
              .transform<Color>((value) => Color(value))
              .optional()
              .copyWith(defaultValue: const Color('red')),
        });

        expectRepresentationUnavailable(schema.safeParseRepresentation({}));
      },
    );

    test(
      'discriminated representation parsing fails for transformed branch defaults',
      () {
        final catSchema = Ack.object({
          'type': Ack.literal('cat'),
          'favoriteColor': Ack.string()
              .transform<Color>((value) => Color(value))
              .optional()
              .copyWith(defaultValue: const Color('red')),
        });
        final animalSchema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {'cat': catSchema},
        );

        expectRepresentationUnavailable(
          animalSchema.safeParseRepresentation({'type': 'cat'}),
        );
      },
    );

    test(
      'object representation parsing fails for nested transformed list defaults',
      () {
        final schema = Ack.object({
          'colors': Ack.list(
            Ack.string().transform<Color>((value) => Color(value)),
          ).optional().copyWith(defaultValue: const [Color('red')]),
        });

        final result = schema.safeParseRepresentation({});

        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(error, isA<SchemaNestedError>());
        final nestedError = (error as SchemaNestedError).errors.first;
        expect(nestedError, isA<SchemaNestedError>());
        expect(nestedError.context.path, '#/colors');
      },
    );
  });
}
