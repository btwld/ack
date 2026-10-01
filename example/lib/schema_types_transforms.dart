import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'schema_types_transforms.ack.dart';
part 'schema_types_transforms.ack.g.dart';

class Color {
  final String value;
  const Color(this.value);
}

class TagList {
  final List<String> value;
  const TagList(this.value);
}

final baseColorSchema = Ack.string();

@AckInfer(name: 'ColorModel')
final colorSchema = Ack.string().codec<Color>(
  decode: Color.new,
  encode: (color) => color.value,
);

@AckInfer()
final profileSchema = Ack.object({
  'homepage': Ack.uri(),
  'birthday': Ack.date(),
  'lastLogin': Ack.datetime(),
  'timeout': Ack.duration(),
  'links': Ack.list(Ack.uri()),
  'favoriteColor': Ack.string().codec<Color>(
    decode: Color.new,
    encode: (color) => color.value,
  ),
  'slug': Ack.string().codec<String>(
    decode: (value) => '$value#',
    encode: (value) =>
        value.endsWith('#') ? value.substring(0, value.length - 1) : value,
  ),
  'accent': colorSchema,
  'colors': Ack.list(colorSchema),
  'customColors': Ack.list(
    baseColorSchema.codec<Color>(
      decode: Color.new,
      encode: (color) => color.value,
    ),
  ),
  'tagList': Ack.list(
    Ack.string(),
  ).codec<TagList>(decode: TagList.new, encode: (tags) => tags.value),
});
