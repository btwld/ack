import 'dart:convert';
import 'dart:ui';

import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('localeCodec', () {
    const cases = <String, Locale>{
      'en': Locale('en'),
      'en-US': Locale('en', 'US'),
      'zh-Hans-CN': Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'CN',
      ),
      'pt-BR': Locale('pt', 'BR'),
    };

    cases.forEach((tag, locale) {
      test('round-trips "$tag"', () {
        expect(localeCodec.parse(tag), locale);

        final encoded = localeCodec.encode(locale);
        expect(encoded, tag);
        expectJsonSafe(encoded);
      });
    });
  });

  group('localeCodec rejects invalid input', () {
    for (final input in ['EN', 'en-us', '']) {
      test('rejects "$input"', () {
        expect(localeCodec.safeParse(input).isFail, isTrue);
      });
    }
  });

  group('localeCodec JSON Schema', () {
    test('BCP-47 subset pattern is reflected', () {
      expect(
        jsonEncode(localeCodec.toJsonSchema()),
        contains(
          r'"pattern":"^([a-z]{2,3})(?:-([A-Z][a-z]{3}))?(?:-([A-Z]{2}|\\d{3}))?$"',
        ),
      );
    });
  });
}
