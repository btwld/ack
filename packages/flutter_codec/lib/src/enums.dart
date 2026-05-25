import 'dart:ui' show BoxHeightStyle, BoxWidthStyle;

import 'package:ack/ack.dart';
import 'package:flutter/foundation.dart' show Brightness, TargetPlatform;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart' show MaterialTapTargetSize, ThemeMode;
import 'package:flutter/painting.dart'
    show
        Axis,
        AxisDirection,
        BlendMode,
        BlurStyle,
        BorderStyle,
        BoxFit,
        BoxShape,
        Clip,
        FilterQuality,
        FontStyle,
        ImageRepeat,
        PaintingStyle,
        PathFillType,
        PlaceholderAlignment,
        StrokeCap,
        StrokeJoin,
        TextAlign,
        TextBaseline,
        TextDecorationStyle,
        TextDirection,
        TextLeadingDistribution,
        TextOverflow,
        TextWidthBasis,
        TileMode,
        VerticalDirection;
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
import 'package:flutter/widgets.dart' show ScrollViewKeyboardDismissBehavior;

final axisSchema = Ack.enumValues(Axis.values);

final axisDirectionSchema = Ack.enumValues(AxisDirection.values);

final blendModeSchema = Ack.enumValues(BlendMode.values);

final blurStyleSchema = Ack.enumValues(BlurStyle.values);

final borderStyleSchema = Ack.enumValues(BorderStyle.values);

final boxFitSchema = Ack.enumValues(BoxFit.values);

final boxHeightStyleSchema = Ack.enumValues(BoxHeightStyle.values);

final boxShapeSchema = Ack.enumValues(BoxShape.values);

final boxWidthStyleSchema = Ack.enumValues(BoxWidthStyle.values);

final brightnessSchema = Ack.enumValues(Brightness.values);

final clipSchema = Ack.enumValues(Clip.values);

final crossAxisAlignmentSchema = Ack.enumValues(CrossAxisAlignment.values);

final decorationPositionSchema = Ack.enumValues(DecorationPosition.values);

final dragStartBehaviorSchema = Ack.enumValues(DragStartBehavior.values);

final filterQualitySchema = Ack.enumValues(FilterQuality.values);

final flexFitSchema = Ack.enumValues(FlexFit.values);

final fontStyleSchema = Ack.enumValues(FontStyle.values);

final growthDirectionSchema = Ack.enumValues(GrowthDirection.values);

final hitTestBehaviorSchema = Ack.enumValues(HitTestBehavior.values);

final imageRepeatSchema = Ack.enumValues(ImageRepeat.values);

final mainAxisAlignmentSchema = Ack.enumValues(MainAxisAlignment.values);

final mainAxisSizeSchema = Ack.enumValues(MainAxisSize.values);

final materialTapTargetSizeSchema = Ack.enumValues(
  MaterialTapTargetSize.values,
);

final paintingStyleSchema = Ack.enumValues(PaintingStyle.values);

final pathFillTypeSchema = Ack.enumValues(PathFillType.values);

final placeholderAlignmentSchema = Ack.enumValues(PlaceholderAlignment.values);

final scrollDirectionSchema = Ack.enumValues(ScrollDirection.values);

final scrollViewKeyboardDismissBehaviorSchema = Ack.enumValues(
  ScrollViewKeyboardDismissBehavior.values,
);

final stackFitSchema = Ack.enumValues(StackFit.values);

final strokeCapSchema = Ack.enumValues(StrokeCap.values);

final strokeJoinSchema = Ack.enumValues(StrokeJoin.values);

final targetPlatformSchema = Ack.enumValues(TargetPlatform.values);

final textAlignSchema = Ack.enumValues(TextAlign.values);

final textBaselineSchema = Ack.enumValues(TextBaseline.values);

final textCapitalizationSchema = Ack.enumValues(TextCapitalization.values);

final textDecorationStyleSchema = Ack.enumValues(TextDecorationStyle.values);

final textDirectionSchema = Ack.enumValues(TextDirection.values);

final textLeadingDistributionSchema = Ack.enumValues(
  TextLeadingDistribution.values,
);

final textOverflowSchema = Ack.enumValues(TextOverflow.values);

final textWidthBasisSchema = Ack.enumValues(TextWidthBasis.values);

final themeModeSchema = Ack.enumValues(ThemeMode.values);

final tileModeSchema = Ack.enumValues(TileMode.values);

final verticalDirectionSchema = Ack.enumValues(VerticalDirection.values);

final wrapAlignmentSchema = Ack.enumValues(WrapAlignment.values);

final wrapCrossAlignmentSchema = Ack.enumValues(WrapCrossAlignment.values);
