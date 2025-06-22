# MuseSchemas - Flutter UI Schema Library

A comprehensive schema validation library for Flutter UI components using the Ack validation framework. MuseSchemas provides type-safe, reusable schema definitions for all Flutter visual, typography, animation, and layout types.

## Installation and Setup

```dart
import 'package:ack/ack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
```

## Core MuseSchemas Class

```dart
/// Static schema definitions for Flutter UI components
/// Provides reusable, type-safe validation schemas following Ack patterns
class MuseSchemas {
  
  // ==============================================================================
  // 🎨 VISUAL STYLING SCHEMAS
  // ==============================================================================

  /// Schema for Flutter Color validation using Color() constructor
  static final colorSchema = Ack.object({
    'value': Ack.int.min(0), // 32-bit ARGB value
  }, required: ['value']);

  /// Schema for BorderSide validation
  static final borderSideSchema = Ack.object({
    'color': colorSchema,
    'width': Ack.double.min(0.0),
    'style': Ack.string.enumValues(BorderStyle.values),
    'strokeAlign': Ack.double.range(-1.0, 1.0).nullable(),
  }, required: ['color', 'width', 'style']);

  /// Schema for Border validation (all sides)
  static final borderSchema = Ack.object({
    'top': borderSideSchema.nullable(),
    'right': borderSideSchema.nullable(),
    'bottom': borderSideSchema.nullable(),
    'left': borderSideSchema.nullable(),
    'uniform': borderSideSchema.nullable(), // For Border.all()
  });

  /// Schema for BorderDirectional validation  
  static final borderDirectionalSchema = Ack.object({
    'top': borderSideSchema.nullable(),
    'start': borderSideSchema.nullable(),
    'end': borderSideSchema.nullable(),
    'bottom': borderSideSchema.nullable(),
  });

  /// Schema for BorderRadius validation using BorderRadius.only() constructor
  static final borderRadiusSchema = Ack.object({
    'topLeft': Ack.double.min(0.0),
    'topRight': Ack.double.min(0.0),
    'bottomLeft': Ack.double.min(0.0),
    'bottomRight': Ack.double.min(0.0),
  }, required: ['topLeft', 'topRight', 'bottomLeft', 'bottomRight']);

  /// Schema for Offset validation
  static final offsetSchema = Ack.object({
    'dx': Ack.double,
    'dy': Ack.double,
  }, required: ['dx', 'dy']);

  /// Schema for BoxShadow validation
  static final boxShadowSchema = Ack.object({
    'color': colorSchema,
    'offset': offsetSchema,
    'blurRadius': Ack.double.min(0.0),
    'spreadRadius': Ack.double,
    'blurStyle': Ack.string.enumValues(BlurStyle.values),
  }, required: ['color', 'offset', 'blurRadius']);

  /// Schema for text Shadow validation
  static final shadowSchema = Ack.object({
    'color': colorSchema,
    'offset': offsetSchema,
    'blurRadius': Ack.double.min(0.0),
  }, required: ['color', 'offset', 'blurRadius']);

  /// Schema for EdgeInsets validation using EdgeInsets.fromLTRB() constructor
  static final edgeInsetsSchema = Ack.object({
    'left': Ack.double.min(0.0),
    'top': Ack.double.min(0.0),
    'right': Ack.double.min(0.0),
    'bottom': Ack.double.min(0.0),
  }, required: ['left', 'top', 'right', 'bottom']);

  /// Schema for Alignment validation using Alignment() constructor
  static final alignmentSchema = Ack.object({
    'x': Ack.double.range(-1.0, 1.0),
    'y': Ack.double.range(-1.0, 1.0),
  }, required: ['x', 'y']);

  /// Schema for Matrix4 validation using Matrix4() constructor
  static final matrix4Schema = Ack.object({
    'storage': Ack.list(Ack.double).exactItems(16), // 4x4 matrix values
  }, required: ['storage']);

  /// Schema for DecorationImage validation
  static final decorationImageSchema = Ack.object({
    'image': Ack.string.uri(), // Asset path or network URL
    'fit': Ack.string.enumValues(BoxFit.values).nullable(),
    'alignment': alignmentSchema.nullable(),
    'repeat': Ack.string.enumValues(ImageRepeat.values).nullable(),
    'centerSlice': edgeInsetsSchema.nullable(),
    'matchTextDirection': Ack.boolean.nullable(),
    'scale': Ack.double.positive().nullable(),
    'opacity': Ack.double.range(0.0, 1.0).nullable(),
    'filterQuality': Ack.string.enumValues(FilterQuality.values).nullable(),
    'invertColors': Ack.boolean.nullable(),
    'isAntiAlias': Ack.boolean.nullable(),
  }, required: ['image']);

  /// Schema for LinearGradient validation using LinearGradient() constructor
  static final gradientSchema = Ack.object({
    'colors': Ack.list(colorSchema).minItems(2),
    'stops': Ack.list(Ack.double.range(0.0, 1.0)).nullable(),
    'begin': alignmentSchema,
    'end': alignmentSchema,
    'tileMode': Ack.string.enumValues(TileMode.values).nullable(),
    'transform': matrix4Schema.nullable(),
  }, required: ['colors', 'begin', 'end']);

  /// Schema for BoxDecoration validation
  static final boxDecorationSchema = Ack.object({
    'color': colorSchema.nullable(),
    'image': decorationImageSchema.nullable(),
    'border': borderSchema.nullable(),
    'borderRadius': borderRadiusSchema.nullable(),
    'boxShadow': Ack.list(boxShadowSchema).nullable(),
    'gradient': gradientSchema.nullable(),
    'backgroundBlendMode': Ack.string.enumValues(BlendMode.values).nullable(),
    'shape': Ack.string.enumValues(BoxShape.values).nullable(),
  });

  /// Schema for Shape validation (reusable across widgets)
  static final shapeSchema = Ack.object({
    'type': Ack.string.enumValues(['rectangle', 'roundedRectangle', 'circle', 'stadium', 'border']),
    'borderRadius': borderRadiusSchema.nullable(),
    'side': borderSideSchema.nullable(),
  }, required: ['type']);

  /// Schema for ShapeDecoration validation
  static final shapeDecorationSchema = Ack.object({
    'color': colorSchema.nullable(),
    'image': decorationImageSchema.nullable(),
    'gradient': gradientSchema.nullable(),
    'shadows': Ack.list(boxShadowSchema).nullable(),
    'shape': shapeSchema,
  }, required: ['shape']);

  // ==============================================================================
  // 📝 TYPOGRAPHY SCHEMAS
  // ==============================================================================

  /// Schema for FontFeature validation
  static final fontFeatureSchema = Ack.object({
    'feature': Ack.string.minLength(4).maxLength(4), // OpenType feature tag
    'value': Ack.int.min(0),
  }, required: ['feature', 'value']);

  /// Schema for FontVariation validation
  static final fontVariationSchema = Ack.object({
    'axis': Ack.string.minLength(4).maxLength(4), // Font variation axis
    'value': Ack.double,
  }, required: ['axis', 'value']);

  /// Schema for MaskFilter validation
  static final maskFilterSchema = Ack.object({
    'blurStyle': Ack.string.enumValues(BlurStyle.values),
    'sigma': Ack.double.min(0.0),
  }, required: ['blurStyle', 'sigma']);

  /// Schema for TextDecoration validation with combine operations
  static final textDecorationSchema = Ack.object({
    'decorations': Ack.list(Ack.string.enumValues([
      'none', 'underline', 'overline', 'lineThrough'
    ])).minItems(1),
    'combined': Ack.boolean,
  }, required: ['decorations', 'combined']);

  /// Schema for Paint (foreground/background) validation
  static final paintSchema = Ack.object({
    'color': colorSchema.nullable(),
    'shader': gradientSchema.nullable(),
    'strokeWidth': Ack.double.min(0.0).nullable(),
    'style': Ack.string.enumValues(['fill', 'stroke']).nullable(),
    'strokeCap': Ack.string.enumValues(['butt', 'round', 'square']).nullable(),
    'strokeJoin': Ack.string.enumValues(['miter', 'round', 'bevel']).nullable(),
    'strokeMiterLimit': Ack.double.positive().nullable(),
    'maskFilter': maskFilterSchema.nullable(),
    'filterQuality': Ack.string.enumValues(FilterQuality.values).nullable(),
    'isAntiAlias': Ack.boolean.nullable(),
  });

  /// Schema for comprehensive TextStyle validation
  static final textStyleSchema = Ack.object({
    'inherit': Ack.boolean.nullable(),
    'color': colorSchema.nullable(),
    'backgroundColor': colorSchema.nullable(),
    'fontSize': Ack.double.positive().nullable(),
    'fontWeight': Ack.string.enumValues(FontWeight.values).nullable(),
    'fontStyle': Ack.string.enumValues(FontStyle.values).nullable(),
    'letterSpacing': Ack.double.nullable(),
    'wordSpacing': Ack.double.nullable(),
    'textBaseline': Ack.string.enumValues(TextBaseline.values).nullable(),
    'height': Ack.double.positive().nullable(),
    'leadingDistribution': Ack.string.enumValues(TextLeadingDistribution.values).nullable(),
    'locale': Ack.string.matches(r'^[a-z]{2}(_[A-Z]{2})?$').nullable(), // Locale format
    'foreground': paintSchema.nullable(),
    'background': paintSchema.nullable(),
    'shadows': Ack.list(shadowSchema).nullable(),
    'fontFeatures': Ack.list(fontFeatureSchema).nullable(),
    'fontVariations': Ack.list(fontVariationSchema).nullable(),
    'decoration': textDecorationSchema.nullable(),
    'decorationColor': colorSchema.nullable(),
    'decorationStyle': Ack.string.enumValues(TextDecorationStyle.values).nullable(),
    'decorationThickness': Ack.double.nullable(),
    'debugLabel': Ack.string.nullable(),
    'fontFamily': Ack.string.nullable(),
    'fontFamilyFallback': Ack.list(Ack.string).nullable(),
    'overflow': Ack.string.enumValues(TextOverflow.values).nullable(),
    'package': Ack.string.nullable(), // For custom fonts
  });

  /// Schema for StrutStyle validation
  static final strutStyleSchema = Ack.object({
    'fontFamily': Ack.string.nullable(),
    'fontFamilyFallback': Ack.list(Ack.string).nullable(),
    'fontSize': Ack.double.positive().nullable(),
    'height': Ack.double.positive().nullable(),
    'leadingDistribution': Ack.string.enumValues(TextLeadingDistribution.values).nullable(),
    'leading': Ack.double.nullable(),
    'fontWeight': Ack.string.enumValues(FontWeight.values).nullable(),
    'fontStyle': Ack.string.enumValues(FontStyle.values).nullable(),
    'forceStrutHeight': Ack.boolean.nullable(),
    'debugLabel': Ack.string.nullable(),
    'package': Ack.string.nullable(),
  });

  /// Schema for TextHeightBehavior validation
  static final textHeightBehaviorSchema = Ack.object({
    'applyHeightToFirstAscent': Ack.boolean,
    'applyHeightToLastDescent': Ack.boolean,
    'leadingDistribution': Ack.string.enumValues(TextLeadingDistribution.values).nullable(),
  }, required: ['applyHeightToFirstAscent', 'applyHeightToLastDescent']);

  /// Schema for TextScaler validation using TextScaler.linear() constructor
  static final textScalerSchema = Ack.object({
    'scaleFactor': Ack.double.positive(), // For linear scaling
  }, required: ['scaleFactor']);

  /// Schema for TextTheme validation (Material 3 typography scale)
  static final textThemeSchema = Ack.object({
    'displayLarge': textStyleSchema.nullable(),
    'displayMedium': textStyleSchema.nullable(),
    'displaySmall': textStyleSchema.nullable(),
    'headlineLarge': textStyleSchema.nullable(),
    'headlineMedium': textStyleSchema.nullable(),
    'headlineSmall': textStyleSchema.nullable(),
    'titleLarge': textStyleSchema.nullable(),
    'titleMedium': textStyleSchema.nullable(),
    'titleSmall': textStyleSchema.nullable(),
    'bodyLarge': textStyleSchema.nullable(),
    'bodyMedium': textStyleSchema.nullable(),
    'bodySmall': textStyleSchema.nullable(),
    'labelLarge': textStyleSchema.nullable(),
    'labelMedium': textStyleSchema.nullable(),
    'labelSmall': textStyleSchema.nullable(),
  });

  // ==============================================================================
  // 🔄 ANIMATION & TRANSFORM SCHEMAS
  // ==============================================================================

  /// Schema for Duration validation using Duration() constructor
  static final durationSchema = Ack.object({
    'days': Ack.int.min(0).nullable(),
    'hours': Ack.int.min(0).nullable(),
    'minutes': Ack.int.min(0).nullable(),
    'seconds': Ack.int.min(0).nullable(),
    'milliseconds': Ack.int.min(0).nullable(),
    'microseconds': Ack.int.min(0).nullable(),
  });

  /// Schema for Curve validation using Cubic() constructor
  static final curveSchema = Ack.object({
    'x1': Ack.double.range(0.0, 1.0),
    'y1': Ack.double,
    'x2': Ack.double.range(0.0, 1.0),
    'y2': Ack.double,
  }, required: ['x1', 'y1', 'x2', 'y2']);

  /// Schema for AnimatedData validation
  static final animatedDataSchema = Ack.object({
    'duration': durationSchema,
    'curve': curveSchema,
    'reverseDuration': durationSchema.nullable(),
    'reverseCurve': curveSchema.nullable(),
    'vsync': Ack.boolean, // Whether ticker provider is available
  }, required: ['duration', 'curve', 'vsync']);

  // ==============================================================================
  // 📐 GEOMETRY & LAYOUT SCHEMAS
  // ==============================================================================

  /// Schema for Size validation using Size() constructor
  static final sizeSchema = Ack.object({
    'width': Ack.double.min(0.0),
    'height': Ack.double.min(0.0),
  }, required: ['width', 'height']);

  /// Schema for Rect validation using Rect.fromLTWH() constructor
  static final rectSchema = Ack.object({
    'left': Ack.double,
    'top': Ack.double,
    'width': Ack.double.min(0.0),
    'height': Ack.double.min(0.0),
  }, required: ['left', 'top', 'width', 'height']);

  /// Schema for BoxConstraints validation
  static final boxConstraintsSchema = Ack.object({
    'minWidth': Ack.double.min(0.0),
    'maxWidth': Ack.double.min(0.0),
    'minHeight': Ack.double.min(0.0),
    'maxHeight': Ack.double.min(0.0),
  }, required: ['minWidth', 'maxWidth', 'minHeight', 'maxHeight']);

  // ==============================================================================
  // 📱 FLUTTER ENUM SCHEMAS
  // ==============================================================================

  // Layout Enums
  static final axisSchema = Ack.string.enumValues(Axis.values);
  static final crossAxisAlignmentSchema = Ack.string.enumValues(CrossAxisAlignment.values);
  static final mainAxisAlignmentSchema = Ack.string.enumValues(MainAxisAlignment.values);
  static final mainAxisSizeSchema = Ack.string.enumValues(MainAxisSize.values);
  static final verticalDirectionSchema = Ack.string.enumValues(VerticalDirection.values);
  static final textDirectionSchema = Ack.string.enumValues(TextDirection.values);

  // Visual Enums
  static final blendModeSchema = Ack.string.enumValues(BlendMode.values);
  static final boxFitSchema = Ack.string.enumValues(BoxFit.values);
  static final clipSchema = Ack.string.enumValues(Clip.values);
  static final filterQualitySchema = Ack.string.enumValues(FilterQuality.values);
  static final imageRepeatSchema = Ack.string.enumValues(ImageRepeat.values);
  static final stackFitSchema = Ack.string.enumValues(StackFit.values);

  // Typography Enums
  static final textAlignSchema = Ack.string.enumValues(TextAlign.values);
  static final textBaselineSchema = Ack.string.enumValues(TextBaseline.values);
  static final textOverflowSchema = Ack.string.enumValues(TextOverflow.values);
  static final textWidthBasisSchema = Ack.string.enumValues(TextWidthBasis.values);
  static final fontStyleSchema = Ack.string.enumValues(FontStyle.values);
  static final textDecorationStyleSchema = Ack.string.enumValues(TextDecorationStyle.values);
  static final textLeadingDistributionSchema = Ack.string.enumValues(TextLeadingDistribution.values);

  // Border Enums
  static final borderStyleSchema = Ack.string.enumValues(BorderStyle.values);

  // Additional Enums
  static final tileModeSchema = Ack.string.enumValues(TileMode.values);
  static final blurStyleSchema = Ack.string.enumValues(BlurStyle.values);
  static final boxShapeSchema = Ack.string.enumValues(BoxShape.values);
  static final fontWeightSchema = Ack.string.enumValues(FontWeight.values);

  // ==============================================================================
  // 🎛️ WIDGET-SPECIFIC SCHEMAS  
  // ==============================================================================

  /// Schema for Material widget properties using Material() constructor
  static final materialWidgetSchema = Ack.object({
    'elevation': Ack.double.range(0.0, 24.0),
    'color': colorSchema.nullable(),
    'shadowColor': colorSchema.nullable(),
    'surfaceTintColor': colorSchema.nullable(),
    'textStyle': textStyleSchema.nullable(),
    'borderRadius': borderRadiusSchema.nullable(),
    'shape': Ack.string.enumValues(['rectangle', 'circle']).nullable(),
    'borderOnForeground': Ack.boolean.nullable(),
    'clipBehavior': clipSchema.nullable(),
    'animationDuration': durationSchema.nullable(),
  }, required: ['elevation']);

  /// Schema for Container widget properties
  static final containerWidgetSchema = Ack.object({
    'alignment': alignmentSchema.nullable(),
    'padding': edgeInsetsSchema.nullable(),
    'color': colorSchema.nullable(),
    'decoration': boxDecorationSchema.nullable(),
    'foregroundDecoration': boxDecorationSchema.nullable(),
    'width': Ack.double.min(0.0).nullable(),
    'height': Ack.double.min(0.0).nullable(),
    'constraints': boxConstraintsSchema.nullable(),
    'margin': edgeInsetsSchema.nullable(),
    'transform': matrix4Schema.nullable(),
    'transformAlignment': alignmentSchema.nullable(),
    'clipBehavior': clipSchema.nullable(),
  });

  /// Schema for Text widget properties
  static final textWidgetSchema = Ack.object({
    'data': Ack.string,
    'style': textStyleSchema.nullable(),
    'strutStyle': strutStyleSchema.nullable(),
    'textAlign': textAlignSchema.nullable(),
    'textDirection': textDirectionSchema.nullable(),
    'locale': Ack.string.matches(r'^[a-z]{2}(_[A-Z]{2})?$').nullable(),
    'softWrap': Ack.boolean.nullable(),
    'overflow': textOverflowSchema.nullable(),
    'textScaleFactor': Ack.double.positive().nullable(),
    'textScaler': textScalerSchema.nullable(),
    'maxLines': Ack.int.positive().nullable(),
    'semanticsLabel': Ack.string.nullable(),
    'textWidthBasis': textWidthBasisSchema.nullable(),
    'textHeightBehavior': textHeightBehaviorSchema.nullable(),
    'selectionColor': colorSchema.nullable(),
  }, required: ['data']);

  // ==============================================================================
  // 🏗️ COMPOSITE SCHEMAS FOR COMMON USE CASES
  // ==============================================================================

  /// Schema for complete theme configuration
  static final themeDataSchema = Ack.object({
    'brightness': Ack.string.enumValues(['light', 'dark']),
    'primarySwatch': colorSchema.nullable(),
    'primaryColor': colorSchema.nullable(),
    'primaryColorLight': colorSchema.nullable(),
    'primaryColorDark': colorSchema.nullable(),
    'canvasColor': colorSchema.nullable(),
    'scaffoldBackgroundColor': colorSchema.nullable(),
    'cardColor': colorSchema.nullable(),
    'dividerColor': colorSchema.nullable(),
    'focusColor': colorSchema.nullable(),
    'hoverColor': colorSchema.nullable(),
    'highlightColor': colorSchema.nullable(),
    'splashColor': colorSchema.nullable(),
    'selectedRowColor': colorSchema.nullable(),
    'unselectedWidgetColor': colorSchema.nullable(),
    'disabledColor': colorSchema.nullable(),
    'secondaryHeaderColor': colorSchema.nullable(),
    'backgroundColor': colorSchema.nullable(),
    'dialogBackgroundColor': colorSchema.nullable(),
    'indicatorColor': colorSchema.nullable(),
    'hintColor': colorSchema.nullable(),
    'errorColor': colorSchema.nullable(),
    'toggleableActiveColor': colorSchema.nullable(),
    'fontFamily': Ack.string.nullable(),
    'textTheme': textThemeSchema.nullable(),
    'visualDensity': Ack.string.enumValues(['compact', 'comfortable', 'standard', 'adaptivePlatformDensity']).nullable(),
    'materialTapTargetSize': Ack.string.enumValues(['padded', 'shrinkWrap']).nullable(),
    'pageTransitionsTheme': Ack.object({
      'builders': Ack.object({}).nullable(), // Platform-specific builders
    }).nullable(),
    'platform': Ack.string.enumValues(['android', 'iOS', 'fuchsia', 'linux', 'macOS', 'windows']).nullable(),
  });

  /// Schema for Material 3 ColorScheme validation
  static final colorSchemeSchema = Ack.object({
    'brightness': Ack.string.enumValues(['light', 'dark']),
    'primary': colorSchema,
    'onPrimary': colorSchema,
    'primaryContainer': colorSchema.nullable(),
    'onPrimaryContainer': colorSchema.nullable(),
    'secondary': colorSchema,
    'onSecondary': colorSchema,
    'secondaryContainer': colorSchema.nullable(),
    'onSecondaryContainer': colorSchema.nullable(),
    'tertiary': colorSchema.nullable(),
    'onTertiary': colorSchema.nullable(),
    'tertiaryContainer': colorSchema.nullable(),
    'onTertiaryContainer': colorSchema.nullable(),
    'error': colorSchema,
    'onError': colorSchema,
    'errorContainer': colorSchema.nullable(),
    'onErrorContainer': colorSchema.nullable(),
    'outline': colorSchema.nullable(),
    'outlineVariant': colorSchema.nullable(),
    'background': colorSchema,
    'onBackground': colorSchema,
    'surface': colorSchema,
    'onSurface': colorSchema,
    'surfaceVariant': colorSchema.nullable(),
    'onSurfaceVariant': colorSchema.nullable(),
    'inverseSurface': colorSchema.nullable(),
    'onInverseSurface': colorSchema.nullable(),
    'inversePrimary': colorSchema.nullable(),
    'shadow': colorSchema.nullable(),
    'scrim': colorSchema.nullable(),
    'surfaceTint': colorSchema.nullable(),
  }, required: [
    'brightness', 'primary', 'onPrimary', 'secondary', 'onSecondary',
    'error', 'onError', 'background', 'onBackground', 'surface', 'onSurface'
  ]);

  /// Schema for Card widget configuration
  static final cardWidgetSchema = Ack.object({
    'color': colorSchema.nullable(),
    'shadowColor': colorSchema.nullable(),
    'surfaceTintColor': colorSchema.nullable(),
    'elevation': Ack.double.range(0.0, 24.0).nullable(),
    'shape': shapeSchema.nullable(),
    'borderOnForeground': Ack.boolean.nullable(),
    'margin': edgeInsetsSchema.nullable(),
    'clipBehavior': clipSchema.nullable(),
    'semanticContainer': Ack.boolean.nullable(),
  });

  /// Schema for Button styling configuration
  static final buttonStyleSchema = Ack.object({
    'textStyle': textStyleSchema.nullable(),
    'backgroundColor': colorSchema.nullable(),
    'foregroundColor': colorSchema.nullable(),
    'overlayColor': colorSchema.nullable(),
    'shadowColor': colorSchema.nullable(),
    'surfaceTintColor': colorSchema.nullable(),
    'elevation': Ack.double.range(0.0, 24.0).nullable(),
    'padding': edgeInsetsSchema.nullable(),
    'minimumSize': sizeSchema.nullable(),
    'fixedSize': sizeSchema.nullable(),
    'maximumSize': sizeSchema.nullable(),
    'side': borderSideSchema.nullable(),
    'shape': shapeSchema.nullable(),
    'mouseCursor': Ack.string.enumValues(['click', 'basic', 'forbidden', 'grab', 'grabbing']).nullable(),
    'visualDensity': Ack.string.enumValues(['compact', 'comfortable', 'standard']).nullable(),
    'tapTargetSize': Ack.string.enumValues(['padded', 'shrinkWrap']).nullable(),
    'animationDuration': durationSchema.nullable(),
    'enableFeedback': Ack.boolean.nullable(),
    'alignment': alignmentSchema.nullable(),
    'splashFactory': Ack.string.enumValues(['ink', 'ripple', 'noSplash']).nullable(),
  });
}
```

