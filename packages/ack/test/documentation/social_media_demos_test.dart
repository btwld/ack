import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Social Media Demo Tests', () {
    group('Demo 1: Transform Magic', () {
      test('should transform data with age calculation', () {
        final userSchema =
            Ack.object({
              'name': Ack.string(),
              'birthYear': Ack.integer().min(1900).max(2024),
            }).transform((data) {
              final age = DateTime.now().year - (data!['birthYear'] as int);
              return {...data, 'age': age};
            });

        final result =
            userSchema.parse({'name': 'John Doe', 'birthYear': 1990})
                as Map<String, dynamic>;

        expect(result['name'], equals('John Doe'));
        expect(result['birthYear'], equals(1990));
        expect(result['age'], equals(DateTime.now().year - 1990));
      });

      test('should validate birth year constraints', () {
        final userSchema =
            Ack.object({
              'name': Ack.string(),
              'birthYear': Ack.integer().min(1900).max(2024),
            }).transform((data) {
              final age = DateTime.now().year - (data!['birthYear'] as int);
              return {...data, 'age': age};
            });

        expect(
          () => userSchema.parse({'name': 'Time Traveler', 'birthYear': 2025}),
          throwsA(isA<AckException>()),
        );
      });
    });

    group('Demo 2: Custom Validation with refine()', () {
      test('should validate password confirmation', () {
        final signupSchema =
            Ack.object({
              'email': Ack.string().email(),
              'password': Ack.string().minLength(8),
              'confirmPassword': Ack.string().minLength(8),
            }).refine(
              (data) => data['password'] == data['confirmPassword'],
              message: 'Passwords do not match!',
            );

        // Valid case
        final validResult = signupSchema.safeParse({
          'email': 'user@example.com',
          'password': 'password123',
          'confirmPassword': 'password123',
        });
        expect(validResult.isOk, isTrue);

        // Invalid case - passwords don't match
        final invalidResult = signupSchema.safeParse({
          'email': 'user@example.com',
          'password': 'password123',
          'confirmPassword': 'password456',
        });
        expect(invalidResult.isFail, isTrue);
        expect(
          invalidResult.getError().message,
          contains('Passwords do not match!'),
        );
      });

      test('should validate order total calculation', () {
        final orderSchema =
            Ack.object({
              'items': Ack.list(
                Ack.object({'price': Ack.double(), 'quantity': Ack.integer()}),
              ),
              'total': Ack.double(),
            }).refine((order) {
              final calculated = (order['items'] as List).fold(
                0.0,
                (sum, item) => sum + item['price'] * item['quantity'],
              );
              return ((order['total'] as double) - calculated).abs() < 0.01;
            }, message: 'Total doesn\'t match item prices!');

        // Valid case
        final validOrder = orderSchema.safeParse({
          'items': [
            {'price': 10.00, 'quantity': 2},
            {'price': 5.50, 'quantity': 3},
          ],
          'total': 36.50,
        });
        expect(validOrder.isOk, isTrue);

        // Invalid case - wrong total
        final invalidOrder = orderSchema.safeParse({
          'items': [
            {'price': 10.00, 'quantity': 2},
            {'price': 5.50, 'quantity': 3},
          ],
          'total': 40.00,
        });
        expect(invalidOrder.isFail, isTrue);
        expect(
          invalidOrder.getError().message,
          contains('Total doesn\'t match item prices!'),
        );
      });
    });

    group('Demo 3: Flexible Union Types with anyOf()', () {
      test('should validate different payment methods', () {
        final paymentSchema = Ack.object({
          'amount': Ack.double().positive(),
          'method': Ack.anyOf([
            // Credit card
            Ack.object({
              'type': Ack.literal('card'),
              'number': Ack.string().matches(r'^\d{16}$'),
              'cvv': Ack.string().matches(r'^\d{3,4}$'),
            }),
            // PayPal email
            Ack.string().email(),
            // Crypto wallet
            Ack.object({
              'type': Ack.literal('crypto'),
              'wallet': Ack.string().matches(r'^0x[a-fA-F0-9]{40}$'),
              'network': Ack.enumString(['ETH', 'BTC', 'SOL']),
            }),
          ]),
        });

        // Test credit card payment
        final cardPayment = paymentSchema.safeParse({
          'amount': 99.99,
          'method': {
            'type': 'card',
            'number': '1234567812345678',
            'cvv': '123',
          },
        });
        expect(cardPayment.isOk, isTrue);

        // Test PayPal email payment
        final paypalPayment = paymentSchema.safeParse({
          'amount': 49.99,
          'method': 'user@paypal.com',
        });
        expect(paypalPayment.isOk, isTrue);

        // Test crypto payment
        final cryptoPayment = paymentSchema.safeParse({
          'amount': 150.00,
          'method': {
            'type': 'crypto',
            'wallet': '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8',
            'network': 'ETH',
          },
        });
        expect(cryptoPayment.isOk, isTrue);

        // Test invalid payment method
        final invalidPayment = paymentSchema.safeParse({
          'amount': 10.00,
          'method': 'cash', // Not a valid payment method
        });
        expect(invalidPayment.isFail, isTrue);
      });
    });

    group('Demo 4: Discriminated Unions', () {
      test('should validate different notification types', () {
        final notificationSchema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'email': Ack.object({
              'type': Ack.literal('email'),
              'to': Ack.string().email(),
              'subject': Ack.string(),
              'body': Ack.string(),
            }),
            'sms': Ack.object({
              'type': Ack.literal('sms'),
              'phone': Ack.string().matches(r'^\+\d{10,15}$'),
              'message': Ack.string().maxLength(160),
            }),
            'push': Ack.object({
              'type': Ack.literal('push'),
              'deviceId': Ack.string().uuid(),
              'title': Ack.string(),
              'body': Ack.string(),
              'badge': Ack.integer().optional(),
            }),
          },
        );

        // Test email notification
        final emailNotif = notificationSchema.safeParse({
          'type': 'email',
          'to': 'user@example.com',
          'subject': 'Hello!',
          'body': 'This is a test email.',
        });
        expect(emailNotif.isOk, isTrue);

        // Test SMS notification
        final smsNotif = notificationSchema.safeParse({
          'type': 'sms',
          'phone': '+12345678901',
          'message': 'Your OTP is 123456',
        });
        expect(smsNotif.isOk, isTrue);

        // Test push notification with optional badge
        final pushNotif = notificationSchema.safeParse({
          'type': 'push',
          'deviceId': '550e8400-e29b-41d4-a716-446655440000',
          'title': 'New Message',
          'body': 'You have a new message!',
          'badge': 5,
        });
        expect(pushNotif.isOk, isTrue);

        // Test push notification without badge (optional field)
        final pushNotifNoBadge = notificationSchema.safeParse({
          'type': 'push',
          'deviceId': '550e8400-e29b-41d4-a716-446655440000',
          'title': 'New Message',
          'body': 'You have a new message!',
        });
        expect(pushNotifNoBadge.isOk, isTrue);

        // Test invalid notification type
        final invalidNotif = notificationSchema.safeParse({
          'type': 'webhook',
          'url': 'https://example.com/webhook',
        });
        expect(invalidNotif.isFail, isTrue);
      });
    });

    group('Demo 5: Chain Everything Together', () {
      test('should validate and transform API responses', () {
        final apiResponseSchema =
            Ack.anyOf([
                  // Success response
                  Ack.object({
                    'status': Ack.literal('success'),
                    'data': Ack.any(),
                    'timestamp': Ack.string().datetime(),
                  }),
                  // Error response
                  Ack.object({
                    'status': Ack.literal('error'),
                    'code': Ack.integer().min(400).max(599),
                    'message': Ack.string(),
                  }),
                ])
                .transform((response) {
                  // Add request ID for tracking
                  return {
                    ...response as Map<String, dynamic>,
                    'requestId':
                        'test-request-id-${DateTime.now().millisecondsSinceEpoch}',
                  };
                })
                .refine(
                  (response) =>
                      response['timestamp'] != null ||
                      response['status'] == 'error',
                  message: 'Success responses must have timestamp!',
                );

        // Test success response
        final successResponse = apiResponseSchema.safeParse({
          'status': 'success',
          'data': {'userId': 123, 'name': 'John'},
          'timestamp': '2024-01-15T10:30:00Z',
        });
        expect(successResponse.isOk, isTrue);
        final successData =
            successResponse.getOrThrow() as Map<String, dynamic>;
        expect(successData['requestId'], isNotNull);
        expect(successData['requestId'], startsWith('test-request-id-'));

        // Test error response (no timestamp required)
        final errorResponse = apiResponseSchema.safeParse({
          'status': 'error',
          'code': 404,
          'message': 'Resource not found',
        });
        expect(errorResponse.isOk, isTrue);
        final errorData = errorResponse.getOrThrow() as Map<String, dynamic>;
        expect(errorData['requestId'], isNotNull);

        // Test invalid success response (missing timestamp)
        final invalidSuccess = apiResponseSchema.safeParse({
          'status': 'success',
          'data': {'userId': 123},
          // Missing timestamp!
        });
        expect(invalidSuccess.isFail, isTrue);

        // Test invalid error code
        final invalidError = apiResponseSchema.safeParse({
          'status': 'error',
          'code': 200, // Not in 400-599 range
          'message': 'This should fail',
        });
        expect(invalidError.isFail, isTrue);
      });
    });
  });
}
