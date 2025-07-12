import 'package:ack_generator/src/validation/code_validator.dart';
import 'package:test/test.dart';

void main() {
  group('CodeValidator', () {
    test('should catch syntax errors', () {
      const invalidSyntax = '''
        class Test {
          void method() {
            // Missing closing brace
        }
      ''';
      
      final result = CodeValidator.validate(invalidSyntax);
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
      
      final result = CodeValidator.validate(validSyntaxInvalidSemantic);
      // This should pass because syntax is valid, even though semantics are wrong
      expect(result.isSuccess, isTrue);
    });
    
    test('should catch actual syntax errors like missing braces', () {
      const actualSyntaxError = '''
        class Test {
          void method( {
            return;
          }
        }
      ''';
      
      final result = CodeValidator.validate(actualSyntaxError);
      expect(result.isFailure, isTrue);
    });
  });
}