## Usage Examples

### Basic Schema Validation

```dart
// Validate a color configuration
final colorData = {
  'value': 0xFFFF5722, // ARGB format
};

final colorResult = MuseSchemas.colorSchema.validate(colorData);
if (colorResult.isOk) {
  print('Color is valid!');
}

// Validate a text style
final textStyleData = {
  'fontSize': 16.0,
  'fontWeight': FontWeight.bold,
  'color': {'value': 0xFF000000},
  'letterSpacing': 0.5,
};

final textStyleResult = MuseSchemas.textStyleSchema.validate(textStyleData);
```

### Component Configuration

```dart
// Validate a complete card configuration
final cardConfig = {
  'elevation': 4.0,
  'color': {'value': 0xFFFFFFFF},
  'shadowColor': {'value': 0x32000000}, // 50 alpha, black
  'shape': {
    'type': 'roundedRectangle',
    'borderRadius': {
      'topLeft': 8.0,
      'topRight': 8.0,
      'bottomLeft': 8.0,
      'bottomRight': 8.0,
    },
  },
  'margin': {
    'left': 16.0,
    'top': 16.0,
    'right': 16.0,
    'bottom': 16.0,
  },
  'clipBehavior': Clip.antiAlias,
};

final cardResult = MuseSchemas.cardWidgetSchema.validate(cardConfig);
```

