import 'package:ack/ack.dart' show AckModelAdapter, AckSchema, JsonMaybe;
import 'package:ack/annotations.dart' as annotations;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../json/helper_names.dart';
import '../models/schema_model_graph.dart';
import '../utils/string_literal.dart';
import 'generated_companion_visibility.dart';

/// Parsed method-invocation chain for an `Ack.*` or referenced schema AST.
final class SchemaChain {
  const SchemaChain({
    required this.base,
    required this.reference,
    required this.hasTransform,
    required this.hasCodec,
  });

  final MethodInvocation? base;
  final Expression? reference;
  final bool hasTransform;
  final bool hasCodec;
}

/// Shared analyzer infrastructure for [ClassModelGraphBuilder] and
/// [SchemaModelGraphBuilder].
///
/// Centralizes resolved-library AST caching, import prefix and companion
/// visibility checks, `AckSchema<Boundary, Runtime>` type inspection,
/// structural [AckInferRef] construction, and `Ack.*` AST chain inspection.
abstract base class ModelGraphBuilderBase {
  ModelGraphBuilderBase(this.library, {this.ackPrefix});

  static const oneWayTransformMethods = {'transform'};

  static const maxReferenceDepth = 16;

  static const AckInferRef jsonMapRef = AckMapTypeRef(
    AckNullableTypeRef(AckScalarTypeRef('Object')),
  );

  static const coreScalarNames = {
    'String',
    'int',
    'double',
    'num',
    'bool',
    'Object',
  };

  static const schemableChecker = TypeChecker.typeNamed(
    annotations.Schemable,
    inPackage: 'ack',
  );
  static const ackKeyChecker = TypeChecker.typeNamed(
    annotations.AckKey,
    inPackage: 'ack',
  );
  static const ackSchemaChecker = TypeChecker.typeNamed(
    AckSchema,
    inPackage: 'ack',
  );
  static const ackModelAdapterChecker = TypeChecker.typeNamed(
    AckModelAdapter,
    inPackage: 'ack',
  );
  static const jsonMaybeChecker = TypeChecker.typeNamed(
    JsonMaybe,
    inPackage: 'ack',
  );

  final LibraryReader library;
  final String? ackPrefix;
  final AckModelGraph graph = AckModelGraph();
  ResolvedLibraryResult? inputResolved;
  final Map<Uri, ResolvedLibraryResult> _resolvedByUri = {};

  /// Resolves and caches the input [library] before graph analysis begins.
  Future<ResolvedLibraryResult> initInputLibrary() async {
    final libraryElement = library.element;
    final resolved = await libraryElement.session.getResolvedLibraryByElement(
      libraryElement,
    );
    if (resolved is! ResolvedLibraryResult) {
      throw InvalidGenerationSource(
        'Could not resolve ${libraryElement.uri} for Ack model generation.',
      );
    }
    inputResolved = resolved;
    _resolvedByUri[libraryElement.uri] = resolved;
    return resolved;
  }

  /// Resolves and caches [element]'s library for cross-library AST inspection.
  Future<ResolvedLibraryResult> resolvedLibraryFor(
    LibraryElement element,
  ) async {
    if (identical(element, library.element) && inputResolved != null) {
      return inputResolved!;
    }
    final cached = _resolvedByUri[element.uri];
    if (cached != null) return cached;
    final result = await element.session.getResolvedLibraryByElement(element);
    if (result is! ResolvedLibraryResult) {
      throw InvalidGenerationSource(
        'Could not resolve ${element.uri} for Ack model generation.',
      );
    }
    _resolvedByUri[element.uri] = result;
    return result;
  }

  /// Looks up the AST declaration node for [element] in [result].
  AstNode? declarationNode(ResolvedLibraryResult result, Element element) =>
      result.getFragmentDeclaration(element.firstFragment)?.node;

  /// Extracts the initializer or single-expression body of [element].
  Expression? declarationExpression(
    ResolvedLibraryResult result,
    Element element,
  ) {
    final node = declarationNode(result, element);
    if (node is VariableDeclaration) return node.initializer;
    if (node is FunctionDeclaration) {
      return functionBodyExpression(node.functionExpression.body);
    }
    if (node is MethodDeclaration) {
      return functionBodyExpression(node.body);
    }
    return null;
  }

  /// Extracts the returned expression from an arrow or single-return [body].
  Expression? functionBodyExpression(FunctionBody body) {
    if (body is ExpressionFunctionBody) return body.expression;
    if (body is BlockFunctionBody && body.block.statements.length == 1) {
      final statement = body.block.statements.single;
      if (statement is ReturnStatement) return statement.expression;
    }
    return null;
  }

  /// Normalizes synthetic variable getters back to their backing variable.
  Element propertyDeclaration(Element element) {
    if (element is GetterElement && element.isOriginVariable) {
      return element.variable.baseElement;
    }
    return element.baseElement;
  }

  /// Returns the `@Schemable` top-level declaration behind [element], if any.
  Element? schemableDeclaration(Element element) {
    final declaration = switch (element) {
      GetterElement(isOriginVariable: true) => element.variable.baseElement,
      TopLevelVariableElement() => element.baseElement,
      _ => null,
    };
    return declaration != null &&
            schemableChecker.hasAnnotationOfExact(declaration)
        ? declaration
        : null;
  }

  bool hasSchemable(Element element) =>
      schemableChecker.hasAnnotationOfExact(propertyDeclaration(element));

  /// The annotation spelling that marks [element] or its sealed base.
  String annotationName(Element element) => '@Schemable';

  /// Reads the custom `name` override from `@Schemable(name: ...)` on [element].
  String? schemableCustomName(Element element) {
    final declaration = propertyDeclaration(element);
    final annotation = schemableChecker.firstAnnotationOfExact(declaration);
    final field = annotation == null
        ? null
        : ConstantReader(annotation).peek('name');
    return field == null || field.isNull ? null : field.stringValue;
  }

  /// Derives the model class name generated for a schema-first [declaration].
  String generatedSchemaClassName(Element declaration) =>
      ackInferModelClassName(
        declaration.name!,
        override: schemableCustomName(declaration),
      );

  /// Returns the generated facade name for a class-first `@Schemable` class or
  /// implicit sealed-union branch, or `null` if [element] is not class-first.
  String? classFirstFacadeName(ClassElement element) {
    final annotation = schemableChecker.firstAnnotationOfExact(element);
    if (annotation != null) {
      final value = ConstantReader(annotation).read('schemaName');
      return ackClassSchemaFacadeName(
        element.name!,
        override: value.isNull ? null : value.stringValue,
      );
    }
    final isImplicitUnionBranch = element.allSupertypes.any((supertype) {
      final base = supertype.element;
      return base is ClassElement &&
          base.library == element.library &&
          base.isSealed &&
          schemableChecker.hasAnnotationOfExact(base);
    });
    return isImplicitUnionBranch
        ? ackClassSchemaFacadeName(element.name!)
        : null;
  }

  /// The boundary and runtime type arguments of [type] as an
  /// `AckSchema<Boundary, Runtime>`.
  ({DartType boundary, DartType runtime})? ackSchemaTypeArguments(
    DartType type,
  ) {
    if (type is! InterfaceType) return null;
    for (final candidate in [type, ...type.allSupertypes]) {
      if (ackSchemaChecker.isExactlyType(candidate) &&
          candidate.typeArguments.length == 2) {
        return (
          boundary: candidate.typeArguments[0],
          runtime: candidate.typeArguments[1],
        );
      }
    }
    return null;
  }

  /// The boundary type argument of [type] as an `AckSchema<Boundary, Runtime>`.
  DartType? ackSchemaBoundaryType(DartType type) =>
      ackSchemaTypeArguments(type)?.boundary;

  /// The runtime type argument of [type] as an `AckSchema<Boundary, Runtime>`.
  DartType? ackSchemaRuntimeType(DartType type) =>
      ackSchemaTypeArguments(type)?.runtime;

  /// Whether a schema producing [left] can back a field of type [right].
  ///
  /// The types must match apart from nullability: collection schemas such as
  /// `Ack.map` type their values as nullable.
  bool sameTypeIgnoringNullability(DartType left, DartType right) {
    final typeSystem = library.element.typeSystem;
    final a = typeSystem.promoteToNonNull(left);
    final b = typeSystem.promoteToNonNull(right);
    if (a is InterfaceType && b is InterfaceType) {
      if (a.element.baseElement != b.element.baseElement ||
          a.typeArguments.length != b.typeArguments.length) {
        return false;
      }
      for (var i = 0; i < a.typeArguments.length; i++) {
        if (!sameTypeIgnoringNullability(
          a.typeArguments[i],
          b.typeArguments[i],
        )) {
          return false;
        }
      }
      return true;
    }
    return typeSystem.isSubtypeOf(a, b) && typeSystem.isSubtypeOf(b, a);
  }

  bool containsInvalidType(DartType type) =>
      type is InvalidType ||
      (type is InterfaceType && type.typeArguments.any(containsInvalidType));

  bool isCoreType(InterfaceType type, String name) =>
      type.element.library.uri.toString() == 'dart:core' &&
      type.element.name == name;

  bool isCoreScalar(InterfaceType type) =>
      type.element.library.uri.toString() == 'dart:core' &&
      coreScalarNames.contains(type.element.name);

  bool isNullableType(DartType type) =>
      type.nullabilitySuffix == NullabilitySuffix.question;

  bool isJsonMaybeType(DartType type) =>
      type is InterfaceType &&
      type.typeArguments.length == 1 &&
      jsonMaybeChecker.isExactlyType(type);

  DartType unwrapJsonMaybeType(DartType type) => isJsonMaybeType(type)
      ? (type as InterfaceType).typeArguments.single
      : type;

  bool isSupportedMapKey(InterfaceType mapType) {
    if (!mapType.isDartCoreMap || mapType.typeArguments.length != 2) {
      return true;
    }
    final key = mapType.typeArguments.first;
    return key is InterfaceType && isCoreType(key, 'String');
  }

  /// A type argument of an application type, where `void` is also valid,
  /// as in `Trigger<void>`. It is never a field or collection item type.
  AckInferRef inferTypeArgumentRef(
    DartType type, {
    required String path,
    required Element context,
    AckInferRef Function(DartType type)? onUnsupportedType,
    void Function(InterfaceType mapType)? validateMapKey,
    AckInferRef? Function(InterfaceElement element)? resolveModelType,
  }) => type is VoidType
      ? const AckExternalTypeRef(name: 'void')
      : inferTypeRef(
          type,
          path: path,
          context: context,
          allowJsonMaybe: false,
          onUnsupportedType: onUnsupportedType,
          validateMapKey: validateMapKey,
          resolveModelType: resolveModelType,
        );

  /// Converts a resolved [DartType] into a normalized [AckInferRef].
  AckInferRef inferTypeRef(
    DartType type, {
    required String path,
    required Element context,
    bool allowJsonMaybe = false,
    AckInferRef Function(DartType type)? onUnsupportedType,
    void Function(InterfaceType mapType)? validateMapKey,
    AckInferRef? Function(InterfaceElement element)? resolveModelType,
  }) {
    if (type is DynamicType) {
      if (onUnsupportedType != null) return onUnsupportedType(type);
      return const AckNullableTypeRef(AckScalarTypeRef('Object'));
    }
    if (type is TypeParameterType) {
      if (onUnsupportedType != null) return onUnsupportedType(type);
      return AckExternalTypeRef(name: type.element.name ?? 'Object');
    }
    if (type is! InterfaceType) {
      if (onUnsupportedType != null) return onUnsupportedType(type);
      throw InvalidGenerationSource(
        'Unsupported runtime type ${type.getDisplayString()}.',
        element: context,
      );
    }
    final nullable = isNullableType(type);
    if (onUnsupportedType != null && isJsonMaybeType(type)) {
      if (!allowJsonMaybe) {
        return onUnsupportedType(type);
      }
      if (nullable) {
        throw InvalidGenerationSource(
          '$path uses nullable ${type.getDisplayString()}; use non-nullable '
          'JsonMaybe<...> instead, which already models both absent and null '
          'values.',
          element: context,
        );
      }
      return AckJsonMaybeTypeRef(
        inferTypeRef(
          type.typeArguments.single,
          path: path,
          context: context,
          onUnsupportedType: onUnsupportedType,
          validateMapKey: validateMapKey,
          resolveModelType: resolveModelType,
        ),
      );
    }
    final name = type.element.name ?? type.getDisplayString();
    late final AckInferRef result;
    if (type.isDartCoreList && type.typeArguments.length == 1) {
      result = AckListTypeRef(
        inferTypeRef(
          type.typeArguments.single,
          path: path,
          context: context,
          onUnsupportedType: onUnsupportedType,
          validateMapKey: validateMapKey,
          resolveModelType: resolveModelType,
        ),
      );
    } else if (type.isDartCoreSet && type.typeArguments.length == 1) {
      result = AckSetTypeRef(
        inferTypeRef(
          type.typeArguments.single,
          path: path,
          context: context,
          onUnsupportedType: onUnsupportedType,
          validateMapKey: validateMapKey,
          resolveModelType: resolveModelType,
        ),
      );
    } else if (type.isDartCoreMap && type.typeArguments.length == 2) {
      if (validateMapKey != null) {
        validateMapKey(type);
      } else if (!isSupportedMapKey(type)) {
        throw InvalidGenerationSource(
          'Generated Ack models support only Map<String, T> runtime types; '
          'received ${type.getDisplayString()}.',
          element: context,
          todo:
              'Use a string-keyed map or codec the value to a supported '
              'runtime type before generating the model.',
        );
      }
      result = AckMapTypeRef(
        inferTypeRef(
          type.typeArguments[1],
          path: path,
          context: context,
          onUnsupportedType: onUnsupportedType,
          validateMapKey: validateMapKey,
          resolveModelType: resolveModelType,
        ),
      );
    } else if (isCoreScalar(type)) {
      result = AckScalarTypeRef(name);
    } else if (resolveModelType?.call(type.element) case final modelRef?) {
      result = modelRef;
    } else {
      result = AckExternalTypeRef(
        name: name,
        importPrefix: visiblePrefixFor(
          type.element,
          path: path,
          context: context,
        ),
        typeArguments: [
          for (final argument in type.typeArguments)
            inferTypeArgumentRef(
              argument,
              path: path,
              context: context,
              onUnsupportedType: onUnsupportedType,
              validateMapKey: validateMapKey,
              resolveModelType: resolveModelType,
            ),
        ],
      );
    }
    return nullable ? AckNullableTypeRef(result) : result;
  }

  /// The import prefix that names [target] in this library, or null when an
  /// unprefixed name reaches it.
  ///
  /// Throws when [target] is not visible, because a part cannot add imports.
  String? visiblePrefixFor(
    Element target, {
    required String path,
    required Element context,
  }) {
    if (target.library == library.element) return null;
    final name = target.name;
    if (name == null) return null;
    String? prefixed;
    var unprefixed = false;
    for (final import in library.element.firstFragment.libraryImports) {
      if (import.isSynthetic || (import.prefix?.isDeferred ?? false)) continue;
      final prefix = import.prefix?.element.name;
      final candidate = prefix == null
          ? import.namespace.get2(name)
          : import.namespace.getPrefixed2(prefix, name);
      if (candidate?.baseElement != target.baseElement) continue;
      if (prefix != null && prefix.isNotEmpty) {
        prefixed ??= prefix;
      } else {
        unprefixed = true;
      }
    }
    if (prefixed != null || unprefixed) return prefixed;
    final inScope = library.element.firstFragment.scope.lookup(name).getter;
    if (inScope?.baseElement == target.baseElement) return null;
    throw InvalidGenerationSource(
      '$path uses $name, which is not visible in this library. Import '
      '${target.library?.uri}.',
      element: context,
    );
  }

  String visibleTypeNameFor(
    InterfaceType type, {
    required String path,
    required Element context,
  }) => qualifySymbol(
    visiblePrefixFor(type.element, path: path, context: context),
    type.element.name!,
  );

  /// Checks whether both [declaration] and its generated [companionName] are
  /// exposed through imports with [prefix].
  ({bool declarationVisible, bool companionVisible}) checkCompanionVisibility(
    Element declaration,
    String companionName, {
    required String? prefix,
  }) {
    final definingLibrary = declaration.library;
    final declarationName = declaration.name;
    if (definingLibrary == null || declarationName == null) {
      return (declarationVisible: false, companionVisible: false);
    }
    if (definingLibrary == library.element) {
      return (declarationVisible: true, companionVisible: true);
    }
    final canonical = propertyDeclaration(declaration).baseElement;
    var declarationVisible = false;
    var companionVisible = false;
    for (final import in library.element.firstFragment.libraryImports) {
      if (import.isSynthetic || (import.prefix?.isDeferred ?? false)) continue;
      final importPrefix = import.prefix?.element.name;
      if (importPrefix != prefix) continue;
      final candidate = prefix == null
          ? import.namespace.get2(declarationName)
          : import.namespace.getPrefixed2(prefix, declarationName);
      if (candidate != null &&
          propertyDeclaration(candidate).baseElement == canonical) {
        declarationVisible = true;
      }
      if (importExposesGeneratedCompanion(
        import,
        definingLibrary: definingLibrary,
        generatedName: companionName,
      )) {
        companionVisible = true;
      }
    }
    return (
      declarationVisible: declarationVisible,
      companionVisible: companionVisible,
    );
  }

  /// Yields all classes in [root] and its transitive export closure.
  Iterable<ClassElement> classesInExportClosure(LibraryElement root) sync* {
    final pending = <LibraryElement>[root];
    final visited = <Uri>{};
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (!visited.add(current.uri)) continue;
      yield* current.classes;
      for (final export in current.firstFragment.libraryExports) {
        if (export.exportedLibrary case final exported?) {
          pending.add(exported);
        }
      }
    }
  }

  /// Resolves a `<prefix.>?<FacadeName>.schema` reference to the underlying
  /// class-first `@Schemable` model class, if any.
  AckExternalTypeRef? resolveClassFirstModelReference(
    Expression expression,
    Element context,
  ) {
    final match = RegExp(
      r'^(?:([A-Za-z$][A-Za-z0-9_$]*)\.)?'
      r'([A-Z][A-Za-z0-9_$]*)\.schema$',
    ).firstMatch(expression.toSource());
    if (match == null) return null;
    final prefix = match.group(1);
    final facadeName = match.group(2)!;
    final matches = <ClassElement>{};
    final candidates = <ClassElement>{};
    final visibleModels = <ClassElement>{};
    String? hiddenModelName;

    void consider(ClassElement element) {
      final generatedFacade = classFirstFacadeName(element);
      if (generatedFacade != facadeName) return;
      candidates.add(element);
    }

    if (prefix == null) {
      for (final element in library.element.classes) {
        if (classFirstFacadeName(element) == facadeName) {
          matches.add(element);
        }
      }
    }
    final imports = <LibraryImport>[];
    for (final import in library.element.firstFragment.libraryImports) {
      if (import.isSynthetic || (import.prefix?.isDeferred ?? false)) continue;
      final importPrefix = import.prefix?.element.name;
      if (importPrefix != prefix) continue;
      imports.add(import);
      final importedLibrary = import.importedLibrary;
      if (importedLibrary == null) continue;
      for (final element in classesInExportClosure(importedLibrary)) {
        consider(element);
        final modelName = element.name;
        if (modelName == null) continue;
        final visible = prefix == null
            ? import.namespace.get2(modelName)
            : import.namespace.getPrefixed2(prefix, modelName);
        if (visible?.baseElement == element.baseElement) {
          visibleModels.add(element);
        }
      }
    }
    for (final target in candidates) {
      final facadeVisible = imports.any(
        (import) => importExposesGeneratedCompanion(
          import,
          definingLibrary: target.library,
          generatedName: facadeName,
        ),
      );
      if (visibleModels.contains(target) && facadeVisible) {
        matches.add(target);
      } else {
        hiddenModelName = target.name;
      }
    }
    if (matches.isEmpty) {
      if (hiddenModelName != null) {
        throw InvalidGenerationSource(
          'Generated facade "$facadeName" is hidden by an import combinator '
          'or an upstream export combinator. Expose both $hiddenModelName and '
          '$facadeName through the full import route.',
          element: context,
        );
      }
      return null;
    }
    if (matches.length > 1) {
      throw InvalidGenerationSource(
        'Generated facade reference ${expression.toSource()} is ambiguous.',
        element: context,
      );
    }
    final target = matches.single;
    return AckExternalTypeRef(name: target.name!, importPrefix: prefix);
  }

  /// Names of all top-level declarations in the current [library].
  Set<String> localDeclarationNames() => {
    for (final element in library.allElements)
      if (element.name case final name?) name,
  };

  /// Validates that generated `copyWith` helper types for [className] do not
  /// collide with [localNames].
  void validateCopyWithHelperNames({
    required String className,
    required bool needsCopyWithSentinel,
    required Element element,
    required Set<String> localNames,
  }) {
    final sentinelType = ackCopyWithUnsetTypeName(className);
    if (needsCopyWithSentinel && localNames.contains(sentinelType)) {
      throw InvalidGenerationSource(
        'Generated helper "$sentinelType" conflicts with a local declaration.',
        element: element,
      );
    }
    for (final copyWithType in [
      ackCopyWithInterfaceName(className),
      ackCopyWithImplementationName(className),
    ]) {
      if (!localNames.contains(copyWithType)) continue;
      throw InvalidGenerationSource(
        'Generated helper "$copyWithType" conflicts with a local declaration.',
        element: element,
      );
    }
  }

  /// Parses an `Ack.*` or referenced schema method chain from [expression].
  SchemaChain parseSchemaChain(Expression expression) {
    if (expression is! MethodInvocation) {
      return SchemaChain(
        base: null,
        reference: expression,
        hasTransform: false,
        hasCodec: false,
      );
    }
    MethodInvocation? current = expression;
    MethodInvocation? base;
    Expression? reference;
    var transform = false;
    var codec = false;
    while (current != null) {
      final name = current.methodName.name;
      transform |= oneWayTransformMethods.contains(name);
      codec |= name == 'codec';
      if (current.methodName.element is TopLevelFunctionElement ||
          isTypeOwnedSchema(current.methodName.element)) {
        reference = current;
        break;
      }
      final target = current.target;
      if (isAckTarget(target)) {
        base = current;
        break;
      }
      if (target is MethodInvocation) {
        current = target;
      } else {
        reference = target;
        break;
      }
    }
    return SchemaChain(
      base: base,
      reference: reference,
      hasTransform: transform,
      hasCodec: codec,
    );
  }

  bool isAckTarget(Expression? expression) {
    if (expression is SimpleIdentifier) return expression.name == 'Ack';
    if (expression is PrefixedIdentifier) {
      return expression.identifier.name == 'Ack';
    }
    return false;
  }

  /// Whether [element] is a static `schema` member that a type declares.
  bool isTypeOwnedSchema(Element? element) =>
      (element is GetterElement || element is MethodElement) &&
      element is ExecutableElement &&
      element.isStatic &&
      element.name == 'schema' &&
      element.enclosingElement is InterfaceElement;

  Element? memberElement(Expression expression) => switch (expression) {
    PrefixedIdentifier() => expression.identifier.element,
    PropertyAccess() => expression.propertyName.element,
    MethodInvocation() => expression.methodName.element,
    _ => null,
  };

  /// Resolves the top-level declaration referenced by [expression], if any.
  Element? referencedElement(Expression expression) {
    if (expression is ParenthesizedExpression) {
      return referencedElement(expression.expression);
    }
    if (expression is SimpleIdentifier) {
      final element = expression.element;
      return element == null ? null : propertyDeclaration(element);
    }
    if (expression is PrefixedIdentifier) {
      final element = expression.identifier.element;
      return element == null ? null : propertyDeclaration(element);
    }
    if (expression is MethodInvocation) {
      final method = expression.methodName.element;
      if (method is TopLevelFunctionElement) {
        return propertyDeclaration(method);
      }
      final chain = parseSchemaChain(expression);
      final reference = chain.reference;
      return reference == null ? null : referencedElement(reference);
    }
    return null;
  }

  String? expressionPrefix(Expression expression) {
    if (expression is PrefixedIdentifier) return expression.prefix.name;
    if (expression is MethodInvocation && expression.target != null) {
      return expressionPrefix(expression.target!);
    }
    return null;
  }

  /// Resolves the initializer or body expression of a top-level variable,
  /// getter, or function [referenced] by another schema expression.
  Future<({Element declaration, Expression expression})?>
  resolveReferencedTopLevelExpression(
    Element? referenced, {
    required Set<Element> visited,
  }) async {
    if (referenced == null) return null;
    final declaration = propertyDeclaration(referenced);
    if (declaration is! TopLevelVariableElement &&
        declaration is! GetterElement &&
        declaration is! TopLevelFunctionElement) {
      return null;
    }
    final canonical = declaration.baseElement;
    if (visited.contains(canonical) || visited.length >= maxReferenceDepth) {
      return null;
    }
    final owningLibrary = declaration.library;
    if (owningLibrary == null) return null;
    final resolved = await resolvedLibraryFor(owningLibrary);
    final expression = declarationExpression(resolved, declaration);
    if (expression == null) return null;
    return (declaration: declaration, expression: expression);
  }

  /// Returns a human-readable trace (`a → b → transform`) if [expression]
  /// invokes or transitively reaches a one-way `.transform()` call.
  Future<String?> oneWayTransformSource(
    Expression expression, {
    Set<Element> visited = const {},
  }) async {
    Expression? current = expression;
    while (current is ParenthesizedExpression) {
      current = current.expression;
    }
    Element? referenced;
    while (current is MethodInvocation) {
      if (oneWayTransformMethods.contains(current.methodName.name)) {
        return current.methodName.name;
      }
      final method = current.methodName.element;
      if (method is TopLevelFunctionElement) referenced = method;
      current = current.target;
    }
    referenced ??= switch (current) {
      SimpleIdentifier() => current.element,
      PrefixedIdentifier() => current.identifier.element,
      PropertyAccess() => current.propertyName.element,
      _ => null,
    };
    final target = await resolveReferencedTopLevelExpression(
      referenced,
      visited: visited,
    );
    if (target == null) return null;
    final nested = await oneWayTransformSource(
      target.expression,
      visited: {...visited, target.declaration.baseElement},
    );
    return nested == null ? null : '${target.declaration.name} → $nested';
  }

  /// Normalizes Analyzer argument nodes into plain expressions.
  List<Expression> argumentExpressions(ArgumentList argumentList) => [
    for (final argument in argumentList.arguments) argument.argumentExpression,
  ];

  Expression argumentExpression(Argument argument) =>
      argument.argumentExpression;

  ({String name, Expression expression})? namedArgument(Argument argument) =>
      argument is NamedArgument
      ? (name: argument.name.lexeme, expression: argument.argumentExpression)
      : null;

  bool? constantBool(Expression expression) {
    while (expression is ParenthesizedExpression) {
      expression = expression.expression;
    }
    if (expression is BooleanLiteral) return expression.value;

    final element = switch (expression) {
      SimpleIdentifier() => expression.element,
      PrefixedIdentifier() => expression.identifier.element,
      PropertyAccess() => expression.propertyName.element,
      _ => null,
    };
    final declaration = element == null ? null : propertyDeclaration(element);
    return declaration is VariableElement
        ? declaration.computeConstantValue()?.toBoolValue()
        : null;
  }

  String? descriptionFromExpression(Expression expression) {
    Expression? current = expression;
    while (current is MethodInvocation) {
      final arguments = argumentExpressions(current.argumentList);
      if (current.methodName.name == 'describe' &&
          arguments.firstOrNull is SimpleStringLiteral) {
        return (arguments.first as SimpleStringLiteral).value;
      }
      current = current.target;
    }
    return null;
  }

  String ack(String symbol) => qualifySymbol(ackPrefix, symbol);
}
