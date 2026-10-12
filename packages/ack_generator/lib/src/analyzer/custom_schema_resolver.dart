import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../models/schema_model_graph.dart';
import '../utils/string_literal.dart';
import 'generated_companion_visibility.dart';
import 'model_graph_builder_base.dart';

typedef RegisteredSchema = ({
  Element declaration,
  DartType boundary,
  DartType runtime,
  bool isFunction,
});

typedef FutureGeneratedType = ({
  String schemaExpression,
  AckInferRef runtimeRef,
  String? setListSchema,
});

/// Resolves custom `@Schemable(schemas: ...)`, `@AckField(schema: ...)`,
/// auto-detected top-level schemas, type-owned static `.schema` declarations,
/// and future-generated schema-first types for [ClassModelGraphBuilder].
final class CustomSchemaResolver {
  CustomSchemaResolver(this._base);

  final ModelGraphBuilderBase _base;

  final List<RegisteredSchema> _librarySchemas = [];
  final List<RegisteredSchema> _importedLibrarySchemas = [];
  final Map<ClassElement, List<RegisteredSchema>> _classSchemas = {};
  final Map<ClassElement, ClassElement> unionBaseByBranch = {};
  final List<RegisteredSchema> _libraryTopLevelSchemaCandidates = [];

  LibraryReader get _library => _base.library;
  String? get _ackPrefix => _base.ackPrefix;

  Future<void> initRegisteredAndLibrarySchemas() async {
    final libraryAnnotation = ModelGraphBuilderBase.schemableChecker
        .firstAnnotationOfExact(_library.element);
    if (libraryAnnotation != null) {
      _librarySchemas.addAll(
        await _parseSchemasList(
          _library.element,
          ConstantReader(libraryAnnotation),
        ),
      );
    }

    final seenImportedLibraries = <LibraryElement>{};
    for (final import in _library.element.firstFragment.libraryImports) {
      if (import.isSynthetic || (import.prefix?.isDeferred ?? false)) continue;
      final importedLibrary = import.importedLibrary;
      if (importedLibrary == null ||
          importedLibrary == _library.element ||
          !seenImportedLibraries.add(importedLibrary)) {
        continue;
      }
      final importedAnnotation = ModelGraphBuilderBase.schemableChecker
          .firstAnnotationOfExact(importedLibrary);
      if (importedAnnotation == null) continue;
      _importedLibrarySchemas.addAll(
        await _parseSchemasList(
          importedLibrary,
          ConstantReader(importedAnnotation),
        ),
      );
    }

    for (final classElement in _library.classes) {
      final annotation = ModelGraphBuilderBase.schemableChecker
          .firstAnnotationOfExact(classElement);
      if (annotation == null) continue;
      final parsed = await _parseSchemasList(
        classElement,
        ConstantReader(annotation),
      );
      if (parsed.isNotEmpty) {
        _classSchemas[classElement] = parsed;
      }
    }

    for (final variable in _library.element.topLevelVariables) {
      if (!variable.isOriginDeclaration ||
          ModelGraphBuilderBase.schemableChecker.hasAnnotationOfExact(
            variable,
          )) {
        continue;
      }
      _addLibrarySchemaCandidate(
        declaration: variable,
        schemaType: variable.type,
        isFunction: false,
      );
    }
    for (final getter in _library.element.getters) {
      if (!getter.isOriginDeclaration ||
          ModelGraphBuilderBase.schemableChecker.hasAnnotationOfExact(getter)) {
        continue;
      }
      _addLibrarySchemaCandidate(
        declaration: getter,
        schemaType: getter.returnType,
        isFunction: false,
      );
    }
    for (final function in _library.element.topLevelFunctions) {
      if (!function.isOriginDeclaration ||
          function.typeParameters.isNotEmpty ||
          function.formalParameters.isNotEmpty) {
        continue;
      }
      _addLibrarySchemaCandidate(
        declaration: function,
        schemaType: function.returnType,
        isFunction: true,
      );
    }
  }

