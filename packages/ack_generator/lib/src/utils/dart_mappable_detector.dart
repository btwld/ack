import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:recase/recase.dart';

/// Detects and processes dart_mappable annotations for case style transformations
///
/// This utility class provides seamless integration between Ack schema generation
/// and dart_mappable serialization by detecting case style annotations and
/// applying consistent field name transformations.
class DartMappableDetector {
  /// Extract case style from dart_mappable annotations using Modern Dart patterns
  ///
  /// Checks both class-level @MappableClass and library-level @MappableLib
  /// annotations to determine the appropriate case style transformation.
  static String? getCaseStyle(ClassElement element) {
    // Check class-level @MappableClass annotation first
    final classStyle = element.metadata
        .where((m) => m.element?.displayName == 'MappableClass')
        .map(_extractCaseStyleFromAnnotation)
        .firstOrNull;

    if (classStyle != null) return classStyle;

    // Fallback to library-level @MappableLib annotation
    return element.library.metadata
        .where((m) => m.element?.displayName == 'MappableLib')
        .map(_extractCaseStyleFromAnnotation)
        .firstOrNull;
  }

  /// Extract case style value from a dart_mappable annotation
  static String? _extractCaseStyleFromAnnotation(ElementAnnotation annotation) {
    try {
      return annotation
          .computeConstantValue()
          ?.getField('caseStyle')
          ?.getField('name')
          ?.toStringValue();
    } catch (e) {
      // Return null for malformed annotations rather than throwing
      return null;
    }
  }

  /// Get custom field key from @MappableField annotation
  ///
  /// Returns the custom key if specified, null otherwise.
  static String? getFieldKey(FieldElement field) {
    try {
      final annotation = field.metadata
          .firstWhereOrNull((m) => m.element?.displayName == 'MappableField');

      return annotation
          ?.computeConstantValue()
          ?.getField('key')
          ?.toStringValue();
    } catch (e) {
      // Return null for malformed annotations
      return null;
    }
  }

  /// Transform field name based on case style using a registry pattern
  ///
  /// Applies the specified case transformation using the recase package.
  /// Returns the original field name if no case style is specified or recognized.
  static String transformFieldName(String fieldName, String? caseStyle) {
    if (caseStyle == null) return fieldName;

    return _CaseStyleRegistry.transform(fieldName, caseStyle);
  }

  /// Check if a class uses dart_mappable annotations
  ///
  /// Useful for conditional logic that only applies when dart_mappable is present.
  static bool hasDartMappableAnnotations(ClassElement element) {
    final hasClassAnnotation =
        element.metadata.any((m) => m.element?.displayName == 'MappableClass');

    final hasLibraryAnnotation = element.library.metadata
        .any((m) => m.element?.displayName == 'MappableLib');

    return hasClassAnnotation || hasLibraryAnnotation;
  }
}

/// Internal registry for case style transformations
///
/// This registry pattern allows for easy extension of supported case styles
/// without modifying existing code, following the Open/Closed Principle.
class _CaseStyleRegistry {
  /// Map of case style names to their transformation functions
  static final Map<String, String Function(ReCase)> _transformers = {
    'camelCase': (rc) => rc.camelCase,
    'snakeCase': (rc) => rc.snakeCase,
    'pascalCase': (rc) => rc.pascalCase,
    'paramCase': (rc) => rc.paramCase,
    'kebabCase': (rc) => rc.paramCase, // kebabCase is alias for paramCase
    'constantCase': (rc) => rc.constantCase,
    'dotCase': (rc) => rc.dotCase,
    'pathCase': (rc) => rc.pathCase,
    'sentenceCase': (rc) => rc.sentenceCase,
    'headerCase': (rc) => rc.headerCase,
  };

  /// Transform field name using the specified case style
  ///
  /// Returns the original field name if the case style is not recognized.
  static String transform(String fieldName, String caseStyle) {
    final transformer = _transformers[caseStyle];
    if (transformer == null) return fieldName;

    return transformer(ReCase(fieldName));
  }

  /// Register a new case style transformation
  ///
  /// This allows for runtime extension of supported case styles.
  // ignore: unused_element
  static void registerCaseStyle(
    String caseStyleName,
    String Function(ReCase) transformer,
  ) {
    _transformers[caseStyleName] = transformer;
  }

  /// Get all supported case style names
  // ignore: unused_element
  static Set<String> get supportedCaseStyles => _transformers.keys.toSet();
}
