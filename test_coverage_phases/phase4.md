# Phase 4: Constraint System Direct Testing 🔒

## Overview
This phase focuses on creating direct unit tests for constraint classes to improve maintainability and debugging. Currently, constraints are only tested indirectly through schemas.

## Current Status
- Constraints well-tested indirectly through schema tests
- No direct unit tests for individual constraint classes
- Constraint classes located in `/packages/ack/lib/src/constraints/`
- Custom constraint creation not tested

## Implementation Plan

### 4.1 Core Constraint Tests

#### Test: NonNullableConstraint
```dart
// File: packages/ack/test/constraints/non_nullable_constraint_test.dart
import 'package:ack/src/constraints/non_nullable_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('NonNullableConstraint', () {
    late NonNullableConstraint constraint;
    
    setUp(() {
      constraint = NonNullableConstraint();
    });
    
    test('should reject null values', () {
      expect(constraint.isValid(null), isFalse);
    });
    
    test('should accept non-null values', () {
      expect(constraint.isValid(''), isTrue);
      expect(constraint.isValid(0), isTrue);
      expect(constraint.isValid(false), isTrue);
      expect(constraint.isValid([]), isTrue);
      expect(constraint.isValid({}), isTrue);
    });
    
    test('should provide clear error message', () {
      expect(constraint.errorMessage, contains('null'));
      expect(constraint.errorMessage, contains('required'));
    });
    
    test('should have correct error code', () {
      expect(constraint.code, equals('non_nullable'));
    });
    
    test('should serialize to JSON correctly', () {
      final json = constraint.toJson();
      expect(json['type'], equals('non_nullable'));
      expect(json['message'], equals(constraint.errorMessage));
    });
  });
}
```

#### Test: InvalidTypeConstraint
```dart
// File: packages/ack/test/constraints/invalid_type_constraint_test.dart
import 'package:ack/src/constraints/invalid_type_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('InvalidTypeConstraint', () {
    test('should validate expected types', () {
      final stringConstraint = InvalidTypeConstraint<String>('string');
      
      expect(stringConstraint.isValid('hello'), isTrue);
      expect(stringConstraint.isValid(''), isTrue);
      expect(stringConstraint.isValid(123), isFalse);
      expect(stringConstraint.isValid(null), isFalse);
    });
    
    test('should handle numeric types correctly', () {
      final intConstraint = InvalidTypeConstraint<int>('integer');
      final doubleConstraint = InvalidTypeConstraint<double>('number');
      final numConstraint = InvalidTypeConstraint<num>('number');
      
      expect(intConstraint.isValid(42), isTrue);
      expect(intConstraint.isValid(42.5), isFalse);
      
      expect(doubleConstraint.isValid(42.5), isTrue);
      expect(doubleConstraint.isValid(42), isFalse); // Strict double
      
      expect(numConstraint.isValid(42), isTrue);
      expect(numConstraint.isValid(42.5), isTrue);
    });
    
    test('should handle collection types', () {
      final listConstraint = InvalidTypeConstraint<List>('array');
      final mapConstraint = InvalidTypeConstraint<Map>('object');
      
      expect(listConstraint.isValid([1, 2, 3]), isTrue);
      expect(listConstraint.isValid({'a': 1}), isFalse);
      
      expect(mapConstraint.isValid({'key': 'value'}), isTrue);
      expect(mapConstraint.isValid([1, 2, 3]), isFalse);
    });
    
    test('should provide descriptive error messages', () {
      final constraint = InvalidTypeConstraint<String>('string');
      expect(constraint.errorMessage, contains('string'));
      expect(constraint.errorMessage, contains('Expected'));
    });
    
    test('should handle custom type names', () {
      final constraint = InvalidTypeConstraint<DateTime>('ISO 8601 date');
      expect(constraint.errorMessage, contains('ISO 8601 date'));
    });
  });
}
```

