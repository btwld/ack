import 'package:ack/ack.dart';
import 'package:ack/src/constraints/core/comparison_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('TransformExtension', () {
    test('should transform a string to an integer successfully', () {
      final schema = Ack.string().transform((val) => val?.length ?? 0);
      final result = schema.parse('hello');
      expect(result, 5);
    });

    test('should chain a refinement check after a transformation', () {
      final schema = Ack.string()
          .transform((val) => val?.length ?? 0)
          .refine((val) => val > 3, message: 'Length must be greater than 3');

      // Test success
      final successResult = schema.safeParse('hello');
      expect(successResult.isOk, isTrue);
      expect(successResult.getOrThrow(), 5);

      // Test failure
      final failureResult = schema.safeParse('hi');
      expect(failureResult.isFail, isTrue);
      expect(
        failureResult.getError().message,
        contains('Length must be greater than 3'),
      );
    });

    test('should handle nullable schemas and transform a null value', () {
      final schema = Ack.string().nullable().transform((val) {
        return val == null ? 'was null' : 'was not null';
      });

      final result = schema.safeParse(null);
      expect(result.isOk, isTrue);
      expect(result.getOrThrow(), 'was null');

      final result2 = schema.safeParse('a');
      expect(result2.isOk, isTrue);
      expect(result2.getOrThrow(), 'was not null');
    });

    test('should error when transformer returns null for non-nullable output',
        () {
      final schema = Ack.string().transform<int>((val) {
        return (null as dynamic);
      });

      final result = schema.safeParse('value');

      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaTransformError>());
    });

    test('should return a SchemaTransformError if the transformer fails', () {
      final schema = Ack.string().transform<int>((val) {
        if (val == 'fail') {
          throw Exception('Intentional failure');
        }
        return 42;
      });

      final result = schema.safeParse('fail');

      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaTransformError>());
      expect(
        result.getError().message,
        contains('Transformation failed: Exception: Intentional failure'),
      );
    });

    test('should fail validation before the transformer is ever called', () {
      final schema =
          Ack.string().minLength(10).transform((val) => 'transformed');

      final result = schema.safeParse('short');

      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaConstraintsError>());
      final error = result.getError() as SchemaConstraintsError;
      expect(error.getConstraint<ComparisonConstraint>(), isNotNull);
    });
  });
}
