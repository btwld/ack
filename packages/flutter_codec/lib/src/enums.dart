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

/// Creates a reusable [CodecSchema] for the Dart enum [T], mapping each value
/// to and from its `.name` string. Wraps [Ack.enumValues] — which already does
/// the String↔enum conversion and emits an `enum` JSON Schema — in a codec so
/// the return type matches the package's other `*Codec` exports.
CodecSchema<String, T> enumCodec<T extends Enum>(List<T> values) =>
    Ack.enumValues(
      values,
    ).codec<T>(decode: (value) => value, encode: (value) => value);

final axisCodec = enumCodec(Axis.values);

final axisDirectionCodec = enumCodec(AxisDirection.values);

final blendModeCodec = enumCodec(BlendMode.values);

final blurStyleCodec = enumCodec(BlurStyle.values);

final borderStyleCodec = enumCodec(BorderStyle.values);

final boxFitCodec = enumCodec(BoxFit.values);

final boxHeightStyleCodec = enumCodec(BoxHeightStyle.values);

final boxShapeCodec = enumCodec(BoxShape.values);

final boxWidthStyleCodec = enumCodec(BoxWidthStyle.values);

final brightnessCodec = enumCodec(Brightness.values);

final clipCodec = enumCodec(Clip.values);

final crossAxisAlignmentCodec = enumCodec(CrossAxisAlignment.values);

final decorationPositionCodec = enumCodec(DecorationPosition.values);

final dragStartBehaviorCodec = enumCodec(DragStartBehavior.values);

final filterQualityCodec = enumCodec(FilterQuality.values);

final flexFitCodec = enumCodec(FlexFit.values);

final fontStyleCodec = enumCodec(FontStyle.values);

final growthDirectionCodec = enumCodec(GrowthDirection.values);

final hitTestBehaviorCodec = enumCodec(HitTestBehavior.values);

final imageRepeatCodec = enumCodec(ImageRepeat.values);

final mainAxisAlignmentCodec = enumCodec(MainAxisAlignment.values);

final mainAxisSizeCodec = enumCodec(MainAxisSize.values);

final materialTapTargetSizeCodec = enumCodec(MaterialTapTargetSize.values);

final paintingStyleCodec = enumCodec(PaintingStyle.values);

final pathFillTypeCodec = enumCodec(PathFillType.values);

final placeholderAlignmentCodec = enumCodec(PlaceholderAlignment.values);

final scrollDirectionCodec = enumCodec(ScrollDirection.values);

final scrollViewKeyboardDismissBehaviorCodec = enumCodec(
  ScrollViewKeyboardDismissBehavior.values,
);

final stackFitCodec = enumCodec(StackFit.values);

final strokeCapCodec = enumCodec(StrokeCap.values);

final strokeJoinCodec = enumCodec(StrokeJoin.values);

final targetPlatformCodec = enumCodec(TargetPlatform.values);

final textAlignCodec = enumCodec(TextAlign.values);

final textBaselineCodec = enumCodec(TextBaseline.values);

final textCapitalizationCodec = enumCodec(TextCapitalization.values);

final textDecorationStyleCodec = enumCodec(TextDecorationStyle.values);

final textDirectionCodec = enumCodec(TextDirection.values);

final textLeadingDistributionCodec = enumCodec(TextLeadingDistribution.values);

final textOverflowCodec = enumCodec(TextOverflow.values);

final textWidthBasisCodec = enumCodec(TextWidthBasis.values);

final themeModeCodec = enumCodec(ThemeMode.values);

final tileModeCodec = enumCodec(TileMode.values);

final verticalDirectionCodec = enumCodec(VerticalDirection.values);

final wrapAlignmentCodec = enumCodec(WrapAlignment.values);

final wrapCrossAlignmentCodec = enumCodec(WrapCrossAlignment.values);
