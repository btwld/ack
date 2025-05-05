import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

// Helper function to capture builder output
Matcher captureOutput(List<int> bytes) {
  return predicate((List<int> content) {
    bytes.addAll(content);
    return true;
  });
}

void main() {
  group('Nested models schema generation', () {
    test('generates schema for slide with nested models', () async {
      final builder = schemaModelBuilder(BuilderOptions.empty);

      const modelSource = '''
import 'package:ack/ack.dart';

@Schema(description: 'Base class for blocks')
abstract class Block {
  const Block();
}

@Schema(description: 'A section block')
class SectionBlock extends Block {
  final List<ColumnBlock> columns;
  const SectionBlock(this.columns);
}

@Schema(description: 'A column block')
class ColumnBlock extends Block {
  final String content;
  const ColumnBlock(this.content);
}

@Schema(description: 'A slide in a presentation')
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
}

@Schema(description: 'Options for a slide')
class SlideOptions {
  final String? title;
  final String? style;
  final Map<String, dynamic> args;

  const SlideOptions({
    this.title,
    this.style,
    this.args = const {},
  });
}
''';

      // Run builder on the model file and capture output
      var outputAsBytes = <int>[];
      
      await testBuilder(
        builder,
        {
          'a|lib/slide_model.dart': modelSource,
        },
        outputs: {
          'a|lib/slide_model.g.dart': captureOutput(outputAsBytes),
        },
        reader: await PackageAssetReader.currentIsolate(),
      );
      
      // Convert output to String
      final generatedContent = String.fromCharCodes(outputAsBytes);
      
      // These assertions verify that our nested model generation works correctly
      expect(generatedContent, contains('class BlockSchema extends SchemaModel<Block>'));
      expect(generatedContent, contains('class SectionBlockSchema extends SchemaModel<SectionBlock>'));
      expect(generatedContent, contains('class ColumnBlockSchema extends SchemaModel<ColumnBlock>'));
      expect(generatedContent, contains('class SlideSchema extends SchemaModel<Slide>'));
      expect(generatedContent, contains('class SlideOptionsSchema extends SchemaModel<SlideOptions>'));
      
      // Verify schema generation for nested types
      expect(generatedContent, contains("Block toModel()"));
      expect(generatedContent, contains("SectionBlock toModel()"));
      expect(generatedContent, contains("ColumnBlock toModel()"));
      expect(generatedContent, contains("Slide toModel()"));
      expect(generatedContent, contains("SlideOptions toModel()"));
      
      // Make sure parse methods are generated for all types
      expect(generatedContent, contains('Block parse(Object? input, {String? debugName})'));
      expect(generatedContent, contains('SectionBlock parse(Object? input, {String? debugName})'));
      expect(generatedContent, contains('ColumnBlock parse(Object? input, {String? debugName})'));
      expect(generatedContent, contains('Slide parse(Object? input, {String? debugName})'));
      expect(generatedContent, contains('SlideOptions parse(Object? input, {String? debugName})'));
    });
  });
}