import 'package:ack/ack.dart';

void main() {
  /// Object Example
  final addressSchema = Ack.object(
    {
      'street': Ack.string.notEmpty(),
      'city': Ack.string.notEmpty(),
      'zip': Ack.string.nullable(),
    },
    required: ['street', 'city'],
  );

  final userSchema = Ack.object(
    {
      'name': Ack.string.notEmpty(),
      'email': Ack.string.email(),
      'age': Ack.int.min(18),
      'address': addressSchema,
    },
    additionalProperties: true,
    required: ['name', 'email'],
  );

  final userWithAddressSchema = userSchema.extend({'address': addressSchema});

  final result = userWithAddressSchema.validate({
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 25,
    'address': {
      'street': '123 Main St',
      'city': 'Springfield',
      'zip': '12345',
    },
  });

  result.match(
    onOk: (data) => print('User data is valid!'),
    onFail: (errors) => print('Validation errors: $errors'),
  );
}
