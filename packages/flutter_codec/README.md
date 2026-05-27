# flutter_codec

JSON value codecs for Flutter's painting layer, built on
[`ack`](../ack/README.md).

Every codec is an Ack `CodecSchema` and exposes the same surface:

```dart
codec.parse(json);      // decode, throws on failure
codec.safeParse(json);  // decode, returns SchemaResult
codec.encode(value);    // encode to a JSON-safe map / scalar
codec.toJsonSchema();   // emit JSON Schema for downstream tooling
```

Codecs compose: composite types reuse their dependents, so a `BoxDecoration`
codec inherits the validation and schema output of `Color`, `BoxBorder`,
`Gradient`, `BoxShadow`, and so on.

## Quick example

```dart
import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';

final decoration = BoxDecoration(
  color: const Color(0xFF2196F3),
  border: Border.all(color: const Color(0xFFFF0000), width: 2),
  borderRadius: BorderRadius.circular(8),
  gradient: const LinearGradient(
    colors: [Color(0xFFFF0000), Color(0xFF0000FF)],
  ),
);

final json = boxDecorationCodec.encode(decoration);
// json is a Map<String, Object?> safe for jsonEncode

final roundTripped = boxDecorationCodec.parse(json);
assert(roundTripped == decoration);
```

## Coverage

| Family | Type(s) | Codec(s) | Source |
|---|---|---|---|
| Primitives | `Color` | `colorCodec` | [lib/src/primitives/color.dart](lib/src/primitives/color.dart) |
| | `Offset` | `offsetCodec` | [lib/src/primitives/offset.dart](lib/src/primitives/offset.dart) |
| | `Radius` | `radiusCodec` | [lib/src/primitives/radius.dart](lib/src/primitives/radius.dart) |
| | `Rect` | `rectCodec` | [lib/src/primitives/rect.dart](lib/src/primitives/rect.dart) |
| | `Alignment` / `AlignmentDirectional` / `AlignmentGeometry` | `alignmentCodec`, `alignmentDirectionalCodec`, `alignmentGeometryCodec` | [lib/src/primitives/alignment.dart](lib/src/primitives/alignment.dart) |
| | `EdgeInsets` / `EdgeInsetsDirectional` / `EdgeInsetsGeometry` | `edgeInsetsCodec`, `edgeInsetsDirectionalCodec`, `edgeInsetsGeometryCodec` | [lib/src/primitives/edge_insets.dart](lib/src/primitives/edge_insets.dart) |
| | `BorderRadius` / `BorderRadiusDirectional` / `BorderRadiusGeometry` | `borderRadiusCodec`, `borderRadiusDirectionalCodec`, `borderRadiusGeometryCodec` | [lib/src/primitives/border_radius.dart](lib/src/primitives/border_radius.dart) |
| | `FontWeight` | `fontWeightCodec` | [lib/src/primitives/font_weight.dart](lib/src/primitives/font_weight.dart) |
| | `FontFeature` | `fontFeatureCodec` | [lib/src/primitives/font_feature.dart](lib/src/primitives/font_feature.dart) |
| | `FontVariation` | `fontVariationCodec` | [lib/src/primitives/font_variation.dart](lib/src/primitives/font_variation.dart) |
| | `TextDecoration` | `textDecorationCodec` | [lib/src/primitives/text_decoration.dart](lib/src/primitives/text_decoration.dart) |
| | `Locale` | `localeCodec` | [lib/src/primitives/locale.dart](lib/src/primitives/locale.dart) |
| Enums | 30+ painting/rendering enums (e.g. `blendModeCodec`, `boxShapeCodec`, `tileModeCodec`, `fontStyleCodec`) | see file | [lib/src/enums.dart](lib/src/enums.dart) |
| Borders | `BorderSide`, `Border`, `BorderDirectional`, `BoxBorder`, `StrokeAlign` | `borderSideCodec`, `borderCodec`, `borderDirectionalCodec`, `boxBorderCodec`, `strokeAlignCodec` | [lib/src/borders.dart](lib/src/borders.dart) |
| Shape borders | `CircleBorder`, `StadiumBorder`, `RoundedRectangleBorder`, `BeveledRectangleBorder`, `ContinuousRectangleBorder`, `RoundedSuperellipseBorder`, `ShapeBorder` | `circleBorderCodec`, `stadiumBorderCodec`, `roundedRectangleBorderCodec`, `beveledRectangleBorderCodec`, `continuousRectangleBorderCodec`, `roundedSuperellipseBorderCodec`, `shapeBorderCodec` | [lib/src/shape_borders.dart](lib/src/shape_borders.dart) |
| Shadows | `Shadow`, `BoxShadow` | `shadowCodec`, `boxShadowCodec` | [lib/src/shadows.dart](lib/src/shadows.dart) |
| Gradients | `LinearGradient`, `RadialGradient`, `SweepGradient`, `Gradient` | `linearGradientCodec`, `radialGradientCodec`, `sweepGradientCodec`, `gradientCodec` | [lib/src/gradients.dart](lib/src/gradients.dart) |
| Image providers | `NetworkImage`, `AssetImage`, `ImageProvider` | `networkImageCodec`, `assetImageCodec`, `imageProviderCodec` | [lib/src/image_providers.dart](lib/src/image_providers.dart) |
| Decoration image | `DecorationImage` | `decorationImageCodec` | [lib/src/decoration_image.dart](lib/src/decoration_image.dart) |
| Text style | `TextStyle` | `textStyleCodec` | [lib/src/text_style.dart](lib/src/text_style.dart) |
| Decorations | `BoxDecoration`, `ShapeDecoration`, `Decoration` | `boxDecorationCodec`, `shapeDecorationCodec`, `decorationCodec` | [lib/src/decorations.dart](lib/src/decorations.dart) |