  void _addLibrarySchemaCandidate({
    required Element declaration,
    required DartType schemaType,
    required bool isFunction,
  }) {
    if (_base.containsInvalidType(schemaType) ||
        !ModelGraphBuilderBase.ackSchemaChecker.isAssignableFromType(
          schemaType,
        )) {
      return;
    }
    final boundary = _base.ackSchemaBoundaryType(schemaType);
    final runtime = _base.ackSchemaRuntimeType(schemaType);
    if (boundary == null ||
        runtime == null ||
        _base.containsInvalidType(boundary) ||
        _base.containsInvalidType(runtime) ||
        runtime is DynamicType ||
        (runtime is InterfaceType && _base.isCoreType(runtime, 'Object'))) {
      return;
    }
    _libraryTopLevelSchemaCandidates.add((
      declaration: declaration,
      boundary: boundary,
      runtime: _library.element.typeSystem.promoteToNonNull(runtime),
      isFunction: isFunction,
    ));
  }

  Future<List<RegisteredSchema>> _parseSchemasList(
    Element owner,
    ConstantReader reader,
  ) async {
    final schemasReader = reader.read('schemas');
    if (schemasReader.isNull) return const [];
    final ownerLabel = owner is LibraryElement
        ? 'library'
        : (owner.name ?? '@Schemable');
    final list = schemasReader.listValue;
    if (list.isEmpty) {
      throw InvalidGenerationSource(
        '$ownerLabel @Schemable(schemas: ...) must not be empty.',
        element: owner,
      );
    }
    final result = <RegisteredSchema>[];
    for (final item in list) {
      final function = item.toFunctionValue();
      if (function is! TopLevelFunctionElement) {
        throw InvalidGenerationSource(
          '$ownerLabel @Schemable(schemas: ...) entries must be const '
          'tear-offs of top-level functions.',
          element: owner,
        );
      }
      if (function.typeParameters.isNotEmpty) {
        throw InvalidGenerationSource(
          '$ownerLabel @Schemable(schemas: ...) function ${function.name} is '
          'generic. Use a non-generic top-level function, or declare a static '
          'schema method on the type.',
          element: owner,
        );
      }
      if (function.formalParameters.isNotEmpty ||
          !ModelGraphBuilderBase.ackSchemaChecker.isAssignableFromType(
            function.returnType,
          )) {
        throw InvalidGenerationSource(
          '$ownerLabel @Schemable(schemas: ...) function ${function.name} must '
          'have type AckSchema Function().',
          element: owner,
        );
      }
      final boundary = _base.ackSchemaBoundaryType(function.returnType);
      final runtime = _base.ackSchemaRuntimeType(function.returnType);
      if (boundary == null ||
          runtime == null ||
          runtime is DynamicType ||
          (runtime is InterfaceType && _base.isCoreType(runtime, 'Object'))) {
        throw InvalidGenerationSource(
          '$ownerLabel @Schemable(schemas: ...) function ${function.name} must '
          'return a typed AckSchema<Boundary, Runtime> for a specific runtime '
          'type.',
          element: owner,
        );
      }
      if (runtime is InterfaceType && isNonOverridableCoreType(runtime)) {
        throw InvalidGenerationSource(
          '$ownerLabel @Schemable(schemas: ...) cannot override core type '
          '${runtime.getDisplayString()}; use @AckField(schema: '
          '${function.name}) on the specific field instead.',
          element: owner,
        );
      }
      final resolved = await _base.resolvedLibraryFor(function.library);
      final bodyExpression = _base.declarationExpression(resolved, function);
      if (bodyExpression == null) {
        throw InvalidGenerationSource(
          '$ownerLabel @Schemable(schemas: ...) function ${function.name} must '
          'have a statically resolvable expression or single return.',
          element: owner,
        );
      }
      final oneWaySource = await _base.oneWayTransformSource(bodyExpression);
      if (oneWaySource != null) {
        throw InvalidGenerationSource(
          '$ownerLabel @Schemable(schemas: ...) function ${function.name} '
          'reaches one-way schema $oneWaySource. Migrate this .transform() '
          'path to .codec() with an encoder.',
          element: owner,
        );
      }
      final nonNullRuntime = _library.element.typeSystem.promoteToNonNull(
        runtime,
      );
      for (final prior in result) {
        if (_base.sameTypeIgnoringNullability(prior.runtime, nonNullRuntime)) {
          throw InvalidGenerationSource(
            '$ownerLabel @Schemable(schemas: ...) registers multiple schemas '
            'for ${nonNullRuntime.getDisplayString()}: '
            '${prior.declaration.name} and ${function.name}.',
            element: owner,
          );
        }
      }
      result.add((
        declaration: function,
        boundary: boundary,
        runtime: nonNullRuntime,
        isFunction: true,
      ));
    }
    return result;
  }

