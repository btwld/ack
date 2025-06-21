import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Utilities for analyzing Dart code in tests
class AnalysisUtils {
  /// Parse source code and return the library element
  static Future<LibraryElement> resolveSource(String source) async {
    final result = parseString(content: source);
    if (result.errors.isNotEmpty) {
      throw Exception('Parse errors: ${result.errors}');
    }
    
    // In tests, we can work with the parsed unit directly
    final visitor = _LibraryElementVisitor();
    result.unit.accept(visitor);
    
    if (visitor.library == null) {
      throw Exception('No library found in source');
    }
    
    return visitor.library!;
  }

  /// Get a class element by name from a library
  static ClassElement? getClass(LibraryElement library, String name) {
    for (final unit in library.units) {
      for (final type in unit.classes) {
        if (type.name == name) {
          return type;
        }
      }
    }
    return null;
  }

  /// Create a ConstantReader from an annotation value
  static ConstantReader createAnnotationReader(Map<String, dynamic> values) {
    // Simplified for testing - in real scenarios this would use DartObject
    return ConstantReader(null);
  }
}

class _LibraryElementVisitor extends GeneralizingElementVisitor<void> {
  LibraryElement? library;

  @override
  void visitLibraryElement(LibraryElement element) {
    library = element;
  }
}

/// Helper to create mock ClassElement for testing
class MockClassElement {
  static ClassElement create({
    required String name,
    List<MockFieldElement> fields = const [],
    bool isAbstract = false,
  }) {
    // This would typically use a mocking framework
    // For now, we'll rely on build_test which provides this functionality
    throw UnimplementedError('Use testBuilder for integration testing');
  }
}

/// Helper to create mock FieldElement for testing
class MockFieldElement {
  final String name;
  final String type;
  final bool isRequired;
  final bool isNullable;
  final Map<String, dynamic>? ackFieldAnnotation;

  MockFieldElement({
    required this.name,
    required this.type,
    this.isRequired = false,
    this.isNullable = false,
    this.ackFieldAnnotation,
  });
}
