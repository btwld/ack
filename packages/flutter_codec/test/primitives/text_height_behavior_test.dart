import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('textHeightBehaviorCodec decode', () {
    test('decodes an empty object as the default TextHeightBehavior', () {
      expect(textHeightBehaviorCodec.parse({}), const TextHeightBehavior());
    });

    test('decodes a fully-specified object', () {
      expect(
        textHeightBehaviorCodec.parse({
          'applyHeightToFirstAscent': false,
          'applyHeightToLastDescent': false,
          'leadingDistribution': 'even',
        }),
        const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      );
    });
  });

  group('textHeightBehaviorCodec encode', () {
    test('emits the canonical map with all three fields', () {
      final encoded = textHeightBehaviorCodec.encode(
        const TextHeightBehavior(),
      );
      expect(encoded, {
        'applyHeightToFirstAscent': true,
        'applyHeightToLastDescent': true,
        'leadingDistribution': 'proportional',
      });
      expectJsonSafe(encoded);
    });

    test('round-trips a non-default behavior', () {
      const original = TextHeightBehavior(
        applyHeightToFirstAscent: false,
        leadingDistribution: TextLeadingDistribution.even,
      );
      expect(
        textHeightBehaviorCodec.parse(textHeightBehaviorCodec.encode(original)),
        original,
      );
    });
  });

  group('textHeightBehaviorCodec rejects invalid input', () {
    test('rejects an unknown leadingDistribution', () {
      expect(
        textHeightBehaviorCodec.safeParse({
          'leadingDistribution': 'centered',
        }).isFail,
        isTrue,
      );
    });

    test('rejects unknown keys', () {
      expect(
        textHeightBehaviorCodec.safeParse({
          'applyHeightToFirstAscent': true,
          'extra': 1,
        }).isFail,
        isTrue,
      );
    });
  });
}
