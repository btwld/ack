import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('TransformedSchema encode (one-way safety)', () {
    test('safeEncode fails with SchemaEncodeError.oneWayTransform', () {
      // .transform(...) is documented as one-way. Until M13 unifies it with
      // CodecSchema, an explicit encodeBoundary override must surface a
      // SchemaEncodeError.oneWayTransform — otherwise the base default's
      // identity encode would silently round-trip the runtime value back to
      // the boundary form.
      final schema = Ack.string().transform<int>(int.parse);
      final result = schema.safeEncode(42);
      expect(result.isFail, isTrue);
      final err = result.getError();
      expect(err, isA<SchemaEncodeError>());
      // Message should point users at Ack.codec for bidirectional behaviour.
      expect(err.message, contains('Ack.codec'));
    });

    test('encode through transformed branch in an object fails', () {
      // Composite recursion exercises encodeBoundary on the transformed child.
      final schema = Ack.object({
        'count': Ack.string().transform<int>(int.parse),
      });
      final result = schema.safeEncode({'count': 42});
      expect(result.isFail, isTrue);
    });

    test('parse through a transformed schema is unaffected', () {
      // Sanity: the parse path keeps working as before.
      final schema = Ack.string().transform<int>(int.parse);
      expect(schema.parse('42'), equals(42));
    });
  });
}
