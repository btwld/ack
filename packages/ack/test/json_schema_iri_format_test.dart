import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  for (final format in ['iri', 'iri-reference']) {
    group(format, () {
      final schema = Ack.fromJsonSchema({
        'type': 'string',
        'format': format,
      }, assertFormats: true);
      final roundTrip = Ack.fromJsonSchema(schema.toJsonSchema());

      void expectValidity(String value, bool valid) {
        expect(schema.safeParse(value).isOk, valid, reason: value);
        expect(
          roundTrip.safeParse(value).isOk,
          valid,
          reason: 'export: $value',
        );
      }

      const privateRunes = [
        0xe000,
        0xf8ff,
        0xf0000,
        0xffffd,
        0x100000,
        0x10fffd,
      ];
      final components = <String, String Function(String)>{
        'userinfo': (char) => 'https://$char@example.test/',
        'host': (char) => 'https://example$char.test/',
        'path': (char) => 'https://example.test/$char',
        'fragment': (char) => 'https://example.test/#$char',
        'fragment containing a question mark': (char) =>
            'https://example.test/#fragment?$char',
        'fragment after a query': (char) =>
            'https://example.test/?q=allowed#$char',
      };
      for (final MapEntry(key: component, value: makeValue)
          in components.entries) {
        test('rejects private-use code points in $component', () {
          for (final rune in privateRunes) {
            expectValidity(makeValue(String.fromCharCode(rune)), false);
          }
        });
      }

      test('accepts private-use code points in the query', () {
        for (final rune in privateRunes) {
          final char = String.fromCharCode(rune);
          expectValidity('https://example.test/?q=$char?more#fragment', true);
          if (format == 'iri-reference') expectValidity('?q=$char', true);
        }
      });

      for (final rune in [
        0x0080,
        0x009f,
        0xd800,
        0xfdd0,
        0xfdef,
        0xffff,
        0x1fffe,
        0xe0000,
        0xe0fff,
        0xffffe,
        0x10ffff,
      ]) {
        test('rejects forbidden U+${rune.toRadixString(16)}', () {
          final char = String.fromCharCode(rune);
          for (final suffix in ['/$char', '/?q=$char', '/#$char']) {
            expectValidity('https://example.test$suffix', false);
          }
        });
      }

      test('accepts RFC 3987 Unicode range boundaries', () {
        for (final rune in [
          0x00a0,
          0xd7ff,
          0xf900,
          0xfdcf,
          0xfdf0,
          0xffef,
          0x10000,
          0xdfffd,
          0xe1000,
          0xefffd,
        ]) {
          final char = String.fromCharCode(rune);
          for (final suffix in ['/$char', '/?q=$char', '/#$char']) {
            expectValidity('https://example.test$suffix', true);
          }
        }
      });

      test(
        'accepts percent-encoded private-use characters outside queries',
        () {
          expectValidity('https://example.test/%EE%80%80#%EE%80%80', true);
        },
      );

      if (format == 'iri-reference') {
        test(
          'rejects private-use code points in relative paths and fragments',
          () {
            for (final value in ['/\ue000', '#\ue000', '?q=allowed#\ue000']) {
              expectValidity(value, false);
            }
          },
        );
      }
    });
  }
}
