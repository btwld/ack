import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:source_gen/source_gen.dart';

import '../models/model_info.dart';
import '../models/field_info.dart';

/// Analyzes classes annotated with @AckModel
class ModelAnalyzer {
  // TODO: Add FieldAnalyzer when implemented
  // final _fieldAnalyzer = FieldAnalyzer();

  ModelInfo analyze(ClassElement element, ConstantReader annotation) {
    // Extract schema name from annotation or generate it
    final schemaName = annotation.read('schemaName').isNull
        ? null
        : annotation.read('schemaName').stringValue;
    
    final schemaClassName = schemaName ?? _getSchemaClassName(element.name);
    
    // Extract description if provided
    final description = annotation.read('description').isNull
        ? null
        : annotation.read('description').stringValue;

    // Analyze all fields
    final fields = <FieldInfo>[];
    final requiredFields = <String>[];

    // Get all fields including inherited ones
    final allFields = [
      ...element.fields,
      ...element.allSupertypes.expand((type) => type.element.fields),
    ].where((field) => !field.isStatic && !field.isSynthetic);

    for (final field in allFields) {
      // TODO: Use FieldAnalyzer when implemented
      // final fieldInfo = _fieldAnalyzer.analyze(field);
      
      // Temporary implementation - create basic FieldInfo
      final isNullable = field.type.nullabilitySuffix != NullabilitySuffix.none;
      final fieldInfo = FieldInfo(
        name: field.name,
        jsonKey: field.name, // TODO: Extract from annotations
        type: field.type,
        isRequired: !isNullable && !field.hasInitializer,
        isNullable: isNullable,
        constraints: [], // TODO: Extract from annotations
        defaultValue: null, // TODO: Extract default values
      );
      
      fields.add(fieldInfo);
      
      if (fieldInfo.isRequired) {
        requiredFields.add(fieldInfo.jsonKey);
      }
    }

    return ModelInfo(
      className: element.name,
      schemaClassName: schemaClassName,
      description: description,
      fields: fields,
      requiredFields: requiredFields,
    );
  }

  /// Generate schema class name from model class name
  String _getSchemaClassName(String className) {
    return '${className}Schema';
  }
}