#### Test: ComparisonConstraint
```dart
// File: packages/ack/test/constraints/comparison_constraint_test.dart
import 'package:ack/src/constraints/comparison_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('ComparisonConstraint', () {
    group('min constraint', () {
      test('should validate minimum values', () {
        final constraint = ComparisonConstraint.min(10);
        
        expect(constraint.isValid(10), isTrue);
        expect(constraint.isValid(11), isTrue);
        expect(constraint.isValid(9), isFalse);
        expect(constraint.isValid(9.999), isFalse);
      });
      
      test('should handle edge cases', () {
        final constraint = ComparisonConstraint.min(0);
        
        expect(constraint.isValid(0), isTrue);
        expect(constraint.isValid(-0.0), isTrue);
        expect(constraint.isValid(-1), isFalse);
      });
      
      test('should provide clear error message', () {
        final constraint = ComparisonConstraint.min(10);
        expect(constraint.errorMessage, contains('at least 10'));
      });
    });
    
    group('max constraint', () {
      test('should validate maximum values', () {
        final constraint = ComparisonConstraint.max(100);
        
        expect(constraint.isValid(100), isTrue);
        expect(constraint.isValid(99), isTrue);
        expect(constraint.isValid(101), isFalse);
        expect(constraint.isValid(100.001), isFalse);
      });
    });
    
    group('greaterThan constraint', () {
      test('should validate greater than', () {
        final constraint = ComparisonConstraint.greaterThan(5);
        
        expect(constraint.isValid(5), isFalse);
        expect(constraint.isValid(5.001), isTrue);
        expect(constraint.isValid(6), isTrue);
      });
    });
    
    group('lessThan constraint', () {
      test('should validate less than', () {
        final constraint = ComparisonConstraint.lessThan(10);
        
        expect(constraint.isValid(10), isFalse);
        expect(constraint.isValid(9.999), isTrue);
        expect(constraint.isValid(9), isTrue);
      });
    });
    
    test('should handle infinity and NaN', () {
      final minConstraint = ComparisonConstraint.min(0);
      final maxConstraint = ComparisonConstraint.max(100);
      
      expect(minConstraint.isValid(double.infinity), isTrue);
      expect(maxConstraint.isValid(double.negativeInfinity), isTrue);
      
      expect(minConstraint.isValid(double.nan), isFalse);
      expect(maxConstraint.isValid(double.nan), isFalse);
    });
    
    test('should serialize to JSON correctly', () {
      final constraint = ComparisonConstraint.min(42);
      final json = constraint.toJson();
      
      expect(json['type'], equals('comparison'));
      expect(json['operator'], equals('min'));
      expect(json['value'], equals(42));
    });
  });
}
```

#### Test: PatternConstraint
```dart
// File: packages/ack/test/constraints/pattern_constraint_test.dart
import 'package:ack/src/constraints/pattern_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('PatternConstraint', () {
    test('should validate against regex patterns', () {
      final constraint = PatternConstraint(RegExp(r'^\d{3}-\d{3}-\d{4}$'));
      
      expect(constraint.isValid('123-456-7890'), isTrue);
      expect(constraint.isValid('1234567890'), isFalse);
      expect(constraint.isValid('123-45-6789'), isFalse);
    });
    
    test('should handle complex patterns', () {
      final emailPattern = PatternConstraint(
        RegExp(r'^[\w.-]+@[\w.-]+\.\w+$'),
      );
      
      expect(emailPattern.isValid('test@example.com'), isTrue);
      expect(emailPattern.isValid('user.name@domain.co.uk'), isTrue);
      expect(emailPattern.isValid('invalid@'), isFalse);
      expect(emailPattern.isValid('@invalid.com'), isFalse);
    });
    
    test('should provide helpful error messages', () {
      final constraint = PatternConstraint(
        RegExp(r'^\d{3}-\d{3}-\d{4}$'),
        'Must be in format XXX-XXX-XXXX',
      );
      
      expect(constraint.errorMessage, equals('Must be in format XXX-XXX-XXXX'));
    });
    
    test('should handle pattern flags', () {
      final caseInsensitive = PatternConstraint(
        RegExp(r'^hello$', caseSensitive: false),
      );
      
      expect(caseInsensitive.isValid('hello'), isTrue);
      expect(caseInsensitive.isValid('HELLO'), isTrue);
      expect(caseInsensitive.isValid('HeLLo'), isTrue);
    });
    
    test('should handle multiline patterns', () {
      final multiline = PatternConstraint(
        RegExp(r'^test$', multiLine: true),
      );
      
      expect(multiline.isValid('test'), isTrue);
      expect(multiline.isValid('line1\ntest\nline3'), isTrue);
      expect(multiline.isValid('testing'), isFalse);
    });
  });
}
```

