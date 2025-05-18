import 'package:ack/ack.dart';
import 'package:test/test.dart';

import 'models/block_model.dart';
import 'models/slide_model.dart';

// Test for validating nested model structure and schema definitions
// This ensures the code generator can properly handle complex nested models
void main() {
  group('Nested Model Structure Tests', () {
    test('Can create and validate slide model instances with nested components',
        () {
      // Create the most nested component first
      final columnBlock = ColumnBlock('Test content');
      expect(columnBlock.content, equals('Test content'));

      // Create a section containing a column
      final sectionBlock = SectionBlock([columnBlock]);
      expect(sectionBlock.columns.length, equals(1));
      expect(sectionBlock.columns[0].content, equals('Test content'));

      // Create a slide with options and sections
      final slide = Slide(
        key: 'test-slide',
        options: SlideOptions(
          title: 'Test Slide',
          style: 'default',
          args: {'theme': 'dark'},
        ),
        sections: [sectionBlock],
        comments: ['This is a test slide'],
      );

      // Verify the complete structure
      expect(slide.key, equals('test-slide'));
      expect(slide.options?.title, equals('Test Slide'));
      expect(slide.options?.style, equals('default'));
      expect(slide.options?.args, containsPair('theme', 'dark'));
      expect(slide.sections.length, equals(1));
      expect(slide.sections[0].columns.length, equals(1));
      expect(slide.sections[0].columns[0].content, equals('Test content'));
      expect(slide.comments, contains('This is a test slide'));

      // Test inheritance with ErrorSlide
      final errorSlide = ErrorSlide(
        title: 'Error Title',
        message: 'Error Message',
        error: Exception('Test error'),
      );

      // Verify ErrorSlide inherits from Slide
      expect(errorSlide, isA<Slide>());
      expect(errorSlide.key, equals('error'));
      expect(errorSlide.sections.length, equals(1));
      expect(errorSlide.sections[0].columns.length, equals(2));
    });

    test('Validate schema definitions exist for all nested components', () {
      // Skip abstract class Block since it doesn't have a schema definition
      expect(ColumnBlock.schema, isA<ObjectSchema>());
      expect(SectionBlock.schema, isA<ObjectSchema>());
      expect(Slide.schema, isA<ObjectSchema>());
      expect(SlideOptions.schema, isA<ObjectSchema>());

      // Check schema structure by creating a valid JSON object
      final validJson = {
        'key': 'test-key',
        'options': {'title': 'Test Title', 'style': 'default'},
        'sections': [
          {
            'columns': [
              {'content': 'Test content'},
            ],
          },
        ],
        'comments': ['Test comment'],
      };

      // Validate the JSON against the schemas (should work if schemas are defined correctly)
      expect(() => Slide.schema.validate(validJson).isOk, returnsNormally);

      // Create an invalid JSON to test validation
      final invalidJson = {
        // Missing required 'key' field
        'sections': [],
      };

      // This should not validate successfully
      expect(Slide.schema.validate(invalidJson).isOk, isFalse);
    });
  });
}
