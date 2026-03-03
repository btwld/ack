import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('@AckType nested schema references', () {
    test(
      'generates typed getters for primitive and object schema refs',
      () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final statusSchema = Ack.string();

@AckType()
final addressSchema = Ack.object({
  'street': Ack.string(),
  'city': Ack.string(),
});

@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'status': statusSchema,
  'address': addressSchema,
  'aliases': Ack.list(statusSchema),
});
''',
          },
          outputs: {
            'test_pkg|lib/schema.g.dart': decodedMatches(
              allOf([
                contains('extension type StatusType(String _value)'),
                contains(
                  'extension type AddressType(Map<String, Object?> _data)',
                ),
                contains('extension type UserType(Map<String, Object?> _data)'),
                contains('StatusType get status'),
                contains("StatusType(_data['status'] as String)"),
                contains('AddressType get address'),
                contains(
                  "AddressType(_data['address'] as Map<String, Object?>)",
                ),
                contains('List<StatusType> get aliases'),
                contains('StatusType(e as String)'),
              ]),
            ),
          },
        );
      },
    );

    test('resolves custom @AckType names for nested refs', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType(name: 'CustomStatus')
final statusSchema = Ack.string();

@AckType()
final orderSchema = Ack.object({
  'status': statusSchema,
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type CustomStatusType(String _value)'),
              contains('CustomStatusType get status'),
              contains("CustomStatusType(_data['status'] as String)"),
            ]),
          ),
        },
      );
    });

    test('fails on anonymous inline object fields in strict mode', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await expectLater(
        () => testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final userSchema = Ack.object({
  'profile': Ack.object({
    'name': Ack.string(),
  }),
});
''',
          },
          outputs: {'test_pkg|lib/schema.g.dart': anything},
        ),
        // Generator emits: 'anonymous inline Ack.object(...). Strict typed generation requires a named schema reference.'
        throwsA(isA<Exception>()),
      );
    });

    test('fails on Ack.list(Ack.object(...)) in strict mode', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await expectLater(
        () => testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final userSchema = Ack.object({
  'profiles': Ack.list(Ack.object({
    'name': Ack.string(),
  })),
});
''',
          },
          outputs: {'test_pkg|lib/schema.g.dart': anything},
        ),
        // Generator emits: 'anonymous inline Ack.object(...). Strict typed generation requires a named schema reference.'
        throwsA(isA<Exception>()),
      );
    });
  });
}
