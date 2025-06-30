import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Transformation with Discriminated Union', () {
    test('should transform discriminated union results', () {
      final eventSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'click': Ack.object({
            'type': Ack.literal('click'),
            'x': Ack.integer(),
            'y': Ack.integer(),
          }),
          'scroll': Ack.object({
            'type': Ack.literal('scroll'),
            'delta': Ack.double(),
          }),
        },
      ).transform<String>((event) {
        return switch (event!['type']) {
          'click' => 'Click at (${event['x']}, ${event['y']})',
          'scroll' => 'Scroll by ${event['delta']}',
          _ => 'Unknown event',
        };
      });

      expect(
        eventSchema.parse({'type': 'click', 'x': 100, 'y': 200}),
        equals('Click at (100, 200)'),
      );

      expect(
        eventSchema.parse({'type': 'scroll', 'delta': 50.5}),
        equals('Scroll by 50.5'),
      );
    });

    test('should validate before transforming discriminated unions', () {
      final schema = Ack.discriminated(
        discriminatorKey: 'status',
        schemas: {
          'success': Ack.object({
            'status': Ack.literal('success'),
            'data': Ack.string(),
          }),
          'error': Ack.object({
            'status': Ack.literal('error'),
            'code': Ack.integer(),
          }),
        },
      ).transform<int>((result) {
        return result!['status'] == 'success' ? 0 : result['code'] as int;
      });

      // Invalid discriminator should fail before transform
      expect(
        () => schema.parse({'status': 'unknown', 'data': 'test'}),
        throwsA(isA<AckException>()),
      );

      // Invalid schema should fail before transform
      expect(
        () => schema.parse({'status': 'error', 'code': 'not-a-number'}),
        throwsA(isA<AckException>()),
      );
    });
  });
}
