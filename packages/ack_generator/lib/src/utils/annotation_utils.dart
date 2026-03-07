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
  return schemaVariableNameForSchemaClassName(
    schemaClassNameForElement(element),
  );
}

String schemaVariableNameForSchemaClassName(String schemaClassName) {
  return schemaClassName[0].toLowerCase() + schemaClassName.substring(1);
}

String? importPrefixForElement(
  LibraryElement2? currentLibrary,
  InterfaceElement2 targetElement,
) {
  if (currentLibrary == null) {
    return null;
  }

  final targetName = targetElement.name3;
  if (targetName == null || targetName.isEmpty) {
    return null;
  }

  for (final import in currentLibrary.firstFragment.libraryImports2) {
    final prefix = import.prefix2?.element.name3;
    if (prefix == null || prefix.isEmpty) {
      continue;
    }

    final importedElement = import.namespace.get2(targetName);
    if (importedElement == targetElement) {
      return prefix;
    }

    final exportedElement = import.importedLibrary2?.exportNamespace.get2(
      targetName,
    );
    if (exportedElement == targetElement) {
      return prefix;
    }
  }

  return null;
}
