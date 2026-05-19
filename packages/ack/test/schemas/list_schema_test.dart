import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('ListSchema', () {
    test('rejects nullable item schemas at construction', () {
      expect(
        () => Ack.list(Ack.string().nullable()),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('non-nullable item schemas'),
          ),
        ),
      );
    });
  });
}
