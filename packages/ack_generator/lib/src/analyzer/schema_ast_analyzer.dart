import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:source_gen/source_gen.dart';

import '../models/field_info.dart';
import '../models/model_info.dart';

/// Analyzes schema variables by walking the AST
///
/// This analyzer inspects the AST structure of schema definitions
/// (like `Ack.object({...})`) to extract field type information without
/// requiring const evaluation or string parsing.
class SchemaAstAnalyzer {
  /// Analyzes a schema variable annotated with @AckType
  ///
  /// Walks the AST to extract type information from the schema definition.
  ModelInfo? analyzeSchemaVariable(TopLevelVariableElement element) {
    // Get the AST node for this variable
    final session = element.session;
    if (session == null) {
      throw InvalidGenerationSourceError(
        'Could not get analysis session for "${element.name}"',
        element: element,
      );
    }

    final parsedLibResult = session.getParsedLibraryByElement(element.library);

    // getParsedLibraryByElement returns a SomeParsedLibraryResult which might not have getElementDeclaration
    // We need to check if it's actually a ParsedLibraryResult
    if (parsedLibResult is! ParsedLibraryResult) {
      throw InvalidGenerationSourceError(
        'Could not get parsed library for "${element.name}"',
        element: element,
      );
    }

    final declaration = parsedLibResult.getElementDeclaration(element);
    if (declaration == null || declaration.node is! VariableDeclaration) {
      throw InvalidGenerationSourceError(
        'Could not find variable declaration for "${element.name}"',
        element: element,
      );
    }

    final varDecl = declaration.node as VariableDeclaration;
    final initializer = varDecl.initializer;

    if (initializer == null) {
      throw InvalidGenerationSourceError(
        'Schema variable "${element.name}" must have an initializer',
        element: element,
      );
    }

    // Check if the initializer is Ack.object({...})
    if (initializer is! MethodInvocation) {
      throw InvalidGenerationSourceError(
        'Schema variable "${element.name}" must be initialized with a schema '
        '(e.g., Ack.object({...}))',
        element: element,
      );
    }

    return _parseSchemaFromAST(element.name, initializer, element);
  }

  /// Parses a schema from a MethodInvocation AST node
  ModelInfo? _parseSchemaFromAST(
    String variableName,
    MethodInvocation invocation,
    Element element,
  ) {
    // Check if this is Ack.object(...) call
    final target = invocation.target;
    final methodName = invocation.methodName.name;

    if (target is! SimpleIdentifier || target.name != 'Ack') {
      throw InvalidGenerationSourceError(
        'Only Ack.object() schemas are supported for @AckType',
        element: element,
      );
    }

    if (methodName != 'object') {
      throw InvalidGenerationSourceError(
        'Only Ack.object() schemas are supported for @AckType. Found: Ack.$methodName()',
        element: element,
      );
    }

    // Extract the properties map from the first argument
    final args = invocation.argumentList.arguments;
    if (args.isEmpty) {
      throw InvalidGenerationSourceError(
        'Ack.object() requires a properties map argument',
        element: element,
      );
    }

    final firstArg = args.first;
    if (firstArg is! SetOrMapLiteral) {
      throw InvalidGenerationSourceError(
        'Ack.object() first argument must be a map literal',
        element: element,
      );
    }

    // Extract fields from the map literal
    final fields = _extractFieldsFromMapLiteral(firstArg, element);

    // Generate extension type name from variable name
    final typeName = _generateTypeNameFromVariable(variableName);

    return ModelInfo(
      className: typeName,
      schemaClassName: variableName,
      fields: fields,
      isFromSchemaVariable: true,
    );
  }

  /// Extracts field information from a map literal
  List<FieldInfo> _extractFieldsFromMapLiteral(
    SetOrMapLiteral mapLiteral,
    Element element,
  ) {
    final fields = <FieldInfo>[];

    for (final mapElement in mapLiteral.elements) {
      if (mapElement is! MapLiteralEntry) continue;

      final key = mapElement.key;
      final value = mapElement.value;

      // Key should be a string literal
      if (key is! SimpleStringLiteral) {
        throw InvalidGenerationSourceError(
          'Map keys must be string literals in schema definition',
          element: element,
        );
      }

      final fieldName = key.value;
      final fieldInfo = _parseFieldValue(fieldName, value, element);
      if (fieldInfo != null) {
        fields.add(fieldInfo);
      }
    }

    return fields;
  }

