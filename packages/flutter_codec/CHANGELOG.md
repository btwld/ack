# Changelog

## 0.1.0

Initial release. JSON value codecs for Flutter's painting layer, built on
[`ack`](../ack/README.md).

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
  `ContinuousRectangleBorder` → `ShapeBorder`.
- **Shadows**: `Shadow`, `BoxShadow`.
- **Gradients** (discriminated by `"type"`): `LinearGradient`,
  `RadialGradient`, `SweepGradient` → `Gradient`.
- **Image providers** (discriminated by `"type"`): `NetworkImage`,
  `AssetImage` → `ImageProvider`.
- **Decoration image**: `DecorationImage` (composes `imageProviderCodec`,
  `rectCodec`, and the relevant enum codecs).
- **Text style**: `TextStyle` (including `fontFeatures` and `fontVariations`
  lists).
- **Decorations** (discriminated by `"type"`): `BoxDecoration`,
  `ShapeDecoration` → `Decoration`.

Every codec exposes `.parse`, `.safeParse`, `.encode`, and `.toJsonSchema`.
