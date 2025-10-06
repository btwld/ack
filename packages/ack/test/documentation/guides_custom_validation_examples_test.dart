import 'package:ack/ack.dart';
import 'package:test/test.dart';

class CustomValidationPositiveConstraint extends Constraint<double>
    with Validator<double> {
  CustomValidationPositiveConstraint()
    : super(
        constraintKey: 'is_positive',
        description: 'Number must be positive',
      );

  @override
  bool isValid(double value) => value > 0;

  @override
  String buildMessage(double value) => 'Number must be positive';
}

/// Tests for code snippets in docs/guides/custom-validation.mdx.
void main() {
  group('Docs /guides/custom-validation.mdx', () {
    test('custom constraint validates positive numbers', () {
      final priceSchema = Ack.double().constrain(
        CustomValidationPositiveConstraint(),
      );

      expect(priceSchema.safeParse(10.5).isOk, isTrue);
      expect(priceSchema.safeParse(-5.0).isFail, isTrue);
    });

    test('password match validation works via refine', () {
      final signUpSchema =
          Ack.object({
            'password': Ack.string().minLength(8),
            'confirmPassword': Ack.string().minLength(8),
          }).refine(
            (data) => data['password'] == data['confirmPassword'],
            message: 'Passwords do not match',
          );

      expect(
        signUpSchema.safeParse({
          'password': 'pass1234',
          'confirmPassword': 'pass1234',
        }).isOk,
        isTrue,
      );

      expect(
        signUpSchema.safeParse({
          'password': 'pass1234',
          'confirmPassword': 'different',
        }).isFail,
        isTrue,
      );
    });

    test('custom message override works with constrain()', () {
      final schema = Ack.double().constrain(
        CustomValidationPositiveConstraint(),
        message: 'Price must be greater than zero.',
      );

      final result = schema.safeParse(-10);
      expect(result.isFail, isTrue);
      expect(result.getError().message, contains('greater than zero'));
    });
  });
}
