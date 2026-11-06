import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  for (final format in ['idn-hostname', 'idn-email']) {
    for (final encode in [false, true]) {
      test('$format ${encode ? 'encode' : 'parse'} rejects malformed ACE', () {
        final schema = Ack.fromJsonSchema({
          'type': 'string',
          'format': format,
        }, assertFormats: true);
        final input = '${format == 'idn-email' ? 'user@' : ''}xn--😀.example';
        final result = encode
            ? schema.safeEncode(input)
            : schema.safeParse(input);
        expect(result.isFail, isTrue);
        expect(result.getError().toString(), contains('format'));
      });
    }
  }
}
