import 'package:ack/ack.dart';

part 'sealed_block_model.g.dart';

/// A sealed block class that demonstrates polymorphic model pattern with discrimination
@Schema(
  description: 'Base block class with polymorphic subclasses',
  discriminatedKey: 'type',
)
sealed class SealedBlock {
  /// The type field used for discrimination
  final String type;

  /// Optional alignment property
  final String? align;

  /// Optional flexibility property
  final int? flex;

  /// Whether the block is scrollable
  final bool? scrollable;

  const SealedBlock({
    required this.type,
    this.align,
    this.flex,
    this.scrollable,
  });

  /// Convert to a JSON map
  Map<String, dynamic> toJson();
}

/// Text block with markdown content
@Schema(
  description: 'A text block with markdown content',
  discriminatedValue: 'text',
)
class TextBlock extends SealedBlock {
  /// The markdown content for this block
  final String content;

  const TextBlock({
    super.align,
    super.flex,
    super.scrollable,
    required this.content,
  }) : super(type: 'text');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content,
      if (align != null) 'align': align,
      if (flex != null) 'flex': flex,
      if (scrollable != null) 'scrollable': scrollable,
    };
  }
}

/// Image block with image source
@Schema(
  description: 'An image block with image source and attributes',
  discriminatedValue: 'image',
)
class ImageBlock extends SealedBlock {
  /// The image path or URL
  final String src;

  /// Optional width
  final double? width;

  /// Optional height
  final double? height;

  /// Optional image fit mode
  final String? fit;

  const ImageBlock({
    super.align,
    super.flex,
    super.scrollable,
    required this.src,
    this.width,
    this.height,
    this.fit,
  }) : super(type: 'image');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'src': src,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (fit != null) 'fit': fit,
      if (align != null) 'align': align,
      if (flex != null) 'flex': flex,
      if (scrollable != null) 'scrollable': scrollable,
    };
  }
}

/// Widget block with custom properties
@Schema(
  description: 'A widget block with custom properties',
  additionalProperties: true,
  additionalPropertiesField: 'properties',
  discriminatedValue: 'widget',
)
class WidgetBlock extends SealedBlock {
  /// The widget name
  final String name;

  /// Any additional custom properties
  final Map<String, dynamic> properties;

  const WidgetBlock({
    super.align,
    super.flex,
    super.scrollable,
    required this.name,
    this.properties = const {},
  }) : super(type: 'widget');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      ...properties,
      if (align != null) 'align': align,
      if (flex != null) 'flex': flex,
      if (scrollable != null) 'scrollable': scrollable,
    };
  }
}
