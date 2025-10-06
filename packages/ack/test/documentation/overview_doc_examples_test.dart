import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Tests for code snippets in docs/index.mdx (Overview page).
void main() {
  group('Docs /index.mdx (Overview)', () {
    test('basic usage example validates a user map', () {
      final userSchema = Ack.object({
        'name': Ack.string().minLength(2).maxLength(50),
        'age': Ack.integer().min(0).max(120),
        'email': Ack.string().email().nullable(),
      });

      final dataToValidate = {
        'name': 'John',
        'age': 30,
        'email': 'john@example.com',
      };

      final result = userSchema.safeParse(dataToValidate);
      expect(result.isOk, isTrue);
      final validData = result.getOrThrow()!;
      expect(validData, equals(dataToValidate));

      final nullEmailResult = userSchema.safeParse({
        'name': 'Jane',
        'age': 27,
        'email': null,
      });
      expect(nullEmailResult.isOk, isTrue);

      final invalidAgeResult = userSchema.safeParse({
        'name': 'Short',
        'age': -1,
        'email': 'short@example.com',
      });
      expect(invalidAgeResult.isFail, isTrue);
    });

    test('nested order schema validates items and totals', () {
      final orderSchema = Ack.object({
        'id': Ack.string().uuid(),
        'customer': Ack.object({
          'name': Ack.string().minLength(2),
          'email': Ack.string().email(),
        }),
        'items': Ack.list(
          Ack.object({
            'product': Ack.string(),
            'quantity': Ack.integer().positive(),
            'price': Ack.double().positive(),
          }),
        ).minLength(1),
        'total': Ack.double().positive(),
      });

      final validOrder = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'customer': {'name': 'Alice', 'email': 'alice@example.com'},
        'items': [
          {'product': 'Widget', 'quantity': 2, 'price': 19.99},
          {'product': 'Gadget', 'quantity': 1, 'price': 9.50},
        ],
        'total': 49.48,
      };

      final result = orderSchema.safeParse(validOrder);
      expect(result.isOk, isTrue);
      expect(result.getOrThrow(), isNotNull);

      final invalidItems = {
        ...validOrder,
        'items': [
          {'product': 'Widget', 'quantity': 0, 'price': 19.99},
        ],
      };
      expect(orderSchema.safeParse(invalidItems).isFail, isTrue);
    });

    test('refine example enforces calculated totals', () {
      final orderSchema = Ack.object({
        'id': Ack.string().uuid(),
        'customer': Ack.object({
          'name': Ack.string().minLength(2),
          'email': Ack.string().email(),
        }),
        'items': Ack.list(
          Ack.object({
            'product': Ack.string(),
            'quantity': Ack.integer().positive(),
            'price': Ack.double().positive(),
          }),
        ).minLength(1),
        'total': Ack.double().positive(),
      });

      final validatedOrder = orderSchema.refine((order) {
        final items = order['items'] as List;
        final calculatedTotal = items.fold<double>(0, (sum, item) {
          final itemMap = item as Map<String, Object?>;
          final quantity = itemMap['quantity'] as int;
          final price = itemMap['price'] as double;
          return sum + (quantity * price);
        });
        final total = order['total'] as double;
        return (calculatedTotal - total).abs() < 0.01;
      }, message: 'Total must match sum of item prices');

      final validOrder = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'customer': {'name': 'Alice', 'email': 'alice@example.com'},
        'items': [
          {'product': 'Widget', 'quantity': 2, 'price': 19.99},
          {'product': 'Gadget', 'quantity': 1, 'price': 9.50},
        ],
        'total': 49.48,
      };

      expect(validatedOrder.safeParse(validOrder).isOk, isTrue);

      final invalidOrder = {...validOrder, 'total': 40.00};
      final invalidResult = validatedOrder.safeParse(invalidOrder);
      expect(invalidResult.isFail, isTrue);
      expect(
        invalidResult.getError().message,
        contains('Total must match sum of item prices'),
      );
    });

    test('union examples accept multiple data shapes', () {
      final stringOrNumber = Ack.anyOf([
        Ack.string().strictParsing(),
        Ack.integer(),
      ]);

      expect(stringOrNumber.safeParse('hello').isOk, isTrue);
      expect(stringOrNumber.safeParse(42).isOk, isTrue);
      expect(stringOrNumber.safeParse(true).isFail, isTrue);

      final shapeSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'circle': Ack.object({
            'type': Ack.literal('circle'),
            'radius': Ack.double().positive(),
          }),
          'rectangle': Ack.object({
            'type': Ack.literal('rectangle'),
            'width': Ack.double().positive(),
            'height': Ack.double().positive(),
          }),
        },
      );

      expect(
        shapeSchema.safeParse({'type': 'circle', 'radius': 5.0}).isOk,
        isTrue,
      );

      expect(
        shapeSchema.safeParse({
          'type': 'rectangle',
          'width': 10.0,
          'height': 4.0,
        }).isOk,
        isTrue,
      );

      expect(
        shapeSchema.safeParse({'type': 'triangle', 'side': 3}).isFail,
        isTrue,
      );
    });

    test('transformation example adds derived age field', () {
      final personSchema =
          Ack.object({
            'name': Ack.string(),
            'birthYear': Ack.integer(),
          }).transform((data) {
            final birthYear = data!['birthYear'] as int;
            final age = DateTime.now().year - birthYear;
            return {...data, 'age': age};
          });

      final result = personSchema.safeParse({
        'name': 'Taylor',
        'birthYear': DateTime.now().year - 25,
      });

      expect(result.isOk, isTrue);
      final transformed = result.getOrThrow() as Map<String, Object?>;
      expect(transformed['age'], equals(25));
    });

    test('json schema generation example matches expectations', () {
      final orderSchema = Ack.object({
        'id': Ack.string().uuid(),
        'customer': Ack.object({
          'name': Ack.string().minLength(2),
          'email': Ack.string().email(),
        }),
        'items': Ack.list(
          Ack.object({
            'product': Ack.string(),
            'quantity': Ack.integer().positive(),
            'price': Ack.double().positive(),
          }),
        ).minLength(1),
        'total': Ack.double().positive(),
      });

      final jsonSchema = orderSchema.toJsonSchema();
      expect(jsonSchema['type'], equals('object'));
      expect(jsonSchema['properties'], isA<Map<String, Object?>>());
      expect(
        jsonSchema['required'],
        containsAll(['id', 'customer', 'items', 'total']),
      );

      final encoded = jsonEncode(jsonSchema);
      expect(encoded, contains('"type":"object"'));
    });
  });
}
