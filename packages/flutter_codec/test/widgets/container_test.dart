import 'package:flutter/widgets.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('containerWidgetCodec decode', () {
    test('decodes an empty object as the default Container shape', () {
      final parsed = containerWidgetCodec.parse({})!;

      expect(parsed.key, isNull);
      expect(parsed.alignment, isNull);
      expect(parsed.padding, isNull);
      expect(parsed.color, isNull);
      expect(parsed.isAntiAlias, isTrue);
      expect(parsed.decoration, isNull);
      expect(parsed.foregroundDecoration, isNull);
      expect(parsed.constraints, isNull);
      expect(parsed.margin, isNull);
      expect(parsed.transform, isNull);
      expect(parsed.transformAlignment, isNull);
      expect(parsed.clipBehavior, Clip.none);
      expect(parsed.child, isNull);
    });

    test('accepts width and height constructor shorthands', () {
      final parsed = containerWidgetCodec.parse({'width': 10, 'height': 20})!;

      expect(
        parsed.constraints,
        BoxConstraints.tightFor(width: 10, height: 20),
      );
    });
  });

  group('containerWidgetCodec encode', () {
    test('emits a full canonical map with explicit nulls for defaults', () {
      final encoded = containerWidgetCodec.encode(Container());

      expect(encoded, {
        'key': null,
        'alignment': null,
        'padding': null,
        'color': null,
        'isAntiAlias': true,
        'decoration': null,
        'foregroundDecoration': null,
        'width': null,
        'height': null,
        'constraints': null,
        'margin': null,
        'transform': null,
        'transformAlignment': null,
        'clipBehavior': 'none',
        'child': null,
      });
      expectJsonSafe(encoded);
    });

    test('round-trips a color-only container through a stable encoding', () {
      final original = Container(color: const Color(0xFF2196F3));
      final encoded = containerWidgetCodec.encode(original);
      final parsed = containerWidgetCodec.parse(encoded)!;

      expect(containerWidgetCodec.encode(parsed), encoded);
      expect(parsed.color, original.color);
      expect(parsed.decoration, isNull);
      expectJsonSafe(encoded);
    });

    test(
      'round-trips a populated decorated container through stable encoding',
      () {
        final transform = Matrix4.identity()
          ..translateByDouble(4.0, 8.0, 0.0, 1.0)
          ..rotateZ(0.25);
        final constraints = const BoxConstraints(
          minWidth: 10,
          maxWidth: 100,
          minHeight: 20,
          maxHeight: 200,
        );
        final original = Container(
          key: const ValueKey<String>('shell'),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.all(8),
          isAntiAlias: false,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(6),
          ),
          foregroundDecoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF004D40)),
          ),
          constraints: constraints,
          margin: const EdgeInsetsDirectional.only(start: 2, end: 4),
          transform: transform,
          transformAlignment: Alignment.bottomLeft,
          clipBehavior: Clip.antiAlias,
          child: Container(color: const Color(0xFFFF0000)),
        );

        final encoded = containerWidgetCodec.encode(original);
        final parsed = containerWidgetCodec.parse(encoded)!;

        expect(containerWidgetCodec.encode(parsed), encoded);
        expect(parsed.key, original.key);
        expect(parsed.padding, original.padding);
        expect(parsed.isAntiAlias, isFalse);
        expect(parsed.decoration, isA<BoxDecoration>());
        expect(parsed.foregroundDecoration, isA<BoxDecoration>());
        expect(parsed.constraints, constraints);
        expect(parsed.margin, original.margin);
        expect(parsed.transform, transform);
        expect(parsed.transformAlignment, original.transformAlignment);
        expect(parsed.clipBehavior, Clip.antiAlias);
        expect(parsed.child, isA<Container>());
        expectJsonSafe(encoded);
      },
    );

    test('canonicalizes width and height to constraints on encode', () {
      final original = Container(width: 10, height: 20);
      final encoded = containerWidgetCodec.encode(original);

      expect(encoded!['width'], isNull);
      expect(encoded['height'], isNull);
      expect(
        encoded['constraints'],
        boxConstraintsCodec.encode(
          BoxConstraints.tightFor(width: 10, height: 20),
        ),
      );
      expect(
        containerWidgetCodec.encode(containerWidgetCodec.parse(encoded)),
        encoded,
      );
    });

    test('uses the direct BoxConstraints shape without a discriminator', () {
      final original = Container(
        constraints: const BoxConstraints(
          minWidth: 1,
          maxWidth: 10,
          minHeight: 2,
          maxHeight: 20,
        ),
      );
      final encoded = containerWidgetCodec.encode(original)!;
      final constraints = encoded['constraints']! as Map<String, Object?>;

      expect(constraints.containsKey('type'), isFalse);
      expect(constraints, {
        'minWidth': 1.0,
        'maxWidth': 10.0,
        'minHeight': 2.0,
        'maxHeight': 20.0,
      });
      expect(
        containerWidgetCodec.encode(containerWidgetCodec.parse(encoded)),
        encoded,
      );
      expectJsonSafe(encoded);
    });
  });

  group('containerWidgetCodec rejects invalid input', () {
    test('rejects color and decoration together', () {
      expect(
        containerWidgetCodec.safeParse({
          'color': '#FFFFFF',
          'decoration': {'type': 'box'},
        }).isFail,
        isTrue,
      );
    });

    test('rejects clipBehavior without a decoration', () {
      expect(
        containerWidgetCodec.safeParse({'clipBehavior': 'antiAlias'}).isFail,
        isTrue,
      );
    });
  });

  group('widgetCodec', () {
    test('round-trips nested containers through the widget union', () {
      final original = Container(
        padding: const EdgeInsets.all(4),
        child: Container(
          key: const ValueKey<int>(7),
          constraints: const BoxConstraints.tightFor(width: 12),
        ),
      );

      final encoded = widgetCodec.encode(original);
      final parsed = widgetCodec.parse(encoded)!;

      expect(widgetCodec.encode(parsed), encoded);
      expect(encoded!['type'], 'container');
      expect(parsed, isA<Container>());
      expect((parsed as Container).child, isA<Container>());
      expectJsonSafe(encoded);
    });
  });
}
