import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('@AckType custom names', () {
    test('generates default and custom extension type names', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final passwordSchema = Ack.string();

@AckType(name: 'CustomPassword')
final customPasswordSchema = Ack.string();

@AckType(name: 'Order2')
final orderSchema = Ack.integer();
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type PasswordType(String _value)'),
              contains('extension type CustomPasswordType(String _value)'),
              contains('extension type Order2Type(int _value)'),
            ]),
          ),
        },
      );
    });

    test('normalizes lowercase custom names', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType(name: 'customUser')
final customUserSchema = Ack.object({
  'id': Ack.string(),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains(
                'extension type CustomUserType(Map<String, Object?> _data)',
              ),
            ]),
          ),
        },
      );
    });

    test('throws when custom name contains invalid characters', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType(name: 'bad-name')
final invalidSchema = Ack.string();
''',
        },
        outputs: {},
        onLog: (log) {
          if (log.level.name == 'SEVERE') {
            expect(
              log.message,
              contains('Invalid custom @AckType name "bad-name"'),
            );
          }
        },
      );
    });

    test('throws when custom name is empty', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType(name: '')
final invalidSchema = Ack.string();
''',
        },
        outputs: {},
        onLog: (log) {
          if (log.level.name == 'SEVERE') {
            expect(
              log.message,
              contains('Custom @AckType name cannot be empty'),
            );
          }
        },
      );
    });
  });
}
