import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import '../models/class_info.dart';
import '../models/discriminated_class_info.dart';
import '../models/property_info.dart';
import '../models/schema_data.dart';
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

  /// Find constructor parameters from the primary constructor
  static Map<String, PropertyInfo> _findConstructorParameters(
    ClassElement classElement,
  ) {
    final constructorParams = <String, PropertyInfo>{};

    // Use the existing findPrimaryConstructor method to avoid duplication
    final primaryConstructor = findPrimaryConstructor(classElement);

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

    // Find the primary constructor for enhanced analysis
    final primaryConstructor = findPrimaryConstructor(classElement);

    // Process all instance fields
    for (final field in classElement.fields) {
      // Skip excluded fields
      if (PropertyAnalyzer.shouldExcludeField(
        field,
        additionalPropertiesField,
      )) {
        continue;
      }

      // Analyze the field with enhanced constructor analysis
      final property = PropertyAnalyzer.analyzeField(
        field,
        constructor: primaryConstructor,
      );

      properties[field.name] = property;
    }

    return properties;
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

  /// Analyze a class for discriminated union pattern.
  /// Works with both sealed and abstract classes that have a discriminatedKey.
  /// Returns null if the class doesn't have a proper discriminated union setup.
  static DiscriminatedClassInfo? analyzeDiscriminatedClass(
    ClassElement element,
    SchemaData schemaData,
  ) {
    // Check if class has discriminatedKey and is either sealed or abstract
    if (schemaData.discriminatedKey == null ||
        (!element.isSealed && !element.isAbstract)) {
      return null;
    }

    final discriminatorKey = schemaData.discriminatedKey!;
    final subclasses = <ClassElement>[];
    final discriminatorMapping = <String, ClassElement>{};

    // Find all subclasses in the same library
    final library = element.library;
    for (final unit in library.units) {
      for (final type in unit.classes) {
        if (type.supertype?.element == element) {
          subclasses.add(type);

          // Extract discriminated value from subclass annotation
          final discriminatedValue = _extractDiscriminatedValue(type);
          if (discriminatedValue != null) {
            discriminatorMapping[discriminatedValue] = type;
          }
        }
      }
    }

    // Validate that we found subclasses with discriminated values
    if (subclasses.isEmpty || discriminatorMapping.isEmpty) {
      return null;
    }

    return DiscriminatedClassInfo(
      baseClass: element,
      subclasses: subclasses,
      discriminatorMapping: discriminatorMapping,
      discriminatorKey: discriminatorKey,
    );
  }

  /// Extract discriminated value from a class element's Schema annotation
  static String? _extractDiscriminatedValue(ClassElement element) {
    for (final annotation in element.metadata) {
      if (annotation.element?.displayName == 'Schema') {
        final reader = ConstantReader(annotation.computeConstantValue());
        return reader.peek('discriminatedValue')?.stringValue;
      }
    }
    return null;
  }
}
