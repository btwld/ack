// Golden / fixture coverage for every public codec.
//
// For each codec this test:
//   1. Encodes a representative typed value and records the canonical JSON it
//      produces in a per-family fixture under `test/golden/fixtures/*.json`.
//      Those files are committed so the exact wire shape of every type is
//      reviewable in one place and regressions surface as a golden diff.
//   2. Reads that JSON back, parses it, and asserts the round-trip:
//        - value-equality (`==`) for the painting/rendering value types,
//        - JSON stability (`encode(parse(json)) == json`) for the widget types
//          that intentionally have no value equality, and
//        - the documented narrowing for the few lossy types.
//
// To regenerate the fixtures after an intentional change:
//   UPDATE_GOLDENS=true flutter test test/golden/golden_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle, Shadow;

import 'package:ack/ack.dart' show CodecSchema;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart' show MaterialTapTargetSize, ThemeMode;
import 'package:flutter/rendering.dart'
    show
        CrossAxisAlignment,
        DecorationPosition,
        FlexFit,
        GrowthDirection,
        HitTestBehavior,
        MainAxisAlignment,
        MainAxisSize,
        ScrollDirection,
        StackFit,
        WrapAlignment,
        WrapCrossAlignment;
import 'package:flutter/services.dart' show TextCapitalization;
import 'package:flutter/widgets.dart';

import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

typedef _Json = Object?;

const _fixturesDir = 'test/golden/fixtures';
const _encoder = JsonEncoder.withIndent('  ');
final _update = Platform.environment['UPDATE_GOLDENS'] == 'true';

const _redBlue = [Color(0xFFFF0000), Color(0xFF0000FF)];

void main() {
  for (final family in _families) {
    group('golden/${family.file}', () {
      final path = '$_fixturesDir/${family.file}.json';

      test('encodes every type to the recorded fixture', () {
        final actual = <String, _Json>{};
        for (final fixture in family.cases) {
          final encoded = fixture.encode();
          expect(
            jsonSafetyViolation(encoded),
            isNull,
            reason: '${fixture.name} produced non-JSON-safe output',
          );
          actual[fixture.name] = encoded;
        }

        final actualText = _encoder.convert(actual);
        final file = File(path);
        if (_update) {
          file.parent.createSync(recursive: true);
          file.writeAsStringSync('$actualText\n');
          return;
        }

        expect(
          file.existsSync(),
          isTrue,
          reason:
              'Missing golden $path. Generate it with '
              'UPDATE_GOLDENS=true flutter test test/golden/golden_test.dart',
        );
        expect(
          actualText,
          file.readAsStringSync().trimRight(),
          reason:
              'Golden drift in ${family.file}.json. If this change is '
              'intentional, regenerate with UPDATE_GOLDENS=true.',
        );
      });

      for (final fixture in family.cases) {
        test('${fixture.name} parses back from its JSON', () {
          if (_update) return;
          final golden =
              jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
          expect(
            golden.containsKey(fixture.name),
            isTrue,
            reason: 'No golden entry for ${fixture.name}',
          );
          final json = golden[fixture.name];
          expectJsonSafe(json);
          fixture.verify(json);
        });
      }
    });
  }
}

/// A single codec fixture: a representative value to [encode] and a [verify]
/// callback that checks the parsed-back result against the recorded JSON.
final class _Case {
  _Case(this.name, this.encode, this.verify);

  final String name;
  final _Json Function() encode;
  final void Function(_Json json) verify;
}

final class _Family {
  _Family(this.file, this.cases);

  final String file;
  final List<_Case> cases;
}

/// Builds a fixture for an enum codec: the recorded JSON is the full, ordered
/// list of wire names the codec accepts/emits, and every name round-trips.
_Case _enumCase<T extends Enum>(
  String name,
  CodecSchema<String, T> codec,
  List<T> values,
) {
  return _Case(name, () => [for (final value in values) codec.encode(value)], (
    json,
  ) {
    final names = (json! as List).cast<String>();
    expect(
      names,
      [for (final value in values) value.name],
      reason: '$name wire vocabulary drifted from its enum declaration order',
    );
    for (final wireName in names) {
      expect(codec.parse(wireName)!.name, wireName);
    }
  });
}

final _families = <_Family>[
  _Family('primitives', _primitives),
  _Family('borders', _borders),
  _Family('shape_borders', _shapeBorders),
  _Family('gradients', _gradients),
  _Family('shadows', _shadows),
  _Family('image_providers', _imageProviders),
  _Family('decorations', _decorations),
  _Family('decoration_image', _decorationImage),
  _Family('constraints', _constraints),
  _Family('text', _text),
  _Family('widgets', _widgets),
  _Family('enums', _enums),
];

// --- primitives -------------------------------------------------------------

