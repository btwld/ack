import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'schema_types_transforms.g.dart';

class Color {
  final String value;
  const Color(this.value);
}

class TagList {
  final List<String> value;
  const TagList(this.value);
}

final baseColorSchema = Ack.string();

@AckType()
final colorSchema = Ack.string().transform<Color>((value) => Color(value));

@AckType()
final profileSchema = Ack.object({
  'homepage': Ack.uri(),
  'birthday': Ack.date(),
  'lastLogin': Ack.datetime(),
  'timeout': Ack.duration(),
  'links': Ack.list(Ack.uri()),
  'favoriteColor': Ack.string().transform<Color>((value) => Color(value)),
  'slug': Ack.string().transform<String>((value) => value + '#'),
  'accent': colorSchema,
  'colors': Ack.list(colorSchema),
  'customColors': Ack.list(
    baseColorSchema.transform<Color>((value) => Color(value)),
  ),
  'tagList': Ack.list(
    Ack.string(),
  ).transform<TagList>((value) => TagList(value)),
});