  RegisteredSchema? registeredSchemaForType(
    InterfaceType interfaceType,
    FieldElement field, {
    ClassElement? activeClass,
  }) {
    final fieldOwner = field.enclosingElement;
    for (final scope in [
      if (activeClass != null) ...[
        if (_classSchemas[activeClass] case final classList?) classList,
        if (unionBaseByBranch[activeClass] case final base?)
          if (_classSchemas[base] case final baseList?) baseList,
      ],
      if (fieldOwner is ClassElement && fieldOwner != activeClass)
        if (_classSchemas[fieldOwner] case final ownerList?) ownerList,
      _librarySchemas,
    ]) {
      for (final entry in scope) {
        if (_base.sameTypeIgnoringNullability(entry.runtime, interfaceType)) {
          return entry;
        }
      }
    }
    final importedMatches = <Element, RegisteredSchema>{};
    for (final entry in _importedLibrarySchemas) {
      if (_base.sameTypeIgnoringNullability(entry.runtime, interfaceType)) {
        importedMatches[entry.declaration.baseElement] = entry;
      }
    }
    if (importedMatches.length > 1) {
      final path = _fieldPath(field);
      final display = _library.element.typeSystem
          .promoteToNonNull(interfaceType)
          .getDisplayString();
      final names = importedMatches.values
          .map((m) => m.declaration.name)
          .join(', ');
      throw InvalidGenerationSource(
        '$path has multiple imported library schemas for $display ($names). '
        'Disambiguate with @Schemable(schemas: [...]) or '
        '@AckField(schema: ...).',
        element: field,
      );
    }
    if (importedMatches.length == 1) return importedMatches.values.single;
    return null;
  }

  RegisteredSchema? uniqueLibrarySchemaCandidate(InterfaceType interfaceType) {
    if (isNonOverridableCoreType(interfaceType) ||
        isOverridableBuiltInScalar(interfaceType) ||
        interfaceType.element is EnumElement) {
      return null;
    }
    final matches = [
      for (final candidate in _libraryTopLevelSchemaCandidates)
        if (_base.sameTypeIgnoringNullability(candidate.runtime, interfaceType))
          candidate,
    ];
    return matches.length == 1 ? matches.single : null;
  }

  Future<String?> autoDetectedLibrarySchema(
    InterfaceType interfaceType,
    FieldElement field,
  ) async {
    if (isNonOverridableCoreType(interfaceType) ||
        isOverridableBuiltInScalar(interfaceType) ||
        interfaceType.element is EnumElement) {
      return null;
    }
    final matches = [
      for (final candidate in _libraryTopLevelSchemaCandidates)
        if (_base.sameTypeIgnoringNullability(candidate.runtime, interfaceType))
          candidate,
    ];
    if (matches.isEmpty) return null;
    final path = _fieldPath(field);
    final display = _library.element.typeSystem
        .promoteToNonNull(interfaceType)
        .getDisplayString();
    if (matches.length > 1) {
      final names = matches.map((m) => m.declaration.name).join(', ');
      throw InvalidGenerationSource(
        '$path has multiple top-level schemas for $display in this library '
        '($names). Disambiguate with @Schemable(schemas: [...]) or '
        '@AckField(schema: ...).',
        element: field,
      );
    }
    final candidate = matches.single;
    final resolved = await _base.resolvedLibraryFor(
      candidate.declaration.library!,
    );
    final bodyExpression = _base.declarationExpression(
      resolved,
      candidate.declaration,
    );
    if (bodyExpression == null) {
      throw InvalidGenerationSource(
        '$path resolves to top-level schema ${candidate.declaration.name}, '
        'which must have a statically resolvable expression or single return.',
        element: field,
      );
    }
    final oneWaySource = await _base.oneWayTransformSource(bodyExpression);
    if (oneWaySource != null) {
      throw InvalidGenerationSource(
        '$path resolves to top-level schema ${candidate.declaration.name}, '
        'which reaches one-way schema $oneWaySource. Migrate this '
        '.transform() path to .codec() with an encoder.',
        element: field,
      );
    }
    return renderRegisteredSchema(candidate, field);
  }

  String renderRegisteredSchema(RegisteredSchema schema, FieldElement field) {
    final prefix = _base.visiblePrefixFor(
      schema.declaration,
      path: _fieldPath(field),
      context: field,
    );
    final qualified =
        '${prefix == null ? '' : '$prefix.'}${schema.declaration.name}';
    return schema.isFunction ? '$qualified()' : qualified;
  }

