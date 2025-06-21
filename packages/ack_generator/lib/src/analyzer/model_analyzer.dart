import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import '../models/model_info.dart';
import '../models/field_info.dart';
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
    
    final schemaClassName = schemaName ?? NamingUtils.getSchemaClassName(element.name);
    
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
      final fieldInfo = _fieldAnalyzer.analyze(field);
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
}
