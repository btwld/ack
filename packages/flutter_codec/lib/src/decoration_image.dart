import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show
        Alignment,
        AlignmentGeometry,
        BoxFit,
        DecorationImage,
        FilterQuality,
        ImageProvider,
        ImageRepeat,
        Rect;

import 'enums.dart' show boxFitCodec, filterQualityCodec, imageRepeatCodec;
import 'image_providers.dart' show imageProviderCodec;
import 'json_readers.dart';
import 'primitives/alignment.dart' show alignmentGeometryCodec;
import 'primitives/rect.dart' show rectCodec;

/// Codec for [DecorationImage].
///
/// Composes [imageProviderCodec] (the required image), the [BoxFit] /
/// [ImageRepeat] / [FilterQuality] enum codecs, [alignmentGeometryCodec], and
/// [rectCodec]. All non-`image` fields default to the Flutter
/// [DecorationImage] constructor defaults.
///
/// Note: `opacity` is range-validated `[0, 1]` here. Flutter only clamps it
/// at paint time, so this codec is stricter than the constructor — invalid
/// inputs fail to parse rather than silently clamp.
///
/// Intentionally unsupported:
/// * `colorFilter` — `ColorFilter` has no portable JSON shape.
/// * `onError` — callback type, not serializable.
///
/// Both are excluded from [DecorationImage]'s `==`, so round-trips remain
/// stable.
final decorationImageCodec =
    Ack.object({
      'image': imageProviderCodec,
      'fit': boxFitCodec.nullable().optional(),
      'alignment': alignmentGeometryCodec.withDefault(Alignment.center),
      'centerSlice': rectCodec.nullable().optional(),
      'repeat': imageRepeatCodec.withDefault(ImageRepeat.noRepeat),
      'matchTextDirection': Ack.boolean().withDefault(false),
      'scale': Ack.number().withDefault(1.0),
      'opacity': Ack.number().min(0).max(1).withDefault(1.0),
      'filterQuality': filterQualityCodec.withDefault(FilterQuality.medium),
      'invertColors': Ack.boolean().withDefault(false),
      'isAntiAlias': Ack.boolean().withDefault(false),
    }).codec<DecorationImage>(
      decode: (data) => DecorationImage(
        image: readValue<ImageProvider>(data, 'image'),
        fit: readNullableValue<BoxFit>(data, 'fit'),
        alignment: readValue<AlignmentGeometry>(data, 'alignment'),
        centerSlice: readNullableValue<Rect>(data, 'centerSlice'),
        repeat: readValue<ImageRepeat>(data, 'repeat'),
        matchTextDirection: readValue<bool>(data, 'matchTextDirection'),
        scale: readDouble(data, 'scale'),
        opacity: readDouble(data, 'opacity'),
        filterQuality: readValue<FilterQuality>(data, 'filterQuality'),
        invertColors: readValue<bool>(data, 'invertColors'),
        isAntiAlias: readValue<bool>(data, 'isAntiAlias'),
      ),
      encode: (value) => {
        'image': value.image,
        'fit': value.fit,
        'alignment': value.alignment,
        'centerSlice': value.centerSlice,
        'repeat': value.repeat,
        'matchTextDirection': value.matchTextDirection,
        'scale': value.scale,
        'opacity': value.opacity,
        'filterQuality': value.filterQuality,
        'invertColors': value.invertColors,
        'isAntiAlias': value.isAntiAlias,
      },
    );