### Widget Configuration

```dart
// Validate container widget properties
final containerConfig = {
  'alignment': {'x': 0.0, 'y': 0.0}, // Center alignment
  'padding': {'left': 16.0, 'top': 8.0, 'right': 16.0, 'bottom': 8.0},
  'decoration': {
    'color': {'value': 0xFFE3F2FD},
    'borderRadius': {
      'topLeft': 12.0,
      'topRight': 12.0,
      'bottomLeft': 12.0,
      'bottomRight': 12.0,
    },
  },
  'width': 200.0,
  'height': 100.0,
};

final containerResult = MuseSchemas.containerWidgetSchema.validate(containerConfig);
```

### Animation Configuration

```dart
// Validate animation settings
final animationConfig = {
  'duration': {'milliseconds': 300},
  'curve': {'x1': 0.25, 'y1': 0.1, 'x2': 0.25, 'y2': 1.0}, // ease curve
  'vsync': true,
};

final animationResult = MuseSchemas.animatedDataSchema.validate(animationConfig);
```

## Integration with Ack Generator

### Using with @AckModel

```dart
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class AppTheme {
  final Map<String, dynamic> colorScheme;
  final Map<String, dynamic> textTheme;
  final Map<String, dynamic> buttonStyle;
  
  const AppTheme({
    required this.colorScheme,
    required this.textTheme,
    required this.buttonStyle,
  });
}
```

