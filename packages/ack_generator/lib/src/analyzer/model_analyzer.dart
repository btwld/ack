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
}
