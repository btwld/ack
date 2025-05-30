import 'package:analyzer/dart/element/element.dart';

import '../models/class_info.dart';
import '../models/property_info.dart';
import 'property_analyzer.dart';

/// Analyzes a class element and extracts comprehensive class information
class ClassAnalyzer {
  /// Analyze a class element and extract all relevant information
  static ClassInfo analyzeClass(
    ClassElement element,
    String? additionalPropertiesField,
  ) {
    return ClassInfo(
      name: element.name,
      constructorParams: _findConstructorParameters(element),
      properties: _analyzeClassProperties(element, additionalPropertiesField),
      dependencies: {},
    );
  }

  /// Find constructor parameters from the default or annotated constructor
  static Map<String, PropertyInfo> _findConstructorParameters(
    ClassElement classElement,
  ) {
    final constructorParams = <String, PropertyInfo>{};

    // Find the primary constructor
    ConstructorElement? primaryConstructor;

    // First look for a constructor annotated with @SchemaConstructor
    for (final constructor in classElement.constructors) {
      if (constructor.metadata
          .any((m) => m.element?.displayName == 'SchemaConstructor')) {
        primaryConstructor = constructor;
        break;
      }
    }

    // If no annotated constructor, use the default constructor
    if (primaryConstructor == null && classElement.unnamedConstructor != null) {
      primaryConstructor = classElement.unnamedConstructor;
    }

    // If still no constructor, try to use any constructor
    if (primaryConstructor == null && classElement.constructors.isNotEmpty) {
      primaryConstructor = classElement.constructors.firstOrNull;
    }

    // Analyze the parameters
    if (primaryConstructor != null) {
      for (final param in primaryConstructor.parameters) {
        final propertyInfo =
            PropertyAnalyzer.analyzeConstructorParameter(param);
        constructorParams[param.name] = propertyInfo;
      }
    }

    return constructorParams;
  }

  /// Find the primary constructor element
  static ConstructorElement? findPrimaryConstructor(ClassElement classElement) {
    // First look for a constructor annotated with @SchemaConstructor
    for (final constructor in classElement.constructors) {
      if (constructor.metadata
          .any((m) => m.element?.displayName == 'SchemaConstructor')) {
        return constructor;
      }
    }

    // If no annotated constructor, use the default constructor
    if (classElement.unnamedConstructor != null) {
      return classElement.unnamedConstructor;
    }

    // If still no constructor, try to use any constructor
    if (classElement.constructors.isNotEmpty) {
      return classElement.constructors.firstOrNull;
    }

    return null;
  }

  /// Analyze all properties of a class
  static Map<String, PropertyInfo> _analyzeClassProperties(
    ClassElement classElement,
    String? additionalPropertiesField,
  ) {
    final properties = <String, PropertyInfo>{};

    // First, get constructor parameters as a starting point
    final constructorParams = _findConstructorParameters(classElement);
    properties.addAll(constructorParams);

    // Find the primary constructor for AST analysis
    final primaryConstructor = _findPrimaryConstructor(classElement);

    // Process all instance fields
    for (final field in classElement.fields) {
      // Skip excluded fields
      if (PropertyAnalyzer.shouldExcludeField(
        field,
        additionalPropertiesField,
      )) {
        continue;
      }

      // Find corresponding constructor parameter if any
      final constructorParam = constructorParams[field.name];

      // Find the actual constructor parameter if any
      ParameterElement? actualConstructorParam;
      if (constructorParam != null) {
        for (final constructor in classElement.constructors) {
          for (final param in constructor.parameters) {
            if (param.name == field.name) {
              actualConstructorParam = param;
              break;
            }
          }
          if (actualConstructorParam != null) break;
        }
      }

      // Analyze the field with enhanced constructor analysis
      final property = PropertyAnalyzer.analyzeField(
        field,
        constructorParam: actualConstructorParam,
        constructor: primaryConstructor,
      );

      properties[field.name] = property;
    }

    return properties;
  }

  /// Find the primary constructor for analysis
  static ConstructorElement? _findPrimaryConstructor(
    ClassElement classElement,
  ) {
    // First look for a constructor annotated with @SchemaConstructor
    for (final constructor in classElement.constructors) {
      if (constructor.metadata
          .any((m) => m.element?.displayName == 'SchemaConstructor')) {
        return constructor;
      }
    }

    // If no annotated constructor, use the default constructor
    if (classElement.unnamedConstructor != null) {
      return classElement.unnamedConstructor;
    }

    // If still no constructor, try to use any constructor
    if (classElement.constructors.isNotEmpty) {
      return classElement.constructors.firstOrNull;
    }

    return null;
  }

  /// Find all dependencies for the class
  static Set<String> findClassDependencies(
    Map<String, PropertyInfo> properties,
  ) {
    final dependencies = <String>{};

    for (final property in properties.values) {
      dependencies.addAll(PropertyAnalyzer.findPropertyDependencies(property));
    }

    return dependencies;
  }
}
