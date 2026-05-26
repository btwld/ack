import 'package:flutter/painting.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('textDecorationCodec decode', () {
    const atomic = <String, TextDecoration>{
      'none': TextDecoration.none,
      'underline': TextDecoration.underline,
      'overline': TextDecoration.overline,
      'lineThrough': TextDecoration.lineThrough,
    };

    atomic.forEach((name, value) {
      test('decodes "$name"', () {
        expect(textDecorationCodec.parse(name), value);
      });
    });

    test('decodes a combined list', () {
      expect(
        textDecorationCodec.parse(['underline', 'overline']),
        TextDecoration.combine([
          TextDecoration.underline,
          TextDecoration.overline,
        ]),
      );
    });

    test('decodes an empty list as none', () {
      expect(textDecorationCodec.parse([]), TextDecoration.none);
    });

    test('filters none out of combined lists', () {
      expect(
        textDecorationCodec.parse(['none', 'underline']),
        TextDecoration.underline,
      );
    });
  });

  group('textDecorationCodec encode', () {
    const atomic = [
      (TextDecoration.none, 'none'),
      (TextDecoration.underline, 'underline'),
      (TextDecoration.overline, 'overline'),
      (TextDecoration.lineThrough, 'lineThrough'),
    ];

    for (final (value, name) in atomic) {
      test('encodes $value as "$name"', () {
        final encoded = textDecorationCodec.encode(value);
        expect(encoded, name);
        expectJsonSafe(encoded);
      });
    }

    test('encodes a combined decoration as participating aliases', () {
      final encoded = textDecorationCodec.encode(
        TextDecoration.combine([
          TextDecoration.underline,
          TextDecoration.overline,
        ]),
      );

      expect(encoded, ['underline', 'overline']);
      expectJsonSafe(encoded);
    });

    test('encodes atomic values as bare strings, not single-item lists', () {
      expect(textDecorationCodec.encode(TextDecoration.underline), 'underline');
      expect(textDecorationCodec.encode(TextDecoration.none), 'none');
    });
  });

  group('textDecorationCodec rejects invalid input', () {
    test('rejects unknown strings', () {
      expect(textDecorationCodec.safeParse('blink').isFail, isTrue);
    });

    test('rejects unknown list entries', () {
      expect(
        textDecorationCodec.safeParse(['underline', 'blink']).isFail,
        isTrue,
      );
    });
  });
}