#### Test: ObjectRequiredPropertiesConstraint
```dart
// File: packages/ack/test/constraints/object_required_properties_constraint_test.dart
import 'package:ack/src/constraints/object_required_properties_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('ObjectRequiredPropertiesConstraint', () {
    test('should validate required properties', () {
      final constraint = ObjectRequiredPropertiesConstraint(['id', 'name']);
      
      expect(constraint.isValid({'id': 1, 'name': 'Test'}), isTrue);
      expect(constraint.isValid({'id': 1, 'name': 'Test', 'extra': true}), isTrue);
      expect(constraint.isValid({'id': 1}), isFalse);
      expect(constraint.isValid({'name': 'Test'}), isFalse);
      expect(constraint.isValid({}), isFalse);
    });
    
    test('should handle nested required properties', () {
      final constraint = ObjectRequiredPropertiesConstraint(['user.id', 'user.name']);
      
      expect(constraint.isValid({
        'user': {'id': 1, 'name': 'John'}
      }), isTrue);
      
      expect(constraint.isValid({
        'user': {'id': 1}
      }), isFalse);
    });
    
    test('should provide clear error messages', () {
      final constraint = ObjectRequiredPropertiesConstraint(['id', 'name', 'email']);
      
      expect(constraint.errorMessage, contains('required'));
      expect(constraint.errorMessage, contains('id'));
      expect(constraint.errorMessage, contains('name'));
      expect(constraint.errorMessage, contains('email'));
    });
    
    test('should handle empty required list', () {
      final constraint = ObjectRequiredPropertiesConstraint([]);
      
      expect(constraint.isValid({}), isTrue);
      expect(constraint.isValid({'any': 'value'}), isTrue);
    });
  });
}
```

### 4.2 String Constraints

