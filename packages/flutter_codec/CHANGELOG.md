# Changelog

## 0.1.0

Initial release. JSON value codecs for Flutter's painting and rendering layers,
plus a small set of widget codecs, built on [`ack`](../ack/README.md).
Requires Flutter `>=3.32.0`.

- **Primitives**: `Color`, `Offset`, `Radius`, `Rect`, `Alignment` /
  `AlignmentDirectional` / `AlignmentGeometry`, `EdgeInsets` /
  `EdgeInsetsDirectional` / `EdgeInsetsGeometry`, `BorderRadius` /
  `BorderRadiusDirectional` / `BorderRadiusGeometry`, `FontWeight`,
  `FontFeature`, `FontVariation`, `TextDecoration`, `Locale`.
- **Enums**: 30+ painting / rendering / widget enums in a single
  `lib/src/enums.dart` (e.g. `blendModeCodec`, `boxShapeCodec`,
  `tileModeCodec`, `fontStyleCodec`).
- **Borders**: `BorderSide`, `Border`, `BorderDirectional`, `BoxBorder`,
  `StrokeAlign`.
- **Shape borders** (discriminated by `"type"`): `CircleBorder`,
  `StadiumBorder`, `RoundedRectangleBorder`, `BeveledRectangleBorder`,
  `ContinuousRectangleBorder`, `RoundedSuperellipseBorder`, `StarBorder`,
  `LinearBorder` (with `LinearBorderEdge`) → `ShapeBorder`.
- **Shadows**: `Shadow`, `BoxShadow`.
- **Gradients** (discriminated by `"type"`): `LinearGradient`,
  `RadialGradient`, `SweepGradient` → `Gradient`.
- **Image providers** (discriminated by `"type"`): `NetworkImage`,
  `AssetImage` → `ImageProvider`.
- **Decoration image**: `DecorationImage` (composes `imageProviderCodec`,
  `rectCodec`, and the relevant enum codecs).
- **Text style**: `TextStyle` (including `fontFeatures` and `fontVariations`
  lists), `StrutStyle` (sibling layout style), `TextHeightBehavior`.
- **Decorations** (discriminated by `"type"`): `BoxDecoration`,
  `ShapeDecoration` → `Decoration`.
- **Constraints**: `BoxConstraints`, `Constraints` (discriminated by `"type"`).
- **Matrix**: `Matrix4`.
- **Widgets**: `Container`, `Text`, and portable `Key` / `ValueKey` codecs,
  plus a `widgetCodec` union (discriminated by `"type"`).

`FontWeight` accepts and emits arbitrary integer weights (`[1, 1000]`) for
variable fonts in addition to the `"w100"`–`"w900"` / `"normal"` / `"bold"`
aliases.

Every codec exposes `.parse`, `.safeParse`, `.encode`, and `.toJsonSchema`.
