import 'package:ack/ack.dart';
import 'package:test/test.dart';

final _usesJavaScriptNumberRepresentation = <num>[1e20].single is int;

void main() {
  group('numeric schema platform parity', () {
    group('integer', () {
      test('accepts integer and integral-double inputs as int values', () {
        final schema = Ack.integer();

        for (final input in <num>[1, 1.0]) {
          final result = schema.safeParse(input);

          expect(result.isOk, isTrue, reason: 'input: $input');
          expect(result.getOrNull(), equals(1), reason: 'input: $input');
          expect(result.getOrNull(), isA<int>(), reason: 'input: $input');
        }
      });

      test('normalizes negative zero to integer zero', () {
        final result = Ack.integer().safeParse(-0.0);

        expect(result.isOk, isTrue);
        expect(result.getOrNull(), equals(0));
        expect(result.getOrNull(), isA<int>());
        expect(result.getOrNull()!.isNegative, isFalse);
      });

      test('rejects positive and negative non-integral doubles', () {
        final schema = Ack.integer();

        expect(schema.safeParse(1.5).isFail, isTrue);
        expect(schema.safeParse(-1.5).isFail, isTrue);
      });

      test('runs refinements with the normalized integer', () {
        int? refinedValue;
        final schema = Ack.integer().refine((value) {
          refinedValue = value;
          return true;
        });

        expect(schema.safeParse(1.0).isOk, isTrue);
        expect(refinedValue, equals(1));
        expect(refinedValue, isA<int>());
      });

      test('mixed inputs preserve constraints and normalized refinements', () {
        final refinedValues = <int>[];
        final schema = Ack.integer().min(-10).max(10).refine((value) {
          expect(value, isA<int>());
          if (value == 0) expect(value.isNegative, isFalse);
          refinedValues.add(value);
          return true;
        });

        for (var round = 0; round < 2; round++) {
          for (final (input, accepted) in <(Object?, bool)>[
            (7, true),
            (7.0, true),
            (-0.0, true),
            (-4, true),
            (1.5, false),
            (double.infinity, false),
            (11, false),
            ('7', false),
            (true, false),
            (null, false),
          ]) {
            expect(
              schema.safeParse(input).isOk,
              accepted,
              reason: 'round: $round, input: $input',
            );
          }
        }
        expect(refinedValues, [7, 7, 0, -4, 7, 7, 0, -4]);
      });
    });

    group('double', () {
      test('accepts integer and double inputs as double values', () {
        final schema = Ack.double();

        for (final input in <num>[1, 1.0]) {
          final result = schema.safeParse(input);

          expect(result.isOk, isTrue, reason: 'input: $input');
          expect(result.getOrNull(), equals(1.0), reason: 'input: $input');
          expect(result.getOrNull(), isA<double>(), reason: 'input: $input');
        }
      });

      test('runs refinements with the normalized double', () {
        double? refinedValue;
        final schema = Ack.double().refine((value) {
          refinedValue = value;
          return true;
        });

        expect(schema.safeParse(1).isOk, isTrue);
        expect(refinedValue, equals(1.0));
        expect(refinedValue, isA<double>());
      });
    });

    test('integer and double schemas reject non-finite inputs', () {
      for (final input in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          Ack.integer().safeParse(input).getError(),
          isA<TypeMismatchError>(),
          reason: 'IntegerSchema input: $input',
        );
        expect(
          Ack.double().safeParse(input).isFail,
          isTrue,
          reason: 'DoubleSchema input: $input',
        );
      }
    });

    test('infers JSON Schema numeric types independently of Dart shape', () {
      expect(SchemaType.tryOf(1), SchemaType.integer);
      expect(SchemaType.tryOf(1.0), SchemaType.integer);
      expect(SchemaType.tryOf(-0.0), SchemaType.integer);
      expect(SchemaType.tryOf(1.5), SchemaType.number);
      expect(SchemaType.tryOf(double.infinity), SchemaType.number);
    });

    test(
      'numeric anyOf branches normalize through the first matching schema',
      () {
        final integerFirst = Ack.anyOf([Ack.integer(), Ack.double()]);
        final doubleFirst = Ack.anyOf([Ack.double(), Ack.integer()]);

        expect(integerFirst.parse(1.0), isA<int>());
        expect(doubleFirst.parse(1), isA<double>());
      },
    );

    test('preserves exactly representable integers beyond the safe range', () {
      const maxSafeInteger = 9007199254740991;
      final exactBeyondSafeInteger = maxSafeInteger + 3;

      final integerResult = Ack.integer().safeParse(exactBeyondSafeInteger);
      final doubleResult = Ack.double().safeParse(exactBeyondSafeInteger);

      expect(integerResult.getOrNull(), exactBeyondSafeInteger);
      expect(doubleResult.getOrNull(), exactBeyondSafeInteger.toDouble());
      expect(Ack.integer().safe().safeParse(1e20).isFail, isTrue);
    });

    test(
      'rejects lossy native numeric conversions',
      () {
        const maxSafeInteger = 9007199254740991;
        final nonRepresentableAsDouble = maxSafeInteger + 2;

        expect(Ack.integer().safeParse(1e20).isFail, isTrue);
        expect(Ack.double().safeParse(nonRepresentableAsDouble).isFail, isTrue);
      },
      skip: _usesJavaScriptNumberRepresentation
          ? 'JavaScript has already represented these values as doubles.'
          : false,
    );
  });
}
