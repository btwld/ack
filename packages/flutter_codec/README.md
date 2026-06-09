# flutter_codec

JSON value codecs for Flutter's painting and rendering layers — plus a small,
growing set of widget codecs (`Container`, `Text`, `Key`) — built on
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
| | `TextHeightBehavior` | `textHeightBehaviorCodec` | [lib/src/primitives/text_height_behavior.dart](lib/src/primitives/text_height_behavior.dart) |
| | `Locale` | `localeCodec` | [lib/src/primitives/locale.dart](lib/src/primitives/locale.dart) |
| Enums | 30+ painting/rendering enums (e.g. `blendModeCodec`, `boxShapeCodec`, `tileModeCodec`, `fontStyleCodec`) | see file | [lib/src/enums.dart](lib/src/enums.dart) |
| Borders | `BorderSide`, `Border`, `BorderDirectional`, `BoxBorder`, `StrokeAlign` | `borderSideCodec`, `borderCodec`, `borderDirectionalCodec`, `boxBorderCodec`, `strokeAlignCodec` | [lib/src/borders.dart](lib/src/borders.dart) |
| Shape borders | `CircleBorder`, `StadiumBorder`, `RoundedRectangleBorder`, `BeveledRectangleBorder`, `ContinuousRectangleBorder`, `RoundedSuperellipseBorder`, `StarBorder`, `LinearBorder`, `LinearBorderEdge`, `ShapeBorder` | `circleBorderCodec`, `stadiumBorderCodec`, `roundedRectangleBorderCodec`, `beveledRectangleBorderCodec`, `continuousRectangleBorderCodec`, `roundedSuperellipseBorderCodec`, `starBorderCodec`, `linearBorderCodec`, `linearBorderEdgeCodec`, `shapeBorderCodec` | [lib/src/shape_borders.dart](lib/src/shape_borders.dart) |
| Shadows | `Shadow`, `BoxShadow` | `shadowCodec`, `boxShadowCodec` | [lib/src/shadows.dart](lib/src/shadows.dart) |
| Gradients | `LinearGradient`, `RadialGradient`, `SweepGradient`, `Gradient` | `linearGradientCodec`, `radialGradientCodec`, `sweepGradientCodec`, `gradientCodec` | [lib/src/gradients.dart](lib/src/gradients.dart) |
| Image providers | `NetworkImage`, `AssetImage`, `ImageProvider` | `networkImageCodec`, `assetImageCodec`, `imageProviderCodec` | [lib/src/image_providers.dart](lib/src/image_providers.dart) |
| Decoration image | `DecorationImage` | `decorationImageCodec` | [lib/src/decoration_image.dart](lib/src/decoration_image.dart) |
| Text style | `TextStyle` | `textStyleCodec` | [lib/src/text_style.dart](lib/src/text_style.dart) |
| Strut style | `StrutStyle` | `strutStyleCodec` | [lib/src/strut_style.dart](lib/src/strut_style.dart) |
| Decorations | `BoxDecoration`, `ShapeDecoration`, `Decoration` | `boxDecorationCodec`, `shapeDecorationCodec`, `decorationCodec` | [lib/src/decorations.dart](lib/src/decorations.dart) |
| Constraints | `BoxConstraints`, `Constraints` | `boxConstraintsCodec`, `constraintsCodec` | [lib/src/constraints.dart](lib/src/constraints.dart) |
| Matrix | `Matrix4` | `matrix4Codec` | [lib/src/primitives/matrix4.dart](lib/src/primitives/matrix4.dart) |
| Widgets | `Container`, `Text`, `Key` (`ValueKey`) | `containerWidgetCodec`, `textWidgetCodec`, `keyCodec`, `widgetCodec` | [lib/src/widgets/](lib/src/widgets/) |

## Discriminated unions

Polymorphic types are encoded as `{ "type": "<branch>", ...fields }`. The
discriminator key is injected by the union at encode time. Most standalone
branch codecs do not require it on input; the gradient branches are the
exception — they embed a `"type"` literal in their own schema, so they self-tag
and accept (and require) the key on input as well.

| Union | Discriminator key | Branches |
|---|---|---|
| `gradientCodec` | `"type"` | `"linear"`, `"radial"`, `"sweep"` |
| `imageProviderCodec` | `"type"` | `"network"`, `"asset"` |
| `shapeBorderCodec` | `"type"` | `"circle"`, `"stadium"`, `"roundedRectangle"`, `"beveledRectangle"`, `"continuousRectangle"`, `"roundedSuperellipse"`, `"star"`, `"linear"` |
| `decorationCodec` | `"type"` | `"box"`, `"shape"` |
| `keyCodec` | `"type"` | `"value"` |
| `widgetCodec` | `"type"` | `"container"`, `"text"` |
| `constraintsCodec` | `"type"` | `"box"` |

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
  `DecorationImage.colorFilter` (which embeds a `ColorFilter`). Because
  `colorFilter` *is* part of `DecorationImage` equality, encoding a
  `DecorationImage` that carries one **throws** rather than silently dropping it.
- **No portable JSON shape (encode throws)**: `Gradient.transform`
  (`GradientTransform` is an open abstract type — encoding a transformed
  gradient throws rather than dropping it silently).
- **No portable JSON shape**: `Paint`, `Path`, `Shader`,
  `TextStyle.foreground` / `TextStyle.background`,
  `DecorationImage.onError`, `FlutterLogoDecoration`.
- **Local or recursive providers**: `FileImage` (local path), `MemoryImage`
  (base64 bloat), `ResizeImage` (wraps another provider), custom
  `AssetBundle` instances on `AssetImage`.
- **8-bit sRGB color**: `Color` encodes as `#RRGGBB` / `#AARRGGBB`. Integer sRGB
  colors round-trip exactly, but sub-8-bit float-channel precision (from
  `Color.withValues` / `Color.lerp`) is quantized and a non-sRGB `colorSpace`
  (display P3, extended sRGB) is flattened to sRGB.
- **Lossy narrowing**: `OvalBorder` extends `CircleBorder`, so it round-trips
  as `CircleBorder` — the runtime subtype is lost. The painted output is
  equivalent to `CircleBorder(eccentricity: 1.0)`. Likewise `StarBorder.polygon`
  round-trips as the equivalent regular `StarBorder` (its null
  `innerRadiusRatio` becomes the resolved value), and `StarBorder.rotation`
  survives only to floating-point precision (degrees↔radians). Both are
  painted-equivalent but not `==`-equal.
- **Font-family `packages/` ambiguity**: a literal `fontFamily:
  'packages/<pkg>/<x>'` supplied without a `package:` argument is read back as
  package-qualified (the common case), so it does not round-trip under
  `TextStyle` equality although the resolved family string is preserved.
- **Separate plans**: `InputBorder` family (Material — `OutlineInputBorder`,
  `UnderlineInputBorder`).

## JSON Schema export

Every codec implements `.toJsonSchema()`, returning a `Map<String, Object?>`
that round-trips through `jsonEncode`. Composition flows through: the schema
for `boxDecorationCodec` embeds the schemas for its dependent codecs (color
pattern, gradient discriminator, shape enum, and so on).

## Roadmap

The painting- and rendering-layer surface is feature-complete for the types
Flutter exposes JSON-safely. The widget codecs (`Container`, `Text`, `Key`) are
a deliberately small surface that will grow over time. Further additions to the
painting layer would require either upstream changes to `dart:ui` (to expose
`ColorFilter` / `ImageFilter` state) or a parallel descriptor-type design that
we'd own outside the raw Flutter types.
