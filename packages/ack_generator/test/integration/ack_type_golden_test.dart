import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

/// Full-output snapshot for one canonical `@AckType` object schema.
///
/// The scattered `decodedMatches(contains(...))` assertions in the sibling
/// integration tests catch missing pieces, but not formatting drift, member
/// reordering, or unexpected additions. This single exact-match golden guards
/// the overall shape of generated code for a representative schema; update the
/// expected string deliberately when the emitter output is meant to change.
void main() {
  test('emits stable extension-type output for an object schema', () async {
    final builder = ackGenerator(BuilderOptions.empty);

    const expected = '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'schema.dart';

/// Extension type for User
extension type UserType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static UserType parse(Object? data) {
    return userSchema.parseAs(
      data,
      (validated) => UserType(validated as Map<String, Object?>),
    );
  }

  static SchemaResult<UserType> safeParse(Object? data) {
    return userSchema.safeParseAs(
      data,
      (validated) => UserType(validated as Map<String, Object?>),
    );
  }

  String get name => _data['name'] as String;

  int get age => _data['age'] as int;
}
''';

    await testBuilder(
      builder,
      {
        ...allAssets,
        'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
});
''',
      },
      outputs: {'test_pkg|lib/schema.g.dart': decodedMatches(expected)},
    );
  });
}
