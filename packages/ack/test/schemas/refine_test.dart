import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('AckSchema.refine', () {
    test('should succeed when refinement condition is met', () {
      final schema = Ack.string().refine(
        (value) => value.startsWith('ack'),
        message: 'Must start with "ack"',
      );
      final result = schema.validate('ack is awesome');
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), 'ack is awesome');
    });

    test('should fail with custom message when refinement condition is not met',
        () {
      final schema = Ack.string().refine(
        (value) => value.startsWith('ack'),
        message: 'Custom Error: Must start with "ack"',
      );
      final result = schema.validate('hello world');
      expect(result.isFail, isTrue);
      expect(
        (result.getError() as SchemaValidationError).message,
        'Custom Error: Must start with "ack"',
      );
    });

    test('should execute refinements only after base constraints are met', () {
      final schema = Ack.string().minLength(10).refine(
            (value) => value.contains('fail'),
            message: 'Refine should not run',
          );

      // This input fails the minLength constraint
      final result = schema.validate('short');
      expect(result.isFail, isTrue);
      // Crucially, the error should be from minLength, not the refinement.
      expect(
        (result.getError() as SchemaConstraintsError).constraints.first.message,
        contains('at least 10'),
      );
    });

    test(
        'should chain multiple refinements and fail on the first one that fails',
        () {
      final schema = Ack.string()
          .refine(
            (value) => value.length > 5,
            message: 'First refinement: must be > 5 chars',
          )
          .refine(
            (value) => value.contains('world'),
            message: 'Second refinement: must contain "world"',
          );

      final result = schema.validate('hello'); // Fails first refinement
      expect(result.isFail, isTrue);
      expect(
        (result.getError() as SchemaValidationError).message,
        'First refinement: must be > 5 chars',
      );
    });

    test('should work on complex types like ObjectSchema', () {
      final schema = Ack.object({
        'password': Ack.string().minLength(8),
        'confirmPassword': Ack.string().minLength(8),
      }).refine(
        (data) => data['password'] == data['confirmPassword'],
        message: 'Passwords do not match',
      );

      // Success case
      final resultSuccess = schema.validate({
        'password': 'password123',
        'confirmPassword': 'password123',
      });
      expect(resultSuccess.isOk, isTrue);

      // Failure case
      final resultFailure = schema.validate({
        'password': 'password123',
        'confirmPassword': 'password456',
      });
      expect(resultFailure.isFail, isTrue);
      expect(
        (resultFailure.getError() as SchemaValidationError).message,
        'Passwords do not match',
      );
    });
  });
}
