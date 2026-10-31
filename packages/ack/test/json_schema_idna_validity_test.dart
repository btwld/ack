import 'package:ack/ack.dart';
import 'package:punycoder/punycoder.dart' as pc;
import 'package:test/test.dart';

import 'fixtures/idna/iana_12_sample.dart';

void main() {
  final examples = [
    (
      label: '\u{20000}a--b',
      valid: false,
      name: 'rejects hyphens at scalar positions three and four',
    ),
    (
      label: '\u{20000}--a',
      valid: true,
      name: 'allows hyphens at scalar positions two and three',
    ),
    (label: '\u1100', valid: false, name: 'rejects isolated Hangul Jamo'),
    (label: 'a\u20ddb', valid: false, name: 'rejects enclosing marks'),
    (label: 'a\u0488b', valid: false, name: 'rejects enclosing Cyrillic marks'),
    (
      label: 'a\u{1d165}b',
      valid: false,
      name: 'rejects musical combining marks',
    ),
    (label: 'a\u034fb', valid: false, name: 'rejects default ignorables'),
    (label: 'a\ufe0fb', valid: false, name: 'rejects variation selectors'),
    (label: '\u19da', valid: false, name: 'rejects nondecimal number letters'),
    (label: '\ue000', valid: false, name: 'rejects private use'),
    (label: '\u0378', valid: false, name: 'rejects unassigned code points'),
    (
      label: '\u{1e290}',
      valid: false,
      name: 'rejects post-Unicode-12 assignments',
    ),
    (label: '실례', valid: true, name: 'allows precomposed Hangul'),
    (label: '\u00df', valid: true, name: 'allows the sharp s exception'),
    (label: '\u03c2', valid: true, name: 'allows the final sigma exception'),
    (label: '\u0f0b', valid: true, name: 'allows the Tibetan tsheg exception'),
    (
      label: '\u3007',
      valid: true,
      name: 'allows the ideographic zero exception',
    ),
    (label: '\u{20000}', valid: true, name: 'allows supplementary Han'),
    (label: 'a\u0301', valid: true, name: 'allows mapped NFC combining marks'),
    (label: '\u0301a', valid: false, name: 'rejects a leading mark'),
    for (final sample in ianaIdna12Samples)
      (
        label: sample.label,
        valid:
            sample.property == 'PVALID' ||
            sample.property == 'CONTEXTJ' ||
            sample.property == 'CONTEXTO',
        name: 'IANA ${sample.property} U+${sample.codePoint.toRadixString(16)}',
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
              // A decomposed Unicode input is mapped before validation. Its
              // noncanonical ACE representation must still fail round-trip.
              final valid =
                  example.label == 'a\u0301' && label.startsWith('xn--')
                  ? false
                  : example.valid;
              expect(result.isOk, valid, reason: input);
            }
          }
        });
      }
    }
  }
}
