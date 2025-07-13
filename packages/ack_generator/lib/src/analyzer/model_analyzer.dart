import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import '../models/field_info.dart';
import '../models/model_info.dart';
import '../utils/naming.dart';
import 'field_analyzer.dart';

/// Analyzes classes annotated with @AckModel
class ModelAnalyzer {
  final _fieldAnalyzer = FieldAnalyzer();

  ModelInfo analyze(ClassElement element, ConstantReader annotation) {
    // Extract schema name from annotation or generate it
    final schemaName = annotation.read('schemaName').isNull
        ? null
        : annotation.read('schemaName').stringValue;

    final schemaClassName =
        schemaName ?? NamingUtils.getSchemaClassName(element.name);

    // Extract description if provided
    final description = annotation.read('description').isNull
        ? null
        : annotation.read('description').stringValue;

    // Extract additionalProperties settings
    final additionalProperties = annotation.read('additionalProperties').isNull
        ? false
        : annotation.read('additionalProperties').boolValue;

    final additionalPropertiesField =
        annotation.read('additionalPropertiesField').isNull
            ? null
            : annotation.read('additionalPropertiesField').stringValue;

    // Extract model flag (with fallback for backward compatibility)
    bool model = false;
    try {
      model = annotation.read('model').isNull
          ? false
          : annotation.read('model').boolValue;
    } catch (e) {
      // Field doesn't exist in annotation, default to false
      model = false;
    }

    // Extract discriminated type parameters
    final discriminatedKey = annotation.read('discriminatedKey').isNull
        ? null
        : annotation.read('discriminatedKey').stringValue;

    final discriminatedValue = annotation.read('discriminatedValue').isNull
        ? null
        : annotation.read('discriminatedValue').stringValue;

    // Validate discriminated type usage
    _validateDiscriminatedTypeUsage(element, discriminatedKey, discriminatedValue);

    // Analyze all fields
    final fields = <FieldInfo>[];
    final requiredFields = <String>[];

    // Get all fields including inherited ones
    final allFields = [
      ...element.fields,
      // Suppress deprecation warning for analyzer API
      // ignore: deprecated_member_use
      ...element.allSupertypes.expand((type) => type.element.fields),
    ].where((field) => !field.isStatic && !field.isSynthetic);

    for (final field in allFields) {
      final fieldInfo = _fieldAnalyzer.analyze(field);

      // Skip the additionalPropertiesField from schema generation
      if (additionalPropertiesField != null &&
          fieldInfo.name == additionalPropertiesField) {
        continue;
      }

      fields.add(fieldInfo);

      if (fieldInfo.isRequired) {
        requiredFields.add(fieldInfo.jsonKey);
      }
      
    }

    // Validate additionalPropertiesField if specified
    if (additionalPropertiesField != null) {
      _validateAdditionalPropertiesField(
          element, additionalPropertiesField, additionalProperties);
    }

    return ModelInfo(
      className: element.name,
      schemaClassName: schemaClassName,
      description: description,
      fields: fields,
      requiredFields: requiredFields,
      additionalProperties: additionalProperties,
      additionalPropertiesField: additionalPropertiesField,
      model: model,
      // New discriminated properties
      isDiscriminatedBase: discriminatedKey != null,
      isDiscriminatedSubtype: discriminatedValue != null,
      discriminatorKey: discriminatedKey,
      discriminatorValue: discriminatedValue,
      // subtypes will be populated later in a second pass
      subtypes: null,
    );
  }

  void _validateAdditionalPropertiesField(
    // ignore: deprecated_member_use
    ClassElement element,
    String fieldName,
    bool additionalProperties,
  ) {
    // Find the field in the class
    final field = element.fields.firstWhere(
      (f) => f.name == fieldName,
      orElse: () => throw ArgumentError(
        'additionalPropertiesField "$fieldName" not found in class ${element.name}',
      ),
    );

    // Check if additionalProperties is true when field is specified
    if (!additionalProperties) {
      throw ArgumentError(
        'additionalProperties must be true when additionalPropertiesField is specified',
      );
    }

    // Check if field type is Map<String, dynamic> or compatible using modern Dart pattern matching
    final fieldType = field.type.getDisplayString();
    final isValidType = switch (fieldType) {
      String type when type.startsWith('Map<String,') => true,
      String type when type.startsWith('Map<String, dynamic>') => true,
      String type when type.startsWith('Map<String, Object?>') => true,
      _ => false,
    };

    if (!isValidType) {
      throw ArgumentError(
        'additionalPropertiesField "$fieldName" must be of type Map<String, dynamic> or Map<String, Object?>, got $fieldType',
      );
    }
  }

