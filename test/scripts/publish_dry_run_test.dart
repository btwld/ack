import 'package:test/test.dart';

import '../../scripts/publish_dry_run.dart';

void main() {
  group('publishValidationCounts', () {
    test('reads a clean validation', () {
      const output =
          'Validating package...\n'
          'The server may enforce additional checks.\n'
          '\n'
          'Package has 0 warnings.\n';

      expect(publishValidationCounts(output), (warnings: 0, hints: 0));
    });

    test('a version-skip hint is not a warning', () {
      // The exact summary `pub` prints when a package jumps a version, which
      // is what an incompletely published coordinated release produces.
      const output =
          'Validating package...\n'
          'Package validation found the following hint:\n'
          '* The previous version is 1.5.0.\n'
          '\n'
          '  It seems you are not publishing an incremental update.\n'
          '\n'
          '  Consider one of:\n'
          '  * 2.0.0 for a breaking release.\n'
          '  * 1.6.0 for a minor release.\n'
          '  * 1.5.1 for a patch release.\n'
          'The server may enforce additional checks.\n'
          '\n'
          'Package has 0 warnings and 1 hint.\n';

      expect(publishValidationCounts(output), (warnings: 0, hints: 1));
    });

    test('a single warning is still reported', () {
      expect(publishValidationCounts('Package has 1 warning.\n'), (
        warnings: 1,
        hints: 0,
      ));
    });

    test('warnings alongside hints are still reported', () {
      expect(publishValidationCounts('Package has 2 warnings and 3 hints.\n'), (
        warnings: 2,
        hints: 3,
      ));
    });

    test('a summary naming only hints reports no warnings', () {
      expect(publishValidationCounts('Package has 1 hint.\n'), (
        warnings: 0,
        hints: 1,
      ));
    });

    test('output without a summary is not mistaken for a clean run', () {
      expect(
        publishValidationCounts('Validating package...\nUploading...\n'),
        isNull,
      );
    });

    test('the final summary describes the validated package', () {
      const output = 'Package has 0 warnings.\nPackage has 4 warnings.\n';

      expect(publishValidationCounts(output), (warnings: 4, hints: 0));
    });
  });
}
