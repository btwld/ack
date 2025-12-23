import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('@AckType custom names', () {
    test('generates extension types for non-nullable schemas', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

// Primitive schemas - extension types ARE generated
@AckType()
final passwordSchema = Ack.string();

@AckType(name: 'CustomPassword')
final customPasswordSchema = Ack.string().nullable();

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
              // Non-nullable primitives SHOULD have extension types
              contains('extension type PasswordType(String _value)'),
              contains('extension type Order2Type(int _value)'),
              // Nullable schema should NOT generate extension type
              isNot(contains('extension type CustomPasswordType(String _value)')),
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

    test('nullable object schemas do not generate extension types', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

// Non-nullable object schema - extension type IS generated
@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
});

// Nullable object schema - extension type should NOT be generated
@AckType()
final nullableUserSchema = Ack.object({
  'name': Ack.string(),
}).nullable();
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              // Non-nullable object SHOULD have extension type
              contains('extension type UserType(Map<String, Object?> _data)'),
              // Nullable object should NOT have extension type
              isNot(contains('extension type NullableUserType')),
            ]),
          ),
        },
      );
    });
  });
}
