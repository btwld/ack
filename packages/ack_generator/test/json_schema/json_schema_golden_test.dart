import 'dart:io';

import 'package:ack_generator/src/json_schema/json_schema_library.dart';
import 'package:test/test.dart';

import 'fixture_library.dart';

/// The committed schema libraries the equivalence test imports.
///
/// Regenerate them with `ACK_UPDATE_GOLDENS=1 dart test
/// test/json_schema/json_schema_golden_test.dart`.
const _goldens = {
  'mapping.schema.dart': ('mapping', AckUnknownPropertiesMode.schema),
  'mapping_preserve.schema.dart': (
    'mapping',
    AckUnknownPropertiesMode.preserve,
  ),
};

void main() {
  final update = Platform.environment['ACK_UPDATE_GOLDENS'] == '1';

  for (final MapEntry(key: golden, value: (fixture, mode))
      in _goldens.entries) {
    test('$golden matches the generated library', () {
      final source = generateFixture(fixture, unknownProperties: mode).source;
      final file = File('$fixtureDirectory/$golden');
      if (update) file.writeAsStringSync(source);
      expect(
        file.readAsStringSync(),
        source,
        reason: 'Regenerate with ACK_UPDATE_GOLDENS=1.',
      );
    });
  }
}
