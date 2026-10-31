import 'package:ack/ack.dart';
import 'package:punycoder/punycoder.dart' as pc;
import 'package:test/test.dart';

void main() {
  // RFC 5892 Appendix A.4-A.7 use Script, not Script_Extensions or blocks.
  const examples = [
    (label: '\u30fb\u31f0', valid: true, name: 'allows Katakana extensions'),
    (label: '\u30fb\u{20000}', valid: true, name: 'allows supplementary Han'),
    (
      label: '\u30fb\u30fc',
      valid: false,
      name: 'rejects Common prolonged sound mark',
    ),
    (
      label: '\u30fb\u3099',
      valid: false,
      name: 'rejects Inherited combining mark',
    ),
    (label: '\u30fb\u3007', valid: true, name: 'allows Han ideographic zero'),
    (
      label: '\u0375\u1d26',
      valid: true,
      name: 'allows Greek outside Greek blocks',
    ),
    (label: '\u0375a', valid: false, name: 'rejects non-Greek after keraia'),
    (
      label: '\u05d0\u05f3\u05d1',
      valid: true,
      name: 'allows Hebrew geresh context',
    ),
    (
      label: '\u05d0\u05f4\u05d1',
      valid: true,
      name: 'allows Hebrew gershayim context',
    ),
    (
      label: 'a\u05f3\u05d1',
      valid: false,
      name: 'rejects non-Hebrew before geresh',
    ),
  ];
  for (final format in ['idn-hostname', 'idn-email', 'hostname', 'email']) {
    for (final operation in ['parse', 'encode']) {
      for (final example in examples) {
        test('$format $operation ${example.name}', () {
          final schema = Ack.fromJsonSchema({
            'type': 'string',
            'format': format,
          }, assertFormats: true);
          final restored = Ack.fromJsonSchema(schema.toJsonSchema());
          for (final label in [
            if (format.startsWith('idn-')) example.label,
            'xn--${pc.punycode.encode(example.label)}',
          ]) {
            final host = '$label.example';
            final input = format.endsWith('email') ? 'user@$host' : host;
            for (final candidate in [schema, restored]) {
              final result = operation == 'parse'
                  ? candidate.safeParse(input)
                  : candidate.safeEncode(input);
              expect(result.isOk, example.valid, reason: input);
            }
          }
        });
      }
    }
  }
}
