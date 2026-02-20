import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('@AckType getter support', () {
    test('generates extension types from expression-body getters', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
StringSchema get statusSchema => Ack.string();

@AckType()
ObjectSchema get userSchema => Ack.object({
  'status': statusSchema,
  'aliases': Ack.list(statusSchema),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type StatusType(String _value)'),
              contains('extension type UserType(Map<String, Object?> _data)'),
              contains('StatusType get status'),
              contains("StatusType(_data['status'] as String)"),
              contains('List<StatusType> get aliases'),
              contains('StatusType(e as String)'),
              contains('return statusSchema.parseAs('),
              contains('return userSchema.safeParseAs('),
              isNot(contains('_\$ackParse<')),
              isNot(contains('_\$ackSafeParse<')),
            ]),
          ),
        },
      );
    });

    test('supports block-body getters and custom names', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType(name: 'CustomAddress')
ObjectSchema get addressSchema {
  return Ack.object({
    'city': Ack.string(),
  });
}

@AckType()
ObjectSchema get userSchema {
  return Ack.object({
    'address': addressSchema,
  });
}
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains(
                'extension type CustomAddressType(Map<String, Object?> _data)',
              ),
              contains('extension type UserType(Map<String, Object?> _data)'),
              contains('CustomAddressType get address'),
              contains(
                "CustomAddressType(_data['address'] as Map<String, Object?>)",
              ),
            ]),
          ),
        },
      );
    });

    test('uses prefixed SchemaResult when Ack import is aliased', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart' as ack;
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
ack.StringSchema get statusSchema => ack.Ack.string();
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type StatusType(String _value)'),
              contains('ack.SchemaResult<StatusType> safeParse'),
              contains('return statusSchema.parseAs('),
              contains('return statusSchema.safeParseAs('),
              isNot(contains('_\$ackParse<')),
              isNot(contains('_\$ackSafeParse<')),
            ]),
          ),
        },
      );
    });

    test('uses shared collection cast helper for primitive lists', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
ObjectSchema get userSchema => Ack.object({
  'tags': Ack.list(Ack.string()),
});
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type UserType(Map<String, Object?> _data)'),
              contains(
                "List<String> get tags => _\$ackListCast<String>(_data['tags'])",
              ),
              contains(
                'List<T> _\$ackListCast<T>(Object? value) => (value as List).cast<T>();',
              ),
            ]),
          ),
        },
      );
    });
  });
}
