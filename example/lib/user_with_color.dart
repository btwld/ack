import 'package:ack/ack.dart';

import 'pet.dart';

part 'user_with_color.g.dart';

class Color {
  final int value;
  const Color(this.value);

  @override
  String toString() =>
      '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Color schema: validates and bidirectionally maps hex values to Color.
@Schemable(name: 'ColorModel')
final colorSchema = Ack.string()
    .refine(
      (value) => RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value),
      message: 'Must be a valid hex color code (e.g., #FF0000)',
    )
    .codec<Color>(
      decode: (hex) => Color(int.parse(hex.substring(1), radix: 16)),
      encode: (color) => color.toString(),
    );

/// Profile: nested object with bio and website
@Schemable()
final profileSchema = Ack.object({
  'bio': Ack.string().minLength(1).maxLength(500),
  'website': Ack.uri().optional(),
});

/// User with color: combines user fields, nested profile, and color
@Schemable()
final userWithColorSchema =
    Ack.object({
      'firstName': Ack.string().minLength(1).maxLength(50),
      'lastName': Ack.string().minLength(1).maxLength(50),
      'age': Ack.integer().min(0).max(150),
      'profile': profileSchema,
      'color': colorSchema,
      'favoriteColor': colorSchema.optional(),
      'pet': petSchema,
      'pets': Ack.list(petSchema),
    }).refine(
      (data) => data['firstName'] != data['lastName'],
      message: 'firstName and lastName must be different',
    );
