import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:test/test.dart';

import '../test_utils/generation_test_utils.dart';
import '../test_utils/test_assets.dart';

void main() {
  // @AckType is frozen until Ack 2.0; Ack.map inference is AckInfer/AckModel
  // only. Pin that the legacy generator fails loudly instead of guessing.
  test('frozen @AckType rejects Ack.map fields', () async {
    await expectGenerationFailure(
      builder: ackGenerator(BuilderOptions.empty),
      expectedMessage: 'Ack.map',
      assets: {
        ...allAssets,
        'test_pkg|lib/config_schema.dart': '''
import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

@AckType()
final configSchema = Ack.object({'scores': Ack.map(Ack.integer())});
''',
      },
    );
  });
}