  /// Parses a field's value expression to determine its type
  FieldInfo? _parseFieldValue(
    String fieldName,
    Expression value,
    Element element,
  ) {
    // Handle Ack.xxx() method calls
    if (value is MethodInvocation) {
      return _parseSchemaMethod(fieldName, value, element);
    }

    // Handle references to other schema variables (for nested objects)
    if (value is SimpleIdentifier) {
      // Schema variable reference - treat as Map<String, dynamic>
      // This allows nested schemas to work without complex resolution
      final library = element.library;
      if (library == null) {
        throw InvalidGenerationSourceError(
          'Could not get library for element',
          element: element,
        );
      }

      final typeProvider = library.typeProvider;

      return FieldInfo(
        name: fieldName,
        jsonKey: fieldName,
        type: typeProvider.mapType(
          typeProvider.stringType,
          typeProvider.dynamicType,
        ),
        isRequired: true,
        isNullable: false,
        constraints: [],
      );
    }

    return null;
  }

  /// Parses a schema method call (e.g., Ack.string(), Ack.integer().optional())
  FieldInfo _parseSchemaMethod(
    String fieldName,
    MethodInvocation invocation,
    Element element,
  ) {
    // Walk the method chain to find modifiers and base type
    var isOptional = false;
    var isNullable = false;
    MethodInvocation? current = invocation;
    MethodInvocation? baseInvocation;

    while (current != null) {
      final methodName = current.methodName.name;

      if (methodName == 'optional') {
        isOptional = true;
      } else if (methodName == 'nullable') {
        isNullable = true;
      } else {
        // This might be the base schema type (Ack.string(), etc.)
        final target = current.target;
        if (target is SimpleIdentifier && target.name == 'Ack') {
          baseInvocation = current;
          break;
        }
      }

      // Move to the next method in the chain
      final target = current.target;
      if (target is MethodInvocation) {
        current = target;
      } else {
        break;
      }
    }

    if (baseInvocation == null) {
      throw InvalidGenerationSourceError(
        'Could not determine schema type for field "$fieldName"',
        element: element,
      );
    }

    // Map schema type to Dart type (passing full invocation for context)
    final dartType = _mapSchemaTypeToDartType(baseInvocation, element);

    return FieldInfo(
      name: fieldName,
      jsonKey: fieldName,
      type: dartType,
      isRequired: !isOptional,
      isNullable: isNullable,
      constraints: [],
    );
  }

  /// Maps a schema method invocation to a Dart type
  DartType _mapSchemaTypeToDartType(
    MethodInvocation invocation,
    Element element,
  ) {
    final schemaMethod = invocation.methodName.name;

    // We need to get the type provider from the element's library
    final library = element.library;
    if (library == null) {
      throw InvalidGenerationSourceError(
        'Could not get library for element',
        element: element,
      );
    }

    final typeProvider = library.typeProvider;

    switch (schemaMethod) {
      case 'string':
        return typeProvider.stringType;
      case 'integer':
        return typeProvider.intType;
      case 'double':
        return typeProvider.doubleType;
      case 'boolean':
        return typeProvider.boolType;
      case 'list':
        // Extract element type from Ack.list(elementSchema) argument
        return _extractListType(invocation, element, typeProvider);
      case 'object':
        // Nested objects represented as Map<String, dynamic>
        return typeProvider.mapType(
          typeProvider.stringType,
          typeProvider.dynamicType,
        );
      default:
        throw InvalidGenerationSourceError(
          'Unsupported schema method: Ack.$schemaMethod()',
          element: element,
        );
    }
  }

  /// Extracts the element type from Ack.list(elementSchema) calls
  DartType _extractListType(
    MethodInvocation listInvocation,
    Element element,
    TypeProvider typeProvider,
  ) {
    final args = listInvocation.argumentList.arguments;

    // If no arguments or empty, fall back to List<dynamic>
    if (args.isEmpty) {
      return typeProvider.listType(typeProvider.dynamicType);
    }

    final firstArg = args.first;

    // Handle Ack.list(Ack.string()) - nested method invocation
    if (firstArg is MethodInvocation) {
      // Check if this is an Ack.xxx() call
      if (firstArg.target is SimpleIdentifier &&
          (firstArg.target as SimpleIdentifier).name == 'Ack') {
        // Recursively extract the element type
        final elementType = _mapSchemaTypeToDartType(firstArg, element);
        return typeProvider.listType(elementType);
      }
    }

    // For other cases (like schema variable references), return List<dynamic>
    return typeProvider.listType(typeProvider.dynamicType);
  }

  /// Generates an extension type name from a schema variable name
  ///
  /// Examples:
  /// - "userSchema" → "User"
  /// - "addressSchema" → "Address"
  /// - "myDataSchema" → "MyData"
  String _generateTypeNameFromVariable(String variableName) {
    // Remove "Schema" suffix if present
    var name = variableName;
    if (name.endsWith('Schema')) {
      name = name.substring(0, name.length - 'Schema'.length);
    }

    // Capitalize first letter
    if (name.isEmpty) return 'Type';
    return name[0].toUpperCase() + name.substring(1);
  }
}
