import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('@Schemable schema provider resolution', () {
    test('uses same-file provider registrations', () async {
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

  const Invoice({required this.total});
}
''',
        },
        outputs: {
          'test_pkg|lib/invoice.g.dart': decodedMatches(
            contains(
              "'total': (const MoneySchemaProvider().schema as AckSchema)",
            ),
          ),
        },
      );
    });

    test('uses unprefixed imported provider registrations', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/money.dart': '''
class Money {
  final int cents;
  const Money(this.cents);
}
''',
          'test_pkg|lib/money_provider.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'money.dart';

class MoneySchemaProvider implements SchemaProvider<Money> {
  const MoneySchemaProvider();

  @override
  AckSchema<Money> get schema => Ack.object({
    'cents': Ack.integer(),
  }).transform((value) => Money(value!['cents'] as int));
}
''',
          'test_pkg|lib/invoice.dart': '''
import 'package:ack_annotations/ack_annotations.dart';
import 'money.dart';
import 'money_provider.dart';

@Schemable(useProviders: const [MoneySchemaProvider])
class Invoice {
  final Money total;

  const Invoice({required this.total});
}
''',
        },
        outputs: {
          'test_pkg|lib/invoice.g.dart': decodedMatches(
            contains(
              "'total': (const MoneySchemaProvider().schema as AckSchema)",
            ),
          ),
        },
      );
    });

    test('uses prefixed imported provider registrations', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/money.dart': '''
class Money {
  final int cents;
  const Money(this.cents);
}
''',
          'test_pkg|lib/money_provider.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';
import 'money.dart';

class MoneySchemaProvider implements SchemaProvider<Money> {
  const MoneySchemaProvider();

  @override
  AckSchema<Money> get schema => Ack.object({
    'cents': Ack.integer(),
  }).transform((value) => Money(value!['cents'] as int));
}
''',
          'test_pkg|lib/invoice.dart': '''
import 'package:ack_annotations/ack_annotations.dart';
import 'money.dart';
import 'money_provider.dart' as money;

@Schemable(useProviders: const [money.MoneySchemaProvider])
class Invoice {
  final Money total;

  const Invoice({required this.total});
}
''',
        },
        outputs: {
          'test_pkg|lib/invoice.g.dart': decodedMatches(
            contains(
              "'total': (const money.MoneySchemaProvider().schema as AckSchema)",
            ),
          ),
        },
      );
    });
  });
}
