import 'support/idna_labels.dart';

void main() {
  // RFC 5892 Appendix A.4-A.7 use Script, not Script_Extensions or blocks.
  const examples = [
    (label: 'ا١٢', valid: true, name: 'allows Arabic-Indic digits'),
    (label: 'ا۱۲', valid: true, name: 'allows Extended Arabic-Indic digits'),
    (
      label: 'ا١۲',
      valid: false,
      name: 'rejects mixed contextual digit families',
    ),
    (label: 'ا۱٢', valid: false, name: 'rejects mixed digits in reverse order'),
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
  testIdnaLabels(examples);
}
