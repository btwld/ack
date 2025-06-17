import 'package:ack/src/constraints/core/pattern_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('PatternConstraint', () {
    group('Regex patterns', () {
      test('regex validates correctly', () {
        final constraint = PatternConstraint.regex(
          r'^[A-Z]{2}\d{3}$',
          patternName: 'product_code',
          example: 'AB123',
        );
        
        expect(constraint.isValid('AB123'), isTrue);
        expect(constraint.isValid('XY999'), isTrue);
        expect(constraint.isValid('ab123'), isFalse);
        expect(constraint.isValid('ABC123'), isFalse);
        
        expect(constraint.buildMessage('invalid'), 
          'Invalid format. Example: AB123');
        expect(constraint.constraintKey, 'string_pattern_product_code');
      });

      test('email validates correctly', () {
        final constraint = PatternConstraint.email();
        
        expect(constraint.isValid('test@example.com'), isTrue);
        expect(constraint.isValid('user.name+tag@example.co.uk'), isTrue);
        expect(constraint.isValid('invalid-email'), isFalse);
        expect(constraint.isValid('@example.com'), isFalse);
        expect(constraint.isValid('test@'), isFalse);
        
        expect(constraint.buildMessage('invalid'), 
          'Invalid email format. Ex: example@domain.com');
        expect(constraint.constraintKey, 'email');
        expect(constraint.toJsonSchema(), {'pattern': r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$', 'format': 'email'});
      });

      test('hexColor validates correctly', () {
        final constraint = PatternConstraint.hexColor();
        
        expect(constraint.isValid('#ffffff'), isTrue);
        expect(constraint.isValid('#000000'), isTrue);
        expect(constraint.isValid('#f0f'), isTrue);
        expect(constraint.isValid('ffffff'), isTrue); // Without hash
        expect(constraint.isValid('f0f'), isTrue); // Without hash
        expect(constraint.isValid('#ggg'), isFalse);
        expect(constraint.isValid('#fffffff'), isFalse);
        
        expect(constraint.buildMessage('invalid'), 
          'Invalid hex color format. Ex: #f0f0f0');
        expect(constraint.constraintKey, 'hex_color');
      });
    });

    group('Enum patterns', () {
      test('enumValues validates correctly', () {
        final constraint = PatternConstraint.enumValues(['small', 'medium', 'large']);
        
        expect(constraint.isValid('small'), isTrue);
        expect(constraint.isValid('medium'), isTrue);
        expect(constraint.isValid('large'), isTrue);
        expect(constraint.isValid('extra-large'), isFalse);
        expect(constraint.isValid('SMALL'), isFalse);
        
        expect(constraint.buildMessage('smll'), 
          contains('Did you mean "small"?'));
        expect(constraint.constraintKey, 'string_enum');
        expect(constraint.toJsonSchema(), {'enum': ['small', 'medium', 'large']});
      });

      test('enumValues provides closest match suggestions', () {
        final constraint = PatternConstraint.enumValues(['red', 'green', 'blue']);
        
        expect(constraint.buildMessage('gren'), contains('Did you mean "green"?'));
        expect(constraint.buildMessage('yellow'), contains('Allowed: "red", "green", "blue"'));
        
        final context = constraint.buildContext('gren');
        expect(context['closestMatch'], 'green');
        expect(context['allowedValues'], ['red', 'green', 'blue']);
      });

      test('notEnumValues validates correctly', () {
        final constraint = PatternConstraint.notEnumValues(['admin', 'root', 'superuser']);
        
        expect(constraint.isValid('user'), isTrue);
        expect(constraint.isValid('guest'), isTrue);
        expect(constraint.isValid('admin'), isFalse);
        expect(constraint.isValid('root'), isFalse);
        expect(constraint.isValid('superuser'), isFalse);
        
        expect(constraint.buildMessage('admin'), 
          'Disallowed value: Cannot be one of [admin, root, superuser]');
        expect(constraint.constraintKey, 'not_one_of');
        expect(constraint.toJsonSchema(), {'not': {'enum': ['admin', 'root', 'superuser']}});
      });
    });

    group('Format patterns', () {
      test('dateTime validates correctly', () {
        final constraint = PatternConstraint.dateTime();
        
        expect(constraint.isValid('2023-12-25T10:30:00'), isTrue);
        expect(constraint.isValid('2023-12-25T10:30:00Z'), isTrue);
        expect(constraint.isValid('2023-12-25T10:30:00+05:00'), isTrue);
        expect(constraint.isValid('2023-12-25'), isTrue); // DateTime.parse accepts this
        expect(constraint.isValid('invalid-date'), isFalse);
        expect(constraint.isValid('25/12/2023'), isFalse);
        
        expect(constraint.buildMessage('invalid'), 
          'Invalid date-time (ISO 8601 required)');
        expect(constraint.constraintKey, 'datetime');
        expect(constraint.toJsonSchema(), {'format': 'date-time'});
      });

      test('date validates correctly', () {
        final constraint = PatternConstraint.date();
        
        expect(constraint.isValid('2023-12-25'), isTrue);
        expect(constraint.isValid('2023-01-01'), isTrue);
        expect(constraint.isValid('2023-12-25T10:30:00'), isFalse); // Has time component
        expect(constraint.isValid('25/12/2023'), isFalse);
        expect(constraint.isValid('2023-13-01'), isFalse); // Invalid month
        expect(constraint.isValid('invalid'), isFalse);
        
        expect(constraint.buildMessage('invalid'), 
          'Invalid date. YYYY-MM-DD required. Ex: 2017-07-21');
        expect(constraint.constraintKey, 'date');
        expect(constraint.toJsonSchema(), {'format': 'date'});
      });

      test('json validates correctly', () {
        final constraint = PatternConstraint.json();
        
        expect(constraint.isValid('{}'), isTrue);
        expect(constraint.isValid('[]'), isTrue);
        expect(constraint.isValid('{"key": "value"}'), isTrue);
        expect(constraint.isValid('[1, 2, 3]'), isTrue);
        expect(constraint.isValid('null'), isTrue);
        expect(constraint.isValid('{invalid json}'), isFalse);
        expect(constraint.isValid('not json'), isFalse);
        
        expect(constraint.buildMessage('invalid'), 'Invalid JSON');
        expect(constraint.constraintKey, 'string_json');
      });
    });

    group('Generic PatternConstraint', () {
      test('can create custom format constraints', () {
        // Custom constraint for UUID format
        final uuidConstraint = PatternConstraint(
          type: PatternType.format,
          formatValidator: (value) => RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            caseSensitive: false,
          ).hasMatch(value),
          constraintKey: 'uuid',
          description: 'Must be a valid UUID',
          customMessageBuilder: (value) => 'Invalid UUID format',
        );
        
        expect(uuidConstraint.isValid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
        expect(uuidConstraint.isValid('not-a-uuid'), isFalse);
        expect(uuidConstraint.buildMessage('invalid'), 'Invalid UUID format');
      });

      test('requires pattern/allowedValues/formatValidator based on type', () {
        expect(
          () => PatternConstraint(
            type: PatternType.regex,
            // pattern is missing
            constraintKey: 'test',
            description: 'test',
          ),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => PatternConstraint(
            type: PatternType.enumValues,
            // allowedValues is missing
            constraintKey: 'test',
            description: 'test',
          ),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => PatternConstraint(
            type: PatternType.format,
            // formatValidator is missing
            constraintKey: 'test',
            description: 'test',
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });
}