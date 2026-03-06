import 'package:ack_annotations/ack_annotations.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:source_gen/source_gen.dart';

final TypeChecker schemableChecker = TypeChecker.typeNamed(Schemable);
final TypeChecker ackModelChecker = TypeChecker.typeNamed(AckModel);
final TypeChecker schemaConstructorChecker = TypeChecker.typeNamed(
  SchemaConstructor,
);
final TypeChecker schemaKeyChecker = TypeChecker.typeNamed(SchemaKey);
final TypeChecker descriptionChecker = TypeChecker.typeNamed(Description);

DartObject? firstSchemableAnnotationOf(Annotatable element) {
  return schemableChecker.firstAnnotationOf(element) ??
      ackModelChecker.firstAnnotationOf(element);
}

String schemaClassNameForElement(InterfaceElement2 element) {
  final annotation = firstSchemableAnnotationOf(element);
  if (annotation == null) {
    return '${element.name3}Schema';
  }

  final reader = ConstantReader(annotation);
  final schemaNameReader = reader.peek('schemaName');
  if (schemaNameReader != null && !schemaNameReader.isNull) {
    return schemaNameReader.stringValue;
  }

  return '${element.name3}Schema';
}

String schemaVariableNameForElement(InterfaceElement2 element) {
  final schemaClassName = schemaClassNameForElement(element);
  return schemaClassName[0].toLowerCase() + schemaClassName.substring(1);
}

String schemaVariableNameForSchemaClassName(String schemaClassName) {
  return schemaClassName[0].toLowerCase() + schemaClassName.substring(1);
}