  bool isOverridableBuiltInScalar(InterfaceType type) =>
      _base.isCoreType(type, 'DateTime') ||
      _base.isCoreType(type, 'Uri') ||
      _base.isCoreType(type, 'Duration');

  bool isNonOverridableCoreType(InterfaceType type) =>
      _base.isCoreType(type, 'String') ||
      _base.isCoreType(type, 'int') ||
      _base.isCoreType(type, 'double') ||
      _base.isCoreType(type, 'num') ||
      _base.isCoreType(type, 'bool') ||
      _base.isCoreType(type, 'Object') ||
      type.isDartCoreList ||
      type.isDartCoreSet ||
      type.isDartCoreMap ||
      _base.isJsonMaybeType(type);

  Future<String> escapeHatchExpression(
    FieldElement field,
    ConstantReader annotation,
  ) async {
    final function = annotation.read('schema').objectValue.toFunctionValue();
    final path = _fieldPath(field);
    if (function is! TopLevelFunctionElement) {
      throw InvalidGenerationSource(
        '$path @AckField schema must be a const tear-off of a top-level '
        'function.',
        element: field,
      );
    }
    if (function.typeParameters.isNotEmpty) {
      throw InvalidGenerationSource(
        '$path @AckField schema function ${function.name} is generic, and the '
        'generated call cannot keep its type arguments. Use a non-generic '
        'function, or declare a static schema method on the field type.',
        element: field,
      );
    }
    if (function.formalParameters.isNotEmpty ||
        !ModelGraphBuilderBase.ackSchemaChecker.isAssignableFromType(
          function.returnType,
        )) {
      throw InvalidGenerationSource(
        '$path @AckField top-level function must have type AckSchema '
        'Function().',
        element: field,
      );
    }
    final runtime = _base.ackSchemaRuntimeType(function.returnType);
    final expectedFieldType = _base.unwrapJsonMaybeType(field.type);
    if (runtime == null ||
        !_base.sameTypeIgnoringNullability(runtime, expectedFieldType)) {
      throw InvalidGenerationSource(
        '$path @AckField schema function ${function.name} produces '
        '${runtime?.getDisplayString() ?? 'an untyped value'}, but the field '
        'type is ${expectedFieldType.getDisplayString()}.',
        element: field,
        todo: 'Return AckSchema<..., ${expectedFieldType.getDisplayString()}>.',
      );
    }
    final resolved = await _base.resolvedLibraryFor(function.library);
    final bodyExpression = _base.declarationExpression(resolved, function);
    if (bodyExpression == null) {
      throw InvalidGenerationSource(
        '$path @AckField function must have a statically resolvable '
        'expression or single return.',
        element: field,
      );
    }
    final oneWaySource = await _base.oneWayTransformSource(bodyExpression);
    if (oneWaySource != null) {
      throw InvalidGenerationSource(
        '$path @AckField schema function ${function.name} reaches one-way '
        'schema $oneWaySource. Migrate this .transform() path to .codec() '
        'with an encoder.',
        element: field,
      );
    }
    final prefix = _base.visiblePrefixFor(function, path: path, context: field);
    return '${prefix == null ? '' : '$prefix.'}${function.name}()';
  }

  DartType? inferredBoundaryType(
    DartType type,
    FieldElement field, {
    ClassElement? activeClass,
  }) {
    if (type is! InterfaceType) return null;
    final registered = registeredSchemaForType(
      type,
      field,
      activeClass: activeClass,
    );
    if (registered != null) return registered.boundary;
    final provider = _library.element.typeProvider;
    if (_base.isCoreType(type, 'int') ||
        _base.isCoreType(type, 'double') ||
        _base.isCoreType(type, 'num')) {
      return provider.numType;
    }
    if (_base.isCoreType(type, 'String') ||
        _base.isCoreType(type, 'DateTime') ||
        _base.isCoreType(type, 'Uri')) {
      return provider.stringType;
    }
    if (_base.isCoreType(type, 'bool')) return provider.boolType;
    if (_base.isCoreType(type, 'Duration')) return provider.intType;
    if (_base.isCoreType(type, 'Object')) return provider.objectType;
    if (type.isDartCoreList || type.isDartCoreSet) {
      return provider.listType(provider.objectQuestionType);
    }
    if (type.isDartCoreMap) {
      return provider.mapType(provider.stringType, provider.objectQuestionType);
    }
    final target = type.element;
    if (target is ClassElement && _base.classFirstFacadeName(target) != null) {
      return provider.mapType(provider.stringType, provider.objectQuestionType);
    }
    final ackGetter = target.getGetter(r'$ack');
    final ackReturnType = ackGetter?.returnType;
    if (ackGetter != null &&
        ackGetter.isStatic &&
        ackReturnType is InterfaceType &&
        ModelGraphBuilderBase.ackModelAdapterChecker.isExactlyType(
          ackReturnType,
        ) &&
        ackReturnType.typeArguments.length == 3) {
      return ackReturnType.typeArguments[0];
    }
    final schemaGetter = target.getGetter('schema');
    if (schemaGetter != null && schemaGetter.isStatic) {
      return _base.ackSchemaBoundaryType(schemaGetter.returnType);
    }
    final schemaMethod = target.getMethod('schema');
    if (schemaMethod != null &&
        schemaMethod.isStatic &&
        schemaMethod.typeParameters.length == type.typeArguments.length) {
      return _base.ackSchemaBoundaryType(
        schemaMethod.type.instantiate(type.typeArguments).returnType,
      );
    }
    if (target is EnumElement) return provider.stringType;
    final autoDetected = uniqueLibrarySchemaCandidate(type);
    if (autoDetected != null) return autoDetected.boundary;
    return null;
  }