### Schema Validation

```dart
// Define validation schemas for your models
final appThemeSchema = Ack.object({
  'colorScheme': MuseSchemas.colorSchemeSchema,
  'textTheme': MuseSchemas.textThemeSchema,
  'buttonStyle': MuseSchemas.buttonStyleSchema,
}, required: ['colorScheme', 'textTheme', 'buttonStyle']);

// Validate theme configuration
final themeConfig = {
  'colorScheme': colorSchemeData,
  'textTheme': textThemeData,
  'buttonStyle': buttonStyleData,
};

final result = appThemeSchema.validate(themeConfig);
```

## Best Practices

### 1. Schema Composition
Combine MuseSchemas for complex validations:

```dart
final widgetConfigSchema = Ack.object({
  'container': MuseSchemas.containerWidgetSchema,
  'text': MuseSchemas.textWidgetSchema,
  'material': MuseSchemas.materialWidgetSchema,
});
```

### 2. Custom Extensions
Extend MuseSchemas for app-specific needs:

```dart
extension AppMuseSchemas on MuseSchemas {
  static final customButtonWidgetSchema = Ack.object({
    'baseStyle': MuseSchemas.buttonStyleSchema,
    'customProperty': Ack.string,
  }, required: ['baseStyle', 'customProperty']);
}
```