final _primitives = <_Case>[
  _Case(
    'color',
    () => colorCodec.encode(const Color(0xFF2196F3)),
    (j) => expect(colorCodec.parse(j), const Color(0xFF2196F3)),
  ),
  _Case(
    'colorTranslucent',
    () => colorCodec.encode(const Color(0x802196F3)),
    (j) => expect(colorCodec.parse(j), const Color(0x802196F3)),
  ),
  _Case(
    'offset',
    () => offsetCodec.encode(const Offset(12, 4.5)),
    (j) => expect(offsetCodec.parse(j), const Offset(12, 4.5)),
  ),
  _Case(
    'radiusCircular',
    () => radiusCodec.encode(const Radius.circular(8)),
    (j) => expect(radiusCodec.parse(j), const Radius.circular(8)),
  ),
  _Case(
    'radiusElliptical',
    () => radiusCodec.encode(const Radius.elliptical(8, 12.5)),
    (j) => expect(radiusCodec.parse(j), const Radius.elliptical(8, 12.5)),
  ),
  _Case(
    'rect',
    () => rectCodec.encode(const Rect.fromLTRB(1, 2, 30, 40)),
    (j) => expect(rectCodec.parse(j), const Rect.fromLTRB(1, 2, 30, 40)),
  ),
  _Case(
    'alignmentNamed',
    () => alignmentCodec.encode(Alignment.topLeft),
    (j) => expect(alignmentCodec.parse(j), Alignment.topLeft),
  ),
  _Case(
    'alignmentXY',
    () => alignmentCodec.encode(const Alignment(0.25, -0.5)),
    (j) => expect(alignmentCodec.parse(j), const Alignment(0.25, -0.5)),
  ),
  _Case(
    'alignmentDirectional',
    () => alignmentDirectionalCodec.encode(
      const AlignmentDirectional(0.25, -0.5),
    ),
    (j) => expect(
      alignmentDirectionalCodec.parse(j),
      const AlignmentDirectional(0.25, -0.5),
    ),
  ),
  _Case(
    'alignmentGeometryDirectional',
    () => alignmentGeometryCodec.encode(const AlignmentDirectional(0.25, -0.5)),
    (j) {
      final parsed = alignmentGeometryCodec.parse(j);
      expect(parsed, isA<AlignmentDirectional>());
      expect(parsed, const AlignmentDirectional(0.25, -0.5));
    },
  ),
  _Case(
    'borderRadiusCircular',
    () => borderRadiusCodec.encode(BorderRadius.circular(8)),
    (j) => expect(borderRadiusCodec.parse(j), BorderRadius.circular(8)),
  ),
  _Case(
    'borderRadiusPerCorner',
    () => borderRadiusCodec.encode(
      const BorderRadius.only(topLeft: Radius.circular(8)),
    ),
    (j) => expect(
      borderRadiusCodec.parse(j),
      const BorderRadius.only(topLeft: Radius.circular(8)),
    ),
  ),
  _Case(
    'borderRadiusDirectional',
    () => borderRadiusDirectionalCodec.encode(
      const BorderRadiusDirectional.only(topStart: Radius.circular(8)),
    ),
    (j) => expect(
      borderRadiusDirectionalCodec.parse(j),
      const BorderRadiusDirectional.only(topStart: Radius.circular(8)),
    ),
  ),
  _Case(
    'borderRadiusGeometryDirectional',
    () => borderRadiusGeometryCodec.encode(
      BorderRadiusDirectional.all(const Radius.circular(8)),
    ),
    (j) {
      final parsed = borderRadiusGeometryCodec.parse(j);
      expect(parsed, isA<BorderRadiusDirectional>());
      expect(parsed, BorderRadiusDirectional.all(const Radius.circular(8)));
    },
  ),
  _Case(
    'edgeInsetsAll',
    () => edgeInsetsCodec.encode(const EdgeInsets.all(16)),
    (j) => expect(edgeInsetsCodec.parse(j), const EdgeInsets.all(16)),
  ),
  _Case(
    'edgeInsetsOnly',
    () => edgeInsetsCodec.encode(const EdgeInsets.only(left: 8, top: 4)),
    (j) => expect(
      edgeInsetsCodec.parse(j),
      const EdgeInsets.only(left: 8, top: 4),
    ),
  ),
  _Case(
    'edgeInsetsDirectional',
    () => edgeInsetsDirectionalCodec.encode(
      const EdgeInsetsDirectional.only(start: 8),
    ),
    (j) => expect(
      edgeInsetsDirectionalCodec.parse(j),
      const EdgeInsetsDirectional.only(start: 8),
    ),
  ),
  _Case(
    'edgeInsetsGeometryDirectional',
    () => edgeInsetsGeometryCodec.encode(
      const EdgeInsetsDirectional.only(start: 8),
    ),
    (j) {
      final parsed = edgeInsetsGeometryCodec.parse(j);
      expect(parsed, isA<EdgeInsetsDirectional>());
      expect(parsed, const EdgeInsetsDirectional.only(start: 8));
    },
  ),
  _Case(
    'matrix4Identity',
    () => matrix4Codec.encode(Matrix4.identity()),
    (j) => expect(matrix4Codec.parse(j), Matrix4.identity()),
  ),
  _Case(
    'matrix4Transformed',
    () => matrix4Codec.encode(_transformedMatrix()),
    (j) => expect(matrix4Codec.parse(j), _transformedMatrix()),
  ),
  _Case(
    'locale',
    () => localeCodec.encode(const Locale('en', 'US')),
    (j) => expect(localeCodec.parse(j), const Locale('en', 'US')),
  ),
  _Case(
    'localeWithScript',
    () => localeCodec.encode(
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'CN',
      ),
    ),
    (j) => expect(
      localeCodec.parse(j),
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: 'CN',
      ),
    ),
  ),
  _Case(
    'fontFeature',
    () => fontFeatureCodec.encode(const FontFeature('smcp', 1)),
    (j) => expect(fontFeatureCodec.parse(j), const FontFeature('smcp', 1)),
  ),
  _Case(
    'fontVariation',
    () => fontVariationCodec.encode(const FontVariation('wght', 600)),
    (j) =>
        expect(fontVariationCodec.parse(j), const FontVariation('wght', 600)),
  ),
  _Case(
    'fontWeightNamed',
    () => fontWeightCodec.encode(FontWeight.w600),
    (j) => expect(fontWeightCodec.parse(j), FontWeight.w600),
  ),
  _Case(
    'fontWeightVariable',
    () => fontWeightCodec.encode(const FontWeight(550)),
    (j) => expect(fontWeightCodec.parse(j), const FontWeight(550)),
  ),
  _Case(
    'textDecorationAtomic',
    () => textDecorationCodec.encode(TextDecoration.underline),
    (j) => expect(textDecorationCodec.parse(j), TextDecoration.underline),
  ),
  _Case(
    'textDecorationCombined',
    () => textDecorationCodec.encode(
      TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]),
    ),
    (j) => expect(
      textDecorationCodec.parse(j),
      TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]),
    ),
  ),
  _Case(
    'textHeightBehavior',
    () => textHeightBehaviorCodec.encode(
      const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    ),
    (j) => expect(
      textHeightBehaviorCodec.parse(j),
      const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    ),
  ),
];

