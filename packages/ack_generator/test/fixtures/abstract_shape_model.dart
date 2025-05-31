import 'package:ack/ack.dart';

part 'abstract_shape_model.g.dart';

/// An abstract shape class demonstrating discriminated unions with abstract classes
@Schema(
  description: 'A shape that can be a circle, rectangle, or triangle',
  discriminatedKey: 'type',
)
abstract class Shape {
  /// The shape type used for discrimination
  final String type;

  /// Optional color property
  final String? color;

  /// Whether the shape is filled
  final bool isFilled;

  const Shape({
    required this.type,
    this.color,
    this.isFilled = false,
  });

  /// Convert to JSON representation
  Map<String, dynamic> toJson();
}

/// Circle shape with radius
@Schema(
  description: 'A circular shape with radius',
  discriminatedValue: 'circle',
)
class Circle extends Shape {
  /// Circle radius
  final double radius;

  const Circle({
    super.color,
    super.isFilled,
    required this.radius,
  }) : super(type: 'circle');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'radius': radius,
      if (color != null) 'color': color,
      'isFilled': isFilled,
    };
  }
}

/// Rectangle shape with width and height
@Schema(
  description: 'A rectangular shape with width and height',
  discriminatedValue: 'rectangle',
)
class Rectangle extends Shape {
  /// Rectangle width
  final double width;

  /// Rectangle height
  final double height;

  const Rectangle({
    super.color,
    super.isFilled,
    required this.width,
    required this.height,
  }) : super(type: 'rectangle');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'width': width,
      'height': height,
      if (color != null) 'color': color,
      'isFilled': isFilled,
    };
  }
}

/// Triangle shape with three sides
@Schema(
  description: 'A triangular shape with three sides',
  discriminatedValue: 'triangle',
)
class Triangle extends Shape {
  /// First side length
  final double sideA;

  /// Second side length
  final double sideB;

  /// Third side length
  final double sideC;

  const Triangle({
    super.color,
    super.isFilled,
    required this.sideA,
    required this.sideB,
    required this.sideC,
  }) : super(type: 'triangle');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'sideA': sideA,
      'sideB': sideB,
      'sideC': sideC,
      if (color != null) 'color': color,
      'isFilled': isFilled,
    };
  }
}
