import 'package:ack/ack.dart';
import 'package:test/test.dart';

class TestHelpers {
  static Fail<T, E> isFail<T extends Object, E extends SchemaValidationError>(
      SchemaResult<T, E> result) {
    expect(result, isA<Fail>());
    return result as Fail<T, E>;
  }

  static SchemaValidationConstraintsError isConstraintError<T extends Object>(
      SchemaResult<T, SchemaValidationError> result) {
    final failResult = isFail(result);

    expect(failResult.error, isA<SchemaValidationConstraintsError>());
    return failResult.error as SchemaValidationConstraintsError;
  }

  static ConstraintsValidationError getConstraintErrorOfType<T extends Object>(
    SchemaResult<T, SchemaValidationError> result,
    String type,
  ) {
    final constraintError = isConstraintError(result);
    expect(constraintError.getError(type), isA<ConstraintsValidationError>(),
        reason: 'Expected constraint error of type "$type"');
    return constraintError.getError(type) as ConstraintsValidationError;
  }

  static void expectConstraintErrorOfType<T extends Object>(
    SchemaResult<T, SchemaValidationError> result,
    String type,
  ) {
    final constraintError = isConstraintError(result);
    expect(
      constraintError.getError(type),
      isA<ConstraintsValidationError>(),
      reason: 'Expected constraint error of type "$type"',
    );
  }

  static Ok<T, E> isOk<T extends Object, E extends SchemaValidationError>(
      SchemaResult<T, E> result) {
    expect(result, isA<Ok>());
    return result as Ok<T, E>;
  }
}
