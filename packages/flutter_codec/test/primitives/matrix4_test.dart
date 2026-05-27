import 'package:flutter/widgets.dart' show Matrix4;
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('matrix4Codec', () {
    test('round-trips the identity matrix', () {
      final matrix = Matrix4.identity();
      final encoded = matrix4Codec.encode(matrix);

      expect(matrix4Codec.parse(encoded), matrix);
      expectJsonSafe(encoded);
    });

    test('round-trips a transformed matrix in column-major storage order', () {
      final matrix = Matrix4.identity()
        ..translateByDouble(10.0, 20.0, 30.0, 1.0)
        ..rotateZ(0.5);

      final encoded = matrix4Codec.encode(matrix);

      expect(encoded, matrix.storage.toList());
      expect(matrix4Codec.parse(encoded), matrix);
      expectJsonSafe(encoded);
    });

    test('defensively copies parsed storage', () {
      final storage = Matrix4.identity().storage.toList();
      final parsed = matrix4Codec.parse(storage)!;

      storage[0] = 10;

      expect(parsed, Matrix4.identity());
    });

    test('rejects lists that are not exactly 16 items long', () {
      expect(matrix4Codec.safeParse(List<double>.filled(15, 0)).isFail, isTrue);
      expect(matrix4Codec.safeParse(List<double>.filled(17, 0)).isFail, isTrue);
    });
  });
}
