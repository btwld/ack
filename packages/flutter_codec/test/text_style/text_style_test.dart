import 'dart:convert';
import 'dart:ui' as ui show Locale, Paint, Shadow;

import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('textStyleCodec decode', () {
    test('decodes inherit-only input as the default TextStyle', () {
      expect(textStyleCodec.parse({'inherit': true}), const TextStyle());
    });

    test('decodes a full real-world TextStyle', () {
      expect(
        textStyleCodec.parse({
          'inherit': true,
          'color': '#2196F3',
          'backgroundColor': '#FFFDE7',
          'fontSize': 18,
          'fontWeight': 'bold',
          'fontStyle': 'italic',
          'letterSpacing': 0.25,
          'wordSpacing': 1.5,
          'textBaseline': 'alphabetic',
          'height': 1.3,
          'leadingDistribution': 'even',
          'locale': 'en-US',
          'shadows': [
            {
              'color': '#55000000',
              'offset': {'x': 1, 'y': 2},
              'blurRadius': 3,
            },
          ],
          'decoration': ['underline', 'overline'],
          'decorationColor': '#FF0000',
          'decorationStyle': 'dashed',
          'decorationThickness': 2,
          'fontFamily': 'Inter',
          'fontFamilyFallback': ['Roboto', 'Arial'],
          'package': 'my_package',
          'overflow': 'ellipsis',
          'fontFeatures': [
            {'feature': 'smcp', 'value': 1},
            {'feature': 'liga'},
          ],
          'fontVariations': [
            {'axis': 'wght', 'value': 600},
            {'axis': 'wdth', 'value': 100},
          ],
        }),
        TextStyle(
          color: const Color(0xFF2196F3),
          backgroundColor: const Color(0xFFFFFDE7),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.25,
          wordSpacing: 1.5,
          textBaseline: TextBaseline.alphabetic,
          height: 1.3,
          leadingDistribution: TextLeadingDistribution.even,
          locale: const ui.Locale('en', 'US'),
          shadows: const [
            ui.Shadow(
              color: Color(0x55000000),
              offset: Offset(1, 2),
              blurRadius: 3,
            ),
          ],
          decoration: TextDecoration.combine([
            TextDecoration.underline,
            TextDecoration.overline,
          ]),
          decorationColor: const Color(0xFFFF0000),
          decorationStyle: TextDecorationStyle.dashed,
          decorationThickness: 2,
          fontFamily: 'Inter',
          fontFamilyFallback: const ['Roboto', 'Arial'],
          package: 'my_package',
          overflow: TextOverflow.ellipsis,
          fontFeatures: const [FontFeature('smcp'), FontFeature('liga')],
          fontVariations: const [
            FontVariation('wght', 600),
            FontVariation('wdth', 100),
          ],
        ),
      );
    });
  });

  group('textStyleCodec encode', () {
    test('emits a full canonical map with explicit nulls for defaults', () {
      final encoded = textStyleCodec.encode(const TextStyle());

      expect(encoded, {
        'inherit': true,
        'color': null,
        'backgroundColor': null,
        'fontSize': null,
        'fontWeight': null,
        'fontStyle': null,
        'letterSpacing': null,
        'wordSpacing': null,
        'textBaseline': null,
        'height': null,
        'leadingDistribution': null,
        'locale': null,
        'shadows': null,
        'decoration': null,
        'decorationColor': null,
        'decorationStyle': null,
        'decorationThickness': null,
        'fontFamily': null,
        'fontFamilyFallback': null,
        'package': null,
        'overflow': null,
        'fontFeatures': null,
        'fontVariations': null,
      });
      expectJsonSafe(encoded);
    });

    test('round-trips a full TextStyle', () {
      final original = TextStyle(
        inherit: false,
        color: const Color(0xFF2196F3),
        backgroundColor: const Color(0xFFFFFDE7),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.25,
        wordSpacing: 1.5,
        textBaseline: TextBaseline.alphabetic,
        height: 1.3,
        leadingDistribution: TextLeadingDistribution.even,
        locale: const ui.Locale('zh', 'CN'),
        shadows: const [
          ui.Shadow(
            color: Color(0x55000000),
            offset: Offset(1, 2),
            blurRadius: 3,
          ),
        ],
        decoration: TextDecoration.combine([
          TextDecoration.underline,
          TextDecoration.overline,
        ]),
        decorationColor: const Color(0xFFFF0000),
        decorationStyle: TextDecorationStyle.dashed,
        decorationThickness: 2,
        fontFamily: 'Inter',
        fontFamilyFallback: const ['Roboto', 'Arial'],
        package: 'my_package',
        overflow: TextOverflow.ellipsis,
        fontFeatures: const [FontFeature('smcp'), FontFeature('cv01', 3)],
        fontVariations: const [
          FontVariation('wght', 500),
          FontVariation('slnt', -10),
        ],
      );

      final encoded = textStyleCodec.encode(original);

      expect(textStyleCodec.parse(encoded), original);
      expectJsonSafe(encoded);
    });

    test('round-trips a package-prefixed fallback with a null fontFamily', () {
      // A package must not be inferred from the fallback alone: re-folding a
      // null fontFamily with a package yields the literal 'packages/<pkg>/null'.
      const original = TextStyle(
        fontFamilyFallback: ['packages/foo/Bar', 'packages/foo/Baz'],
      );
      final roundTripped = textStyleCodec.parse(
        textStyleCodec.encode(original),
      );
      expect(roundTripped, original);
      expect(roundTripped!.fontFamily, isNull);
    });

    test('preserves a literal packages/<pkg>/<x> fontFamily string', () {
      // A literal 'packages/...' family supplied without a package: argument is
      // intentionally read back as package-qualified (the common case). The
      // resolved font family string is preserved, though TextStyle equality
      // does not hold because the private _package differs.
      const original = TextStyle(fontFamily: 'packages/foo/Bar');
      final roundTripped = textStyleCodec.parse(
        textStyleCodec.encode(original),
      );
      expect(roundTripped!.fontFamily, 'packages/foo/Bar');
    });
  });

  group('textStyleCodec rejects invalid input', () {
    const invalidCases = <String, Object>{
      'unknown keys': {'inherit': true, 'foo': 1},
      'invalid fontWeight': {'fontWeight': 'heavy'},
      'invalid decoration': {'decoration': 'blink'},
      'invalid color': {'color': 'not-a-color'},
    };

    invalidCases.forEach((name, input) {
      test('rejects $name', () {
        expect(textStyleCodec.safeParse(input).isFail, isTrue);
      });
    });
  });

  group('textStyleCodec rejects unsupported paint fields on encode', () {
    test('fails to encode a foreground Paint', () {
      // foreground is a Paint with no JSON shape; it must fail loudly rather
      // than drop to a colorless style.
      final result = textStyleCodec.safeEncode(
        TextStyle(foreground: ui.Paint()),
      );
      expect(result.isFail, isTrue);
    });

    test('fails to encode a background Paint', () {
      final result = textStyleCodec.safeEncode(
        TextStyle(background: ui.Paint()),
      );
      expect(result.isFail, isTrue);
    });
  });

  group('textStyleCodec JSON Schema', () {
    test('dependent codec enums flow through composition', () {
      final schema = jsonEncode(textStyleCodec.toJsonSchema());
      // textDecorationCodec emits its atomic aliases as an enum; the
      // composed object lifts that enum into its property schema.
      expect(
        schema,
        contains('"enum":["none","underline","overline","lineThrough"]'),
      );
      // fontWeightCodec's enum branch surfaces the same way.
      expect(schema, contains('"enum":["w100"'));
    });
  });
}