#### Test: EmailConstraint edge cases
```dart
// File: packages/ack/test/constraints/string_constraints_test.dart
import 'package:ack/src/constraints/string_constraints.dart';
import 'package:test/test.dart';

void main() {
  group('EmailConstraint', () {
    late EmailConstraint constraint;
    
    setUp(() {
      constraint = EmailConstraint();
    });
    
    test('should validate standard email formats', () {
      expect(constraint.isValid('user@example.com'), isTrue);
      expect(constraint.isValid('first.last@company.org'), isTrue);
      expect(constraint.isValid('user+tag@domain.co.uk'), isTrue);
    });
    
    test('should handle international domains', () {
      expect(constraint.isValid('user@例え.jp'), isTrue);
      expect(constraint.isValid('user@münchen.de'), isTrue);
      expect(constraint.isValid('user@қазақстан.қз'), isTrue);
    });
    
    test('should reject invalid formats', () {
      expect(constraint.isValid('invalid'), isFalse);
      expect(constraint.isValid('@example.com'), isFalse);
      expect(constraint.isValid('user@'), isFalse);
      expect(constraint.isValid('user @example.com'), isFalse);
      expect(constraint.isValid('user@example'), isFalse); // No TLD
    });
    
    test('should handle edge cases', () {
      expect(constraint.isValid('a@b.c'), isTrue); // Minimal valid
      expect(constraint.isValid('very.long.email.address@very.long.domain.name.com'), isTrue);
      expect(constraint.isValid('user@sub.domain.example.com'), isTrue);
    });
  });
  
  group('URLConstraint', () {
    late URLConstraint constraint;
    
    setUp(() {
      constraint = URLConstraint();
    });
    
    test('should validate various protocols', () {
      expect(constraint.isValid('http://example.com'), isTrue);
      expect(constraint.isValid('https://example.com'), isTrue);
      expect(constraint.isValid('ftp://files.example.com'), isTrue);
      expect(constraint.isValid('ws://websocket.example.com'), isTrue);
      expect(constraint.isValid('wss://secure.websocket.com'), isTrue);
    });
    
    test('should handle URLs with paths and queries', () {
      expect(constraint.isValid('https://example.com/path/to/resource'), isTrue);
      expect(constraint.isValid('https://example.com?query=value'), isTrue);
      expect(constraint.isValid('https://example.com/path?q=1&r=2#anchor'), isTrue);
    });
    
    test('should handle authentication in URLs', () {
      expect(constraint.isValid('https://user:pass@example.com'), isTrue);
      expect(constraint.isValid('ftp://anonymous@ftp.example.com'), isTrue);
    });
    
    test('should reject invalid URLs', () {
      expect(constraint.isValid('not a url'), isFalse);
      expect(constraint.isValid('//example.com'), isFalse); // No protocol
      expect(constraint.isValid('example.com'), isFalse); // No protocol
      expect(constraint.isValid('http://'), isFalse); // No domain
    });
  });
  
  group('UUIDConstraint', () {
    late UUIDConstraint constraint;
    
    setUp(() {
      constraint = UUIDConstraint();
    });
    
    test('should validate different UUID versions', () {
      // v4 UUID
      expect(constraint.isValid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
      
      // v1 UUID
      expect(constraint.isValid('6ba7b810-9dad-11d1-80b4-00c04fd430c8'), isTrue);
      
      // v5 UUID
      expect(constraint.isValid('6ba7b814-9dad-11d1-80b4-00c04fd430c8'), isTrue);
    });
    
    test('should handle case variations', () {
      expect(constraint.isValid('550E8400-E29B-41D4-A716-446655440000'), isTrue);
      expect(constraint.isValid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
    });
    
    test('should reject invalid UUIDs', () {
      expect(constraint.isValid('550e8400-e29b-41d4-a716'), isFalse); // Too short
      expect(constraint.isValid('550e8400-e29b-41d4-a716-446655440000-extra'), isFalse);
      expect(constraint.isValid('550e8400e29b41d4a716446655440000'), isFalse); // No hyphens
      expect(constraint.isValid('xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'), isFalse);
    });
  });
  
  group('DateTimeConstraint', () {
    late DateTimeConstraint constraint;
    
    setUp(() {
      constraint = DateTimeConstraint();
    });
    
    test('should validate ISO 8601 formats', () {
      expect(constraint.isValid('2024-01-15'), isTrue);
      expect(constraint.isValid('2024-01-15T10:30:00'), isTrue);
      expect(constraint.isValid('2024-01-15T10:30:00Z'), isTrue);
      expect(constraint.isValid('2024-01-15T10:30:00+05:00'), isTrue);
      expect(constraint.isValid('2024-01-15T10:30:00-08:00'), isTrue);
    });
    
    test('should handle different timezone formats', () {
      expect(constraint.isValid('2024-01-15T10:30:00+0530'), isTrue);
      expect(constraint.isValid('2024-01-15T10:30:00.123Z'), isTrue);
      expect(constraint.isValid('2024-01-15T10:30:00.123456Z'), isTrue);
    });
    
    test('should reject invalid date formats', () {
      expect(constraint.isValid('01/15/2024'), isFalse);
      expect(constraint.isValid('2024/01/15'), isFalse);
      expect(constraint.isValid('15-01-2024'), isFalse);
      expect(constraint.isValid('2024-13-01'), isFalse); // Invalid month
      expect(constraint.isValid('2024-01-32'), isFalse); // Invalid day
    });
  });
  
  group('IPConstraint', () {
    late IPConstraint ipv4Constraint;
    late IPConstraint ipv6Constraint;
    late IPConstraint anyConstraint;
    
    setUp(() {
      ipv4Constraint = IPConstraint(version: 4);
      ipv6Constraint = IPConstraint(version: 6);
      anyConstraint = IPConstraint();
    });
    
    test('should validate IPv4 addresses', () {
      expect(ipv4Constraint.isValid('192.168.1.1'), isTrue);
      expect(ipv4Constraint.isValid('10.0.0.0'), isTrue);
      expect(ipv4Constraint.isValid('255.255.255.255'), isTrue);
      expect(ipv4Constraint.isValid('0.0.0.0'), isTrue);
      
      expect(ipv4Constraint.isValid('256.1.1.1'), isFalse);
      expect(ipv4Constraint.isValid('192.168.1'), isFalse);
      expect(ipv4Constraint.isValid('192.168.1.1.1'), isFalse);
    });
    
    test('should validate IPv6 addresses', () {
      expect(ipv6Constraint.isValid('2001:0db8:85a3:0000:0000:8a2e:0370:7334'), isTrue);
      expect(ipv6Constraint.isValid('2001:db8:85a3::8a2e:370:7334'), isTrue);
      expect(ipv6Constraint.isValid('::1'), isTrue); // Loopback
      expect(ipv6Constraint.isValid('::'), isTrue); // All zeros
      
      expect(ipv6Constraint.isValid('192.168.1.1'), isFalse);
      expect(ipv6Constraint.isValid('gggg::1'), isFalse);
    });
    
    test('should validate any IP version', () {
      expect(anyConstraint.isValid('192.168.1.1'), isTrue);
      expect(anyConstraint.isValid('2001:db8:85a3::8a2e:370:7334'), isTrue);
      expect(anyConstraint.isValid('invalid'), isFalse);
    });
  });
}
```

### 4.3 Numeric Constraints

