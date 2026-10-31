import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  for (final format in ['uri-reference', 'iri-reference']) {
    final schema = Ack.fromJsonSchema({
      'type': 'string',
      'format': format,
    }, assertFormats: true);
    final roundTrip = Ack.fromJsonSchema(schema.toJsonSchema());

    test('$format allows colons after the first path segment', () {
      for (final value in [
        'foo?bar:baz',
        'foo#bar:baz',
        'foo?bar:baz#fragment',
        '?bar:baz',
        '#bar:baz',
        'foo/bar:baz',
        './foo:bar',
      ]) {
        expect(schema.safeParse(value).isOk, isTrue, reason: value);
        expect(roundTrip.safeParse(value).isOk, isTrue, reason: value);
      }
    });

    test('$format rejects colons in a relative first path segment', () {
      for (final value in ['1foo:bar', ':bar', '.foo:bar']) {
        expect(schema.safeParse(value).isFail, isTrue, reason: value);
        expect(roundTrip.safeParse(value).isFail, isTrue, reason: value);
      }
    });
  }
}