## Discriminated unions

Polymorphic types are encoded as `{ "type": "<branch>", ...fields }`. The
discriminator key is injected by the union at encode time; standalone branch
codecs do not require it on input.

| Union | Discriminator key | Branches |
|---|---|---|
| `gradientCodec` | `"type"` | `"linear"`, `"radial"`, `"sweep"` |
| `imageProviderCodec` | `"type"` | `"network"`, `"asset"` |
| `shapeBorderCodec` | `"type"` | `"circle"`, `"stadium"`, `"roundedRectangle"`, `"beveledRectangle"`, `"continuousRectangle"`, `"roundedSuperellipse"` |
| `decorationCodec` | `"type"` | `"box"`, `"shape"` |

## Intentionally excluded

These types have no portable JSON shape, or their JSON representation would
mislead more than it helps. Each is documented at the call site rather than
silently falling back.

- **Opaque `dart:ui` state — encode impossible via public API**:
  `ColorFilter` and `ImageFilter`. `ColorFilter` keeps `_color`, `_blendMode`,
  `_matrix`, and `_type` in library-private fields and exposes the same
  `runtimeType` for all four constructor variants, so an existing instance
  cannot be inspected back to JSON. `ImageFilter` is abstract with a private
  constructor (`ImageFilter._()`) and returns library-private subtypes
  (`_GaussianBlurImageFilter`, `_MatrixImageFilter`, etc.) from its factories
  — external code cannot `is`-check or downcast them. The only state-revealing
  surface is `toString()`, which is a debug format Flutter is free to change
  between releases. A bidirectional codec is not achievable here without
  introducing parallel descriptor types; the same goes for
  `DecorationImage.colorFilter` (which embeds a `ColorFilter`).
- **No portable JSON shape**: `Paint`, `Path`, `Shader`,
  `TextStyle.foreground` / `TextStyle.background`,
  `DecorationImage.onError`, `FlutterLogoDecoration`.
- **Local or recursive providers**: `FileImage` (local path), `MemoryImage`
  (base64 bloat), `ResizeImage` (wraps another provider), custom
  `AssetBundle` instances on `AssetImage`.
- **Lossy narrowing**: `OvalBorder` extends `CircleBorder`, so it round-trips
  as `CircleBorder` — the runtime subtype is lost. The painted output is
  equivalent to `CircleBorder(eccentricity: 1.0)`.
- **Separate plans**: `InputBorder` family (Material — `OutlineInputBorder`,
  `UnderlineInputBorder`), `StarBorder`, `LinearBorder`.

## JSON Schema export

Every codec implements `.toJsonSchema()`, returning a `Map<String, Object?>`
that round-trips through `jsonEncode`. Composition flows through: the schema
for `boxDecorationCodec` embeds the schemas for its dependent codecs (color
pattern, gradient discriminator, shape enum, and so on).

## Roadmap

The painting-layer surface is feature-complete for the types Flutter exposes
JSON-safely. Future additions would require either upstream changes to
`dart:ui` (to expose `ColorFilter`/`ImageFilter` state) or a parallel
descriptor-type design that we'd own outside the raw Flutter types.