#### Test: Numeric constraint edge cases
```dart
// File: packages/ack/test/constraints/numeric_constraints_test.dart
import 'package:ack/src/constraints/numeric_constraints.dart';
import 'package:test/test.dart';

void main() {
  group('MultipleOfConstraint', () {
    test('should validate multiples with integers', () {
      final constraint = MultipleOfConstraint(5);
      
      expect(constraint.isValid(0), isTrue);
      expect(constraint.isValid(5), isTrue);
      expect(constraint.isValid(10), isTrue);
      expect(constraint.isValid(-15), isTrue);
      
      expect(constraint.isValid(3), isFalse);
      expect(constraint.isValid(7), isFalse);
    });
    
    test('should handle floating point precision', () {
      final constraint = MultipleOfConstraint(0.1);
      
      expect(constraint.isValid(0.1), isTrue);
      expect(constraint.isValid(0.2), isTrue);
      expect(constraint.isValid(0.3), isTrue);
      
      // Handle floating point precision issues
      expect(constraint.isValid(0.30000000000000004), isTrue); // 0.1 + 0.2
    });
    
    test('should handle decimals', () {
      final constraint = MultipleOfConstraint(0.25);
      
      expect(constraint.isValid(0.25), isTrue);
      expect(constraint.isValid(0.5), isTrue);
      expect(constraint.isValid(0.75), isTrue);
      expect(constraint.isValid(1.0), isTrue);
      
      expect(constraint.isValid(0.3), isFalse);
      expect(constraint.isValid(0.7), isFalse);
    });
  });
  
  group('PositiveConstraint', () {
    late PositiveConstraint constraint;
    
    setUp(() {
      constraint = PositiveConstraint();
    });
    
    test('should validate positive numbers', () {
      expect(constraint.isValid(1), isTrue);
      expect(constraint.isValid(0.1), isTrue);
      expect(constraint.isValid(1000000), isTrue);
      expect(constraint.isValid(double.infinity), isTrue);
    });
    
    test('should handle zero', () {
      expect(constraint.isValid(0), isFalse);
      expect(constraint.isValid(0.0), isFalse);
      expect(constraint.isValid(-0.0), isFalse);
    });
    
    test('should reject negative numbers', () {
      expect(constraint.isValid(-1), isFalse);
      expect(constraint.isValid(-0.1), isFalse);
      expect(constraint.isValid(double.negativeInfinity), isFalse);
    });
  });
  
  group('NegativeConstraint', () {
    late NegativeConstraint constraint;
    
    setUp(() {
      constraint = NegativeConstraint();
    });
    
    test('should validate negative numbers', () {
      expect(constraint.isValid(-1), isTrue);
      expect(constraint.isValid(-0.1), isTrue);
      expect(constraint.isValid(-1000000), isTrue);
      expect(constraint.isValid(double.negativeInfinity), isTrue);
    });
    
    test('should handle zero', () {
      expect(constraint.isValid(0), isFalse);
      expect(constraint.isValid(0.0), isFalse);
      expect(constraint.isValid(-0.0), isFalse);
    });
  });
  
  group('IntegerConstraint', () {
    late IntegerConstraint constraint;
    
    setUp(() {
      constraint = IntegerConstraint();
    });
    
    test('should validate integers', () {
      expect(constraint.isValid(0), isTrue);
      expect(constraint.isValid(42), isTrue);
      expect(constraint.isValid(-100), isTrue);
      expect(constraint.isValid(9007199254740991), isTrue); // Max safe integer
    });
    
    test('should reject decimals', () {
      expect(constraint.isValid(1.1), isFalse);
      expect(constraint.isValid(0.5), isFalse);
      expect(constraint.isValid(-0.1), isFalse);
    });
    
    test('should handle edge cases', () {
      expect(constraint.isValid(1.0), isTrue); // Whole number as double
      expect(constraint.isValid(double.infinity), isFalse);
      expect(constraint.isValid(double.nan), isFalse);
    });
  });
}
```

### 4.4 Custom Constraints