### 3. Validation Pipelines
Create validation pipelines for complex workflows:

```dart
class ThemeValidator {
  static SchemaResult<Map<String, dynamic>> validateTheme(Map<String, dynamic> theme) {
    // Validate base theme
    final baseResult = MuseSchemas.themeDataSchema.validate(theme);
    if (!baseResult.isOk) return baseResult;
    
    // Additional custom validations
    return baseResult;
  }
}
```

### 4. Error Handling
Handle validation errors gracefully:

```dart
final result = MuseSchemas.colorSchema.validate(colorData);
result.fold(
  onSuccess: (validColor) => print('Color is valid: $validColor'),
  onFailure: (errors) => print('Validation errors: $errors'),
);
```

## Schema Extensions

### Creating Custom Schemas
Build upon MuseSchemas for domain-specific needs:

```dart
class DesignSystemSchemas {
  static final brandColorSchema = Ack.object({
    'primary': MuseSchemas.colorSchema,
    'secondary': MuseSchemas.colorSchema,
    'accent': MuseSchemas.colorSchema,
    'brand': Ack.string.enumValues(['corporate', 'playful', 'minimal']),
  }, required: ['primary', 'secondary', 'brand']);
  
  static final componentThemeSchema = Ack.object({
    'card': MuseSchemas.cardWidgetSchema,
    'button': MuseSchemas.buttonStyleSchema,
    'text': MuseSchemas.textStyleSchema,
    'spacing': MuseSchemas.edgeInsetsSchema,
  });
}
```

## Performance Considerations

1. **Schema Reuse**: MuseSchemas are static and immutable - reuse them across your application
2. **Lazy Validation**: Only validate when necessary, not on every render
3. **Caching**: Cache validation results for frequently used configurations
4. **Incremental Validation**: Validate only changed properties in complex objects

## Material 3 Compliance

MuseSchemas follow Material 3 design principles:
- Support for new color roles and tokens
- Updated typography scale
- Modern animation curves and durations
- Accessibility considerations built-in

## Contributing

When adding new schemas to MuseSchemas:
1. Follow the established naming patterns (`{type}Schema` for values, `{widget}WidgetSchema` for widgets)
2. Use direct enum values where possible
3. Include comprehensive validation constraints
4. Add usage examples
5. Ensure Material 3 compliance
6. Test with real Flutter widgets

---

**MuseSchemas** provides a complete, type-safe foundation for validating Flutter UI configurations using the Ack validation framework. Use these schemas to build robust, maintainable UI systems with confidence.