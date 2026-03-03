import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import '../test_utils/test_assets.dart';

void main() {
  group('@AckType object wrappers are immutable', () {
    test(
      'deep-freezes object wrappers while preserving Map compatibility',
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
final catSchema = Ack.object({
  'kind': Ack.literal('cat'),
  'lives': Ack.integer(),
});

@AckType()
final dogSchema = Ack.object({
  'kind': Ack.literal('dog'),
  'bark': Ack.boolean(),
});

@AckType()
final petSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'cat': catSchema,
    'dog': dogSchema,
  },
);
''',
          },
          outputs: {
            'test_pkg|lib/schema.g.dart': decodedMatches(
              allOf([
                contains('extension type CatType(Map<String, Object?> _data)'),
                contains('implements PetType, Map<String, Object?>'),
                contains('Map<String, Object?> toJson() => _data;'),
                contains('CatType(ackDeepFreezeObjectMap('),
                contains('DogType(ackDeepFreezeObjectMap('),
                contains(
                  'ackDeepFreezeObjectMap(validated as Map<String, Object?>)',
                ),
                contains('final map = ackDeepFreezeObjectMap('),
                isNot(contains('Object? _\$ackDeepFreeze(')),
                isNot(
                  contains('Map<String, Object?> _\$ackDeepFreezeObjectMap('),
                ),
              ]),
            ),
          },
        );
      },
    );
  });
}
