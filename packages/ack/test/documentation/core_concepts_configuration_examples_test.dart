import 'package:ack/ack.dart';
import 'package:test/test.dart';

class ConfigIsPositiveConstraint extends Constraint<double>
    with Validator<double> {
  ConfigIsPositiveConstraint()
    : super(
        constraintKey: 'is_positive',
        description: 'Number must be positive',
      );

  @override
  bool isValid(double value) => value > 0;

  @override
  String buildMessage(double value) => 'Number must be positive';
}

/// Tests for code snippets in docs/core-concepts/configuration.mdx.
void main() {
  group('Docs /core-concepts/configuration.mdx', () {
    test('required fields and optional configuration behave as documented', () {
      final schema = Ack.object({
        'id': Ack.integer(),
        'name': Ack.string(),
        'email': Ack.string().email().optional(),
      });

      expect(schema.safeParse({'id': 1, 'name': 'Jane'}).isOk, isTrue);
      expect(
        schema.safeParse({'name': 'Jane'}).isFail,
        isTrue,
        reason: 'id is required',
      );
    });

    test('additional properties toggle between strict and flexible modes', () {
      final flexible = Ack.object({
        'id': Ack.integer(),
      }, additionalProperties: true);

      final strict = Ack.object({
        'id': Ack.integer(),
      }, additionalProperties: false);

      expect(flexible.safeParse({'id': 1, 'extra': 'ok'}).isOk, isTrue);
      expect(strict.safeParse({'id': 1, 'extra': 'nope'}).isFail, isTrue);
    });

    test('custom constraint with constrain() enforces domain rules', () {
      final priceSchema = Ack.double().constrain(ConfigIsPositiveConstraint());
      expect(priceSchema.safeParse(10.5).isOk, isTrue);
      expect(priceSchema.safeParse(-5.0).isFail, isTrue);
    });

    test('manual schema definition example validates incoming data', () {
      final userSchema = Ack.object({
        'name': Ack.string().minLength(2).maxLength(50),
        'email': Ack.string().email(),
        'metadata': Ack.any().optional(),
      });

      final result = userSchema.safeParse({
        'name': 'Sasha',
        'email': 'sasha@example.com',
      });
      expect(result.isOk, isTrue);
    });
  });
}
