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
        expect(constraint.toJsonSchema(), {'format': 'email'});
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
        final constraint =
            PatternConstraint.enumValues(['small', 'medium', 'large']);

        expect(constraint.isValid('small'), isTrue);
        expect(constraint.isValid('medium'), isTrue);
        expect(constraint.isValid('large'), isTrue);
        expect(constraint.isValid('extra-large'), isFalse);
        expect(constraint.isValid('SMALL'), isFalse);

        expect(
            constraint.buildMessage('smll'), contains('Did you mean "small"?'));
        expect(constraint.constraintKey, 'string_enum');
        expect(constraint.toJsonSchema(), {
          'enum': ['small', 'medium', 'large']
        });
      });

      test('enumValues provides closest match suggestions', () {
        final constraint =
            PatternConstraint.enumValues(['red', 'green', 'blue']);

        expect(
            constraint.buildMessage('gren'), contains('Did you mean "green"?'));
        expect(constraint.buildMessage('yellow'),
            contains('Allowed: "red", "green", "blue"'));

        final context = constraint.buildContext('gren');
        expect(context['closestMatch'], 'green');
        expect(context['allowedValues'], ['red', 'green', 'blue']);
      });

      test('notEnumValues validates correctly', () {
        final constraint =
            PatternConstraint.notEnumValues(['admin', 'root', 'superuser']);

        expect(constraint.isValid('user'), isTrue);
        expect(constraint.isValid('guest'), isTrue);
        expect(constraint.isValid('admin'), isFalse);
        expect(constraint.isValid('root'), isFalse);
        expect(constraint.isValid('superuser'), isFalse);

        expect(constraint.buildMessage('admin'),
            'Disallowed value: Cannot be one of [admin, root, superuser]');
        expect(constraint.constraintKey, 'not_one_of');
        expect(constraint.toJsonSchema(), {
          'not': {
            'enum': ['admin', 'root', 'superuser']
          }
        });
      });
    });

    group('Format patterns', () {
      test('dateTime validates correctly', () {
        final constraint = PatternConstraint.dateTime();

        expect(constraint.isValid('2023-12-25T10:30:00'), isTrue);
        expect(constraint.isValid('2023-12-25T10:30:00Z'), isTrue);
        expect(constraint.isValid('2023-12-25T10:30:00+05:00'), isTrue);
        expect(constraint.isValid('2023-12-25'),
            isTrue); // DateTime.parse accepts this
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
        expect(constraint.isValid('2023-12-25T10:30:00'),
            isFalse); // Has time component
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

      test('time validates correctly', () {
        final constraint = PatternConstraint.time();

        expect(constraint.isValid('14:30:00'), isTrue);
        expect(constraint.isValid('00:00:00'), isTrue);
        expect(constraint.isValid('23:59:59'), isTrue);
        expect(constraint.isValid('12:30:45.123'), isTrue);
        expect(constraint.isValid('24:00:00'), isFalse);
        expect(constraint.isValid('12:60:00'), isFalse);
        expect(constraint.isValid('12:30:60'), isFalse);
        expect(constraint.isValid('invalid'), isFalse);

        expect(constraint.buildMessage('invalid'),
            'Invalid time format. Ex: 14:30:00');
        expect(constraint.constraintKey, 'time');
        expect(constraint.toJsonSchema(), {'format': 'time'});
      });

      test('uri validates correctly', () {
        final constraint = PatternConstraint.uri();

        expect(constraint.isValid('https://example.com'), isTrue);
        expect(constraint.isValid('http://example.com/path'), isTrue);
        expect(constraint.isValid('ftp://files.example.com'), isTrue);
        expect(constraint.isValid('mailto:user@example.com'), isTrue);
        expect(constraint.isValid('file:///path/to/file'), isTrue);
        expect(constraint.isValid('not a uri'), isFalse);
        expect(constraint.isValid('://invalid'), isFalse);
        expect(constraint.isValid(''), isFalse);

        expect(constraint.buildMessage('invalid'),
            'Invalid URI format. Ex: https://example.com');
        expect(constraint.constraintKey, 'uri');
        expect(constraint.toJsonSchema(), {'format': 'uri'});
      });

      test('uuid validates correctly', () {
        final constraint = PatternConstraint.uuid();

        expect(
            constraint.isValid('123e4567-e89b-12d3-a456-426614174000'), isTrue);
        expect(
            constraint.isValid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
        expect(
            constraint.isValid('6ba7b810-9dad-11d1-80b4-00c04fd430c8'), isTrue);
        expect(constraint.isValid('not-a-uuid'), isFalse);
        expect(constraint.isValid('123e4567-e89b-12d3-a456'), isFalse);
        expect(constraint.isValid('123e4567-e89b-62d3-a456-426614174000'),
            isFalse); // Invalid version
        expect(constraint.isValid(''), isFalse);

        expect(constraint.buildMessage('invalid'),
            'Invalid UUID format. Ex: 123e4567-e89b-12d3-a456-426614174000');
        expect(constraint.constraintKey, 'uuid');
        expect(constraint.toJsonSchema(), {'format': 'uuid'});
      });

      test('ipv4 validates correctly', () {
        final constraint = PatternConstraint.ipv4();

        expect(constraint.isValid('192.168.1.1'), isTrue);
        expect(constraint.isValid('10.0.0.1'), isTrue);
        expect(constraint.isValid('255.255.255.255'), isTrue);
        expect(constraint.isValid('0.0.0.0'), isTrue);
        expect(constraint.isValid('256.1.1.1'), isFalse);
        expect(constraint.isValid('192.168.1'), isFalse);
        expect(constraint.isValid('192.168.1.1.1'), isFalse);
        expect(constraint.isValid('not an ip'), isFalse);

        expect(constraint.buildMessage('invalid'),
            'Invalid IPv4 address. Ex: 192.168.1.1');
        expect(constraint.constraintKey, 'ipv4');
        expect(constraint.toJsonSchema(), {'format': 'ipv4'});
      });

      test('ipv6 validates correctly', () {
        final constraint = PatternConstraint.ipv6();

        expect(constraint.isValid('2001:0db8:85a3:0000:0000:8a2e:0370:7334'),
            isTrue);
        expect(constraint.isValid('::1'), isTrue);
        expect(constraint.isValid('::'), isTrue);
        expect(constraint.isValid('fe80::1'), isTrue);
        expect(constraint.isValid('invalid:ipv6'), isFalse);
        expect(constraint.isValid('192.168.1.1'), isFalse);
        expect(constraint.isValid(''), isFalse);

        expect(constraint.buildMessage('invalid'),
            'Invalid IPv6 address. Ex: 2001:0db8:85a3::8a2e:0370:7334');
        expect(constraint.constraintKey, 'ipv6');
        expect(constraint.toJsonSchema(), {'format': 'ipv6'});
      });

      test('hostname validates correctly', () {
        final constraint = PatternConstraint.hostname();

        expect(constraint.isValid('example.com'), isTrue);
        expect(constraint.isValid('sub.example.com'), isTrue);
        expect(constraint.isValid('localhost'), isTrue);
        expect(constraint.isValid('my-server.example.org'), isTrue);
        expect(constraint.isValid('server123.test'), isTrue);
        expect(constraint.isValid('-invalid.com'), isFalse);
        expect(constraint.isValid('invalid-.com'), isFalse);
        expect(constraint.isValid('invalid..com'), isFalse);
        expect(constraint.isValid(''), isFalse);

        expect(constraint.buildMessage('invalid'),
            'Invalid hostname. Ex: example.com');
        expect(constraint.constraintKey, 'hostname');
        expect(constraint.toJsonSchema(), {'format': 'hostname'});
      });
    });

    group('Generic PatternConstraint', () {
      test('can create custom format constraints', () {
        // Custom constraint for phone number format
        final phoneConstraint = PatternConstraint(
          type: PatternType.format,
          formatValidator: (value) => RegExp(
            r'^\+?[1-9]\d{1,14}$',
          ).hasMatch(value),
          constraintKey: 'phone',
          description: 'Must be a valid phone number',
          customMessageBuilder: (value) => 'Invalid phone number format',
        );

        expect(phoneConstraint.isValid('+1234567890'), isTrue);
        expect(phoneConstraint.isValid('not-a-phone'), isFalse);
        expect(phoneConstraint.buildMessage('invalid'),
            'Invalid phone number format');
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