  AckInferRef? schemaFirstRuntimeRef(
    InterfaceElement target,
    FieldElement field, {
    required AckInferRef Function(DartType type, FieldElement field) typeRef,
  }) {
    final getter = target.getGetter(r'$ack');
    final returnType = getter?.returnType;
    if (getter == null ||
        !getter.isStatic ||
        returnType is! InterfaceType ||
        !ModelGraphBuilderBase.ackModelAdapterChecker.isExactlyType(
          returnType,
        )) {
      return null;
    }
    final runtimeType = returnType.typeArguments.length == 3
        ? returnType.typeArguments[1]
        : null;
    return runtimeType == null || _base.containsInvalidType(runtimeType)
        ? ModelGraphBuilderBase.jsonMapRef
        : typeRef(runtimeType, field);
  }

  Future<String?> namedSchemaForType(
    InterfaceType interfaceType,
    FieldElement field, {
    ClassElement? activeClass,
    required Future<String> Function(DartType type, FieldElement field)
    schemaForType,
    required AckInferRef Function(DartType type, FieldElement field) typeRef,
    required AckInferRef Function(DartType type, FieldElement field)
    typeArgumentRef,
  }) async {
    final registered = registeredSchemaForType(
      interfaceType,
      field,
      activeClass: activeClass,
    );
    if (registered != null) {
      return renderRegisteredSchema(registered, field);
    }
    if (isOverridableBuiltInScalar(interfaceType)) {
      return null;
    }
    final target = interfaceType.element;
    final path = _fieldPath(field);
    if (target is ClassElement) {
      final facadeName = _base.classFirstFacadeName(target);
      if (facadeName != null) {
        final prefix = _base.visiblePrefixFor(
          target,
          path: path,
          context: field,
        );
        if (target.library != _library.element &&
            !_isClassFirstFacadeVisible(target, facadeName, prefix: prefix)) {
          final typeOwned = await typeOwnedSchema(
            interfaceType,
            field,
            activeClass: activeClass,
            schemaForType: schemaForType,
            typeArgumentRef: typeArgumentRef,
          );
          if (typeOwned != null) return typeOwned;
        }
        _validateClassFirstFacadeImport(
          target,
          facadeName,
          prefix: prefix,
          field: field,
        );
        return '${prefix == null ? '' : '$prefix.'}$facadeName.schema';
      }
    }
    if (schemaFirstRuntimeRef(target, field, typeRef: typeRef) != null) {
      final visibleName = _base.visibleTypeNameFor(
        interfaceType,
        path: path,
        context: field,
      );
      return '$visibleName.\$ack.schema';
    }
    final typeOwned = await typeOwnedSchema(
      interfaceType,
      field,
      activeClass: activeClass,
      schemaForType: schemaForType,
      typeArgumentRef: typeArgumentRef,
    );
    if (typeOwned != null) return typeOwned;
    if (target is EnumElement) return null;
    return await autoDetectedLibrarySchema(interfaceType, field);
  }

