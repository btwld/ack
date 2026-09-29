import 'package:ack_generator/src/utils/doc_comment_utils.dart';
import 'package:test/test.dart';

void main() {
  test('only a description tag becomes schema text', () {
    expect(parseDescriptionTag('/// Ordinary prose.'), isNull);
    expect(
      parseDescriptionTag(
        '/// Ordinary prose.\r\n'
        '/// @description The schema text.\r\n'
        '/// More ordinary prose.',
      ),
      'The schema text.',
    );
    expect(
      parseDescriptionTag('/**\r\n * @description Block text.\r\n */'),
      'Block text.',
    );
  });

  test('tags in fenced examples and inline prose do not export', () {
    expect(
      parseDescriptionTag(
        '/// An example with @description in prose.\n'
        '/// ```dart\n'
        '/// @description Example text.\n'
        '/// ```\n'
        '/// @description Exported text.',
      ),
      'Exported text.',
    );
    expect(
      parseDescriptionTag('/**\n * ~~~\n * @description Example.\n * ~~~\n */'),
      isNull,
    );
  });

  test('blank and duplicate tags are invalid', () {
    expect(
      () => parseDescriptionTag('/// @description'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => parseDescriptionTag(
        '/// @description First.\n/// @description Second.',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
