import 'package:analyzer/dart/element/element2.dart';
import 'package:source_gen/source_gen.dart';

/// Utilities for analyzing Dart code in tests
class AnalysisUtils {
  /// Parse source code and return the library element
  /// Note: This is simplified for testing - use testBuilder for real integration tests
  static Future<LibraryElement2> resolveSource(String source) async {
    throw UnimplementedError(
      'Use testBuilder with resolveSources for integration testing. '
      'This method is a placeholder.',
    );
  }

  /// Get a class element by name from a library
  static ClassElement2? getClass(LibraryElement2 library, String name) {
    for (final type in library.classes) {
      if (type.name3 == name) {
        return type;
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

/// Helper to create mock ClassElement for testing
class MockClassElement {
  static ClassElement2 create({
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
