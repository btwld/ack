import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('Description generation', () {
    test(
      'uses class descriptions and parameter @Description annotations',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(description: 'User payload for public APIs')
class User {
  final String id;
  final String email;
  final String? displayName;

  const User({
    @Description('Public user identifier') required this.id,
    @Description('Primary email address') required this.email,
    this.displayName,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/test.g.dart': decodedMatches(
              allOf([
                contains('/// Generated schema for User'),
                contains('/// User payload for public APIs'),
                contains('Public user identifier'),
                contains('Primary email address'),
                contains('.describe('),
              ]),
            ),
          },
        );
      },
    );

    test(
      'falls back to class doc comments when description is omitted',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/test.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

/// Audit event payload used by internal tooling.
@Schemable()
class AuditEvent {
  final String id;

  const AuditEvent({required this.id});
}
''',
          },
          outputs: {
            'test_pkg|lib/test.g.dart': decodedMatches(
              allOf([
                contains('/// Generated schema for AuditEvent'),
                contains('/// Audit event payload used by internal tooling.'),
              ]),
            ),
          },
        );
      },
    );

    test('escapes special characters in descriptions safely', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/test.dart': r'''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(description: 'Model with "quotes" and \\slashes\\')
class PriceTag {
  final int amount;

  const PriceTag({
    @Description('Price is \$100 "fixed"')
    required this.amount,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/test.g.dart': decodedMatches(
            allOf([
              contains('Model with "quotes" and \\slashes\\'),
              contains(r'Price is \$100 "fixed"'),
              contains('priceTagSchema'),
            ]),
          ),
        },
      );
    });
  });
}