  /// Resolves [type] through a static `schema` that the type declares.
  Future<String?> typeOwnedSchema(
    InterfaceType type,
    FieldElement field, {
    ClassElement? activeClass,
    required Future<String> Function(DartType type, FieldElement field)
    schemaForType,
    required AckInferRef Function(DartType type, FieldElement field)
    typeArgumentRef,
  }) async {
    final target = type.element;
    final getter = target.getGetter('schema');
    final method = target.getMethod('schema');
    final path = _fieldPath(field);
    final fieldType = _library.element.typeSystem.promoteToNonNull(type);
    final display = fieldType.getDisplayString();
    final String expression;
    final DartType returnType;
    if (getter != null && getter.isStatic) {
      expression =
          '${_base.visibleTypeNameFor(type, path: path, context: field)}.schema';
      returnType = getter.returnType;
    } else if (method != null && method.isStatic) {
      if (method.typeParameters.length != type.typeArguments.length) {
        throw InvalidGenerationSource(
          '$path resolves to ${target.name}.schema, which must declare one '
          'type parameter per type argument of $display.',
          element: field,
        );
      }
      for (var i = 0; i < method.typeParameters.length; i++) {
        final typeParam = method.typeParameters[i];
        final rawBound = typeParam.bound;
        if (rawBound == null) continue;
        final bound =
            rawBound is TypeParameterType &&
                method.typeParameters.contains(rawBound.element)
            ? type.typeArguments[method.typeParameters.indexOf(
                rawBound.element,
              )]
            : rawBound;
        final argument = type.typeArguments[i];
        if (!_library.element.typeSystem.isSubtypeOf(argument, bound)) {
          throw InvalidGenerationSource(
            '$path resolves to ${target.name}.schema, whose type parameter '
            '${typeParam.name} requires a subtype of '
            '${bound.getDisplayString()}; received '
            '${argument.getDisplayString()}.',
            element: field,
          );
        }
      }
      final parameters = method.formalParameters;
      if (parameters.isNotEmpty &&
          (parameters.length != type.typeArguments.length ||
              parameters.any((parameter) => !parameter.isRequiredPositional))) {
        throw InvalidGenerationSource(
          '$path resolves to ${target.name}.schema, which must take no '
          'parameters or one positional AckSchema parameter per type '
          'parameter; it takes ${parameters.length} for '
          '${type.typeArguments.length} type parameters.',
          element: field,
        );
      }
      final instantiated = method.type.instantiate(type.typeArguments);
      final schemas = <String>[];
      for (var i = 0; i < parameters.length; i++) {
        final argument = type.typeArguments[i];
        final parameterType = instantiated.formalParameters[i].type;
        final expected = _base.ackSchemaRuntimeType(parameterType);
        if (expected == null ||
            !_base.sameTypeIgnoringNullability(expected, argument)) {
          throw InvalidGenerationSource(
            '$path resolves to ${target.name}.schema, whose parameter '
            '${parameters[i].name} must be an AckSchema of '
            '${argument.getDisplayString()}; it is '
            '${parameterType.getDisplayString()}.',
            element: field,
          );
        }
        final expectedBoundary = _base.ackSchemaBoundaryType(parameterType);
        final inferredBoundary = inferredBoundaryType(
          argument,
          field,
          activeClass: activeClass,
        );
        if (expectedBoundary != null &&
            inferredBoundary != null &&
            !_library.element.typeSystem.isSubtypeOf(
              inferredBoundary,
              expectedBoundary,
            )) {
          throw InvalidGenerationSource(
            '$path resolves to ${target.name}.schema, whose parameter '
            '${parameters[i].name} expects boundary type '
            '${expectedBoundary.getDisplayString()}, but the schema inferred '
            'for ${argument.getDisplayString()} has boundary type '
            '${inferredBoundary.getDisplayString()}.',
            element: field,
          );
        }
        schemas.add(await schemaForType(argument, field));
      }
      final arguments = [
        for (final argument in type.typeArguments)
          typeArgumentRef(argument, field).render(ackPrefix: _ackPrefix),
      ];
      final name = _base.visibleTypeNameFor(type, path: path, context: field);
      expression = arguments.isEmpty
          ? '$name.schema(${schemas.join(', ')})'
          : '$name.schema<${arguments.join(', ')}>(${schemas.join(', ')})';
      returnType = instantiated.returnType;
    } else {
      return null;
    }
    if (_base.containsInvalidType(returnType)) {
      if (target is ClassElement &&
          _base.classFirstFacadeName(target) != null) {
        return expression;
      }
      throw InvalidGenerationSource(
        '$path resolves to ${target.name}.schema, whose type does not resolve '
        'yet. Declare the type of ${target.name}.schema explicitly.',
        element: field,
      );
    }
    final runtime = _base.ackSchemaRuntimeType(returnType);
    if (runtime == null ||
        !_base.sameTypeIgnoringNullability(runtime, fieldType)) {
      final generic = type.typeArguments.isEmpty
          ? ''
          : ' A generic type declares static AckSchema<..., '
                '${target.name}<${target.typeParameters.map((p) => p.name).join(', ')}>> '
                'schema<${target.typeParameters.map((p) => p.name).join(', ')}>() '
                'instead.';
      throw InvalidGenerationSource(
        '$path resolves to ${target.name}.schema, which produces '
        '${runtime?.getDisplayString() ?? 'an untyped value'}, but the field '
        'type is $display.$generic',
        element: field,
      );
    }
    return expression;
  }

