import 'dart:ui';

import 'package:ack/ack.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_codec/flutter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/json_safety.dart';

void main() {
  group('enum schemas', () {
    for (final entry in _registry) {
      group(entry.name, () {
        test('round-trips every enum value', () {
          for (final value in entry.values) {
            final encoded = entry.encode(value);
            expect(encoded, value.name);
            expectJsonSafe(encoded);
            expect(entry.parse(value.name), value);
          }
        });

        test('rejects unknown strings', () {
          expect(entry.rejects('__nope__'), isTrue);
        });
      });
    }
  });
}

final _registry = <_EnumCase<Enum>>[
  _EnumCase<Axis>('Axis', axisCodec, Axis.values),
  _EnumCase<AxisDirection>(
    'AxisDirection',
    axisDirectionCodec,
    AxisDirection.values,
  ),
  _EnumCase<BlendMode>('BlendMode', blendModeCodec, BlendMode.values),
  _EnumCase<BlurStyle>('BlurStyle', blurStyleCodec, BlurStyle.values),
  _EnumCase<BorderStyle>('BorderStyle', borderStyleCodec, BorderStyle.values),
  _EnumCase<BoxFit>('BoxFit', boxFitCodec, BoxFit.values),
  _EnumCase<BoxHeightStyle>(
    'BoxHeightStyle',
    boxHeightStyleCodec,
    BoxHeightStyle.values,
  ),
  _EnumCase<BoxShape>('BoxShape', boxShapeCodec, BoxShape.values),
  _EnumCase<BoxWidthStyle>(
    'BoxWidthStyle',
    boxWidthStyleCodec,
    BoxWidthStyle.values,
  ),
  _EnumCase<Brightness>('Brightness', brightnessCodec, Brightness.values),
  _EnumCase<Clip>('Clip', clipCodec, Clip.values),
  _EnumCase<CrossAxisAlignment>(
    'CrossAxisAlignment',
    crossAxisAlignmentCodec,
    CrossAxisAlignment.values,
  ),
  _EnumCase<DecorationPosition>(
    'DecorationPosition',
    decorationPositionCodec,
    DecorationPosition.values,
  ),
  _EnumCase<DragStartBehavior>(
    'DragStartBehavior',
    dragStartBehaviorCodec,
    DragStartBehavior.values,
  ),
  _EnumCase<FilterQuality>(
    'FilterQuality',
    filterQualityCodec,
    FilterQuality.values,
  ),
  _EnumCase<FlexFit>('FlexFit', flexFitCodec, FlexFit.values),
  _EnumCase<FontStyle>('FontStyle', fontStyleCodec, FontStyle.values),
  _EnumCase<GrowthDirection>(
    'GrowthDirection',
    growthDirectionCodec,
    GrowthDirection.values,
  ),
  _EnumCase<HitTestBehavior>(
    'HitTestBehavior',
    hitTestBehaviorCodec,
    HitTestBehavior.values,
  ),
  _EnumCase<ImageRepeat>('ImageRepeat', imageRepeatCodec, ImageRepeat.values),
  _EnumCase<WebHtmlElementStrategy>(
    'WebHtmlElementStrategy',
    webHtmlElementStrategyCodec,
    WebHtmlElementStrategy.values,
  ),
  _EnumCase<MainAxisAlignment>(
    'MainAxisAlignment',
    mainAxisAlignmentCodec,
    MainAxisAlignment.values,
  ),
  _EnumCase<MainAxisSize>(
    'MainAxisSize',
    mainAxisSizeCodec,
    MainAxisSize.values,
  ),
  _EnumCase<MaterialTapTargetSize>(
    'MaterialTapTargetSize',
    materialTapTargetSizeCodec,
    MaterialTapTargetSize.values,
  ),
  _EnumCase<PaintingStyle>(
    'PaintingStyle',
    paintingStyleCodec,
    PaintingStyle.values,
  ),
  _EnumCase<PathFillType>(
    'PathFillType',
    pathFillTypeCodec,
    PathFillType.values,
  ),
  _EnumCase<PlaceholderAlignment>(
    'PlaceholderAlignment',
    placeholderAlignmentCodec,
    PlaceholderAlignment.values,
  ),
  _EnumCase<ScrollDirection>(
    'ScrollDirection',
    scrollDirectionCodec,
    ScrollDirection.values,
  ),
  _EnumCase<ScrollViewKeyboardDismissBehavior>(
    'ScrollViewKeyboardDismissBehavior',
    scrollViewKeyboardDismissBehaviorCodec,
    ScrollViewKeyboardDismissBehavior.values,
  ),
  _EnumCase<StackFit>('StackFit', stackFitCodec, StackFit.values),
  _EnumCase<StrokeCap>('StrokeCap', strokeCapCodec, StrokeCap.values),
  _EnumCase<StrokeJoin>('StrokeJoin', strokeJoinCodec, StrokeJoin.values),
  _EnumCase<TargetPlatform>(
    'TargetPlatform',
    targetPlatformCodec,
    TargetPlatform.values,
  ),
  _EnumCase<TextAlign>('TextAlign', textAlignCodec, TextAlign.values),
  _EnumCase<TextBaseline>(
    'TextBaseline',
    textBaselineCodec,
    TextBaseline.values,
  ),
  _EnumCase<TextCapitalization>(
    'TextCapitalization',
    textCapitalizationCodec,
    TextCapitalization.values,
  ),
  _EnumCase<TextDecorationStyle>(
    'TextDecorationStyle',
    textDecorationStyleCodec,
    TextDecorationStyle.values,
  ),
  _EnumCase<TextDirection>(
    'TextDirection',
    textDirectionCodec,
    TextDirection.values,
  ),
  _EnumCase<TextLeadingDistribution>(
    'TextLeadingDistribution',
    textLeadingDistributionCodec,
    TextLeadingDistribution.values,
  ),
  _EnumCase<TextOverflow>(
    'TextOverflow',
    textOverflowCodec,
    TextOverflow.values,
  ),
  _EnumCase<TextWidthBasis>(
    'TextWidthBasis',
    textWidthBasisCodec,
    TextWidthBasis.values,
  ),
  _EnumCase<ThemeMode>('ThemeMode', themeModeCodec, ThemeMode.values),
  _EnumCase<TileMode>('TileMode', tileModeCodec, TileMode.values),
  _EnumCase<VerticalDirection>(
    'VerticalDirection',
    verticalDirectionCodec,
    VerticalDirection.values,
  ),
  _EnumCase<WrapAlignment>(
    'WrapAlignment',
    wrapAlignmentCodec,
    WrapAlignment.values,
  ),
  _EnumCase<WrapCrossAlignment>(
    'WrapCrossAlignment',
    wrapCrossAlignmentCodec,
    WrapCrossAlignment.values,
  ),
];

final class _EnumCase<T extends Enum> {
  const _EnumCase(this.name, this.schema, this.values);

  final String name;
  final CodecSchema<String, T> schema;
  final List<T> values;

  String? encode(Enum value) => schema.encode(value as T);

  T? parse(String value) => schema.parse(value);

  bool rejects(String value) => schema.safeParse(value).isFail;
}
