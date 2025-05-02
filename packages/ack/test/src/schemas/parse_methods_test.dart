import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('AckSchema Parse Methods', () {
    group('parse()', () {
      test('returns parsed value for valid input', () {
        final schema = Ack.string;
        final result = schema.parse('hello');
        expect(result, equals('hello'));
      });

      test('throws exception for invalid input', () {
        final schema = Ack.string.strict();
        expect(
          () => schema.parse(42),
          throwsA(isA<AckException>()),
        );
      });

      test('works with nullable schemas', () {
        final schema = Ack.string.nullable();
        // Test parsing null value
        final result = schema.parse(null);
        expect(result, isNull);
        
        // Also test parsing a valid value with nullable schema
        final validResult = schema.parse('hello');
        expect(validResult, equals('hello'));
      });

      test('preserves object structure with complex schemas', () {
        final schema = Ack.object({
          'name': Ack.string,
          'age': Ack.int,
          'address': Ack.object({
            'street': Ack.string,
            'city': Ack.string,
          }),
        });

        final input = {
          'name': 'John',
          'age': 30,
          'address': {
            'street': '123 Main St',
            'city': 'Anytown',
          },
        };

        final result = schema.parse(input);
        expect(result, equals(input));
      });
    });

    group('tryParse()', () {
      test('returns parsed value for valid input', () {
        final schema = Ack.string;
        final result = schema.tryParse('hello');
        expect(result, equals('hello'));
      });

      test('returns null for invalid input', () {
        final schema = Ack.string.strict();
        final result = schema.tryParse(42);
        expect(result, isNull);
      });

      test('works with nullable schemas', () {
        final schema = Ack.string.nullable();
        final result = schema.tryParse(null);
        expect(result, isNull);
      });

      test('preserves object structure with complex schemas', () {
        final schema = Ack.object({
          'name': Ack.string,
          'age': Ack.int,
          'address': Ack.object({
            'street': Ack.string,
            'city': Ack.string,
          }),
        });

        final input = {
          'name': 'John',
          'age': 30,
          'address': {
            'street': '123 Main St',
            'city': 'Anytown',
          },
        };

        final result = schema.tryParse(input);
        expect(result, equals(input));
      });

      test('returns null for invalid nested data', () {
        final schema = Ack.object({
          'name': Ack.string,
          'age': Ack.int,
          'address': Ack.object({
            'street': Ack.string,
            'city': Ack.string,
          }, required: ['street', 'city']),
        }, required: ['name', 'age', 'address']);

        final input = {
          'name': 'John',
          'age': 30,
          'address': {
            'street': '123 Main St',
            // missing required 'city' field
          },
        };

        final result = schema.tryParse(input);
        expect(result, isNull);
      });
    });

    group('validateOrThrow()', () {
      test('returns validated value for valid input', () {
        final schema = Ack.string;
        final result = schema.validateOrThrow('hello');
        expect(result, equals('hello'));
      });

      test('throws exception for invalid input', () {
        final schema = Ack.int.strict();
        expect(
          () => schema.validateOrThrow('42'),
          throwsA(isA<AckException>()),
        );
      });

      test('preserves object structure with complex schemas', () {
        final schema = Ack.object({
          'name': Ack.string,
          'age': Ack.int,
        });

        final input = {
          'name': 'John',
          'age': 30,
        };

        final result = schema.validateOrThrow(input);
        expect(result, equals(input));
      });
    });
  });
}