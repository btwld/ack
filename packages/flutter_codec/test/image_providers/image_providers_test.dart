import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('networkImageCodec', () {
    test('decodes minimal input with defaults', () {
      final value = networkImageCodec.parse({
        'url': 'https://example.com/image.png',
      })!;

      expect(value.url, 'https://example.com/image.png');
      expect(value.scale, 1.0);
      expect(value.headers, isNull);
      expect(value.webHtmlElementStrategy, WebHtmlElementStrategy.never);
    });

    test('decodes full input', () {
      final value = networkImageCodec.parse({
        'url': 'https://example.com/image.png',
        'scale': 2,
        'headers': {'Authorization': 'Bearer token'},
        'webHtmlElementStrategy': 'prefer',
      })!;

      expect(value.url, 'https://example.com/image.png');
      expect(value.scale, 2.0);
      expect(value.headers, {'Authorization': 'Bearer token'});
      expect(value.webHtmlElementStrategy, WebHtmlElementStrategy.prefer);
    });

    test('encodes canonical full map', () {
      final encoded = networkImageCodec.encode(
        const NetworkImage(
          'https://example.com/image.png',
          scale: 2,
          headers: {'Authorization': 'Bearer token'},
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        ),
      );

      expect(encoded, {
        'url': 'https://example.com/image.png',
        'scale': 2.0,
        'headers': {'Authorization': 'Bearer token'},
        'webHtmlElementStrategy': 'fallback',
      });
      expectJsonSafe(encoded);
    });

    test('encodes explicit null headers', () {
      expect(
        networkImageCodec.encode(
          const NetworkImage('https://example.com/image.png'),
        ),
        {
          'url': 'https://example.com/image.png',
          'scale': 1.0,
          'headers': null,
          'webHtmlElementStrategy': 'never',
        },
      );
    });

    test('rejects invalid input', () {
      final cases = <String, Object?>{
        'bad URL type': {'url': 3},
        'negative scale': {'url': 'https://example.com/image.png', 'scale': -1},
        'non-finite scale': {
          'url': 'https://example.com/image.png',
          'scale': double.infinity,
        },
        'non-string headers': {
          'url': 'https://example.com/image.png',
          'headers': {'Authorization': 1},
        },
        'unknown key': {'url': 'https://example.com/image.png', 'extra': true},
      };

      for (final MapEntry(key: label, value: input) in cases.entries) {
        expect(
          networkImageCodec.safeParse(input).isFail,
          isTrue,
          reason: label,
        );
      }
    });
  });

  group('assetImageCodec', () {
    test('decodes minimal input', () {
      final value = assetImageCodec.parse({'assetName': 'assets/image.png'})!;

      expect(value.assetName, 'assets/image.png');
      expect(value.package, isNull);
      expect(value.bundle, isNull);
    });

    test('decodes package-qualified assets', () {
      final value = assetImageCodec.parse({
        'assetName': 'assets/image.png',
        'package': 'design_system',
      })!;

      expect(value.assetName, 'assets/image.png');
      expect(value.package, 'design_system');
      expect(value.bundle, isNull);
    });

    test('encodes canonical map', () {
      final encoded = assetImageCodec.encode(
        const AssetImage('assets/image.png'),
      );

      expect(encoded, {'assetName': 'assets/image.png', 'package': null});
      expectJsonSafe(encoded);
    });

    test('encodes package-qualified assets', () {
      expect(
        assetImageCodec.encode(
          const AssetImage('assets/image.png', package: 'design_system'),
        ),
        {'assetName': 'assets/image.png', 'package': 'design_system'},
      );
    });

    test('rejects invalid input', () {
      final cases = <String, Object?>{
        'empty asset name': {'assetName': ''},
        'non-string asset name': {'assetName': 3},
        'unknown key': {'assetName': 'assets/image.png', 'extra': true},
      };

      for (final MapEntry(key: label, value: input) in cases.entries) {
        expect(assetImageCodec.safeParse(input).isFail, isTrue, reason: label);
      }
    });

    test('rejects encode for AssetImage with custom bundle', () {
      final value = AssetImage(
        'assets/image.png',
        bundle: NetworkAssetBundle(Uri.parse('https://example.com/')),
      );

      final result = assetImageCodec.safeEncode(value);

      expect(result.isFail, isTrue);
      expect(
        result.getError().toString(),
        contains('AssetImage.bundle is not supported by assetImageCodec.'),
      );
    });
  });

  group('imageProviderCodec', () {
    test('dispatches network input', () {
      final value = imageProviderCodec.parse({
        'type': 'network',
        'url': 'https://example.com/image.png',
      })!;

      expect(value, isA<NetworkImage>());
      expect((value as NetworkImage).url, 'https://example.com/image.png');
    });

    test('dispatches asset input', () {
      final value = imageProviderCodec.parse({
        'type': 'asset',
        'assetName': 'assets/image.png',
      })!;

      expect(value, isA<AssetImage>());
      expect((value as AssetImage).assetName, 'assets/image.png');
    });

    test('rejects missing and unknown discriminator', () {
      expect(
        imageProviderCodec.safeParse({
          'url': 'https://example.com/image.png',
        }).isFail,
        isTrue,
      );
      expect(
        imageProviderCodec.safeParse({
          'type': 'file',
          'path': '/tmp/a.png',
        }).isFail,
        isTrue,
      );
    });

    test('encodes by runtime type', () {
      final network = imageProviderCodec.encode(
        const NetworkImage('https://example.com/image.png'),
      );
      final asset = imageProviderCodec.encode(
        const AssetImage('assets/image.png'),
      );

      expect(network, {
        'type': 'network',
        'url': 'https://example.com/image.png',
        'scale': 1.0,
        'headers': null,
        'webHtmlElementStrategy': 'never',
      });
      expect(asset, {
        'type': 'asset',
        'assetName': 'assets/image.png',
        'package': null,
      });
      expectJsonSafe(network);
      expectJsonSafe(asset);
    });

    test('rejects unsupported runtime providers', () {
      final unsupported = <ImageProvider<Object>>[
        ResizeImage(const AssetImage('assets/image.png'), width: 16),
        const ExactAssetImage('assets/image.png'),
      ];

      for (final value in unsupported) {
        expect(
          imageProviderCodec.safeEncode(value).isFail,
          isTrue,
          reason: value.runtimeType.toString(),
        );
      }
    });

    test('JSON Schema includes branch const markers', () {
      final schemaJson = jsonEncode(imageProviderCodec.toJsonSchema());

      expect(schemaJson, contains('"const":"network"'));
      expect(schemaJson, contains('"const":"asset"'));
    });
  });
}
