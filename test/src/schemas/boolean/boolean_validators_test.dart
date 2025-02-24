import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../../test_helpers.dart';

void main() {
  group('Boolean Validators', () {
    group('BooleanSchema Edge Cases', () {
      test('Valid string "true" parses to true', () {
        final schema = BooleanSchema();
        final result = schema.validate("true");

        expect(result.isOk, isTrue);
      });

      test('Valid string "false" parses to false', () {
        final schema = BooleanSchema();
        final result = schema.validate("false");

        expect(result.isOk, isTrue);
      });

      test('Mixed case string "True" fails validation', () {
        final schema = BooleanSchema();
        final result = schema.validate("True");
        // bool.tryParse("True") returns null, so this should fail unless handled differently.

        expect(result, hasOneSchemaError('invalid_type'));
      });

      test('String with whitespace " true " fails validation', () {
        final schema = BooleanSchema();
        final result = schema.validate(" true ");
        // Again, this should fail unless you choose to trim inputs.

        expect(result, hasOneSchemaError('invalid_type'));
      });
    });

    group('BooleanSchema Invalid Types', () {
      test('Passing an integer returns invalid type error', () {
        final schema = BooleanSchema();
        final result = schema.validate(123);

        expect(result, hasOneSchemaError('invalid_type'));
      });

      test('Passing an object returns invalid type error', () {
        final schema = BooleanSchema();
        final result = schema.validate({'key': 'value'});

        expect(result, hasOneSchemaError('invalid_type'));
      });
    });
  });
}
