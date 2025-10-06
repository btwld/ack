import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Complex Schema Integration', () {
    test('should handle all features in a real-world schema', () {
      // E-commerce order schema with all features
      final addressSchema = Ack.object({
        'street': Ack.string(),
        'city': Ack.string(),
        'country': Ack.string(),
        'postalCode': Ack.string().matches(r'^\d{5}(-\d{4})?$'),
      });

      final productSchema =
          Ack.object({
            'id': Ack.string().uuid(),
            'name': Ack.string(),
            'price': Ack.double().positive(),
            'quantity': Ack.integer().positive(),
          }).transform<Map<String, Object?>>((product) {
            return {
              ...product!,
              'total':
                  (product['price'] as double) * (product['quantity'] as int),
            };
          });

      final paymentSchema = Ack.discriminated(
        discriminatorKey: 'method',
        schemas: {
          'card': Ack.object({
            'method': Ack.literal('card'),
            'last4': Ack.string().matches(r'^\d{4}$'),
            'brand': Ack.enumString(['visa', 'mastercard', 'amex']),
          }),
          'paypal': Ack.object({
            'method': Ack.literal('paypal'),
            'email': Ack.string().email(),
          }),
        },
      );

      final orderSchema =
          Ack.object({
                'orderId': Ack.string().uuid(),
                'customer': Ack.object({
                  'email': Ack.string().email(),
                  'name': Ack.string(),
                }),
                'items': Ack.list(productSchema).minItems(1),
                'shippingAddress': addressSchema,
                'billingAddress': addressSchema.partial(), // Optional fields
                'payment': paymentSchema,
                'notes': Ack.string().optional(),
              })
              .strict() // No additional properties
              .refine((order) {
                // Custom validation: total must be positive
                final items = order['items'] as List;
                final total = items.fold<double>(
                  0,
                  (sum, item) => sum + (item as Map)['total'],
                );
                return total > 0;
              }, message: 'Order total must be positive')
              .transform<Map<String, Object?>>((order) {
                // Calculate order summary
                final items = order!['items'] as List;
                final subtotal = items.fold<double>(
                  0,
                  (sum, item) => sum + (item as Map)['total'],
                );
                final tax = subtotal * 0.08;
                final shipping = items.length > 5 ? 0 : 10.0;

                return {
                  ...order,
                  'summary': {
                    'subtotal': subtotal,
                    'tax': tax,
                    'shipping': shipping,
                    'total': subtotal + tax + shipping,
                  },
                  'processedAt': DateTime.now().toIso8601String(),
                };
              });

      // Test with valid order
      final order = orderSchema.parse({
        'orderId': '550e8400-e29b-41d4-a716-446655440000',
        'customer': {'email': 'customer@example.com', 'name': 'John Doe'},
        'items': [
          {
            'id': '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
            'name': 'Widget',
            'price': 29.99,
            'quantity': 2,
          },
          {
            'id': '6ba7b814-9dad-11d1-80b4-00c04fd430c8',
            'name': 'Gadget',
            'price': 49.99,
            'quantity': 1,
          },
        ],
        'shippingAddress': {
          'street': '123 Main St',
          'city': 'Anytown',
          'country': 'USA',
          'postalCode': '12345',
        },
        'billingAddress': {
          'street': '456 Oak Ave',
          'city': 'Somewhere',
          'country': 'USA',
          'postalCode': '67890',
        },
        'payment': {'method': 'card', 'last4': '1234', 'brand': 'visa'},
      });

      expect(order!['summary'] as Map, isNotNull);
      final summary = order['summary'] as Map;
      expect(summary['subtotal'], equals(109.97));
      expect(summary['total'], greaterThan(100));
      expect(order.containsKey('processedAt'), isTrue);
    });

    test('should handle edge cases in feature interactions', () {
      // Nested transformations with partial schemas
      final schema =
          Ack.object({
                'data': Ack.object({
                  'value': Ack.string(),
                  'metadata': Ack.object({
                    'created': Ack.string().datetime(),
                    'tags': Ack.list(Ack.string()),
                  }),
                }),
              })
              .partial() // Make all fields optional
              .transform<Map<String, Object?>>((obj) {
                // Handle missing data gracefully
                final data = obj!['data'] as Map<String, Object?>?;
                return {
                  'hasData': data != null,
                  'value': data?['value'] ?? 'default',
                  'tagCount': (data?['metadata'] as Map?)?['tags'] != null
                      ? ((data!['metadata'] as Map)['tags'] as List).length
                      : 0,
                };
              });

      // Test with full data
      expect(
        schema.parse({
          'data': {
            'value': 'test',
            'metadata': {
              'created': '2024-01-01T00:00:00Z',
              'tags': ['a', 'b', 'c'],
            },
          },
        }),
        equals({'hasData': true, 'value': 'test', 'tagCount': 3}),
      );

      // Test with missing data
      expect(
        schema.parse(<String, Object?>{}),
        equals({'hasData': false, 'value': 'default', 'tagCount': 0}),
      );
    });

    test('should propagate validation errors correctly across features', () {
      final schema =
          Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {
              'user': Ack.object({
                'type': Ack.literal('user'),
                'profile': Ack.object({'age': Ack.integer().min(18)}),
              }),
            },
          ).transform<Map<String, Object?>>((data) => data!).refine((data) {
            final profile = data['profile'] as Map;
            return (profile['age'] as int) < 100;
          }, message: 'Age too high');

      // Test validation at different levels
      try {
        schema.parse({
          'type': 'user',
          'profile': {'age': 150},
        });
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<AckException>());
        final errors = (e as AckException).errors;
        expect(
          errors.any((err) => err.message.contains('Age too high')),
          isTrue,
        );
      }
    });
  });
}
