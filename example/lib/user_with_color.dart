import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'user_with_color.g.dart';

class Color {
  final int value;
  const Color(this.value);

  @override
  String toString() =>
      '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Color schema: validates hex code format, then transforms to Color object
@AckType()
final colorSchema = Ack.string()
    .refine(
      (value) => RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value),
      message: 'Must be a valid hex color code (e.g., #FF0000)',
    )
    .transform<Color>(
      (hex) => Color(int.parse(hex.substring(1), radix: 16)),
    );

/// Profile: nested object with bio and website
@AckType()
final profileSchema = Ack.object({
  'bio': Ack.string().minLength(1).maxLength(500),
  'website': Ack.uri().optional(),
});

/// User with color: combines user fields, nested profile, and color
@AckType()
final userWithColorSchema = Ack.object({
  'firstName': Ack.string().minLength(1).maxLength(50),
  'lastName': Ack.string().minLength(1).maxLength(50),
  'age': Ack.integer().min(0).max(150),
  'profile': profileSchema,
  'color': colorSchema,
});
