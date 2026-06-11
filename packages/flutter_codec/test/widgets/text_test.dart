import 'package:flutter/widgets.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('textWidgetCodec decode', () {
    test('decodes a minimal data object', () {
      final parsed = textWidgetCodec.parse({'data': 'hello'})!;

      expect(parsed.data, 'hello');
      expect(parsed.style, isNull);
      expect(parsed.textScaler, isNull);
    });
  });

  group('textWidgetCodec encode', () {
    test('emits a full canonical map with explicit nulls for defaults', () {
      final encoded = textWidgetCodec.encode(const Text('hello'));

      expect(encoded, {
        'key': null,
        'data': 'hello',
        'style': null,
        'strutStyle': null,
        'textAlign': null,
        'textDirection': null,
        'locale': null,
        'softWrap': null,
        'overflow': null,
        'maxLines': null,
        'semanticsLabel': null,
        'semanticsIdentifier': null,
        'textWidthBasis': null,
        'textHeightBehavior': null,
        'selectionColor': null,
      });
      expect(encoded!.containsKey('textScaler'), isFalse);
      expect(encoded.containsKey('textScaleFactor'), isFalse);
      expectJsonSafe(encoded);
    });

    test('round-trips a fully populated Text through stable encoding', () {
      const original = Text(
        'hello',
        key: ValueKey<String>('copy'),
        style: TextStyle(
          color: Color(0xFF102030),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        strutStyle: StrutStyle(fontSize: 18, height: 1.25),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        locale: Locale('en', 'US'),
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        semanticsLabel: 'label',
        semanticsIdentifier: 'copy-id',
        textWidthBasis: TextWidthBasis.longestLine,
        textHeightBehavior: TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: true,
        ),
        selectionColor: Color(0x330000FF),
      );

      final encoded = textWidgetCodec.encode(original);
      final parsed = textWidgetCodec.parse(encoded)!;

      expect(textWidgetCodec.encode(parsed), encoded);
      expect(parsed.key, original.key);
      expect(parsed.data, original.data);
      expect(parsed.style, original.style);
      expect(parsed.strutStyle, original.strutStyle);
      expect(parsed.textAlign, original.textAlign);
      expect(parsed.textDirection, original.textDirection);
      expect(parsed.locale, original.locale);
      expect(parsed.softWrap, original.softWrap);
      expect(parsed.overflow, original.overflow);
      expect(parsed.maxLines, original.maxLines);
      expect(parsed.semanticsLabel, original.semanticsLabel);
      expect(parsed.semanticsIdentifier, original.semanticsIdentifier);
      expect(parsed.textWidthBasis, original.textWidthBasis);
      expect(parsed.textHeightBehavior, original.textHeightBehavior);
      expect(parsed.selectionColor, original.selectionColor);
      expectJsonSafe(encoded);
    });

    test('fails to encode opaque textScaler state', () {
      // textScaler has no portable JSON shape, so encoding a Text that sets it
      // fails loudly instead of silently dropping the scaler.
      final result = textWidgetCodec.safeEncode(
        Text('scaled', textScaler: TextScaler.linear(1.5)),
      );

      expect(result.isFail, isTrue);
    });
  });

  group('widgetCodec', () {
    test('round-trips Container(child: Text) across widget branches', () {
      final original = Container(
        padding: const EdgeInsets.all(8),
        child: const Text('hi', textAlign: TextAlign.center),
      );

      final encoded = widgetCodec.encode(original);
      final parsed = widgetCodec.parse(encoded)!;

      expect(widgetCodec.encode(parsed), encoded);
      expect(parsed, isA<Container>());
      final child = (parsed as Container).child;
      expect(child, isA<Text>());
      expect((child as Text).data, 'hi');
      expect(child.textAlign, TextAlign.center);
      expectJsonSafe(encoded);
    });
  });
}
