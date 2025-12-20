import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('@AckType custom names', () {
    test('generates extension types only for object schemas', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

// Primitive schemas - NO extension types generated
@AckType()
final passwordSchema = Ack.string();

@AckType(name: 'CustomPassword')
final customPasswordSchema = Ack.string();

@AckType(name: 'Order2')
final orderSchema = Ack.integer();

// Object schema - extension type IS generated
@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
});

@AckType(name: 'CustomUser')
final customUserSchema = Ack.object({
  'id': Ack.string(),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              // Primitive types should NOT have extension types
              isNot(contains('extension type PasswordType(String _value)')),
              isNot(
                contains('extension type CustomPasswordType(String _value)'),
              ),
              isNot(contains('extension type Order2Type(int _value)')),
              // Object types SHOULD have extension types
              contains(
                'extension type UserType(Map<String, Object?> _data)',
              ),
              contains(
                'extension type CustomUserType(Map<String, Object?> _data)',
              ),
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
