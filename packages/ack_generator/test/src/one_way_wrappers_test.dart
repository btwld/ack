import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  test(
    'string normalizers are two-way StringSchema while transform is one-way',
    () {
      final normalizers = <String, StringSchema Function(StringSchema)>{
        'trim': (schema) => schema.trim(),
        'toLowerCase': (schema) => schema.toLowerCase(),
        'toUpperCase': (schema) => schema.toUpperCase(),
      };

      for (final entry in normalizers.entries) {
        final result = entry.value(Ack.string()).safeEncode('  TeSt  ');
        expect(result.isOk, isTrue, reason: entry.key);
      }

      final oneWay = Ack.string().transform((v) => v.trim()).safeEncode('X');
      expect(oneWay.isFail, isTrue);
      expect(
        (oneWay.getError() as SchemaEncodeError).kind,
        SchemaEncodeFailureKind.oneWayTransform,
      );
    },
  );
}
