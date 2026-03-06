import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('Schemable constructor contract', () {
    test('maps required, nullable, and defaulted named parameters', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/retry_policy.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable()
class RetryPolicy {
  final String name;
  final String? alias;
  final String? nickname;
  final int retries;

  const RetryPolicy({
    required this.name,
    required this.alias,
    this.nickname,
    this.retries = 3,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/retry_policy.g.dart': decodedMatches(
            allOf([
              contains("'name': Ack.string()"),
              contains("'alias': Ack.string().nullable()"),
              contains("'nickname': Ack.string().optional().nullable()"),
              contains("'retries': Ack.integer().optional()"),
            ]),
          ),
        },
      );
    });

    test('applies caseStyle and SchemaKey overrides from parameters', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/api_payload.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(caseStyle: CaseStyle.snakeCase)
class ApiPayload {
  final String userId;
  final String createdAt;
  final String? fullName;

  const ApiPayload({
    required this.userId,
    @SchemaKey('created-at') required this.createdAt,
    this.fullName,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/api_payload.g.dart': decodedMatches(
            allOf([
              contains("'user_id': Ack.string()"),
              contains("'created-at': Ack.string()"),
              contains("'full_name': Ack.string().optional().nullable()"),
            ]),
          ),
        },
      );
    });

    test('supports parameter descriptions and decorator constraints', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/signup.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(description: 'Public signup payload')
class Signup {
  final String email;
  final String? displayName;
  final int age;

  const Signup({
    @Description('Primary email address')
    @Email()
    required this.email,
    @Description('Display name shown in profiles')
    @MinLength(3)
    @MaxLength(20)
    this.displayName,
    @Min(13)
    @Max(120)
    required this.age,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/signup.g.dart': decodedMatches(
            allOf([
              contains('/// Public signup payload'),
              contains(
                "'email': Ack.string().email().describe('Primary email address')",
              ),
              contains('.minLength(3)'),
              contains('.maxLength(20)'),
              contains('.optional()'),
              contains('.nullable()'),
              contains('Display name shown in profiles'),
              contains("'age': Ack.integer().min(13).max(120)"),
            ]),
          ),
        },
      );
    });

    test(
      'supports explicit custom providers for custom and collection types',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/invoice.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Money {
  final int cents;
  const Money(this.cents);
}

class MoneySchemaProvider implements SchemaProvider<Money> {
  const MoneySchemaProvider();

  @override
  AckSchema<Money> get schema => Ack.object({
    'cents': Ack.integer(),
  }).transform((value) => Money(value!['cents'] as int));
}

@Schemable(useProviders: const [MoneySchemaProvider])
class Invoice {
  final Money total;
  final List<Money> lineItems;

  const Invoice({
    required this.total,
    required this.lineItems,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/invoice.g.dart': decodedMatches(
              allOf([
                contains(
                  "'total': (const MoneySchemaProvider().schema as AckSchema)",
                ),
                contains(
                  "'lineItems': Ack.list((const MoneySchemaProvider().schema as AckSchema))",
                ),
              ]),
            ),
          },
        );
      },
    );

    test('fails when useProviders contains an abstract provider', () async {
      final builder = ackGenerator(BuilderOptions.empty);
      var sawExpectedError = false;

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/invoice.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Money {
  final int cents;
  const Money(this.cents);
}

abstract class MoneySchemaProvider implements SchemaProvider<Money> {
  const MoneySchemaProvider();

  @override
  AckSchema<Money> get schema;
}

@Schemable(useProviders: const [MoneySchemaProvider])
class Invoice {
  final Money total;

  const Invoice({required this.total});
}
''',
        },
        outputs: const {},
        onLog: (log) {
          if (log.level.name == 'SEVERE' &&
              log.message.contains(
                'must be a concrete class and cannot be abstract',
              )) {
            sawExpectedError = true;
          }
        },
      );

      expect(sawExpectedError, isTrue);
    });

    test('fails with a helpful error for unresolved custom types', () async {
      final builder = ackGenerator(BuilderOptions.empty);
      var sawExpectedError = false;

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/secret_doc.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

class SecretToken {
  const SecretToken();
}

@Schemable()
class SecretDoc {
  final SecretToken token;

  const SecretDoc({required this.token});
}
''',
        },
        outputs: const {},
        onLog: (log) {
          if (log.level.name == 'SEVERE' &&
              log.message.contains('Unsupported type "SecretToken"') &&
              log.message.contains(
                'Annotate the type with @Schemable() or register a schema provider',
              )) {
            sawExpectedError = true;
          }
        },
      );

      expect(sawExpectedError, isTrue);
    });
  });
}
