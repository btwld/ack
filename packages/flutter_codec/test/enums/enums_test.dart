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
  _EnumCase<Axis>('Axis', axisSchema, Axis.values),
  _EnumCase<AxisDirection>(
    'AxisDirection',
    axisDirectionSchema,
    AxisDirection.values,
  ),
  _EnumCase<BlendMode>('BlendMode', blendModeSchema, BlendMode.values),
  _EnumCase<BlurStyle>('BlurStyle', blurStyleSchema, BlurStyle.values),
  _EnumCase<BorderStyle>('BorderStyle', borderStyleSchema, BorderStyle.values),
  _EnumCase<BoxFit>('BoxFit', boxFitSchema, BoxFit.values),
  _EnumCase<BoxHeightStyle>(
    'BoxHeightStyle',
    boxHeightStyleSchema,
    BoxHeightStyle.values,
  ),
  _EnumCase<BoxShape>('BoxShape', boxShapeSchema, BoxShape.values),
  _EnumCase<BoxWidthStyle>(
    'BoxWidthStyle',
    boxWidthStyleSchema,
    BoxWidthStyle.values,
  ),
  _EnumCase<Brightness>('Brightness', brightnessSchema, Brightness.values),
  _EnumCase<Clip>('Clip', clipSchema, Clip.values),
  _EnumCase<CrossAxisAlignment>(
    'CrossAxisAlignment',
    crossAxisAlignmentSchema,
    CrossAxisAlignment.values,
  ),
  _EnumCase<DecorationPosition>(
    'DecorationPosition',
    decorationPositionSchema,
    DecorationPosition.values,
  ),
  _EnumCase<DragStartBehavior>(
    'DragStartBehavior',
    dragStartBehaviorSchema,
    DragStartBehavior.values,
  ),
  _EnumCase<FilterQuality>(
    'FilterQuality',
    filterQualitySchema,
    FilterQuality.values,
  ),
  _EnumCase<FlexFit>('FlexFit', flexFitSchema, FlexFit.values),
  _EnumCase<FontStyle>('FontStyle', fontStyleSchema, FontStyle.values),
  _EnumCase<GrowthDirection>(
    'GrowthDirection',
    growthDirectionSchema,
    GrowthDirection.values,
  ),
  _EnumCase<HitTestBehavior>(
    'HitTestBehavior',
    hitTestBehaviorSchema,
    HitTestBehavior.values,
  ),
  _EnumCase<ImageRepeat>('ImageRepeat', imageRepeatSchema, ImageRepeat.values),
  _EnumCase<MainAxisAlignment>(
    'MainAxisAlignment',
    mainAxisAlignmentSchema,
    MainAxisAlignment.values,
  ),
  _EnumCase<MainAxisSize>(
    'MainAxisSize',
    mainAxisSizeSchema,
    MainAxisSize.values,
  ),
  _EnumCase<MaterialTapTargetSize>(
    'MaterialTapTargetSize',
    materialTapTargetSizeSchema,
    MaterialTapTargetSize.values,
  ),
  _EnumCase<PaintingStyle>(
    'PaintingStyle',
    paintingStyleSchema,
    PaintingStyle.values,
  ),
  _EnumCase<PathFillType>(
    'PathFillType',
    pathFillTypeSchema,
    PathFillType.values,
  ),
  _EnumCase<PlaceholderAlignment>(
    'PlaceholderAlignment',
    placeholderAlignmentSchema,
    PlaceholderAlignment.values,
  ),
  _EnumCase<ScrollDirection>(
    'ScrollDirection',
    scrollDirectionSchema,
    ScrollDirection.values,
  ),
  _EnumCase<ScrollViewKeyboardDismissBehavior>(
    'ScrollViewKeyboardDismissBehavior',
    scrollViewKeyboardDismissBehaviorSchema,
    ScrollViewKeyboardDismissBehavior.values,
  ),
  _EnumCase<StackFit>('StackFit', stackFitSchema, StackFit.values),
  _EnumCase<StrokeCap>('StrokeCap', strokeCapSchema, StrokeCap.values),
  _EnumCase<StrokeJoin>('StrokeJoin', strokeJoinSchema, StrokeJoin.values),
  _EnumCase<TargetPlatform>(
    'TargetPlatform',
    targetPlatformSchema,
    TargetPlatform.values,
  ),
  _EnumCase<TextAlign>('TextAlign', textAlignSchema, TextAlign.values),
  _EnumCase<TextBaseline>(
    'TextBaseline',
    textBaselineSchema,
    TextBaseline.values,
  ),
  _EnumCase<TextCapitalization>(
    'TextCapitalization',
    textCapitalizationSchema,
    TextCapitalization.values,
  ),
  _EnumCase<TextDecorationStyle>(
    'TextDecorationStyle',
    textDecorationStyleSchema,
    TextDecorationStyle.values,
  ),
  _EnumCase<TextDirection>(
    'TextDirection',
    textDirectionSchema,
    TextDirection.values,
  ),
  _EnumCase<TextLeadingDistribution>(
    'TextLeadingDistribution',
    textLeadingDistributionSchema,
    TextLeadingDistribution.values,
  ),
  _EnumCase<TextOverflow>(
    'TextOverflow',
    textOverflowSchema,
    TextOverflow.values,
  ),
  _EnumCase<TextWidthBasis>(
    'TextWidthBasis',
    textWidthBasisSchema,
    TextWidthBasis.values,
  ),
  _EnumCase<ThemeMode>('ThemeMode', themeModeSchema, ThemeMode.values),
  _EnumCase<TileMode>('TileMode', tileModeSchema, TileMode.values),
  _EnumCase<VerticalDirection>(
    'VerticalDirection',
    verticalDirectionSchema,
    VerticalDirection.values,
  ),
  _EnumCase<WrapAlignment>(
    'WrapAlignment',
    wrapAlignmentSchema,
    WrapAlignment.values,
  ),
  _EnumCase<WrapCrossAlignment>(
    'WrapCrossAlignment',
    wrapCrossAlignmentSchema,
    WrapCrossAlignment.values,
  ),
];

final class _EnumCase<T extends Enum> {
  const _EnumCase(this.name, this.schema, this.values);

  final String name;
  final EnumSchema<T> schema;
  final List<T> values;

  String? encode(Enum value) => schema.encode(value as T);

  T? parse(String value) => schema.parse(value);

  bool rejects(String value) => schema.safeParse(value).isFail;
}
