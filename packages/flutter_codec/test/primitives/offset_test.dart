import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('offsetCodec', () {
    test('decodes x and y into an Offset', () {
      expect(offsetCodec.parse({'x': 12, 'y': 4.5}), const Offset(12, 4.5));
    });

    test('encodes Offset as x and y', () {
      final encoded = offsetCodec.encode(const Offset(12, 4.5));
      expect(encoded, {'x': 12.0, 'y': 4.5});
      expectJsonSafe(encoded);
    });

    test('rejects missing coordinates', () {
      expect(offsetCodec.safeParse({'x': 12}).isFail, isTrue);
    });
  });
}
