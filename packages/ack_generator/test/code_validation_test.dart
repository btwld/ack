import 'package:ack_generator/src/validation/code_validator.dart';
import 'package:test/test.dart';

void main() {
  group('validateGeneratedDartCode', () {
    test('should catch syntax errors', () {
      const invalidSyntax = '''
        class Test {
          void method() {
            // Missing closing brace
        }
      ''';

      final result = validateGeneratedDartCode(invalidSyntax);
      expect(result.isFailure, isTrue);
      expect(result.errorMessage, contains('syntax'));
    });

    test('should pass valid syntax even with undefined identifiers', () {
      const validSyntaxInvalidSemantic = '''
        class Test extends UndefinedClass {
          UndefinedType method() {
            return undefinedFunction();
          }
        }
      ''';

      final result = validateGeneratedDartCode(validSyntaxInvalidSemantic);
      expect(result.isSuccess, isTrue);
    });
  });
}
