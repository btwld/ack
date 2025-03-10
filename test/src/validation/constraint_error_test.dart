import 'package:ack/ack.dart';
import 'package:test/test.dart';

class _MockConstraint extends Constraint {
  const _MockConstraint()
      : super(constraintKey: 'test_constraint', description: 'Test constraint');
}

void main() {
  group('$ConstraintError', () {
    test('toMap() returns correct structure', () {
      final error = ConstraintError(
        message: 'Test constraint failed',
        constraint: _MockConstraint(),
      );

      final map = error.toMap();

      expect(
          map,
          equals({
            'message': 'Test constraint failed',
            'constraint': {
              'constraintKey': 'test_constraint',
              'description': 'Test constraint'
            },
            'context': null,
          }));
    });

    test('toString() returns formatted string', () {
      final error = ConstraintError(
        message: 'Test constraint failed',
        constraint: _MockConstraint(),
      );

      final errorString = error.toString();

      expect(
        errorString,
        contains('$ConstraintError'),
      );
      expect(
        errorString,
        contains('test_constraint'),
      );
    });
  });
}