  /// Validates discriminated type usage rules
  void _validateDiscriminatedTypeUsage(
    ClassElement element,
    String? discriminatedKey,
    String? discriminatedValue,
  ) {
    // Rule 1: discriminatedKey and discriminatedValue are mutually exclusive
    if (discriminatedKey != null && discriminatedValue != null) {
      throw ArgumentError(
        'Class ${element.name} cannot have both discriminatedKey and discriminatedValue. '
        'Use discriminatedKey on base classes and discriminatedValue on concrete implementations.',
      );
    }

    // Rule 2: discriminatedKey should only be used on abstract classes
    if (discriminatedKey != null && !element.isAbstract) {
      throw ArgumentError(
        'discriminatedKey can only be used on abstract classes. '
        'Class ${element.name} should be declared as abstract.',
      );
    }

    // Rule 3: discriminatedValue should only be used on concrete classes
    if (discriminatedValue != null && element.isAbstract) {
      throw ArgumentError(
        'discriminatedValue can only be used on concrete classes. '
        'Class ${element.name} is abstract and should use discriminatedKey instead.',
      );
    }

    // Rule 4: If discriminatedKey is used, validate the discriminator field exists
    if (discriminatedKey != null) {
      _validateDiscriminatorField(element, discriminatedKey);
    }
  }

  /// Validates that the discriminator field exists and is properly typed
  void _validateDiscriminatorField(ClassElement element, String discriminatorKey) {
    // Check if the field exists (including inherited fields)
    final allFields = [
      ...element.fields,
      // Suppress deprecation warning for analyzer API
      // ignore: deprecated_member_use
      ...element.allSupertypes.expand((type) => type.element.fields),
    ];

    final discriminatorField = allFields.cast<FieldElement?>().firstWhere(
      (field) => field?.name == discriminatorKey,
      orElse: () => null,
    );

    if (discriminatorField == null) {
      throw ArgumentError(
        'Discriminator field "$discriminatorKey" not found in class ${element.name} or its supertypes.',
      );
    }

    // Validate field type is String (or String getter)
    final fieldType = discriminatorField.type.getDisplayString();
    if (!fieldType.startsWith('String')) {
      throw ArgumentError(
        'Discriminator field "$discriminatorKey" must be of type String, got $fieldType',
      );
    }
  }

