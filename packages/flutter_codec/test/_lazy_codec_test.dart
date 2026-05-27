import 'package:ack/ack.dart';
import 'package:flutter_codec/src/_lazy_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lazyCodec', () {
    test('does not resolve during construction', () {
      var calls = 0;

      lazyCodec<String, String>(() {
        calls++;
        return Ack.string();
      });

      expect(calls, 0);
    });

    test('resolves once and delegates parse and encode', () {
      var calls = 0;
      final schema = lazyCodec<String, String>(() {
        calls++;
        return Ack.string().codec<String>(
          decode: (value) => value.toUpperCase(),
          encode: (value) => value.toLowerCase(),
        );
      });

      expect(schema.parse('hello'), 'HELLO');
      expect(schema.encode('WORLD'), 'world');
      expect(schema.parse('again'), 'AGAIN');
      expect(calls, 1);
    });

    test('supports nullable and optional combinators', () {
      var calls = 0;
      final schema = Ack.object({
        'name': lazyCodec<String, String>(() {
          calls++;
          return Ack.string();
        }).nullable().optional(),
      });

      expect(schema.parse({}), isEmpty);
      expect(schema.parse({'name': null}), {'name': null});
      expect(schema.encode({}), isEmpty);
      expect(schema.encode({'name': null}), {'name': null});
      expect(calls, 0);

      expect(schema.parse({'name': 'ack'}), {'name': 'ack'});
      expect(calls, 1);
    });
  });
}
