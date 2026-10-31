# IDNA2008 data

Hostname and email format assertions validate mapped U-labels and decoded
A-labels against the complete RFC 5892 derived-property registry published by
IANA for **Unicode 12.0.0**. `PVALID`, `CONTEXTJ`, and `CONTEXTO` come directly
from that registry. `DISALLOWED` and `UNASSIGNED` are rejected. Characters
assigned after Unicode 12 are therefore unsupported until this pin is updated.

Joining_Type, Canonical_Combining_Class=Virama, General_Category (leading
marks) and Bidi_Class use the same Unicode
version. The runtime does not infer IDNA admissibility from Unicode categories
or blocks. Contextual rules follow RFC 5892 Appendix A and RFC 5893.

The existing hostname input mapping is applied before this validation
(compatibility normalization, lowercasing, mapped dot separators and ignored
zero width spaces). A-labels must round-trip through Punycode. This mapping
does not relax derived-property or contextual checks on the resulting label.

## Regeneration

Download these pinned sources into a temporary directory:

- https://www.iana.org/assignments/idna-tables-12.0.0/idna-tables-properties.csv
  (SHA-256 `160b72e33a377a84253393c572dc338879f39b93beccbb9cb9baebbf4d6dd743`)
- https://www.unicode.org/Public/12.0.0/ucd/extracted/DerivedGeneralCategory.txt
- https://www.unicode.org/Public/12.0.0/ucd/extracted/DerivedJoiningType.txt
- https://www.unicode.org/Public/12.0.0/ucd/extracted/DerivedCombiningClass.txt
- https://www.unicode.org/Public/12.0.0/ucd/extracted/DerivedBidiClass.txt

From the repository root, substitute their downloaded paths:

```sh
dart scripts/generate_unicode_idna.dart idna-tables-properties.csv DerivedGeneralCategory.txt
dart scripts/generate_unicode_contextj.dart DerivedJoiningType.txt DerivedCombiningClass.txt
dart scripts/generate_unicode_bidi.dart DerivedBidiClass.txt
```

The IANA generator requires complete, ordered coverage of U+0000–U+10FFFF,
including rejected ranges. All generated files are private library parts.
Keep the registry, contextual properties, documentation, and tests pinned to
the same version when updating the data.