// --- borders ----------------------------------------------------------------

final _borders = <_Case>[
  _Case(
    'strokeAlignNamed',
    () => strokeAlignCodec.encode(BorderSide.strokeAlignOutside),
    (j) => expect(strokeAlignCodec.parse(j), BorderSide.strokeAlignOutside),
  ),
  _Case(
    'strokeAlignNumeric',
    () => strokeAlignCodec.encode(0.5),
    (j) => expect(strokeAlignCodec.parse(j), 0.5),
  ),
  _Case(
    'borderSideNone',
    () => borderSideCodec.encode(BorderSide.none),
    (j) => expect(borderSideCodec.parse(j), BorderSide.none),
  ),
  _Case(
    'borderSideFull',
    () => borderSideCodec.encode(
      const BorderSide(
        color: Color(0xFFFF0000),
        width: 2,
        style: BorderStyle.none,
        strokeAlign: BorderSide.strokeAlignCenter,
      ),
    ),
    (j) => expect(
      borderSideCodec.parse(j),
      const BorderSide(
        color: Color(0xFFFF0000),
        width: 2,
        style: BorderStyle.none,
        strokeAlign: BorderSide.strokeAlignCenter,
      ),
    ),
  ),
  _Case(
    'borderNone',
    () => borderCodec.encode(const Border()),
    (j) => expect(borderCodec.parse(j), const Border()),
  ),
  _Case(
    'borderUniform',
    () => borderCodec.encode(
      Border.all(color: const Color(0xFFFF0000), width: 2),
    ),
    (j) => expect(
      borderCodec.parse(j),
      Border.all(color: const Color(0xFFFF0000), width: 2),
    ),
  ),
  _Case(
    'borderMixed',
    () => borderCodec.encode(
      const Border(
        top: BorderSide(color: Color(0xFFFF0000), width: 2),
        bottom: BorderSide(color: Color(0xFF0000FF), width: 3),
      ),
    ),
    (j) => expect(
      borderCodec.parse(j),
      const Border(
        top: BorderSide(color: Color(0xFFFF0000), width: 2),
        bottom: BorderSide(color: Color(0xFF0000FF), width: 3),
      ),
    ),
  ),
  _Case(
    'borderDirectional',
    () => borderDirectionalCodec.encode(
      const BorderDirectional(
        start: BorderSide(color: Color(0xFFFF0000), width: 2),
      ),
    ),
    (j) => expect(
      borderDirectionalCodec.parse(j),
      const BorderDirectional(
        start: BorderSide(color: Color(0xFFFF0000), width: 2),
      ),
    ),
  ),
  _Case(
    'boxBorderDirectional',
    () => boxBorderCodec.encode(
      const BorderDirectional(start: BorderSide(color: Color(0xFFFF0000))),
    ),
    (j) {
      final parsed = boxBorderCodec.parse(j);
      expect(parsed, isA<BorderDirectional>());
      expect(
        parsed,
        const BorderDirectional(start: BorderSide(color: Color(0xFFFF0000))),
      );
    },
  ),
];

// --- shape borders ----------------------------------------------------------

