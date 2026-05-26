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

final axisCodec = Ack.enumCodec(Axis.values);

final axisDirectionCodec = Ack.enumCodec(AxisDirection.values);

final blendModeCodec = Ack.enumCodec(BlendMode.values);

final blurStyleCodec = Ack.enumCodec(BlurStyle.values);

final borderStyleCodec = Ack.enumCodec(BorderStyle.values);

final boxFitCodec = Ack.enumCodec(BoxFit.values);

final boxHeightStyleCodec = Ack.enumCodec(BoxHeightStyle.values);

final boxShapeCodec = Ack.enumCodec(BoxShape.values);

final boxWidthStyleCodec = Ack.enumCodec(BoxWidthStyle.values);

final brightnessCodec = Ack.enumCodec(Brightness.values);

final clipCodec = Ack.enumCodec(Clip.values);

final crossAxisAlignmentCodec = Ack.enumCodec(CrossAxisAlignment.values);

final decorationPositionCodec = Ack.enumCodec(DecorationPosition.values);

final dragStartBehaviorCodec = Ack.enumCodec(DragStartBehavior.values);

final filterQualityCodec = Ack.enumCodec(FilterQuality.values);

final flexFitCodec = Ack.enumCodec(FlexFit.values);

final fontStyleCodec = Ack.enumCodec(FontStyle.values);

final growthDirectionCodec = Ack.enumCodec(GrowthDirection.values);

final hitTestBehaviorCodec = Ack.enumCodec(HitTestBehavior.values);

final imageRepeatCodec = Ack.enumCodec(ImageRepeat.values);

final mainAxisAlignmentCodec = Ack.enumCodec(MainAxisAlignment.values);

final mainAxisSizeCodec = Ack.enumCodec(MainAxisSize.values);

final materialTapTargetSizeCodec = Ack.enumCodec(MaterialTapTargetSize.values);

final paintingStyleCodec = Ack.enumCodec(PaintingStyle.values);

final pathFillTypeCodec = Ack.enumCodec(PathFillType.values);

final placeholderAlignmentCodec = Ack.enumCodec(PlaceholderAlignment.values);

final scrollDirectionCodec = Ack.enumCodec(ScrollDirection.values);

final scrollViewKeyboardDismissBehaviorCodec = Ack.enumCodec(
  ScrollViewKeyboardDismissBehavior.values,
);

final stackFitCodec = Ack.enumCodec(StackFit.values);

final strokeCapCodec = Ack.enumCodec(StrokeCap.values);

final strokeJoinCodec = Ack.enumCodec(StrokeJoin.values);

final targetPlatformCodec = Ack.enumCodec(TargetPlatform.values);

final textAlignCodec = Ack.enumCodec(TextAlign.values);

final textBaselineCodec = Ack.enumCodec(TextBaseline.values);

final textCapitalizationCodec = Ack.enumCodec(TextCapitalization.values);

final textDecorationStyleCodec = Ack.enumCodec(TextDecorationStyle.values);

final textDirectionCodec = Ack.enumCodec(TextDirection.values);

final textLeadingDistributionCodec = Ack.enumCodec(
  TextLeadingDistribution.values,
);

final textOverflowCodec = Ack.enumCodec(TextOverflow.values);

final textWidthBasisCodec = Ack.enumCodec(TextWidthBasis.values);

final themeModeCodec = Ack.enumCodec(ThemeMode.values);

final tileModeCodec = Ack.enumCodec(TileMode.values);

final verticalDirectionCodec = Ack.enumCodec(VerticalDirection.values);

final wrapAlignmentCodec = Ack.enumCodec(WrapAlignment.values);

final wrapCrossAlignmentCodec = Ack.enumCodec(WrapCrossAlignment.values);
