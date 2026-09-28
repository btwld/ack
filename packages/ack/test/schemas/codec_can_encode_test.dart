import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('CodecSchema.canEncode', () {
    test('is false for a transform, which has no encoder', () {
      final schema = Ack.object({
        'id': Ack.string(),
      }).transform<String>((value) => value['id']! as String);

      expect(schema.canEncode, isFalse);
      expect(schema.safeEncode('a').isFail, isTrue);
    });

    test('is true for a codec with an encoder', () {
      final schema = Ack.object({'id': Ack.string()}).codec<String>(
        decode: (value) => value['id']! as String,
        encode: (id) => {'id': id},
      );

      expect(schema.canEncode, isTrue);
      expect(schema.safeEncode('a').getOrNull(), {'id': 'a'});
    });

    test('survives fluent copies', () {
      final transform = Ack.string().transform<int>(int.parse);
      final codec = Ack.string().codec<int>(
        decode: int.parse,
        encode: (value) => '$value',
      );

      expect(transform.nullable().optional().canEncode, isFalse);
      expect(codec.describe('A number.').canEncode, isTrue);
      expect(Ack.date().canEncode, isTrue);
    });

    test('reports only its own encoder, not a wrapped transform', () {
      final schema = Ack.string()
          .transform<int>(int.parse)
          .codec<String>(decode: (value) => '$value', encode: int.parse);

      expect(schema.canEncode, isTrue);
      expect(schema.safeEncode('1').isFail, isTrue);
    });
  });
}
