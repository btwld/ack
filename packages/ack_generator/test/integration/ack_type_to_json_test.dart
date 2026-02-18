import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('@AckType toJson generation', () {
    test('emits toJson for object, primitive, and collection types', () async {
      final builder = ackGenerator(BuilderOptions.empty);

      await testBuilder(
        builder,
        {
          ...allAssets,
          'test_pkg|lib/schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
});

@AckType()
final passwordSchema = Ack.string();

@AckType()
final tagsSchema = Ack.list(Ack.string());
''',
        },
        outputs: {
          'test_pkg|lib/schema.g.dart': decodedMatches(
            allOf([
              contains('extension type UserType(Map<String, Object?> _data)'),
              contains('Map<String, Object?> toJson() => _data;'),
              contains('extension type PasswordType(String _value)'),
              contains('String toJson() => _value;'),
              contains('extension type TagsType(List<String> _value)'),
              contains('List<String> toJson() => _value;'),
            ]),
          ),
        },
      );
    });
  });
}
