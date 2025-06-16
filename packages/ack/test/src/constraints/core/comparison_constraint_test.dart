import 'package:ack/src/constraints/core/comparison_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('ComparisonConstraint', () {
    group('String constraints', () {
      test('stringMinLength validates correctly', () {
        final constraint = ComparisonConstraint.stringMinLength(5);
        
        expect(constraint.isValid('hello'), isTrue);
        expect(constraint.isValid('hello world'), isTrue);
        expect(constraint.isValid('hi'), isFalse);
        expect(constraint.isValid(''), isFalse);
        
        expect(constraint.buildMessage('hi'), 
          'Too short, min 5 characters. Got 2');
        expect(constraint.constraintKey, 'string_min_length');
        expect(constraint.toJsonSchema(), {'minimum': 5});
      });

      test('stringMaxLength validates correctly', () {
        final constraint = ComparisonConstraint.stringMaxLength(5);
        
        expect(constraint.isValid('hello'), isTrue);
        expect(constraint.isValid('hi'), isTrue);
        expect(constraint.isValid('hello world'), isFalse);
        
        expect(constraint.buildMessage('hello world'), 
          'Too long, max 5 characters. Got 11');
        expect(constraint.constraintKey, 'string_max_length');
        expect(constraint.toJsonSchema(), {'maximum': 5});
      });

      test('stringExactLength validates correctly', () {
        final constraint = ComparisonConstraint.stringExactLength(5);
        
        expect(constraint.isValid('hello'), isTrue);
        expect(constraint.isValid('hi'), isFalse);
        expect(constraint.isValid('hello world'), isFalse);
        
        expect(constraint.buildMessage('hi'), 
          'Must be exactly 5 characters. Got 2');
        expect(constraint.constraintKey, 'string_exact_length');
        expect(constraint.toJsonSchema(), {'const': 5});
      });
    });

    group('Number constraints', () {
      test('numberMin validates correctly', () {
        final constraint = ComparisonConstraint.numberMin(10);
        
        expect(constraint.isValid(10), isTrue);
        expect(constraint.isValid(15), isTrue);
        expect(constraint.isValid(9), isFalse);
        expect(constraint.isValid(0), isFalse);
        
        expect(constraint.buildMessage(5), 'Must be at least 10. Got 5');
        expect(constraint.constraintKey, 'number_min');
        expect(constraint.toJsonSchema(), {'minimum': 10});
      });

      test('numberMax validates correctly', () {
        final constraint = ComparisonConstraint.numberMax(10);
        
        expect(constraint.isValid(10), isTrue);
        expect(constraint.isValid(5), isTrue);
        expect(constraint.isValid(11), isFalse);
        expect(constraint.isValid(100), isFalse);
        
        expect(constraint.buildMessage(15), 'Must be at most 10. Got 15');
        expect(constraint.constraintKey, 'number_max');
        expect(constraint.toJsonSchema(), {'maximum': 10});
      });

      test('numberRange validates correctly', () {
        final constraint = ComparisonConstraint.numberRange(10, 20);
        
        expect(constraint.isValid(10), isTrue);
        expect(constraint.isValid(15), isTrue);
        expect(constraint.isValid(20), isTrue);
        expect(constraint.isValid(9), isFalse);
        expect(constraint.isValid(21), isFalse);
        
        expect(constraint.buildMessage(25), 'Must be between 10 and 20. Got 25');
        expect(constraint.constraintKey, 'number_range');
        expect(constraint.toJsonSchema(), {'minimum': 10, 'maximum': 20});
      });

      test('numberExclusiveMin validates correctly', () {
        final constraint = ComparisonConstraint.numberExclusiveMin(10);
        
        expect(constraint.isValid(11), isTrue);
        expect(constraint.isValid(10), isFalse);
        expect(constraint.isValid(9), isFalse);
        
        expect(constraint.buildMessage(10), 'Must be greater than 10. Got 10');
        expect(constraint.constraintKey, 'number_exclusive_min');
        expect(constraint.toJsonSchema(), {'exclusiveMinimum': 10});
      });

      test('numberExclusiveMax validates correctly', () {
        final constraint = ComparisonConstraint.numberExclusiveMax(10);
        
        expect(constraint.isValid(9), isTrue);
        expect(constraint.isValid(10), isFalse);
        expect(constraint.isValid(11), isFalse);
        
        expect(constraint.buildMessage(10), 'Must be less than 10. Got 10');
        expect(constraint.constraintKey, 'number_exclusive_max');
        expect(constraint.toJsonSchema(), {'exclusiveMaximum': 10});
      });

      test('numberMultipleOf validates correctly', () {
        final constraint = ComparisonConstraint.numberMultipleOf(5);
        
        expect(constraint.isValid(0), isTrue);
        expect(constraint.isValid(5), isTrue);
        expect(constraint.isValid(10), isTrue);
        expect(constraint.isValid(15), isTrue);
        expect(constraint.isValid(3), isFalse);
        expect(constraint.isValid(7), isFalse);
        
        expect(constraint.buildMessage(7), 'Must be a multiple of 5');
        expect(constraint.constraintKey, 'number_multiple_of');
        expect(constraint.toJsonSchema(), {'const': 0});
      });

      test('numberMultipleOf works with decimals', () {
        final constraint = ComparisonConstraint.numberMultipleOf(0.5);
        
        expect(constraint.isValid(0), isTrue);
        expect(constraint.isValid(0.5), isTrue);
        expect(constraint.isValid(1.0), isTrue);
        expect(constraint.isValid(1.5), isTrue);
        expect(constraint.isValid(0.3), isFalse);
        expect(constraint.isValid(0.7), isFalse);
      });
    });

    group('List constraints', () {
      test('listMinItems validates correctly', () {
        final constraint = ComparisonConstraint.listMinItems<int>(3);
        
        expect(constraint.isValid([1, 2, 3]), isTrue);
        expect(constraint.isValid([1, 2, 3, 4]), isTrue);
        expect(constraint.isValid([1, 2]), isFalse);
        expect(constraint.isValid([]), isFalse);
        
        expect(constraint.buildMessage([1, 2]), 
          'Too few items, min 3. Got 2');
        expect(constraint.constraintKey, 'list_min_items');
        expect(constraint.toJsonSchema(), {'minimum': 3});
      });

      test('listMaxItems validates correctly', () {
        final constraint = ComparisonConstraint.listMaxItems<int>(3);
        
        expect(constraint.isValid([1, 2, 3]), isTrue);
        expect(constraint.isValid([1, 2]), isTrue);
        expect(constraint.isValid([]), isTrue);
        expect(constraint.isValid([1, 2, 3, 4]), isFalse);
        
        expect(constraint.buildMessage([1, 2, 3, 4]), 
          'Too many items, max 3. Got 4');
        expect(constraint.constraintKey, 'list_max_items');
        expect(constraint.toJsonSchema(), {'maximum': 3});
      });
    });

    group('Object constraints', () {
      test('objectMinProperties validates correctly', () {
        final constraint = ComparisonConstraint.objectMinProperties(2);
        
        expect(constraint.isValid({'a': 1, 'b': 2}), isTrue);
        expect(constraint.isValid({'a': 1, 'b': 2, 'c': 3}), isTrue);
        expect(constraint.isValid({'a': 1}), isFalse);
        expect(constraint.isValid({}), isFalse);
        
        expect(constraint.buildMessage({'a': 1}), 
          'Too few properties, min 2. Got 1');
        expect(constraint.constraintKey, 'object_min_properties');
        expect(constraint.toJsonSchema(), {'minimum': 2});
      });

      test('objectMaxProperties validates correctly', () {
        final constraint = ComparisonConstraint.objectMaxProperties(2);
        
        expect(constraint.isValid({'a': 1, 'b': 2}), isTrue);
        expect(constraint.isValid({'a': 1}), isTrue);
        expect(constraint.isValid({}), isTrue);
        expect(constraint.isValid({'a': 1, 'b': 2, 'c': 3}), isFalse);
        
        expect(constraint.buildMessage({'a': 1, 'b': 2, 'c': 3}), 
          'Too many properties, max 2. Got 3');
        expect(constraint.constraintKey, 'object_max_properties');
        expect(constraint.toJsonSchema(), {'maximum': 2});
      });
    });

    group('Generic ComparisonConstraint', () {
      test('can create custom comparison constraints', () {
        // Custom constraint for string that checks number of words
        final wordCountConstraint = ComparisonConstraint<String>(
          type: ComparisonType.gte,
          threshold: 3,
          valueExtractor: (value) => value.split(' ').length,
          constraintKey: 'min_words',
          description: 'Must have at least 3 words',
          customMessageBuilder: (value, extracted) => 
            'Too few words. Expected at least 3, got ${extracted.toInt()}',
        );
        
        expect(wordCountConstraint.isValid('hello world test'), isTrue);
        expect(wordCountConstraint.isValid('hello world'), isFalse);
        expect(wordCountConstraint.buildMessage('hello world'), 
          'Too few words. Expected at least 3, got 2');
      });

      test('range type requires maxThreshold', () {
        expect(
          () => ComparisonConstraint<num>(
            type: ComparisonType.range,
            threshold: 10,
            // maxThreshold is missing
            valueExtractor: (value) => value,
            constraintKey: 'test',
            description: 'test',
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });
}