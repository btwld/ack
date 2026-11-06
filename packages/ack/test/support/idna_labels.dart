import 'package:ack/ack.dart';
import 'package:punycoder/punycoder.dart' as pc;
import 'package:test/test.dart';

typedef IdnaLabelCase = ({String label, bool valid, String name});

/// Tests each label as a U-label (IDN formats only) and as an ACE label in
/// hostname and email formats, for parse and encode, with format assertions
/// preserved by JSON Schema export and import.
///
/// The ACE forms of [invalidAceLabels] must fail whatever the case expects.
void testIdnaLabels(
  List<IdnaLabelCase> cases, {
  Set<String> invalidAceLabels = const {},
}) {
  for (final format in ['idn-hostname', 'idn-email', 'hostname', 'email']) {
    for (final operation in ['parse', 'encode']) {
      for (final example in cases) {
        test('$format $operation ${example.name}', () {
          final schema = Ack.fromJsonSchema({
            'type': 'string',
            'format': format,
          }, assertFormats: true);
          final restored = Ack.fromJsonSchema(schema.toJsonSchema());
          for (final (label, ace) in [
            if (format.startsWith('idn-')) (example.label, false),
            ('xn--${pc.punycode.encode(example.label)}', true),
          ]) {
            final host = '$label.example';
            final input = format.endsWith('email') ? 'user@$host' : host;
            final valid =
                example.valid &&
                !(ace && invalidAceLabels.contains(example.label));
            for (final candidate in [schema, restored]) {
              final result = operation == 'parse'
                  ? candidate.safeParse(input)
                  : candidate.safeEncode(input);
              expect(result.isOk, valid, reason: input);
            }
          }
        });
      }
    }
  }
}
