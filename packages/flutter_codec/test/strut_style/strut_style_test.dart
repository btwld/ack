import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('strutStyleCodec decode', () {
    test('decodes an empty object as the default StrutStyle', () {
      expect(strutStyleCodec.parse({}), const StrutStyle());
    });

    test('decodes a full real-world StrutStyle', () {
      expect(
        strutStyleCodec.parse({
          'fontFamily': 'Roboto',
          'fontFamilyFallback': ['Arial', 'sans-serif'],
          'fontSize': 14.0,
          'height': 1.2,
          'leadingDistribution': 'even',
          'leading': 0.5,
          'fontWeight': 'w500',
          'fontStyle': 'italic',
          'forceStrutHeight': true,
        }),
        const StrutStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['Arial', 'sans-serif'],
          fontSize: 14.0,
          height: 1.2,
          leadingDistribution: TextLeadingDistribution.even,
          leading: 0.5,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          forceStrutHeight: true,
        ),
      );
    });

    test('decodes (fontFamily, package) and produces the folded form', () {
      final decoded = strutStyleCodec.parse({
        'fontFamily': 'Roboto',
        'package': 'my_pkg',
      });
      // StrutStyle's constructor folds package into fontFamily.
      expect(decoded!.fontFamily, 'packages/my_pkg/Roboto');
    });
  });

  group('strutStyleCodec encode', () {
    test('emits explicit nulls for unset fields', () {
      final encoded = strutStyleCodec.encode(const StrutStyle());
      expect(encoded, {
        'fontFamily': null,
        'fontFamilyFallback': null,
        'package': null,
        'fontSize': null,
        'height': null,
        'leadingDistribution': null,
        'leading': null,
        'fontWeight': null,
        'fontStyle': null,
        'forceStrutHeight': null,
      });
      expectJsonSafe(encoded);
    });

    test('round-trips a populated StrutStyle', () {
      const original = StrutStyle(
        fontFamily: 'Roboto',
        fontSize: 16.0,
        height: 1.5,
        fontWeight: FontWeight.w700,
        forceStrutHeight: false,
      );
      expect(strutStyleCodec.parse(strutStyleCodec.encode(original)), original);
    });

    test('unfolds packages/<pkg>/<family> back to (fontFamily, package)', () {
      const original = StrutStyle(fontFamily: 'Roboto', package: 'my_pkg');
      final encoded = strutStyleCodec.encode(original)!;
      expect(encoded['fontFamily'], 'Roboto');
      expect(encoded['package'], 'my_pkg');
    });
  });

  group('strutStyleCodec rejects invalid input', () {
    test('rejects a non-positive fontSize', () {
      expect(strutStyleCodec.safeParse({'fontSize': 0}).isFail, isTrue);
      expect(strutStyleCodec.safeParse({'fontSize': -1}).isFail, isTrue);
    });

    test('rejects a negative leading', () {
      expect(strutStyleCodec.safeParse({'leading': -0.5}).isFail, isTrue);
    });

    test('rejects unknown keys', () {
      expect(strutStyleCodec.safeParse({'extra': 1}).isFail, isTrue);
    });
  });
}
