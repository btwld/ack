// Sample independently selected from the complete IANA Unicode 12.0.0 CSV:
// https://www.iana.org/assignments/idna-tables-12.0.0/idna-tables-properties.csv
// SHA256: 160b72e33a377a84253393c572dc338879f39b93beccbb9cb9baebbf4d6dd743
// Contextual characters are embedded in labels satisfying Appendix A.
const ianaIdna12Samples = [
  (codePoint: 0x61, property: 'PVALID', label: 'a\u00e9'),
  (codePoint: 0x7a, property: 'PVALID', label: 'z\u00e9'),
  (codePoint: 0xdf, property: 'PVALID', label: '\u00df'),
  (codePoint: 0x3c2, property: 'PVALID', label: '\u03c2'),
  (codePoint: 0x315, property: 'PVALID', label: 'a\u0315'),
  (codePoint: 0x6fd, property: 'PVALID', label: '\u06fd'),
  (codePoint: 0xf0b, property: 'PVALID', label: '\u0f0b'),
  (codePoint: 0x3007, property: 'PVALID', label: '\u3007'),
  (codePoint: 0x20000, property: 'PVALID', label: '\u{20000}'),
  (codePoint: 0x2a6d6, property: 'PVALID', label: '\u{2a6d6}'),
  (codePoint: 0xb7, property: 'CONTEXTO', label: 'l\u00b7l'),
  (codePoint: 0x375, property: 'CONTEXTO', label: '\u0375\u03b1'),
  (codePoint: 0x5f3, property: 'CONTEXTO', label: '\u05d0\u05f3\u05d1'),
  (codePoint: 0x660, property: 'CONTEXTO', label: '\u0628\u0660'),
  (codePoint: 0x6f0, property: 'CONTEXTO', label: '\u0628\u06f0'),
  (codePoint: 0x30fb, property: 'CONTEXTO', label: '\u30fb\u3041'),
  (codePoint: 0x200c, property: 'CONTEXTJ', label: '\u0915\u094d\u200c\u0937'),
  (codePoint: 0x200d, property: 'CONTEXTJ', label: '\u0915\u094d\u200d\u0937'),
  (codePoint: 0x488, property: 'DISALLOWED', label: 'a\u0488b'),
  (codePoint: 0x1100, property: 'DISALLOWED', label: '\u1100'),
  (codePoint: 0x20dd, property: 'DISALLOWED', label: 'a\u20ddb'),
  (codePoint: 0x34f, property: 'DISALLOWED', label: 'a\u034fb'),
  (codePoint: 0xfe0f, property: 'DISALLOWED', label: 'a\ufe0fb'),
  (codePoint: 0x19da, property: 'DISALLOWED', label: '\u19da'),
  (codePoint: 0xe000, property: 'DISALLOWED', label: '\ue000'),
  (codePoint: 0x378, property: 'UNASSIGNED', label: '\u0378'),
  (codePoint: 0x2a6d7, property: 'UNASSIGNED', label: '\u{2a6d7}'),
  (codePoint: 0x10ffff, property: 'DISALLOWED', label: '\u{10ffff}'),
];