  /// Builds discriminator relationships after all models have been analyzed
  /// This is a second pass that connects base classes with their subtypes
  List<ModelInfo> buildDiscriminatorRelationships(
    List<ModelInfo> modelInfos,
    List<ClassElement> elements,
  ) {
    final updatedModelInfos = <ModelInfo>[];

    // Group models by their discriminated state
    final baseClasses = <ModelInfo>[];
    final subtypes = <ModelInfo>[];

    for (final modelInfo in modelInfos) {
      if (modelInfo.isDiscriminatedBase) {
        baseClasses.add(modelInfo);
      } else if (modelInfo.isDiscriminatedSubtype) {
        subtypes.add(modelInfo);
      } else {
        // Regular models, no changes needed
        updatedModelInfos.add(modelInfo);
      }
    }

    // For each base class, find and validate its subtypes
    for (final baseClass in baseClasses) {
      final discriminatorKey = baseClass.discriminatorKey!;
      final matchingSubtypes = <String, ClassElement>{};

      // Find subtypes that belong to this base class
      for (int i = 0; i < subtypes.length; i++) {
        final subtype = subtypes[i];
        final subtypeElement = elements[modelInfos.indexOf(subtype)];

        // Check if this subtype extends the base class
        if (_isSubtypeOf(subtypeElement, baseClass.className)) {
          final discriminatorValue = subtype.discriminatorValue!;

          // Validate no duplicate discriminator values
          if (matchingSubtypes.containsKey(discriminatorValue)) {
            throw ArgumentError(
              'Duplicate discriminator value "$discriminatorValue" found in '
              '${subtype.className} and ${matchingSubtypes[discriminatorValue]!.name}. '
              'Each discriminator value must be unique within the hierarchy.',
            );
          }

          matchingSubtypes[discriminatorValue] = subtypeElement;

          // Validate the discriminator field override
          _validateDiscriminatorOverride(
            subtypeElement,
            discriminatorKey,
            discriminatorValue,
          );
        }
      }

      // Create updated base class ModelInfo with subtype mapping
      final updatedBaseClass = ModelInfo(
        className: baseClass.className,
        schemaClassName: baseClass.schemaClassName,
        description: baseClass.description,
        fields: baseClass.fields,
        requiredFields: baseClass.requiredFields,
        hasDiscriminator: baseClass.hasDiscriminator,
        additionalProperties: baseClass.additionalProperties,
        additionalPropertiesField: baseClass.additionalPropertiesField,
        model: baseClass.model,
        isDiscriminatedBase: true,
        isDiscriminatedSubtype: false,
        discriminatorKey: discriminatorKey,
        discriminatorValue: null,
        subtypes: matchingSubtypes,
      );

      updatedModelInfos.add(updatedBaseClass);
    }

    // Update subtypes with parent discriminator key information
    for (final subtype in subtypes) {
      // Find the parent discriminator key for this subtype
      String? parentDiscriminatorKey;
      for (final baseClass in baseClasses) {
        if (_isSubtypeOf(elements[modelInfos.indexOf(subtype)], baseClass.className)) {
          parentDiscriminatorKey = baseClass.discriminatorKey;
          break;
        }
      }

      // Create updated subtype with parent discriminator key
      final updatedSubtype = ModelInfo(
        className: subtype.className,
        schemaClassName: subtype.schemaClassName,
        description: subtype.description,
        fields: subtype.fields,
        requiredFields: subtype.requiredFields,
        hasDiscriminator: subtype.hasDiscriminator,
        additionalProperties: subtype.additionalProperties,
        additionalPropertiesField: subtype.additionalPropertiesField,
        model: subtype.model,
        isDiscriminatedBase: false,
        isDiscriminatedSubtype: true,
        discriminatorKey: parentDiscriminatorKey, // Add parent's discriminator key
        discriminatorValue: subtype.discriminatorValue,
        subtypes: null,
      );

      updatedModelInfos.add(updatedSubtype);
    }

    return updatedModelInfos;
  }

  /// Checks if a class extends another class (direct or indirect inheritance)
  bool _isSubtypeOf(ClassElement element, String baseClassName) {
    // Check direct superclass
    final supertype = element.supertype;
    if (supertype?.element.name == baseClassName) {
      return true;
    }

    // Check indirect inheritance through supertypes
    for (final supertype in element.allSupertypes) {
      if (supertype.element.name == baseClassName) {
        return true;
      }
    }

    return false;
  }

  /// Validates that the discriminator field is properly overridden in subtype
  void _validateDiscriminatorOverride(
    ClassElement element,
    String discriminatorKey,
    String expectedValue,
  ) {
    // Find the discriminator field override
    final discriminatorField = element.fields.firstWhere(
      (field) => field.name == discriminatorKey,
      orElse: () => throw ArgumentError(
        'Subtype ${element.name} must override discriminator field "$discriminatorKey"',
      ),
    );

    // For getters, we can't easily validate the returned value at compile time
    // The validation will happen at runtime through the schema validation
    // We just ensure the field exists and has the correct type
    final fieldType = discriminatorField.type.getDisplayString();
    if (!fieldType.startsWith('String')) {
      throw ArgumentError(
        'Discriminator field "$discriminatorKey" override in ${element.name} '
        'must be of type String, got $fieldType',
      );
    }
  }
}
