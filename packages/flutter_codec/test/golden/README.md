# Golden fixtures

These files pin the exact JSON that every public codec in `flutter_codec`
produces, and `golden_test.dart` proves each one parses back. They are the
human-reviewable record of the package's wire format — if an encoder changes
shape, a fixture diff makes it obvious.

## How to read a fixture file

Each file under `fixtures/` is one **family** (mirroring `lib/src/`), and is a
JSON object of the form:

```jsonc
{
  "<case identifier>": <the JSON the codec actually emits>,
  ...
}
```

> [!IMPORTANT]
> The **top-level keys are test-case identifiers, not wire data.** They only
> exist to group many cases in one file. The thing the codec produces — the
> actual layout you care about — is always the **value**.

For example, in `primitives.json`:

```jsonc
{
  "color": "#2196F3",                 // case "color"  -> colorCodec emits "#2196F3"
  "offset": { "x": 12.0, "y": 4.5 }   // case "offset" -> the real Offset wire shape
}
```

`color` and `offset` are labels. `"#2196F3"` and `{ "x": 12.0, "y": 4.5 }` are
the real encodings. `enums.json` follows the same rule: the key is the enum type
name, the value is the full ordered list of wire strings that codec accepts and
emits.

## What the round-trip check asserts

For every case the test:

1. **Encodes** a representative typed value and asserts it equals the recorded
   JSON (a shape change shows up as a golden diff).
2. **Parses the JSON back** and verifies the round-trip, one of:
   - **value equality** (`==`) — the painting/rendering value types;
   - **stability** (`encode(parse(json)) == json`) — `Container` / `Text` /
     the widget union, which intentionally have no value equality;
   - **documented narrowing** — e.g. `OvalBorder` routes through the `circle`
     branch and round-trips as `CircleBorder(eccentricity: 1.0)`.

## Null / optional / missing-key conventions

- **Encoding always emits the full canonical map with explicit `null`s.** Every
  supported-but-unset field is present as `null` (this is why the maps look
  verbose). That makes the output self-documenting and gives clean diffs.
- **Decoding treats an absent key and an explicit `null` as identical** for
  `nullable().optional()` fields, so compact input (`{}`, partial objects) and
  the verbose canonical form decode to the same value.
- **Unsupported fields are omitted entirely, not nulled.** A *missing* key in
  the output means "not part of this type's contract" (e.g. `Text.textScaler`),
  whereas `"key": null` means "supported field, currently unset."
- **`BoxConstraints` is the deliberate exception where absent ≠ null:** an
  *omitted* min bound decodes to `0`, but an explicit `"minWidth": null` decodes
  to `infinity` (JSON has no infinity literal, so `null` stands in for it).

## Intentional losses (covered by the dedicated unit tests, not these goldens)

- `Color` is 8-bit sRGB hex; float-channel precision and non-sRGB color spaces
  are not preserved.
- `Gradient.transform` and `DecorationImage.colorFilter` have no portable JSON
  shape and **throw on encode** rather than dropping silently.
- `StarBorder.polygon` is intentionally *not* recorded here: its encoded
  `innerRadiusRatio` is `cos(pi / sides)`, a libm value that is not guaranteed
  bit-identical across platforms. Its narrowing is tested with a tolerance in
  `test/shape_borders/shape_borders_test.dart`.

## Determinism

Fixtures must be byte-identical on any machine, so the representative values
avoid transcendental functions (matrix transforms use translate/scale, not
`rotateZ`). The only long decimal in the fixtures is `6.283185307179586`, which
is exactly `2 * math.pi` — constant arithmetic, not a libm call.

## Regenerating after an intentional change

```sh
UPDATE_GOLDENS=true flutter test test/golden/golden_test.dart
```

This rewrites every `fixtures/*.json` from the current encoders. Review the diff,
then run `flutter test test/golden/golden_test.dart` (without the flag) to
confirm everything still parses back.
