import 'package:ack/ack.dart';
import 'block_model.dart';

// Generated file will be part 'slide_model.g.dart';

@Schema(description: 'A slide in the presentation.')
class Slide {
  final String key;
  final SlideOptions? options;
  final List<SectionBlock> sections;
  final List<String> comments;

  const Slide({
    required this.key,
    this.options,
    this.sections = const [],
    this.comments = const [],
  });

  static final schema = Ack.object(
    {
      "key": Ack.string,
      'options': SlideOptions.schema.nullable(),
      'sections': SectionBlock.schema.list,
      'comments': Ack.string.list,
    },
    required: ['key'],
    additionalProperties: true,
  );
}

@Schema(description: 'Options for a slide.')
class SlideOptions {
  final String? title;
  final String? style;
  final Map<String, Object?> args;

  const SlideOptions({
    this.title,
    this.style,
    this.args = const {},
  });

  static final schema = Ack.object(
    {
      "title": Ack.string.nullable(),
      "style": Ack.string.nullable(),
    },
    additionalProperties: true,
  );
}

class ErrorSlide extends Slide {
  ErrorSlide({
    required String title,
    required String message,
    required Exception error,
  }) : super(
          key: 'error',
          sections: [
            SectionBlock([
              ColumnBlock('''
> [!CAUTION]
> $title
> $message


```dart
${error.toString()}
```
'''),
              ColumnBlock('')
            ]),
          ],
        );
}
