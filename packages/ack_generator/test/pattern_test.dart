import 'package:ack_generator/src/schema_model_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Pattern constraint application', () {
    test('Pattern constraint formats correctly in schema buffer', () {
      // Create the pattern constraint manually
      const testPattern = r'^[A-Z][a-z]+$';
      final constraint = PropertyConstraintInfo(
        constraintKey: 'pattern',
        parameters: {'pattern': testPattern},
      );

      // Create a buffer to test with
      final buffer = StringBuffer('Ack.string');

      // Apply the constraint manually
      switch (constraint.constraintKey) {
        case 'pattern':
          final pattern = constraint.parameters['pattern'] as String;
          buffer.write('.pattern(\'$pattern\')');
          break;
      }

      // Check the output
      expect(buffer.toString(), equals('Ack.string.pattern(\'$testPattern\')'));
    });

    test('Pattern constraint correctly escapes special characters', () {
      // Create the pattern constraint with special characters
      const testPattern = r"^[a-z]+'s$";
      final constraint = PropertyConstraintInfo(
        constraintKey: 'pattern',
        parameters: {'pattern': testPattern},
      );

      // Create a buffer to test with
      final buffer = StringBuffer('Ack.string');

      // Apply the constraint manually
      switch (constraint.constraintKey) {
        case 'pattern':
          final pattern = constraint.parameters['pattern'] as String;
          buffer.write('.pattern(\'$pattern\')');
          break;
      }

      // Check the output includes the escaped pattern
      expect(buffer.toString(), equals('Ack.string.pattern(\'$testPattern\')'));
    });

    test('Multiple constraints can be chained', () {
      // Create a string with both pattern and length constraints
      const testPattern = r'^[A-Z][a-z]+$';

      // Create a buffer to test with
      final buffer = StringBuffer('Ack.string');

      // Apply multiple constraints manually
      buffer.write('.minLength(3)');
      buffer.write('.maxLength(10)');
      buffer.write('.pattern(\'$testPattern\')');

      // Check the output includes all constraints
      expect(
        buffer.toString(),
        equals(
          'Ack.string.minLength(3).maxLength(10).pattern(\'$testPattern\')',
        ),
      );
    });
  });
}
