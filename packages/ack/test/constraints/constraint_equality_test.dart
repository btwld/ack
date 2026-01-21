import 'package:ack/src/constraints/comparison_constraint.dart';
import 'package:ack/src/constraints/datetime_constraint.dart';
import 'package:ack/src/constraints/list_unique_items_constraint.dart';
import 'package:ack/src/constraints/number_finite_constraint.dart';
import 'package:ack/src/constraints/number_safe_integer_constraint.dart';
import 'package:ack/src/constraints/pattern_constraint.dart';
import 'package:ack/src/constraints/string_ip_constraint.dart';
import 'package:ack/src/constraints/string_literal_constraint.dart';
import 'package:ack/src/constraints/validators.dart';
import 'package:test/test.dart';

void main() {
  group('Constraint Equality', () {
    group('ComparisonConstraint', () {
      test('equal stringMinLength are equal', () {
        final a = ComparisonConstraint.stringMinLength(5);
        final b = ComparisonConstraint.stringMinLength(5);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different thresholds are not equal', () {
        final a = ComparisonConstraint.stringMinLength(5);
        final b = ComparisonConstraint.stringMinLength(10);
        expect(a, isNot(equals(b)));
      });

      test('equal numberMin are equal', () {
        final a = ComparisonConstraint.numberMin(0);
        final b = ComparisonConstraint.numberMin(0);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('equal numberRange are equal', () {
        final a = ComparisonConstraint.numberRange(0, 100);
        final b = ComparisonConstraint.numberRange(0, 100);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('equal numberMultipleOf are equal', () {
        final a = ComparisonConstraint.numberMultipleOf(5);
        final b = ComparisonConstraint.numberMultipleOf(5);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('equal listMinItems are equal', () {
        final a = ComparisonConstraint.listMinItems<String>(1);
        final b = ComparisonConstraint.listMinItems<String>(1);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('PatternConstraint', () {
      test('equal email are equal', () {
        final a = PatternConstraint.email();
        final b = PatternConstraint.email();
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('equal uuid are equal', () {
        final a = PatternConstraint.uuid();
        final b = PatternConstraint.uuid();
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('equal regex are equal', () {
        final a = PatternConstraint.regex(r'^\d+$');
        final b = PatternConstraint.regex(r'^\d+$');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different patterns are not equal', () {
        final a = PatternConstraint.regex(r'^\d+$');
        final b = PatternConstraint.regex(r'^\w+$');
        expect(a, isNot(equals(b)));
      });

      test('equal enumString are equal', () {
        final a = PatternConstraint.enumString(['a', 'b', 'c']);
        final b = PatternConstraint.enumString(['a', 'b', 'c']);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different enum values are not equal', () {
        final a = PatternConstraint.enumString(['a', 'b']);
        final b = PatternConstraint.enumString(['a', 'c']);
        expect(a, isNot(equals(b)));
      });
    });

    group('StringLiteralConstraint', () {
      test('equal are equal', () {
        final a = StringLiteralConstraint('test');
        final b = StringLiteralConstraint('test');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different values are not equal', () {
        final a = StringLiteralConstraint('test');
        final b = StringLiteralConstraint('other');
        expect(a, isNot(equals(b)));
      });
    });

    group('ListUniqueItemsConstraint', () {
      test('equal are equal', () {
        final a = ListUniqueItemsConstraint<String>();
        final b = ListUniqueItemsConstraint<String>();
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('DateTimeConstraint', () {
      test('equal min are equal', () {
        final date = DateTime(2023, 1, 1);
        final a = DateTimeConstraint.min(date);
        final b = DateTimeConstraint.min(date);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('equal max are equal', () {
        final date = DateTime(2023, 12, 31);
        final a = DateTimeConstraint.max(date);
        final b = DateTimeConstraint.max(date);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different dates are not equal', () {
        final a = DateTimeConstraint.min(DateTime(2023, 1, 1));
        final b = DateTimeConstraint.min(DateTime(2024, 1, 1));
        expect(a, isNot(equals(b)));
      });

      test('min and max are not equal', () {
        final date = DateTime(2023, 1, 1);
        final a = DateTimeConstraint.min(date);
        final b = DateTimeConstraint.max(date);
        expect(a, isNot(equals(b)));
      });
    });

    group('NumberFiniteConstraint', () {
      test('equal are equal', () {
        const a = NumberFiniteConstraint();
        const b = NumberFiniteConstraint();
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('NumberSafeIntegerConstraint', () {
      test('equal are equal', () {
        const a = NumberSafeIntegerConstraint();
        const b = NumberSafeIntegerConstraint();
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('StringIpConstraint', () {
      test('equal are equal', () {
        const a = StringIpConstraint();
        const b = StringIpConstraint();
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('equal ipv4 are equal', () {
        const a = StringIpConstraint(version: 4);
        const b = StringIpConstraint(version: 4);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different versions are not equal', () {
        const a = StringIpConstraint(version: 4);
        const b = StringIpConstraint(version: 6);
        expect(a, isNot(equals(b)));
      });
    });

    group('Validator Constraints', () {
      test('NonNullableConstraint equal', () {
        const a = NonNullableConstraint();
        const b = NonNullableConstraint();
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('InvalidTypeConstraint equal', () {
        final a = InvalidTypeConstraint.withTypes(
          expectedType: String,
          actualType: int,
        );
        final b = InvalidTypeConstraint.withTypes(
          expectedType: String,
          actualType: int,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('ObjectNoAdditionalPropertiesConstraint equal', () {
        final a = ObjectNoAdditionalPropertiesConstraint(
          unexpectedPropertyKey: 'foo',
        );
        final b = ObjectNoAdditionalPropertiesConstraint(
          unexpectedPropertyKey: 'foo',
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('ObjectRequiredPropertiesConstraint equal', () {
        final a = ObjectRequiredPropertiesConstraint(
          missingPropertyKey: 'name',
        );
        final b = ObjectRequiredPropertiesConstraint(
          missingPropertyKey: 'name',
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('Set and Map operations', () {
      test('constraints work correctly in Set', () {
        final c1 = ComparisonConstraint.stringMinLength(5);
        final c2 = ComparisonConstraint.stringMinLength(5);
        final c3 = ComparisonConstraint.stringMinLength(10);

        final set = {c1, c2, c3};
        expect(set.length, equals(2));
      });

      test('constraints work correctly as Map keys', () {
        final c1 = ComparisonConstraint.stringMinLength(5);
        final c2 = ComparisonConstraint.stringMinLength(5);

        final map = {c1: 'first', c2: 'second'};
        expect(map.length, equals(1));
        expect(map[c1], equals('second'));
      });
    });
  });
}
