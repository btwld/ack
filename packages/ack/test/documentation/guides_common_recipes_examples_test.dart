import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

class CommonPhoneNumberConstraint extends Constraint<String>
    with Validator<String> {
  CommonPhoneNumberConstraint()
    : super(
        constraintKey: 'phone_number',
        description: 'Must be valid phone number (e.g., +1-234-567-8900)',
      );

  final RegExp _regex = RegExp(r'^\+\d{1,3}-\d{3}-\d{3}-\d{4}$');

  @override
  bool isValid(String value) => _regex.hasMatch(value);

  @override
  String buildMessage(String value) =>
      'Must be valid phone number (e.g., +1-234-567-8900)';
}

/// Tests for code snippets in docs/guides/common-recipes.mdx.
void main() {
  group('Docs /guides/common-recipes.mdx', () {
    test('email and password validation recipes work together', () {
      final emailSchema = Ack.string().email().notEmpty();
      final passwordSchema = Ack.string()
          .minLength(8)
          .matches(
            r'.*[A-Z].*',
            message: 'Password must contain an uppercase letter',
          )
          .matches(
            r'.*[a-z].*',
            message: 'Password must contain a lowercase letter',
          )
          .matches(r'.*[0-9].*', message: 'Password must contain a number');

      final loginSchema = Ack.object({
        'email': emailSchema,
        'password': passwordSchema,
      });

      expect(
        loginSchema.safeParse({
          'email': 'user@example.com',
          'password': 'SecurePass123',
        }).isOk,
        isTrue,
      );

      expect(
        loginSchema.safeParse({
          'email': 'user@example.com',
          'password': 'weak',
        }).isFail,
        isTrue,
      );
    });

    test('nested address validation handles optional billing address', () {
      final addressSchema = Ack.object({
        'street': Ack.string().notEmpty(),
        'city': Ack.string().notEmpty(),
        'zipCode': Ack.string().matches(r'^\d{5}(-\d{4})?$'),
        'country': Ack.string().notEmpty(),
      });

      final userWithAddressSchema = Ack.object({
        'name': Ack.string(),
        'email': Ack.string().email(),
        'shippingAddress': addressSchema,
        'billingAddress': addressSchema.optional().nullable(),
      });

      expect(
        userWithAddressSchema.safeParse({
          'name': 'John Doe',
          'email': 'john@example.com',
          'shippingAddress': {
            'street': '123 Main St',
            'city': 'Springfield',
            'zipCode': '12345',
            'country': 'USA',
          },
        }).isOk,
        isTrue,
      );
    });

    test('list validation recipes enforce cart constraints', () {
      final cartSchema = Ack.object({
        'userId': Ack.string(),
        'items': Ack.list(
          Ack.object({
            'productId': Ack.string(),
            'quantity': Ack.integer().positive(),
            'price': Ack.double().positive(),
          }),
        ).minLength(1).maxLength(50),
      });

      expect(
        cartSchema.safeParse({
          'userId': 'user-1',
          'items': [
            {'productId': 'p-1', 'quantity': 2, 'price': 19.99},
          ],
        }).isOk,
        isTrue,
      );

      final postSchema = Ack.object({
        'title': Ack.string().minLength(5).maxLength(100),
        'content': Ack.string().minLength(10),
        'tags': Ack.list(Ack.string()).maxLength(5),
      });

      expect(
        postSchema.safeParse({
          'title': 'Hello World',
          'content': 'This is a sample post with enough content.',
          'tags': ['dart', 'validation'],
        }).isOk,
        isTrue,
      );
    });

    test('enum validation recipe restricts status and priority', () {
      final orderSchema = Ack.object({
        'orderId': Ack.string(),
        'status': Ack.enumString([
          'pending',
          'processing',
          'shipped',
          'delivered',
          'cancelled',
        ]),
        'priority': Ack.enumString(['low', 'medium', 'high']),
      });

      expect(
        orderSchema.safeParse({
          'orderId': 'ORD-123',
          'status': 'shipped',
          'priority': 'high',
        }).isOk,
        isTrue,
      );

      expect(
        orderSchema.safeParse({
          'orderId': 'ORD-123',
          'status': 'unknown',
          'priority': 'low',
        }).isFail,
        isTrue,
      );
    });

    test(
      'custom validation recipes enforce phone and password confirmation',
      () {
        final registrationSchema =
            Ack.object({
              'username': Ack.string().minLength(3),
              'email': Ack.string().email(),
              'phone': Ack.string().constrain(CommonPhoneNumberConstraint()),
              'password': Ack.string().minLength(8),
              'confirmPassword': Ack.string().minLength(8),
            }).refine(
              (data) => data['password'] == data['confirmPassword'],
              message: 'Passwords do not match',
            );

        expect(
          registrationSchema.safeParse({
            'username': 'user123',
            'email': 'user@example.com',
            'phone': '+1-234-567-8900',
            'password': 'Password123',
            'confirmPassword': 'Password123',
          }).isOk,
          isTrue,
        );

        expect(
          registrationSchema.safeParse({
            'username': 'user123',
            'email': 'user@example.com',
            'phone': '+1-234-567-8900',
            'password': 'Password123',
            'confirmPassword': 'Mismatch',
          }).isFail,
          isTrue,
        );
      },
    );

    test('API response validation recipe handles GitHub example', () async {
      final githubUserSchema = Ack.object({
        'login': Ack.string(),
        'id': Ack.integer(),
        'avatar_url': Ack.string().url(),
        'name': Ack.string().nullable(),
        'email': Ack.string().email().nullable(),
        'bio': Ack.string().nullable(),
        'public_repos': Ack.integer(),
        'followers': Ack.integer(),
        'following': Ack.integer(),
        'created_at': Ack.string(),
      });

      final sampleResponse = jsonEncode({
        'login': 'octocat',
        'id': 1,
        'avatar_url': 'https://avatars.githubusercontent.com/u/1?v=4',
        'name': 'The Octocat',
        'email': null,
        'bio': 'Mascot',
        'public_repos': 2,
        'followers': 100,
        'following': 10,
        'created_at': '2011-01-25T18:44:36Z',
      });

      final json = jsonDecode(sampleResponse);
      final result = githubUserSchema.safeParse(json);
      expect(result.isOk, isTrue);
      final user = result.getOrThrow()!;
      expect(user['login'], equals('octocat'));
    });
  });
}
