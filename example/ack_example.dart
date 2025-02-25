import 'package:ack/ack.dart';

void main() {
  final addressSchema = Ack.object({
    'street': Ack.string.isEmail(),
    'city': Ack.string,
    'zip': Ack.string,
  });
  final userSchema = Ack.object({
    'name': Ack.string.isNotEmpty(),
    'email': Ack.string.isEmail(),
    'age': Ack.int.minValue(18),
    'roles': Ack.string.list.minItems(1),
  });

  final userWithAddressSchema = userSchema.extend({'address': addressSchema});

  final userData = {
    'name': 'John Doe',
    'email': 'john.doe@example.com',
    'age': 25,
    'roles': ['admin', 'user'],
    'address': {
      'street': '123 Main St',
      'city': 'Springfield',
      'zip': '12345',
    },
  };

  final result = userWithAddressSchema.checkResult(userData);

  result.match(
    onOk: (data) => print('User data is valid!'),
    onFail: (errors) => print('Validation errors: $errors'),
  );
}