  Future<FutureGeneratedType> futureGeneratedType(
    FieldElement field, {
    required String Function(String listSchema, AckInferRef runtimeRef)
    setCodec,
  }) async {
    final resolved = await _base.resolvedLibraryFor(field.library);
    AstNode? node = _base.declarationNode(resolved, field);
    while (node != null &&
        node is! FieldDeclaration &&
        node is! FormalParameter) {
      node = node.parent;
    }
    final annotation = switch (node) {
      FieldDeclaration() => node.fields.type,
      RegularFormalParameter() => node.type,
      FieldFormalParameter() => node.type,
      SuperFormalParameter() => node.type,
      _ => null,
    };
    final futureType = annotation == null
        ? null
        : _futureGeneratedTypeForAnnotation(
            annotation,
            field,
            setCodec: setCodec,
          );
    if (futureType != null) return futureType;
    final path = _fieldPath(field);
    final arguments = annotation is NamedType
        ? annotation.typeArguments?.arguments ?? const <TypeAnnotation>[]
        : const <TypeAnnotation>[];
    if (annotation is NamedType &&
        annotation.importPrefix == null &&
        annotation.name.lexeme == 'Map' &&
        arguments.length == 2 &&
        _futureGeneratedTypeForAnnotation(
              arguments.last,
              field,
              setCodec: setCodec,
            ) !=
            null) {
      throw InvalidGenerationSource(
        '$path uses ${annotation.toSource()}. A model generated from a '
        '@Schemable schema in this build can be a field type directly or a '
        'List or Set item, but not a Map value.',
        element: field,
      );
    }
    throw InvalidGenerationSource(
      '$path uses ${annotation?.toSource() ?? 'a type'}, which does not '
      'resolve. Check that it is imported.',
      element: field,
    );
  }

  FutureGeneratedType? _futureGeneratedTypeForAnnotation(
    TypeAnnotation annotation,
    FieldElement field, {
    required String Function(String listSchema, AckInferRef runtimeRef)
    setCodec,
    bool allowJsonMaybe = true,
  }) {
    if (annotation is! NamedType) return null;
    final name = annotation.name.lexeme;
    final prefix = annotation.importPrefix?.name.lexeme;
    final arguments = annotation.typeArguments?.arguments ?? const [];
    FutureGeneratedType? result;
    if (allowJsonMaybe &&
        name == 'JsonMaybe' &&
        (prefix == null || prefix == _ackPrefix) &&
        arguments.length == 1) {
      final item = _futureGeneratedTypeForAnnotation(
        arguments.single,
        field,
        setCodec: setCodec,
        allowJsonMaybe: false,
      );
      if (item == null) return null;
      result = (
        schemaExpression: item.schemaExpression,
        runtimeRef: AckJsonMaybeTypeRef(item.runtimeRef),
        setListSchema: item.setListSchema,
      );
    } else if (prefix == null && name == 'List' && arguments.length == 1) {
      final item = _futureGeneratedTypeForAnnotation(
        arguments.single,
        field,
        setCodec: setCodec,
        allowJsonMaybe: false,
      );
      if (item == null) return null;
      result = (
        schemaExpression: '${_base.ack('Ack')}.list(${item.schemaExpression})',
        runtimeRef: AckListTypeRef(item.runtimeRef),
        setListSchema: null,
      );
    } else if (prefix == null && name == 'Set' && arguments.length == 1) {
      final item = _futureGeneratedTypeForAnnotation(
        arguments.single,
        field,
        setCodec: setCodec,
        allowJsonMaybe: false,
      );
      if (item == null) return null;
      final runtimeRef = AckSetTypeRef(item.runtimeRef);
      final listSchema = '${_base.ack('Ack')}.list(${item.schemaExpression})';
      result = (
        schemaExpression: setCodec(listSchema, runtimeRef),
        runtimeRef: runtimeRef,
        setListSchema: listSchema,
      );
    } else {
      final target = _futureGeneratedTarget(
        className: name,
        prefix: prefix,
        field: field,
      );
      if (target == null) return null;
      final visibleName = qualifySymbol(prefix, name);
      result = (
        schemaExpression: '$visibleName.\$ack.schema',
        runtimeRef: AckModelTypeRef(
          schemaId: AckSchemaId(
            libraryUri: target.library!.uri,
            declarationName: target.name!,
          ),
          className: name,
          runtimeRef: ModelGraphBuilderBase.jsonMapRef,
          importPrefix: prefix,
        ),
        setListSchema: null,
      );
    }
    if (annotation.question == null) return result;
    return (
      schemaExpression: result.schemaExpression,
      runtimeRef: AckNullableTypeRef(result.runtimeRef),
      setListSchema: result.setListSchema,
    );
  }

