import 'package:ack/ack.dart';

// There are issues with the generated code for abstract classes
// Testing with manual implementation instead
//part 'block_model.g.dart';

/// Base class for blocks that make up a slide
@Schema(description: 'Base class for blocks that make up a slide')
abstract class Block {
  const Block();
}

/// A section block that contains multiple columns
@Schema(description: 'A section block that contains multiple columns')
class SectionBlock extends Block {
  final List<ColumnBlock> columns;

  const SectionBlock(this.columns);

  static final schema = Ack.object(
    {
      'columns': ColumnBlock.schema.list,
    },
    required: ['columns'],
  );
}

/// A column block that contains markdown content
@Schema(description: 'A column block that contains markdown content')
class ColumnBlock extends Block {
  final String content;

  const ColumnBlock(this.content);

  static final schema = Ack.object(
    {
      'content': Ack.string,
    },
    required: ['content'],
  );
}