final _shapeBorders = <_Case>[
  _Case(
    'circleBorder',
    () => circleBorderCodec.encode(const CircleBorder()),
    (j) => expect(circleBorderCodec.parse(j), const CircleBorder()),
  ),
  _Case(
    'circleBorderSided',
    () => circleBorderCodec.encode(
      const CircleBorder(
        side: BorderSide(color: Color(0xFFFF0000), width: 2),
        eccentricity: 0.5,
      ),
    ),
    (j) => expect(
      circleBorderCodec.parse(j),
      const CircleBorder(
        side: BorderSide(color: Color(0xFFFF0000), width: 2),
        eccentricity: 0.5,
      ),
    ),
  ),
  _Case(
    'stadiumBorder',
    () => stadiumBorderCodec.encode(
      const StadiumBorder(side: BorderSide(color: Color(0xFFFF0000), width: 3)),
    ),
    (j) => expect(
      stadiumBorderCodec.parse(j),
      const StadiumBorder(side: BorderSide(color: Color(0xFFFF0000), width: 3)),
    ),
  ),
  _Case(
    'roundedRectangleBorder',
    () => roundedRectangleBorderCodec.encode(
      RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFFF0000), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    (j) => expect(
      roundedRectangleBorderCodec.parse(j),
      RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFFF0000), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  _Case(
    'beveledRectangleBorder',
    () => beveledRectangleBorderCodec.encode(
      BeveledRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    (j) => expect(
      beveledRectangleBorderCodec.parse(j),
      BeveledRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  ),
  _Case(
    'continuousRectangleBorder',
    () => continuousRectangleBorderCodec.encode(
      ContinuousRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    (j) => expect(
      continuousRectangleBorderCodec.parse(j),
      ContinuousRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  ),
  _Case(
    'roundedSuperellipseBorder',
    () => roundedSuperellipseBorderCodec.encode(
      RoundedSuperellipseBorder(
        side: const BorderSide(color: Color(0xFFFF0000), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    (j) => expect(
      roundedSuperellipseBorderCodec.parse(j),
      RoundedSuperellipseBorder(
        side: const BorderSide(color: Color(0xFFFF0000), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  _Case(
    'starBorder',
    () => starBorderCodec.encode(
      const StarBorder(points: 7, innerRadiusRatio: 0.3),
    ),
    (j) => expect(
      starBorderCodec.parse(j),
      const StarBorder(points: 7, innerRadiusRatio: 0.3),
    ),
  ),
  // StarBorder.polygon is intentionally not recorded as a golden: its encoded
  // innerRadiusRatio is the polygon incircle (cos(pi / sides)), a libm-derived
  // value that is not guaranteed bit-identical across platforms. Its narrowing
  // round-trip is covered with a tolerance in shape_borders_test.dart.
  _Case(
    'linearBorderEdge',
    () => linearBorderEdgeCodec.encode(
      const LinearBorderEdge(size: 0.5, alignment: -0.25),
    ),
    (j) => expect(
      linearBorderEdgeCodec.parse(j),
      const LinearBorderEdge(size: 0.5, alignment: -0.25),
    ),
  ),
  _Case(
    'linearBorder',
    () => linearBorderCodec.encode(
      const LinearBorder(
        side: BorderSide(color: Color(0xFFFF0000), width: 2),
        start: LinearBorderEdge(size: 0.5),
        top: LinearBorderEdge(alignment: -1),
      ),
    ),
    (j) => expect(
      linearBorderCodec.parse(j),
      const LinearBorder(
        side: BorderSide(color: Color(0xFFFF0000), width: 2),
        start: LinearBorderEdge(size: 0.5),
        top: LinearBorderEdge(alignment: -1),
      ),
    ),
  ),
  _Case('shapeBorderStar', () => shapeBorderCodec.encode(const StarBorder()), (
    j,
  ) {
    final parsed = shapeBorderCodec.parse(j);
    expect(parsed, isA<StarBorder>());
    expect(parsed, const StarBorder());
  }),
  // OvalBorder extends CircleBorder, so the union routes it through the
  // "circle" branch and it round-trips as the painted-equivalent
  // CircleBorder(eccentricity: 1.0).
  _Case(
    'shapeBorderOval',
    () => shapeBorderCodec.encode(const OvalBorder()),
    (j) =>
        expect(shapeBorderCodec.parse(j), const CircleBorder(eccentricity: 1)),
  ),
];

// --- gradients --------------------------------------------------------------

final _gradients = <_Case>[
  _Case(
    'linearGradient',
    () => linearGradientCodec.encode(const LinearGradient(colors: _redBlue)),
    (j) => expect(
      linearGradientCodec.parse(j),
      const LinearGradient(colors: _redBlue),
    ),
  ),
  _Case(
    'linearGradientFull',
    () => linearGradientCodec.encode(
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _redBlue,
        stops: [0, 1],
        tileMode: TileMode.mirror,
      ),
    ),
    (j) => expect(
      linearGradientCodec.parse(j),
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _redBlue,
        stops: [0, 1],
        tileMode: TileMode.mirror,
      ),
    ),
  ),
  _Case(
    'radialGradient',
    () => radialGradientCodec.encode(const RadialGradient(colors: _redBlue)),
    (j) => expect(
      radialGradientCodec.parse(j),
      const RadialGradient(colors: _redBlue),
    ),
  ),
  _Case(
    'radialGradientFocal',
    () => radialGradientCodec.encode(
      const RadialGradient(
        colors: _redBlue,
        focal: Alignment.topLeft,
        focalRadius: 0.25,
      ),
    ),
    (j) => expect(
      radialGradientCodec.parse(j),
      const RadialGradient(
        colors: _redBlue,
        focal: Alignment.topLeft,
        focalRadius: 0.25,
      ),
    ),
  ),
  _Case(
    'sweepGradient',
    () => sweepGradientCodec.encode(const SweepGradient(colors: _redBlue)),
    (j) => expect(
      sweepGradientCodec.parse(j),
      const SweepGradient(colors: _redBlue),
    ),
  ),
  _Case(
    'gradientUnionLinear',
    () => gradientCodec.encode(const LinearGradient(colors: _redBlue)),
    (j) {
      final parsed = gradientCodec.parse(j);
      expect(parsed, isA<LinearGradient>());
      expect(parsed, const LinearGradient(colors: _redBlue));
    },
  ),
];

// --- shadows ----------------------------------------------------------------

final _shadows = <_Case>[
  _Case(
    'shadowDefault',
    () => shadowCodec.encode(const ui.Shadow()),
    (j) => expect(shadowCodec.parse(j), const ui.Shadow()),
  ),
  _Case(
    'shadow',
    () => shadowCodec.encode(
      const ui.Shadow(
        color: Color(0xFFFF0000),
        offset: Offset(2, 4),
        blurRadius: 6,
      ),
    ),
    (j) => expect(
      shadowCodec.parse(j),
      const ui.Shadow(
        color: Color(0xFFFF0000),
        offset: Offset(2, 4),
        blurRadius: 6,
      ),
    ),
  ),
  _Case(
    'boxShadowDefault',
    () => boxShadowCodec.encode(const BoxShadow()),
    (j) => expect(boxShadowCodec.parse(j), const BoxShadow()),
  ),
  _Case(
    'boxShadow',
    () => boxShadowCodec.encode(
      const BoxShadow(
        color: Color(0xFFFF0000),
        offset: Offset(2, 4),
        blurRadius: 6,
        spreadRadius: 1,
        blurStyle: BlurStyle.outer,
      ),
    ),
    (j) => expect(
      boxShadowCodec.parse(j),
      const BoxShadow(
        color: Color(0xFFFF0000),
        offset: Offset(2, 4),
        blurRadius: 6,
        spreadRadius: 1,
        blurStyle: BlurStyle.outer,
      ),
    ),
  ),
];

// --- image providers --------------------------------------------------------

final _imageProviders = <_Case>[
  _Case(
    'networkImageMinimal',
    () => networkImageCodec.encode(
      const NetworkImage('https://example.com/image.png'),
    ),
    (j) => expect(
      networkImageCodec.parse(j),
      const NetworkImage('https://example.com/image.png'),
    ),
  ),
  _Case(
    'networkImage',
    () => networkImageCodec.encode(
      const NetworkImage(
        'https://example.com/image.png',
        scale: 2,
        headers: {'Authorization': 'Bearer token'},
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      ),
    ),
    (j) => expect(
      networkImageCodec.parse(j),
      const NetworkImage(
        'https://example.com/image.png',
        scale: 2,
        headers: {'Authorization': 'Bearer token'},
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      ),
    ),
  ),
  _Case(
    'assetImageMinimal',
    () => assetImageCodec.encode(const AssetImage('assets/image.png')),
    (j) =>
        expect(assetImageCodec.parse(j), const AssetImage('assets/image.png')),
  ),
  _Case(
    'assetImage',
    () => assetImageCodec.encode(
      const AssetImage('assets/image.png', package: 'design_system'),
    ),
    (j) => expect(
      assetImageCodec.parse(j),
      const AssetImage('assets/image.png', package: 'design_system'),
    ),
  ),
  _Case(
    'imageProviderNetwork',
    () => imageProviderCodec.encode(
      const NetworkImage('https://example.com/image.png'),
    ),
    (j) {
      final parsed = imageProviderCodec.parse(j);
      expect(parsed, isA<NetworkImage>());
      expect(parsed, const NetworkImage('https://example.com/image.png'));
    },
  ),
  _Case(
    'imageProviderAsset',
    () => imageProviderCodec.encode(const AssetImage('assets/image.png')),
    (j) {
      final parsed = imageProviderCodec.parse(j);
      expect(parsed, isA<AssetImage>());
      expect(parsed, const AssetImage('assets/image.png'));
    },
  ),
];

// --- decorations ------------------------------------------------------------

final _decorations = <_Case>[
  _Case(
    'boxDecorationDefault',
    () => boxDecorationCodec.encode(const BoxDecoration()),
    (j) => expect(boxDecorationCodec.parse(j), const BoxDecoration()),
  ),
  _Case(
    'boxDecorationFull',
    () => boxDecorationCodec.encode(_fullBoxDecoration()),
    (j) => expect(boxDecorationCodec.parse(j), _fullBoxDecoration()),
  ),
  _Case(
    'boxDecorationImage',
    () => boxDecorationCodec.encode(
      BoxDecoration(
        image: DecorationImage(
          image: const NetworkImage('https://example.com/foo.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topLeft,
        ),
      ),
    ),
    (j) => expect(
      boxDecorationCodec.parse(j),
      BoxDecoration(
        image: DecorationImage(
          image: const NetworkImage('https://example.com/foo.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topLeft,
        ),
      ),
    ),
  ),
  _Case(
    'shapeDecorationCircle',
    () => shapeDecorationCodec.encode(
      const ShapeDecoration(shape: CircleBorder()),
    ),
    (j) => expect(
      shapeDecorationCodec.parse(j),
      const ShapeDecoration(shape: CircleBorder()),
    ),
  ),
  _Case(
    'shapeDecorationFull',
    () => shapeDecorationCodec.encode(_fullShapeDecoration()),
    (j) => expect(shapeDecorationCodec.parse(j), _fullShapeDecoration()),
  ),
  _Case(
    'shapeDecorationImage',
    () => shapeDecorationCodec.encode(
      const ShapeDecoration(
        shape: CircleBorder(),
        image: DecorationImage(
          image: NetworkImage('https://example.com/image.png'),
          fit: BoxFit.cover,
        ),
      ),
    ),
    (j) => expect(
      shapeDecorationCodec.parse(j),
      const ShapeDecoration(
        shape: CircleBorder(),
        image: DecorationImage(
          image: NetworkImage('https://example.com/image.png'),
          fit: BoxFit.cover,
        ),
      ),
    ),
  ),
  _Case(
    'decorationUnionBox',
    () => decorationCodec.encode(const BoxDecoration(color: Color(0xFF2196F3))),
    (j) {
      final parsed = decorationCodec.parse(j);
      expect(parsed, isA<BoxDecoration>());
      expect(parsed, const BoxDecoration(color: Color(0xFF2196F3)));
    },
  ),
  _Case(
    'decorationUnionShape',
    () => decorationCodec.encode(const ShapeDecoration(shape: CircleBorder())),
    (j) {
      final parsed = decorationCodec.parse(j);
      expect(parsed, isA<ShapeDecoration>());
      expect(parsed, const ShapeDecoration(shape: CircleBorder()));
    },
  ),
];

// --- decoration image -------------------------------------------------------

final _decorationImage = <_Case>[
  _Case(
    'decorationImageMinimal',
    () => decorationImageCodec.encode(
      DecorationImage(
        image: const NetworkImage('https://example.com/image.png'),
      ),
    ),
    (j) => expect(
      decorationImageCodec.parse(j),
      DecorationImage(
        image: const NetworkImage('https://example.com/image.png'),
      ),
    ),
  ),
  _Case(
    'decorationImageFull',
    () => decorationImageCodec.encode(_fullDecorationImage()),
    (j) => expect(decorationImageCodec.parse(j), _fullDecorationImage()),
  ),
];

// --- constraints ------------------------------------------------------------

final _constraints = <_Case>[
  _Case(
    'boxConstraintsDefault',
    () => boxConstraintsCodec.encode(const BoxConstraints()),
    (j) => expect(boxConstraintsCodec.parse(j), const BoxConstraints()),
  ),
  _Case(
    'boxConstraintsFinite',
    () => boxConstraintsCodec.encode(
      const BoxConstraints(
        minWidth: 1,
        maxWidth: 10,
        minHeight: 2,
        maxHeight: 20,
      ),
    ),
    (j) => expect(
      boxConstraintsCodec.parse(j),
      const BoxConstraints(
        minWidth: 1,
        maxWidth: 10,
        minHeight: 2,
        maxHeight: 20,
      ),
    ),
  ),
  _Case(
    'boxConstraintsExpand',
    () => boxConstraintsCodec.encode(const BoxConstraints.expand()),
    (j) => expect(boxConstraintsCodec.parse(j), const BoxConstraints.expand()),
  ),
  _Case(
    'constraintsUnionBox',
    () => constraintsCodec.encode(
      const BoxConstraints(
        minWidth: 1,
        maxWidth: 10,
        minHeight: 2,
        maxHeight: 20,
      ),
    ),
    (j) => expect(
      constraintsCodec.parse(j),
      const BoxConstraints(
        minWidth: 1,
        maxWidth: 10,
        minHeight: 2,
        maxHeight: 20,
      ),
    ),
  ),
];

// --- text + strut styles ----------------------------------------------------

final _text = <_Case>[
  _Case(
    'textStyleDefault',
    () => textStyleCodec.encode(const TextStyle()),
    (j) => expect(textStyleCodec.parse(j), const TextStyle()),
  ),
  _Case(
    'textStyleFull',
    () => textStyleCodec.encode(_fullTextStyle()),
    (j) => expect(textStyleCodec.parse(j), _fullTextStyle()),
  ),
  _Case(
    'strutStyleDefault',
    () => strutStyleCodec.encode(const StrutStyle()),
    (j) => expect(strutStyleCodec.parse(j), const StrutStyle()),
  ),
  _Case(
    'strutStyleFull',
    () => strutStyleCodec.encode(
      const StrutStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w700,
        forceStrutHeight: false,
      ),
    ),
    (j) => expect(
      strutStyleCodec.parse(j),
      const StrutStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w700,
        forceStrutHeight: false,
      ),
    ),
  ),
  _Case(
    'strutStylePackage',
    () => strutStyleCodec.encode(
      const StrutStyle(fontFamily: 'Roboto', package: 'my_pkg'),
    ),
    (j) => expect(
      strutStyleCodec.parse(j),
      const StrutStyle(fontFamily: 'Roboto', package: 'my_pkg'),
    ),
  ),
];

// --- widgets ----------------------------------------------------------------

final _widgets = <_Case>[
  _Case('containerDefault', () => containerWidgetCodec.encode(Container()), (
    j,
  ) {
    expect(containerWidgetCodec.parse(j), isA<Container>());
    expect(containerWidgetCodec.encode(containerWidgetCodec.parse(j)), j);
  }),
  _Case('containerFull', () => containerWidgetCodec.encode(_fullContainer()), (
    j,
  ) {
    expect(containerWidgetCodec.parse(j), isA<Container>());
    expect(containerWidgetCodec.encode(containerWidgetCodec.parse(j)), j);
  }),
  _Case(
    'textWidgetDefault',
    () => textWidgetCodec.encode(const Text('hello')),
    (j) {
      expect(textWidgetCodec.parse(j), isA<Text>());
      expect(textWidgetCodec.encode(textWidgetCodec.parse(j)), j);
    },
  ),
  _Case('textWidgetFull', () => textWidgetCodec.encode(_fullText()), (j) {
    expect(textWidgetCodec.parse(j), isA<Text>());
    expect(textWidgetCodec.encode(textWidgetCodec.parse(j)), j);
  }),
  _Case(
    'widgetUnionContainerWithText',
    () => widgetCodec.encode(
      Container(
        padding: const EdgeInsets.all(8),
        child: const Text('hi', textAlign: TextAlign.center),
      ),
    ),
    (j) {
      final parsed = widgetCodec.parse(j);
      expect(parsed, isA<Container>());
      expect((parsed! as Container).child, isA<Text>());
      expect(widgetCodec.encode(parsed), j);
    },
  ),
  _Case(
    'keyString',
    () => keyCodec.encode(const ValueKey<String>('foo')),
    (j) => expect(keyCodec.parse(j), const ValueKey<String>('foo')),
  ),
  _Case(
    'keyInt',
    () => keyCodec.encode(const ValueKey<int>(1)),
    (j) => expect(keyCodec.parse(j), const ValueKey<int>(1)),
  ),
  _Case(
    'keyDouble',
    () => keyCodec.encode(const ValueKey<double>(1.5)),
    (j) => expect(keyCodec.parse(j), const ValueKey<double>(1.5)),
  ),
  _Case(
    'keyBool',
    () => keyCodec.encode(const ValueKey<bool>(true)),
    (j) => expect(keyCodec.parse(j), const ValueKey<bool>(true)),
  ),
];

// --- enums ------------------------------------------------------------------

final _enums = <_Case>[
  _enumCase<Axis>('Axis', axisCodec, Axis.values),
  _enumCase<AxisDirection>(
    'AxisDirection',
    axisDirectionCodec,
    AxisDirection.values,
  ),
  _enumCase<BlendMode>('BlendMode', blendModeCodec, BlendMode.values),
  _enumCase<BlurStyle>('BlurStyle', blurStyleCodec, BlurStyle.values),
  _enumCase<BorderStyle>('BorderStyle', borderStyleCodec, BorderStyle.values),
  _enumCase<BoxFit>('BoxFit', boxFitCodec, BoxFit.values),
  _enumCase<ui.BoxHeightStyle>(
    'BoxHeightStyle',
    boxHeightStyleCodec,
    ui.BoxHeightStyle.values,
  ),
  _enumCase<BoxShape>('BoxShape', boxShapeCodec, BoxShape.values),
  _enumCase<ui.BoxWidthStyle>(
    'BoxWidthStyle',
    boxWidthStyleCodec,
    ui.BoxWidthStyle.values,
  ),
  _enumCase<Brightness>('Brightness', brightnessCodec, Brightness.values),
  _enumCase<Clip>('Clip', clipCodec, Clip.values),
  _enumCase<CrossAxisAlignment>(
    'CrossAxisAlignment',
    crossAxisAlignmentCodec,
    CrossAxisAlignment.values,
  ),
  _enumCase<DecorationPosition>(
    'DecorationPosition',
    decorationPositionCodec,
    DecorationPosition.values,
  ),
  _enumCase<DragStartBehavior>(
    'DragStartBehavior',
    dragStartBehaviorCodec,
    DragStartBehavior.values,
  ),
  _enumCase<FilterQuality>(
    'FilterQuality',
    filterQualityCodec,
    FilterQuality.values,
  ),
  _enumCase<FlexFit>('FlexFit', flexFitCodec, FlexFit.values),
  _enumCase<FontStyle>('FontStyle', fontStyleCodec, FontStyle.values),
  _enumCase<GrowthDirection>(
    'GrowthDirection',
    growthDirectionCodec,
    GrowthDirection.values,
  ),
  _enumCase<HitTestBehavior>(
    'HitTestBehavior',
    hitTestBehaviorCodec,
    HitTestBehavior.values,
  ),
  _enumCase<ImageRepeat>('ImageRepeat', imageRepeatCodec, ImageRepeat.values),
  _enumCase<WebHtmlElementStrategy>(
    'WebHtmlElementStrategy',
    webHtmlElementStrategyCodec,
    WebHtmlElementStrategy.values,
  ),
  _enumCase<MainAxisAlignment>(
    'MainAxisAlignment',
    mainAxisAlignmentCodec,
    MainAxisAlignment.values,
  ),
  _enumCase<MainAxisSize>(
    'MainAxisSize',
    mainAxisSizeCodec,
    MainAxisSize.values,
  ),
  _enumCase<MaterialTapTargetSize>(
    'MaterialTapTargetSize',
    materialTapTargetSizeCodec,
    MaterialTapTargetSize.values,
  ),
  _enumCase<PaintingStyle>(
    'PaintingStyle',
    paintingStyleCodec,
    PaintingStyle.values,
  ),
  _enumCase<PathFillType>(
    'PathFillType',
    pathFillTypeCodec,
    PathFillType.values,
  ),
  _enumCase<PlaceholderAlignment>(
    'PlaceholderAlignment',
    placeholderAlignmentCodec,
    PlaceholderAlignment.values,
  ),
  _enumCase<ScrollDirection>(
    'ScrollDirection',
    scrollDirectionCodec,
    ScrollDirection.values,
  ),
  _enumCase<ScrollViewKeyboardDismissBehavior>(
    'ScrollViewKeyboardDismissBehavior',
    scrollViewKeyboardDismissBehaviorCodec,
    ScrollViewKeyboardDismissBehavior.values,
  ),
  _enumCase<StackFit>('StackFit', stackFitCodec, StackFit.values),
  _enumCase<StrokeCap>('StrokeCap', strokeCapCodec, StrokeCap.values),
  _enumCase<StrokeJoin>('StrokeJoin', strokeJoinCodec, StrokeJoin.values),
  _enumCase<TargetPlatform>(
    'TargetPlatform',
    targetPlatformCodec,
    TargetPlatform.values,
  ),
  _enumCase<TextAlign>('TextAlign', textAlignCodec, TextAlign.values),
  _enumCase<TextBaseline>(
    'TextBaseline',
    textBaselineCodec,
    TextBaseline.values,
  ),
  _enumCase<TextCapitalization>(
    'TextCapitalization',
    textCapitalizationCodec,
    TextCapitalization.values,
  ),
  _enumCase<TextDecorationStyle>(
    'TextDecorationStyle',
    textDecorationStyleCodec,
    TextDecorationStyle.values,
  ),
  _enumCase<TextDirection>(
    'TextDirection',
    textDirectionCodec,
    TextDirection.values,
  ),
  _enumCase<TextLeadingDistribution>(
    'TextLeadingDistribution',
    textLeadingDistributionCodec,
    TextLeadingDistribution.values,
  ),
  _enumCase<TextOverflow>(
    'TextOverflow',
    textOverflowCodec,
    TextOverflow.values,
  ),
  _enumCase<TextWidthBasis>(
    'TextWidthBasis',
    textWidthBasisCodec,
    TextWidthBasis.values,
  ),
  _enumCase<ThemeMode>('ThemeMode', themeModeCodec, ThemeMode.values),
  _enumCase<TileMode>('TileMode', tileModeCodec, TileMode.values),
  _enumCase<VerticalDirection>(
    'VerticalDirection',
    verticalDirectionCodec,
    VerticalDirection.values,
  ),
  _enumCase<WrapAlignment>(
    'WrapAlignment',
    wrapAlignmentCodec,
    WrapAlignment.values,
  ),
  _enumCase<WrapCrossAlignment>(
    'WrapCrossAlignment',
    wrapCrossAlignmentCodec,
    WrapCrossAlignment.values,
  ),
];

// --- representative composite values ---------------------------------------

// A non-identity matrix built from translate + scale only. Trigonometric
// helpers (rotateZ, etc.) can differ in the last ULP across platforms, which
// would make the recorded golden machine-dependent; translate/scale are exact.
Matrix4 _transformedMatrix() {
  final matrix = Matrix4.identity()..translateByDouble(10, 20, 30, 1);
  matrix.setEntry(0, 0, 2);
  matrix.setEntry(1, 1, 3);
  return matrix;
}

Container _fullContainer() => Container(
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
  constraints: const BoxConstraints(
    minWidth: 10,
    maxWidth: 100,
    minHeight: 20,
    maxHeight: 200,
  ),
  margin: const EdgeInsetsDirectional.only(start: 2, end: 4),
  transform: _transformedMatrix(),
  transformAlignment: Alignment.bottomLeft,
  clipBehavior: Clip.antiAlias,
  child: Container(color: const Color(0xFFFF0000)),
);

BoxDecoration _fullBoxDecoration() => BoxDecoration(
  color: const Color(0xFF2196F3),
  border: Border.all(color: const Color(0xFFFF0000), width: 2),
  borderRadius: BorderRadius.circular(8),
  boxShadow: const [
    BoxShadow(
      color: Color(0x55000000),
      offset: Offset(1, 2),
      blurRadius: 3,
      spreadRadius: 4,
      blurStyle: BlurStyle.outer,
    ),
  ],
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _redBlue,
    stops: [0, 1],
    tileMode: TileMode.mirror,
  ),
  backgroundBlendMode: BlendMode.multiply,
);

ShapeDecoration _fullShapeDecoration() => ShapeDecoration(
  color: const Color(0xFF2196F3),
  shadows: const [
    BoxShadow(color: Color(0x55000000), offset: Offset(1, 2), blurRadius: 3),
  ],
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
);

DecorationImage _fullDecorationImage() => DecorationImage(
  image: const AssetImage('icons/foo.png', package: 'my_pkg'),
  fit: BoxFit.cover,
  alignment: Alignment.bottomRight,
  centerSlice: const Rect.fromLTRB(1, 2, 3, 4),
  repeat: ImageRepeat.repeatX,
  matchTextDirection: true,
  scale: 1.5,
  opacity: 0.75,
  filterQuality: FilterQuality.low,
  invertColors: true,
  isAntiAlias: true,
);

TextStyle _fullTextStyle() => const TextStyle(
  inherit: false,
  color: Color(0xFF2196F3),
  backgroundColor: Color(0xFFFFFDE7),
  fontSize: 18,
  fontWeight: FontWeight.bold,
  fontStyle: FontStyle.italic,
  letterSpacing: 0.25,
  wordSpacing: 1.5,
  textBaseline: TextBaseline.alphabetic,
  height: 1.3,
  leadingDistribution: TextLeadingDistribution.even,
  locale: Locale('zh', 'CN'),
  shadows: [
    ui.Shadow(color: Color(0x55000000), offset: Offset(1, 2), blurRadius: 3),
  ],
  decorationColor: Color(0xFFFF0000),
  decorationStyle: TextDecorationStyle.dashed,
  decorationThickness: 2,
  fontFamily: 'Inter',
  fontFamilyFallback: ['Roboto', 'Arial'],
  package: 'my_package',
  overflow: TextOverflow.ellipsis,
  fontFeatures: [FontFeature('smcp'), FontFeature('cv01', 3)],
  fontVariations: [FontVariation('wght', 500), FontVariation('slnt', -10)],
);

Text _fullText() => const Text(
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
