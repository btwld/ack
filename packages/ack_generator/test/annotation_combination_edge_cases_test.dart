import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('Schemable edge cases', () {
    test(
      'supports additionalProperties with constructor-driven models',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/flexible_user.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(
  schemaName: 'FlexibleUserSchema',
  description: 'A flexible user model with additional properties',
  caseStyle: CaseStyle.snakeCase,
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class FlexibleUser {
  final String fullName;
  final int age;
  final Map<String, dynamic> metadata;

  const FlexibleUser({
    required this.fullName,
    required this.age,
    required this.metadata,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/flexible_user.g.dart': decodedMatches(
              allOf([
                contains('final flexibleUserSchema = Ack.object({'),
                contains("'full_name': Ack.string()"),
                contains("'age': Ack.integer()"),
                isNot(contains("'metadata':")),
                contains('}, additionalProperties: true)'),
              ]),
            ),
          },
        );
      },
    );

    test(
      'requires sealed discriminated roots and emits subtype schemas',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/notifications.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable(discriminatorKey: 'type')
sealed class Notification {
  final String message;

  const Notification({required this.message});
}

@Schemable(discriminatorValue: 'email')
class EmailNotification extends Notification {
  final String recipient;

  const EmailNotification({
    required super.message,
    required this.recipient,
  });
}

@Schemable(discriminatorValue: 'sms')
class SmsNotification extends Notification {
  final String phoneNumber;

  const SmsNotification({
    required super.message,
    required this.phoneNumber,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/notifications.g.dart': decodedMatches(
              allOf([
                contains('final notificationSchema = Ack.discriminated('),
                contains("discriminatorKey: 'type'"),
                contains("'email': emailNotificationSchema"),
                contains("'sms': smsNotificationSchema"),
                contains("'type': Ack.literal('email')"),
                contains("'type': Ack.literal('sms')"),
              ]),
            ),
          },
        );
      },
    );

    test(
      'uses @SchemaConstructor when the unnamed constructor is not the contract',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/selected_constructor.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable()
class SelectedConstructor {
  final String id;
  final String? nickname;

  const SelectedConstructor._(this.id, this.nickname);

  @SchemaConstructor()
  const SelectedConstructor.fromApi({
    required this.id,
    this.nickname,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/selected_constructor.g.dart': decodedMatches(
              allOf([
                contains("'id': Ack.string()"),
                contains("'nickname': Ack.string().optional().nullable()"),
              ]),
            ),
          },
        );
      },
    );

    test(
      'fails when the selected constructor uses positional parameters',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);
        var sawExpectedError = false;

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/invalid_model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@Schemable()
class InvalidModel {
  final String id;

  const InvalidModel(this.id);
}
''',
          },
          outputs: const {},
          onLog: (log) {
            if (log.level.name == 'SEVERE' &&
                log.message.contains(
                  'Only named constructor parameters are supported',
                )) {
              sawExpectedError = true;
            }
          },
        );

        expect(sawExpectedError, isTrue);
      },
    );
  });
}
