import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show AssetImage, ImageProvider, NetworkImage, WebHtmlElementStrategy;
import 'package:flutter/services.dart' show AssetBundle;

import 'enums.dart' show webHtmlElementStrategyCodec;
import 'json_readers.dart';

final _headersCodec = Ack.object({}, additionalProperties: true)
    .refine(
      (value) => value.values.every((headerValue) => headerValue is String),
      message: 'NetworkImage headers must be a JSON object with string values.',
    )
    .codec<Map<String, String>>(
      decode: (value) => value.cast<String, String>(),
      encode: (value) => Map<String, Object?>.unmodifiable(value),
    );

/// Codec for [NetworkImage].
///
/// Maps the portable public constructor fields only: `url`, `scale`,
/// `headers`, and `webHtmlElementStrategy`. The `"type"` discriminator is
/// added by [imageProviderCodec] when this codec is used as one of its
/// branches.
final networkImageCodec =
    Ack.object({
      'url': Ack.string().notEmpty(),
      'scale': Ack.number().min(0).withDefault(1.0),
      'headers': _headersCodec.nullable().optional(),
      'webHtmlElementStrategy': webHtmlElementStrategyCodec.withDefault(
        WebHtmlElementStrategy.never,
      ),
    }).codec<NetworkImage>(
      decode: (data) => NetworkImage(
        readValue<String>(data, 'url'),
        scale: readDouble(data, 'scale'),
        headers: readNullableValue<Map<String, String>>(data, 'headers'),
        webHtmlElementStrategy: readValue<WebHtmlElementStrategy>(
          data,
          'webHtmlElementStrategy',
        ),
      ),
      encode: (value) => {
        'url': value.url,
        'scale': value.scale,
        'headers': value.headers,
        'webHtmlElementStrategy': value.webHtmlElementStrategy,
      },
    );

/// Codec for [AssetImage].
///
/// Custom [AssetBundle] instances are intentionally unsupported because they
/// are not portable through JSON. Use package-qualified assets for JSON-safe
/// asset references. The `"type"` discriminator is added by
/// [imageProviderCodec] when this codec is used as one of its branches.
final assetImageCodec =
    Ack.object({
      'assetName': Ack.string().notEmpty(),
      'package': Ack.string().nullable().optional(),
    }).codec<AssetImage>(
      decode: (data) => AssetImage(
        readValue<String>(data, 'assetName'),
        package: readNullableValue<String>(data, 'package'),
      ),
      encode: (value) {
        if (value.bundle != null) {
          throw UnsupportedError(
            'AssetImage.bundle is not supported by assetImageCodec.',
          );
        }

        return {'assetName': value.assetName, 'package': value.package};
      },
    );

/// Codec for JSON-safe [ImageProvider] values, discriminated by `"type"`.
///
/// Support is intentionally limited to [NetworkImage] (`"network"`) and
/// [AssetImage] (`"asset"`). Recursive providers ([ResizeImage]), local files
/// ([FileImage]), memory blobs ([MemoryImage]), custom providers, and custom
/// asset bundles are rejected instead of guessing a non-portable JSON shape.
final imageProviderCodec = Ack.discriminated<ImageProvider<Object>>(
  discriminatorKey: 'type',
  schemas: {'network': networkImageCodec, 'asset': assetImageCodec},
);
