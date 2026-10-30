import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  for (final format in ['uri', 'uri-reference', 'iri', 'iri-reference']) {
    final schema = Ack.fromJsonSchema({
      'type': 'string',
      'format': format,
    }, assertFormats: true);
    final roundTrip = Ack.fromJsonSchema(schema.toJsonSchema());
    final prefixes = [
      'https://example.test/',
      if (format.endsWith('-reference')) '',
    ];

    test('$format rejects a second fragment delimiter', () {
      for (final prefix in prefixes) {
        for (final suffix in ['#a#b', '##', '?q=allowed#a#b']) {
          final value = '$prefix$suffix';
          expect(schema.safeParse(value).isFail, isTrue, reason: value);
          expect(roundTrip.safeParse(value).isFail, isTrue, reason: value);
        }
      }
    });

    test('$format accepts empty fragments and encoded hash characters', () {
      for (final prefix in prefixes) {
        for (final suffix in ['#', '#a%23b', '?q=%23#fragment']) {
          final value = '$prefix$suffix';
          expect(schema.safeParse(value).isOk, isTrue, reason: value);
          expect(roundTrip.safeParse(value).isOk, isTrue, reason: value);
        }
      }
    });
  }
}
