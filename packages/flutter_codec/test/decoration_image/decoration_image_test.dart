import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

const _networkUrl = 'https://example.com/image.png';

void main() {
  group('decorationImageCodec decode', () {
    test('decodes a minimal input as DecorationImage with defaults', () {
      final parsed = decorationImageCodec.parse({
        'image': {'type': 'network', 'url': _networkUrl},
      });
      expect(parsed, DecorationImage(image: const NetworkImage(_networkUrl)));
    });

    test('decodes a full real-world DecorationImage', () {
      final parsed = decorationImageCodec.parse({
        'image': {'type': 'asset', 'assetName': 'icons/foo.png'},
        'fit': 'cover',
        'alignment': 'topLeft',
        'centerSlice': {'left': 1, 'top': 2, 'right': 3, 'bottom': 4},
        'repeat': 'repeat',
        'matchTextDirection': true,
        'scale': 2.0,
        'opacity': 0.5,
        'filterQuality': 'high',
        'invertColors': true,
        'isAntiAlias': true,
      });
      expect(
        parsed,
        DecorationImage(
          image: const AssetImage('icons/foo.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topLeft,
          centerSlice: const Rect.fromLTRB(1, 2, 3, 4),
          repeat: ImageRepeat.repeat,
          matchTextDirection: true,
          scale: 2.0,
          opacity: 0.5,
          filterQuality: FilterQuality.high,
          invertColors: true,
          isAntiAlias: true,
        ),
      );
    });
  });

  group('decorationImageCodec encode', () {
    test('emits a full canonical map with explicit defaults', () {
      final encoded = decorationImageCodec.encode(
        DecorationImage(image: const NetworkImage(_networkUrl)),
      );
      expect(encoded, {
        'image': {
          'type': 'network',
          'url': _networkUrl,
          'scale': 1.0,
          'headers': null,
          'webHtmlElementStrategy': 'never',
        },
        'fit': null,
        'alignment': 'center',
        'centerSlice': null,
        'repeat': 'noRepeat',
        'matchTextDirection': false,
        'scale': 1.0,
        'opacity': 1.0,
        'filterQuality': 'medium',
        'invertColors': false,
        'isAntiAlias': false,
      });
      expectJsonSafe(encoded);
    });

    test('round-trips a fully-populated DecorationImage', () {
      final original = DecorationImage(
        image: const AssetImage('icons/foo.png', package: 'my_pkg'),
        fit: BoxFit.cover,
        alignment: Alignment.bottomRight,
        centerSlice: const Rect.fromLTRB(1, 2, 3, 4),
        repeat: ImageRepeat.repeatX,
        matchTextDirection: true,
        scale: 1.5,
        opacity: 0.75,
        filterQuality: FilterQuality.low,
        invertColors: true,
        isAntiAlias: true,
      );

      final encoded = decorationImageCodec.encode(original);
      expect(decorationImageCodec.parse(encoded), original);
      expectJsonSafe(encoded);
    });
  });

  group('decorationImageCodec rejects invalid input', () {
    const invalidCases = <String, Object>{
      'missing image': <String, Object>{},
      'invalid image type': {
        'image': {'type': 'spiral', 'url': _networkUrl},
      },
      'invalid fit': {
        'image': {'type': 'network', 'url': _networkUrl},
        'fit': 'squoosh',
      },
      'opacity above 1': {
        'image': {'type': 'network', 'url': _networkUrl},
        'opacity': 1.5,
      },
      'opacity below 0': {
        'image': {'type': 'network', 'url': _networkUrl},
        'opacity': -0.1,
      },
      'unknown key': {
        'image': {'type': 'network', 'url': _networkUrl},
        'foo': 1,
      },
    };

    invalidCases.forEach((name, input) {
      test('rejects $name', () {
        expect(decorationImageCodec.safeParse(input).isFail, isTrue);
      });
    });
  });

  group('decorationImageCodec JSON Schema', () {
    test('dependent codec markers flow through composition', () {
      final schema = jsonEncode(decorationImageCodec.toJsonSchema());
      // image provider discriminator
      expect(schema, contains('"network"'));
      expect(schema, contains('"asset"'));
      // opacity range
      expect(schema, contains('"minimum":0'));
      expect(schema, contains('"maximum":1'));
    });
  });
}