  Element? _futureGeneratedTarget({
    required String className,
    required String? prefix,
    required FieldElement field,
  }) {
    final matches = <Element>{};
    final candidates = <Element>{};
    final imports = <LibraryImport>[];
    String? hiddenDeclaration;

    Element? candidateFor(Element element) {
      final declaration = _base.schemableDeclaration(element);
      if (declaration == null ||
          _base.generatedSchemaClassName(declaration) != className) {
        return null;
      }
      return declaration.baseElement;
    }

    if (prefix == null) {
      for (final element in _library.allElements) {
        final candidate = candidateFor(element);
        if (candidate != null) matches.add(candidate);
      }
    }
    for (final import in _library.element.firstFragment.libraryImports) {
      if (import.isSynthetic || (import.prefix?.isDeferred ?? false)) continue;
      final importPrefix = import.prefix?.element.name;
      if (importPrefix != prefix) continue;
      imports.add(import);
      final importedLibrary = import.importedLibrary;
      final elements = <Element>{
        if (importedLibrary != null)
          ...LibraryReader(importedLibrary).allElements,
        ...import.namespace.definedNames2.values,
      };
      for (final element in elements) {
        final candidate = candidateFor(element);
        if (candidate != null) candidates.add(candidate);
      }
    }
    for (final candidate in candidates) {
      final definingLibrary = candidate.library;
      final generatedClassVisible =
          definingLibrary != null &&
          imports.any(
            (import) => importExposesGeneratedCompanion(
              import,
              definingLibrary: definingLibrary,
              generatedName: className,
            ),
          );
      if (generatedClassVisible) {
        matches.add(candidate);
      } else {
        hiddenDeclaration = candidate.name;
      }
    }
    if (matches.isEmpty) {
      if (hiddenDeclaration != null) {
        final fieldPath = _fieldPath(field);
        throw InvalidGenerationSource(
          '$fieldPath resolves to generated schema-first type "$className", '
          'which is hidden by an import combinator or an upstream export '
          'combinator. Expose $className through the full import route.',
          element: field,
        );
      }
      return null;
    }
    if (matches.length > 1) {
      throw InvalidGenerationSource(
        '${_fieldPath(field)} resolves future generated type "$className" '
        'ambiguously.',
        element: field,
      );
    }
    return matches.single;
  }

  bool _isClassFirstFacadeVisible(
    ClassElement target,
    String facadeName, {
    required String? prefix,
  }) {
    final visibility = _base.checkCompanionVisibility(
      target,
      facadeName,
      prefix: prefix,
    );
    return visibility.declarationVisible && visibility.companionVisible;
  }

  void _validateClassFirstFacadeImport(
    ClassElement target,
    String facadeName, {
    required String? prefix,
    required FieldElement field,
  }) {
    final visibility = _base.checkCompanionVisibility(
      target,
      facadeName,
      prefix: prefix,
    );
    if (visibility.declarationVisible && visibility.companionVisible) return;
    if (visibility.declarationVisible) {
      final modelName = target.name!;
      throw InvalidGenerationSource(
        'Generated class-first facade "$facadeName" is hidden by an import '
        'combinator or an upstream export combinator for $modelName. Expose '
        'both through the full import route (for example, show $modelName, '
        '$facadeName).',
        element: field,
      );
    }
  }

  String _fieldPath(FieldElement field) =>
      '${field.enclosingElement.name}.${field.name}';
}