#### Test: Creating custom constraint classes
```dart
// File: packages/ack/test/constraints/custom_constraints_test.dart
import 'package:ack/src/constraints/constraint.dart';
import 'package:test/test.dart';

// Example custom constraint
class PasswordStrengthConstraint extends Constraint {
  final int minStrength;
  
  PasswordStrengthConstraint({this.minStrength = 3});
  
  @override
  bool isValid(dynamic value) {
    if (value is! String) return false;
    
    int strength = 0;
    if (value.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(value)) strength++;
    if (RegExp(r'[a-z]').hasMatch(value)) strength++;
    if (RegExp(r'[0-9]').hasMatch(value)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) strength++;
    
    return strength >= minStrength;
  }
  
  @override
  String get errorMessage => 'Password is too weak (strength < $minStrength)';
  
  @override
  String get code => 'password_strength';
  
  @override
  Map<String, dynamic> toJson() => {
    'type': 'password_strength',
    'minStrength': minStrength,
  };
}

void main() {
  group('Custom Constraints', () {
    test('should create and use custom constraints', () {
      final constraint = PasswordStrengthConstraint(minStrength: 3);
      
      expect(constraint.isValid('Password123'), isTrue);
      expect(constraint.isValid('Pass123!'), isTrue);
      expect(constraint.isValid('password'), isFalse);
      expect(constraint.isValid('12345678'), isFalse);
    });
    
    test('should integrate with schemas', () {
      final schema = Ack.string().addConstraint(
        PasswordStrengthConstraint(minStrength: 4),
      );
      
      expect(() => schema.parse('weak'), throwsA(isA<ValidationException>()));
      expect(schema.parse('Str0ng!Pass'), equals('Str0ng!Pass'));
    });
  });
  
  group('Constraint Composition', () {
    test('should compose multiple constraints', () {
      final minLength = LengthConstraint.min(8);
      final maxLength = LengthConstraint.max(20);
      final hasUppercase = PatternConstraint(RegExp(r'[A-Z]'));
      final hasNumber = PatternConstraint(RegExp(r'[0-9]'));
      
      final schema = Ack.string()
        .addConstraint(minLength)
        .addConstraint(maxLength)
        .addConstraint(hasUppercase)
        .addConstraint(hasNumber);
      
      expect(schema.parse('Password1'), equals('Password1'));
      expect(() => schema.parse('pass'), throwsA(isA<ValidationException>()));
      expect(() => schema.parse('PASSWORD'), throwsA(isA<ValidationException>()));
    });
  });
  
  group('Constraint Priority and Ordering', () {
    test('should apply constraints in order', () {
      final errors = <String>[];
      
      class LoggingConstraint extends Constraint {
        final String name;
        final bool passes;
        
        LoggingConstraint(this.name, this.passes);
        
        @override
        bool isValid(dynamic value) {
          errors.add(name);
          return passes;
        }
        
        @override
        String get errorMessage => '$name failed';
        
        @override
        String get code => name;
      }
      
      final schema = Ack.string()
        .addConstraint(LoggingConstraint('first', true))
        .addConstraint(LoggingConstraint('second', true))
        .addConstraint(LoggingConstraint('third', false))
        .addConstraint(LoggingConstraint('fourth', true));
      
      try {
        schema.parse('test');
      } catch (_) {
        // Expected
      }
      
      // Should stop at first failure
      expect(errors, equals(['first', 'second', 'third']));
    });
  });
  
  group('Constraint Error Message Customization', () {
    test('should allow custom error messages', () {
      class CustomMessageConstraint extends Constraint {
        final String customMessage;
        
        CustomMessageConstraint(this.customMessage);
        
        @override
        bool isValid(dynamic value) => false;
        
        @override
        String get errorMessage => customMessage;
        
        @override
        String get code => 'custom';
      }
      
      final constraint = CustomMessageConstraint('This is a custom error');
      
      expect(constraint.errorMessage, equals('This is a custom error'));
    });
    
    test('should support dynamic error messages', () {
      class DynamicMessageConstraint extends Constraint {
        dynamic lastValue;
        
        @override
        bool isValid(dynamic value) {
          lastValue = value;
          return false;
        }
        
        @override
        String get errorMessage => 'Value "$lastValue" is invalid';
        
        @override
        String get code => 'dynamic';
      }
      
      final constraint = DynamicMessageConstraint();
      
      constraint.isValid('test');
      expect(constraint.errorMessage, equals('Value "test" is invalid'));
      
      constraint.isValid(123);
      expect(constraint.errorMessage, equals('Value "123" is invalid'));
    });
  });
}
```

## Validation Checklist

- [ ] All core constraint classes have unit tests
- [ ] String constraints thoroughly tested
- [ ] Numeric constraints edge cases covered
- [ ] Custom constraint creation documented
- [ ] Constraint composition tested
- [ ] Error message customization verified
- [ ] New test files created in appropriate directories
- [ ] 50+ constraint-specific tests added
- [ ] All tests passing

## Success Metrics

- Direct unit tests for every constraint class
- Edge cases documented and tested
- Custom constraint patterns established
- Improved debugging capabilities
- Clear documentation for constraint creation