import 'package:ack/ack.dart';
import 'package:ack/src/context.dart';
import 'package:test/test.dart';

class _MockSchemaContext extends SchemaContext {
  _MockSchemaContext()
      : super(name: 'test', schema: ObjectSchema({}), value: null);
}

class _MockConstraint extends Constraint {
  const _MockConstraint(String postfix)
      : super(
          constraintKey: 'test_constraint_$postfix',
          description: 'Test constraint $postfix',
        );
}

void main() {
  group('AckException', () {
    test('toMap() returns error map', () {
      final constraint1Violation = ConstraintError(
        message: 'Test constraint',
        constraint: _MockConstraint('1'),
      );
      final constraint2Violation = ConstraintError(
        message: 'Test constraint 2',
        constraint: _MockConstraint('2'),
      );
      final constraint3Violation = ConstraintError(
        message: 'Test constraint 3',
        constraint: _MockConstraint('3'),
      );
      final constraintErrors = [
        constraint1Violation,
        constraint2Violation,
        constraint3Violation,
      ];

      final schemaError = SchemaConstraintsError(
        constraints: constraintErrors,
        context: _MockSchemaContext(),
      );
      final exception = AckViolationException(schemaError);
      final map = exception.toMap();

      // Verify the error map structure
      expect(map.containsKey('error'), isTrue);

      // Check the structure of the error
      final errorMap = map['error'] as Map<String, dynamic>;
      expect(errorMap['errorKey'], 'schema_constraints_error');
      expect(errorMap['name'], 'test');
      expect(errorMap['value'], null);
      final constraints = errorMap['constraints'] as List;
      expect(constraints.length, 3);
      expect(constraints.first['message'], contains('Test constraint'));
      expect(constraints[1]['message'], contains('Test constraint 2'));
      expect(constraints.last['message'], contains('Test constraint 3'));

      // Verify the constraints list
      final constraintsList = errorMap['constraints'] as List;
      expect(constraintsList.length, 3);

      // Verify first constraint
      final firstConstraint = constraintsList[0] as Map<String, dynamic>;
      expect(
          firstConstraint['constraint']['constraintKey'], 'test_constraint_1');
      expect(firstConstraint['message'], 'Test constraint');

      // Verify second constraint
      final secondConstraint = constraintsList[1] as Map<String, dynamic>;
      expect(
          secondConstraint['constraint']['constraintKey'], 'test_constraint_2');
      expect(secondConstraint['message'], 'Test constraint 2');

      // Verify third constraint
      final thirdConstraint = constraintsList[2] as Map<String, dynamic>;
      expect(
          thirdConstraint['constraint']['constraintKey'], 'test_constraint_3');
      expect(thirdConstraint['message'], 'Test constraint 3');
    });

    test('toString() includes error details', () {
      final constraintError = ConstraintError(
        message: 'Test constraint',
        constraint: _MockConstraint('4'),
      );
      final schemaError = SchemaConstraintsError(
        constraints: [constraintError],
        context: _MockSchemaContext(),
      );
      final exception = AckViolationException(schemaError);

      final value = exception.toString();

      expect(
        value,
        contains('$AckViolationException'),
      );
      expect(
        value,
        contains('test_constraint_4'),
      );
    });
  });
}
