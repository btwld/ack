import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Tests for code snippets in docs/core-concepts/schemas.mdx.
void main() {
  group('Docs /core-concepts/schemas.mdx', () {
    test('overview example validates user schema', () {
      final userSchema = Ack.object({
        'name': Ack.string().minLength(2),
        'age': Ack.integer().min(0),
        'email': Ack.string().email(),
      });

      final result = userSchema.safeParse({
        'name': 'John',
        'age': 30,
        'email': 'john@example.com',
      });

      expect(result.isOk, isTrue);
      expect(result.getOrThrow()!['name'], equals('John'));
    });

    group('String schema examples', () {
      test('supports constraints and formats', () {
        final nameSchema = Ack.string();
        expect(nameSchema.parse('Hello'), equals('Hello'));

        final usernameSchema = Ack.string()
            .minLength(3)
            .maxLength(20)
            .matches(r'^[a-zA-Z0-9_]+$');
        expect(usernameSchema.safeParse('user_123').isOk, isTrue);
        expect(usernameSchema.safeParse('u').isFail, isTrue);

        final emailSchema = Ack.string().email();
        expect(emailSchema.safeParse('valid@example.com').isOk, isTrue);
        expect(emailSchema.safeParse('invalid-email').isFail, isTrue);

        final websiteSchema = Ack.string().url();
        expect(websiteSchema.safeParse('https://example.com').isOk, isTrue);

        final dateSchema = Ack.string().date();
        expect(dateSchema.safeParse('2024-01-01').isOk, isTrue);
        expect(dateSchema.safeParse('01-01-2024').isFail, isTrue);

        final datetimeSchema = Ack.string().datetime();
        expect(datetimeSchema.safeParse('2024-01-01T12:00:00Z').isOk, isTrue);

        final roleSchema = Ack.string().enumString(['admin', 'user', 'guest']);
        expect(roleSchema.safeParse('user').isOk, isTrue);
        expect(roleSchema.safeParse('unknown').isFail, isTrue);
      });
    });

    group('Number schema examples', () {
      test('enforces ranges and positivity', () {
        final ageSchema = Ack.integer().min(0).max(120);
        expect(ageSchema.safeParse(42).isOk, isTrue);
        expect(ageSchema.safeParse(-1).isFail, isTrue);

        final priceSchema = Ack.double().positive().multipleOf(0.5);
        expect(priceSchema.safeParse(19.5).isOk, isTrue);
        expect(priceSchema.safeParse(-5.0).isFail, isTrue);

        final scoreSchema = Ack.double().positive();
        final debtSchema = Ack.double().negative();
        expect(scoreSchema.safeParse(1.5).isOk, isTrue);
        expect(debtSchema.safeParse(-100.0).isOk, isTrue);
        expect(debtSchema.safeParse(10.0).isFail, isTrue);
      });
    });

    test('boolean schema example accepts true/false', () {
      final isActiveSchema = Ack.boolean();
      expect(isActiveSchema.safeParse(true).isOk, isTrue);
      expect(isActiveSchema.safeParse(false).isOk, isTrue);
      expect(isActiveSchema.safeParse('not bool').isFail, isTrue);
    });

    group('List schema examples', () {
      test('validates lists of primitives and objects', () {
        final tagsSchema = Ack.list(Ack.string());
        expect(tagsSchema.safeParse(['news', 'tech']).isOk, isTrue);

        final itemsSchema = Ack.list(
          Ack.string(),
        ).minLength(1).maxLength(3).unique();
        expect(itemsSchema.safeParse(['a', 'b']).isOk, isTrue);
        expect(itemsSchema.safeParse([]).isFail, isTrue);

        final usersSchema = Ack.list(
          Ack.object({'id': Ack.integer(), 'name': Ack.string()}),
        );
        expect(
          usersSchema.safeParse([
            {'id': 1, 'name': 'Jane'},
          ]).isOk,
          isTrue,
        );
      });
    });

    group('Object schema examples', () {
      test('handles nested objects and access', () {
        final userSchema = Ack.object({
          'name': Ack.string(),
          'address': Ack.object({
            'street': Ack.string(),
            'city': Ack.string(),
            'zipCode': Ack.string().matches(r'^\d{5}$'),
          }),
        });

        final result = userSchema.safeParse({
          'name': 'Jane',
          'address': {
            'street': '123 Main St',
            'city': 'Springfield',
            'zipCode': '12345',
          },
        });

        expect(result.isOk, isTrue);
        final data = result.getOrThrow()!;
        final address = data['address'] as Map<String, Object?>;
        expect(address['city'], equals('Springfield'));
      });
    });

    group('Union type examples', () {
      test('anyOf accepts strings or integers', () {
        final idSchema = Ack.anyOf([
          Ack.string().strictParsing(),
          Ack.integer(),
        ]);
        expect(idSchema.safeParse('A123').isOk, isTrue);
        expect(idSchema.safeParse(99).isOk, isTrue);
        expect(idSchema.safeParse(true).isFail, isTrue);
      });

      test('discriminated union validates polymorphic data', () {
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
          shapeSchema.safeParse({'type': 'circle', 'radius': 3.5}).isOk,
          isTrue,
        );
        expect(
          shapeSchema.safeParse({
            'type': 'rectangle',
            'width': 4.0,
            'height': 2.0,
          }).isOk,
          isTrue,
        );
        expect(
          shapeSchema.safeParse({'type': 'triangle', 'side': 3}).isFail,
          isTrue,
        );
      });
    });

    test('any schema accepts arbitrary metadata', () {
      final flexibleSchema = Ack.object({
        'id': Ack.string(),
        'metadata': Ack.any(),
      });

      final result = flexibleSchema.safeParse({
        'id': '42',
        'metadata': {'key': 'value'},
      });
      expect(result.isOk, isTrue);
    });

    group('Optional vs nullable semantics', () {
      test('nullable requires presence but allows null', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'middleName': Ack.string().nullable(),
        });

        expect(
          schema.safeParse({'name': 'John', 'middleName': null}).isOk,
          isTrue,
        );
        expect(
          schema.safeParse({'name': 'John', 'middleName': 'Robert'}).isOk,
          isTrue,
        );
        expect(schema.safeParse({'name': 'John'}).isFail, isTrue);
      });

      test('optional allows omission but not null without nullable', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().optional(),
        });

        expect(schema.safeParse({'name': 'John'}).isOk, isTrue);
        expect(schema.safeParse({'name': 'John', 'age': 30}).isOk, isTrue);
        expect(schema.safeParse({'name': 'John', 'age': null}).isFail, isTrue);
      });

      test('optional + nullable allows omission or null', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'bio': Ack.string().optional().nullable(),
        });

        expect(schema.safeParse({'name': 'John'}).isOk, isTrue);
        expect(schema.safeParse({'name': 'John', 'bio': null}).isOk, isTrue);
        expect(
          schema.safeParse({'name': 'John', 'bio': 'Developer'}).isOk,
          isTrue,
        );
      });
    });

    group('Object schema operations', () {
      test('extend adds and overrides properties', () {
        final baseSchema = Ack.object({
          'id': Ack.string(),
          'name': Ack.string(),
        });

        final extendedSchema = baseSchema.extend({
          'email': Ack.string().email(),
          'role': Ack.literal('admin'),
        });

        final modifiedSchema = baseSchema.extend({
          'name': Ack.string().optional(),
        });

        expect(
          extendedSchema.safeParse({
            'id': '1',
            'name': 'Admin',
            'email': 'admin@example.com',
            'role': 'admin',
          }).isOk,
          isTrue,
        );

        expect(modifiedSchema.safeParse({'id': '1'}).isOk, isTrue);
      });

      test('pick and omit adjust visible properties', () {
        final fullSchema = Ack.object({
          'id': Ack.string(),
          'name': Ack.string(),
          'email': Ack.string().email(),
          'password': Ack.string(),
          'createdAt': Ack.string().datetime(),
        });

        final publicSchema = fullSchema.pick(['id', 'name', 'email']);
        final safeSchema = fullSchema.omit(['password']);

        expect(
          publicSchema.safeParse({
            'id': '1',
            'name': 'Jane',
            'email': 'jane@example.com',
          }).isOk,
          isTrue,
        );

        expect(
          safeSchema.safeParse({
            'id': '1',
            'name': 'Jane',
            'email': 'jane@example.com',
            'createdAt': '2024-01-01T00:00:00Z',
          }).isOk,
          isTrue,
        );

        expect(
          publicSchema.safeParse({
            'id': '1',
            'name': 'Jane',
            'email': 'jane@example.com',
            'password': 'secret',
          }).isFail,
          isTrue,
        );
      });

      test('partial makes all properties optional', () {
        final userSchema = Ack.object({
          'name': Ack.string(),
          'email': Ack.string().email(),
          'age': Ack.integer(),
        });

        final partialSchema = userSchema.partial();
        expect(partialSchema.safeParse({}).isOk, isTrue);
        expect(partialSchema.safeParse({'name': 'Jane'}).isOk, isTrue);
        expect(
          partialSchema.safeParse({
            'email': 'jane@example.com',
            'age': 30,
          }).isOk,
          isTrue,
        );
      });

      test('additional properties control extra keys', () {
        final baseSchema = Ack.object({'id': Ack.string()});

        final flexible = baseSchema.passthrough();
        final strict = baseSchema.strict();

        expect(
          flexible.safeParse({'id': '1', 'extra': 'allowed'}).isOk,
          isTrue,
        );
        expect(strict.safeParse({'id': '1', 'extra': 'nope'}).isFail, isTrue);
      });
    });

    group('Custom validation and transformations', () {
      test('refine enforces password confirmation and totals', () {
        final passwordSchema =
            Ack.object({
              'password': Ack.string().minLength(8),
              'confirmPassword': Ack.string(),
            }).refine(
              (data) => data['password'] == data['confirmPassword'],
              message: 'Passwords must match',
            );

        expect(
          passwordSchema.safeParse({
            'password': 'pass1234',
            'confirmPassword': 'pass1234',
          }).isOk,
          isTrue,
        );
        expect(
          passwordSchema.safeParse({
            'password': 'pass1234',
            'confirmPassword': 'different',
          }).isFail,
          isTrue,
        );

        final orderSchema =
            Ack.object({
              'items': Ack.list(
                Ack.object({'price': Ack.double(), 'quantity': Ack.integer()}),
              ),
              'total': Ack.double(),
            }).refine((order) {
              final items = order['items'] as List;
              final calculated = items.fold<double>(0, (sum, item) {
                final itemMap = item as Map<String, Object?>;
                return sum +
                    (itemMap['price'] as double) * (itemMap['quantity'] as int);
              });
              final total = order['total'] as double;
              return (calculated - total).abs() < 0.01;
            }, message: 'Total must match sum of items');

        expect(
          orderSchema.safeParse({
            'items': [
              {'price': 10.0, 'quantity': 2},
              {'price': 5.5, 'quantity': 1},
            ],
            'total': 25.5,
          }).isOk,
          isTrue,
        );
        expect(
          orderSchema.safeParse({
            'items': [
              {'price': 10.0, 'quantity': 2},
            ],
            'total': 100.0,
          }).isFail,
          isTrue,
        );
      });

      test('transform examples adjust output data', () {
        final upperSchema = Ack.string().transform(
          (s) => s?.toUpperCase() ?? '',
        );
        expect(upperSchema.safeParse('hello').getOrThrow(), equals('HELLO'));

        final userWithAgeSchema =
            Ack.object({
              'name': Ack.string(),
              'birthYear': Ack.integer(),
            }).transform((data) {
              final birthYear = data!['birthYear'] as int;
              final age = DateTime.now().year - birthYear;
              return {...data, 'age': age};
            });

        final transformed =
            userWithAgeSchema.safeParse({
                  'name': 'Alex',
                  'birthYear': DateTime.now().year - 30,
                }).getOrThrow()
                as Map<String, Object?>;
        expect(transformed['age'], equals(30));

        final dateSchema = Ack.string()
            .matches(r'^\d{4}-\d{2}-\d{2}$')
            .transform<DateTime>((s) => DateTime.parse(s!));
        final parsedDate =
            dateSchema.safeParse('2024-01-01').getOrThrow() as DateTime;
        expect(parsedDate.year, equals(2024));
      });
    });
  });
}
