import 'package:ack/ack.dart' show AckSchema;
import 'package:ack_annotations/ack_annotations.dart' as annotations;
import 'package:ack_annotations/ack_generator_support.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:source_gen/source_gen.dart';

import '../json/helper_names.dart';
import '../models/schema_model_graph.dart';
import '../inference/schema_inference.dart';
import 'generated_companion_visibility.dart';

typedef _ModelOptions = ({
  String? schemaName,
  String caseStyle,
  String? discriminatorKey,
  String? discriminatorValue,
  annotations.AckUnknownPropertyPolicy unknownProperties,
  String captureField,
});

typedef _FutureGeneratedType = ({
  String schemaExpression,
  AckInferRef runtimeRef,
  String? setListSchema,
});

typedef _ClassFirstDependency = ({ClassElement target, FieldElement field});

/// Builds normalized Ack model nodes from hand-written `@AckModel` classes.
///
/// Analyzer elements and AST nodes are consumed here; emitters receive only
/// structural type references and source expressions stored in [AckModelGraph].
final class ClassModelGraphBuilder {
  ClassModelGraphBuilder(this.library, {this.ackPrefix});

  static const _reservedMembers = {
    r'$ack',
    'parse',
    'safeParse',
    'fromJson',
    'toJson',
    'safeToJson',
    'copyWith',
    'additionalProperties',
    'hashCode',
    'noSuchMethod',
    'runtimeType',
  };

  static const _generatedSerializationMembers = {'toJson', 'safeToJson'};

  static const _generatedValueMembers = {
    'copyWith',
    'toString',
    'hashCode',
    '==',
  };

  static const _dartKeywords = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'base',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'of',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'sealed',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'when',
    'while',
    'with',
    'yield',
  };

  static const _oneWayTransformMethods = {
    'transform',
    'trim',
    'toLowerCase',
    'toUpperCase',
  };

  static const _ackModelChecker = TypeChecker.typeNamed(
    annotations.AckModel,
    inPackage: 'ack_annotations',
  );
  static const _ackInferChecker = TypeChecker.typeNamed(
    annotations.AckInfer,
    inPackage: 'ack_annotations',
  );
  static const _ackTypeChecker = TypeChecker.typeNamed(
    // ignore: deprecated_member_use
    annotations.AckType,
    inPackage: 'ack_annotations',
  );
  static const _ackFieldChecker = TypeChecker.typeNamed(
    annotations.AckField,
    inPackage: 'ack_annotations',
  );
  static const _ackSchemaChecker = TypeChecker.typeNamed(
    AckSchema,
    inPackage: 'ack',
  );
  static const _generatedJsonChecker = TypeChecker.typeNamed(
    AckGeneratedJson,
    inPackage: 'ack_annotations',
  );
  static const _jsonSerializableChecker = TypeChecker.typeNamed(
    JsonSerializable,
    inPackage: 'json_annotation',
  );
  static const _jsonKeyChecker = TypeChecker.typeNamed(
    JsonKey,
    inPackage: 'json_annotation',
  );

  static const _optionalChecker = TypeChecker.typeNamed(
    annotations.Optional,
    inPackage: 'ack_annotations',
  );
  static const _requiredChecker = TypeChecker.typeNamed(
    annotations.Required,
    inPackage: 'ack_annotations',
  );
  static const _notNullChecker = TypeChecker.typeNamed(
    annotations.NotNull,
    inPackage: 'ack_annotations',
  );

  final LibraryReader library;
  final String? ackPrefix;
  AckSchemaInference get _inference => AckSchemaInference(ackPrefix: ackPrefix);
  final AckModelGraph _graph = AckModelGraph();
  final Set<ClassElement> _explicit = {};
  final Set<ClassElement> _consumed = {};
  final Map<String, ClassElement> _schemaNameOwners = {};
  final Map<ClassElement, List<_ClassFirstDependency>> _dependencies = {};
  ResolvedLibraryResult? _inputResolved;
  final Map<Uri, ResolvedLibraryResult> _resolvedByUri = {};

  Future<AckModelGraph> build(List<ClassElement> annotatedClasses) async {
    final libraryElement = library.element;
    final resolved = await libraryElement.session.getResolvedLibraryByElement(
      libraryElement,
    );
    if (resolved is! ResolvedLibraryResult) {
      throw InvalidGenerationSource(
        'Could not resolve ${libraryElement.uri} for @AckModel generation.',
      );
    }
    _inputResolved = resolved;
    _resolvedByUri[libraryElement.uri] = resolved;
    _explicit.addAll(annotatedClasses);

    for (final element in annotatedClasses) {
      _validateAnnotatedClass(element);
    }

    for (final element in annotatedClasses.where((item) => item.isSealed)) {
      await _buildUnion(element);
    }
    for (final element in annotatedClasses) {
      if (_consumed.contains(element)) continue;
      final options = _options(element)!;
      if (options.discriminatorValue != null) {
        throw InvalidGenerationSource(
          '${element.name} sets discriminatorValue but is not a concrete '
          'branch of an annotated sealed @AckModel base.',
          element: element,
        );
      }
      if (element.isAbstract || !element.isConstructable) {
        throw InvalidGenerationSource(
          '@AckModel requires a constructable class; ${element.name} is '
          'abstract.',
          element: element,
        );
      }
      await _buildObject(element, options: options);
    }
    _rejectRecursiveClassFirstGraphs();
    _validateGeneratedNames();
    return _graph;
  }

  void _validateGeneratedNames() {
    final localNames = {
      for (final element in library.allElements)
        if (element.name case final name?) name,
    };
    final generatedOwners = <String, ClassElement>{};
    final classes = {
      for (final element in library.classes) element.name!: element,
    };

    void claim(String name, AckModelNode node) {
      final element = classes[node.className]!;
      final prior = generatedOwners[name];
      if (prior != null && prior != element) {
        throw InvalidGenerationSource(
          'Generated helper "$name" for ${element.name} conflicts with '
          '${prior.name}.',
          element: element,
        );
      }
      if (localNames.contains(name)) {
        throw InvalidGenerationSource(
          'Generated helper "$name" conflicts with a local declaration.',
          element: element,
        );
      }
      generatedOwners[name] = element;
    }

    for (final node in _graph.nodes) {
      final metadata = _graph.classMetadataFor(node.id);
      if (metadata == null) {
        throw StateError('Missing class-first metadata for ${node.id}.');
      }
      claim(metadata.facadeName, node);
      claim(metadata.backingName, node);
      claim(ackClassWireSchemaName(node.className), node);
      claim(ackClassMixinName(node.className), node);
      claim(ackClassRawObjectName(node.className), node);
      if (node is! AckObjectModelNode) continue;
      if (node.fields.any((field) => field.nullable || !field.isRequired)) {
        claim(ackCopyWithUnsetTypeName(node.className), node);
      }
      claim(ackClassFromRuntimeName(node.className), node);
      claim(ackClassToRuntimeName(node.className), node);
      claim(jsonFromHelperName(node.className), node);
      claim(jsonToHelperName(node.className), node);
      for (final fieldName in <String>[
        for (final field in node.fields) field.dartName,
        if (node.captureFieldName case final capture?) capture,
      ]) {
        claim(ackClassFromRuntimeBridgeName(node.className, fieldName), node);
        claim(ackClassToRuntimeBridgeName(node.className, fieldName), node);
      }
    }
  }

  void _validateAnnotatedClass(ClassElement element) {
    final name = element.name ?? '';
    if (name.startsWith('_')) {
      throw InvalidGenerationSource(
        '@AckModel requires a public class; received "$name".',
        element: element,
        todo: 'Annotate a public class.',
      );
    }
    _requireFinalConcreteClass(element);
    if (_jsonSerializableChecker.hasAnnotationOfExact(element)) {
      throw InvalidGenerationSource(
        '$name cannot use @AckModel and @JsonSerializable together because '
        'both generate the same _\$$name JSON helpers.',
        element: element,
        todo: 'Remove @JsonSerializable; @AckModel owns JSON generation.',
      );
    }
    final options = _options(element)!;
    if (element.isSealed && options.discriminatorKey == null) {
      throw InvalidGenerationSource(
        'Sealed @AckModel $name requires discriminatorKey.',
        element: element,
      );
    }
    if (!element.isSealed && options.discriminatorKey != null) {
      throw InvalidGenerationSource(
        '$name sets discriminatorKey but is not a sealed class.',
        element: element,
      );
    }
    if (element.isSealed && options.discriminatorValue != null) {
      throw InvalidGenerationSource(
        'Sealed @AckModel $name cannot set discriminatorValue.',
        element: element,
      );
    }
  }

  Future<void> _buildUnion(ClassElement base) async {
    _requireMixin(base);
    _rejectGeneratedMemberCollisions(base, includeValueMembers: false);
    final baseOptions = _options(base)!;
    final discriminatorKey = baseOptions.discriminatorKey!;
    _rejectInvalidMemberName(
      discriminatorKey,
      base,
      memberKind: 'discriminator member',
    );
    if (_reservedMembers.contains(discriminatorKey)) {
      throw InvalidGenerationSource(
        '${base.name}.$discriminatorKey conflicts with a generated member.',
        element: base,
      );
    }
    _validateDiscriminatorType(base, discriminatorKey);

    final candidates = [
      for (final candidate in library.classes)
        if (candidate != base &&
            candidate.allSupertypes.any(
              (type) => type.element.baseElement == base.baseElement,
            ))
          candidate,
    ];
    for (final candidate in candidates) {
      if (candidate.isAbstract || !candidate.isConstructable) {
        throw InvalidGenerationSource(
          '${candidate.name} is an abstract intermediate branch of '
          '${base.name}; flattening abstract union branches is unsupported.',
          element: candidate,
        );
      }
      _requireFinalConcreteClass(candidate);
    }
    if (candidates.isEmpty) {
      throw InvalidGenerationSource(
        'Sealed @AckModel ${base.name} has no concrete same-library branches.',
        element: base,
      );
    }

    final baseId = _id(base);
    _graph.begin(baseId);
    _registerMetadata(base, baseOptions, baseId);
    _consumed.add(base);

    final branches = <String, AckSchemaId>{};
    final valueOwners = <String, ClassElement>{};
    for (final branch in candidates) {
      final branchOptions =
          _options(branch) ??
          (
            schemaName: null,
            caseStyle: baseOptions.caseStyle,
            discriminatorKey: null,
            discriminatorValue: null,
            unknownProperties: annotations.AckUnknownPropertyPolicy.reject,
            captureField: 'additionalProperties',
          );
      if (branchOptions.discriminatorKey != null) {
        throw InvalidGenerationSource(
          '${branch.name} is a union branch and cannot set discriminatorKey.',
          element: branch,
        );
      }
      final value = branchOptions.discriminatorValue ?? branch.name!;
      final prior = valueOwners[value];
      if (prior != null) {
        throw InvalidGenerationSource(
          '${base.name} has duplicate discriminatorValue "$value" on '
          '${prior.name} and ${branch.name}.',
          element: branch,
        );
      }
      valueOwners[value] = branch;
      _validateBranchDiscriminator(branch, discriminatorKey, value);
      final branchNode = await _buildObject(
        branch,
        options: branchOptions,
        unionId: baseId,
        discriminatorKey: discriminatorKey,
        discriminatorValue: value,
      );
      branches[value] = branchNode.id;
      _consumed.add(branch);
    }

    _graph.complete(
      AckUnionModelNode(
        id: baseId,
        className: base.name!,
        boundaryType: _jsonMapRef,
        runtimeRef: AckExternalTypeRef(name: base.name!),
        discriminatorKey: discriminatorKey,
        branches: branches,
      ),
    );
  }

  Future<AckObjectModelNode> _buildObject(
    ClassElement element, {
    required _ModelOptions options,
    AckSchemaId? unionId,
    String? discriminatorKey,
    String? discriminatorValue,
  }) async {
    final id = _id(element);
    _graph.begin(id);
    _registerMetadata(element, options, id);
    final constructor = element.unnamedConstructor;
    if (constructor == null || !constructor.isGenerative) {
      throw InvalidGenerationSource(
        '@AckModel ${element.name} requires an unnamed generative constructor.',
        element: element,
      );
    }
    _requireMixin(element);
    _rejectGeneratedMemberCollisions(element, includeValueMembers: true);

    final fields = _instanceFields(element);
    for (final field in fields.values) {
      if (field.isFinal) continue;
      throw InvalidGenerationSource(
        '${element.name}.${field.name} must be final because @AckModel '
        'generates immutable value semantics.',
        element: field,
        todo: 'Declare the stored field as final.',
      );
    }

    final captureFieldName =
        options.unknownProperties ==
            annotations.AckUnknownPropertyPolicy.capture
        ? options.captureField
        : null;
    if (options.unknownProperties !=
            annotations.AckUnknownPropertyPolicy.capture &&
        options.captureField != 'additionalProperties') {
      throw InvalidGenerationSource(
        '${element.name}.captureField is only valid with '
        'AckUnknownPropertyPolicy.capture.',
        element: element,
      );
    }
    if (captureFieldName != null) {
      _rejectInvalidMemberName(
        captureFieldName,
        element,
        memberKind: 'unknown-property capture field',
      );
    }

    final futureTypes = <String, _FutureGeneratedType>{};
    for (final field in fields.values) {
      final name = field.name;
      if (name == null) continue;
      _rejectResolvedLegacyGeneratedType(field.type, field);
      if (!_containsInvalidType(field.type)) continue;
      final futureType = await _futureGeneratedType(field);
      if (futureType != null) {
        futureTypes[name] = futureType;
      }
    }

    final parameters = <String, FormalParameterElement>{};
    final constructorParameters = <AckConstructorParameter>[];
    for (final parameter in constructor.formalParameters) {
      _rejectJsonKeyOnParameter(element, parameter);
      final field = _parameterField(parameter) ?? fields[parameter.name];
      final fieldName = field?.name;
      if (fieldName == null) {
        throw InvalidGenerationSource(
          '${element.name} constructor parameter "${parameter.name}" is not '
          'mapped to a constructor-initialized field.',
          element: parameter,
        );
      }
      parameters[fieldName] = parameter;
      constructorParameters.add(
        AckConstructorParameter(
          name: parameter.name!,
          kind: parameter.isNamed
              ? AckConstructorParameterKind.named
              : AckConstructorParameterKind.positional,
          fieldName: fieldName,
          typeRef:
              futureTypes[fieldName]?.runtimeRef ??
              _typeRef(parameter.type, field!),
          isSuper: parameter is SuperFormalParameterElement,
          defaultExpression: parameter.defaultValueCode,
        ),
      );
    }

    String? captureJsonKey;
    if (captureFieldName != null) {
      final extras = fields[captureFieldName];
      if (extras == null || !_isExactAdditionalPropertiesType(extras.type)) {
        throw InvalidGenerationSource(
          '${element.name}.$captureFieldName must be declared as '
          'Map<String, Object?> when additional properties are captured.',
          element: extras ?? element,
        );
      }
      if (!parameters.containsKey(captureFieldName)) {
        throw InvalidGenerationSource(
          '${element.name}.$captureFieldName must be initialized by the '
          'unnamed constructor.',
          element: extras,
        );
      }
      captureJsonKey =
          _jsonKey(extras) ?? _rename(captureFieldName, options.caseStyle);
    }

    final nodes = <AckFieldNode>[];
    final ownerByJsonKey = <String, FieldElement>{};
    for (final field in fields.values) {
      final name = field.name;
      if (name == null || name == captureFieldName) continue;
      if (name.startsWith('_')) {
        if (parameters.containsKey(name)) {
          throw InvalidGenerationSource(
            '${element.name}.$name is private and cannot participate in '
            '@AckModel generation.',
            element: field,
          );
        }
        continue;
      }
      final parameter = parameters[name];
      final isDiscriminator = discriminatorKey == name;
      if (parameter == null && !isDiscriminator) {
        throw InvalidGenerationSource(
          '${element.name}.$name must be initialized by a matching unnamed '
          'constructor parameter.',
          element: field,
        );
      }

      _rejectUnsupportedStaticType(field, field.type);
      _validateMapKey(field, field.type);
      final futureType = futureTypes[name];
      _recordClassFirstDependencies(element, field.type, field);
      final jsonKey = _jsonKey(field) ?? _rename(name, options.caseStyle);
      final prior = ownerByJsonKey[jsonKey];
      if (prior != null) {
        throw InvalidGenerationSource(
          '${element.name}.$name produces JSON key "$jsonKey", which '
          'conflicts with ${element.name}.${prior.name}.',
          element: field,
        );
      }
      if (captureJsonKey != null && jsonKey == captureJsonKey) {
        throw InvalidGenerationSource(
          '${element.name}.$name produces reserved JSON key '
          '"$captureJsonKey".',
          element: field,
        );
      }
      ownerByJsonKey[jsonKey] = field;

      final dartNullable =
          futureType?.runtimeRef is AckNullableTypeRef ||
          _isNullable(field.type);
      final rejectNull = _notNullChecker.hasAnnotationOfExact(field);
      final acceptsNull = dartNullable && !rejectNull;
      final presence = _effectivePresence(
        field,
        parameter: parameter,
        isDiscriminator: isDiscriminator,
      );
      var schema = isDiscriminator && discriminatorValue != null
          ? '${_ack('Ack')}.literal(${_literal(discriminatorValue)})'
          : await _fieldSchema(field, futureType: futureType);
      schema = _inference.applyDescription(schema, field);
      schema = _applyPresence(
        schema,
        presence: presence,
        acceptsNull: acceptsNull,
        defaultCode: parameter?.defaultValueCode,
        defaultIsNull: parameter?.computeConstantValue()?.isNull ?? false,
      );
      if (rejectNull) {
        schema = '$schema.nullable(value: false)';
      }
      nodes.add(
        AckFieldNode(
          dartName: name,
          jsonKey: jsonKey,
          presence: presence,
          nullable: dartNullable,
          acceptsNull: acceptsNull,
          runtimeRef: futureType?.runtimeRef ?? _typeRef(field.type, field),
          schemaExpression: schema,
          defaultExpression: parameter?.defaultValueCode,
        ),
      );
    }

    final node = AckObjectModelNode(
      id: id,
      className: element.name!,
      boundaryType: _jsonMapRef,
      runtimeRef: AckExternalTypeRef(name: element.name!),
      fields: nodes,
      constructorParameters: constructorParameters,
      unknownPropertyPolicy: switch (options.unknownProperties) {
        annotations.AckUnknownPropertyPolicy.reject =>
          AckUnknownPropertyPolicy.reject,
        annotations.AckUnknownPropertyPolicy.discard =>
          AckUnknownPropertyPolicy.discard,
        annotations.AckUnknownPropertyPolicy.capture =>
          AckUnknownPropertyPolicy.capture,
      },
      captureFieldName: captureFieldName,
      captureJsonKey: captureJsonKey,
      unionId: unionId,
      discriminatorKey: discriminatorKey,
      discriminatorValue: discriminatorValue,
    );
    _graph.complete(node);
    return node;
  }

  void _recordClassFirstDependencies(
    ClassElement owner,
    DartType type,
    FieldElement field,
  ) {
    if (type is! InterfaceType) return;
    final target = type.element;
    if (target is ClassElement && _classFirstFacadeName(target) != null) {
      _dependencies.putIfAbsent(owner, () => []).add((
        target: target,
        field: field,
      ));
    }
    for (final argument in type.typeArguments) {
      _recordClassFirstDependencies(owner, argument, field);
    }
  }

  void _rejectRecursiveClassFirstGraphs() {
    final visiting = <ClassElement>{};
    final visited = <ClassElement>{};

    List<_ClassFirstDependency> dependenciesFor(ClassElement owner) {
      final recorded = _dependencies[owner];
      if (recorded != null) return recorded;

      _dependencies[owner] = <_ClassFirstDependency>[];
      for (final field in _instanceFields(owner).values) {
        _recordClassFirstDependencies(owner, field.type, field);
      }
      return _dependencies[owner]!;
    }

    void visit(ClassElement owner) {
      if (visited.contains(owner)) return;
      visiting.add(owner);
      for (final dependency in dependenciesFor(owner)) {
        if (visiting.contains(dependency.target)) {
          final field = dependency.field;
          throw InvalidGenerationSource(
            '${field.enclosingElement.name}.${field.name} creates a '
            'recursive class-first schema graph. Automatic class-first '
            'Ack.lazy semantics are not yet defined; use a schema-first '
            'named Ack.lazy contract for recursive models.',
            element: field,
          );
        }
        visit(dependency.target);
      }
      visiting.remove(owner);
      visited.add(owner);
    }

    for (final owner in _dependencies.keys.toList(growable: false)) {
      visit(owner);
    }
  }

  Future<String> _fieldSchema(
    FieldElement field, {
    _FutureGeneratedType? futureType,
  }) async {
    final override = _ackFieldChecker.firstAnnotationOfExact(field);
    if (override != null) {
      final reader = ConstantReader(override);
      if (!reader.read('schema').isNull) {
        final base = await _escapeHatchExpression(field, reader);
        return _applySugar(base, field);
      }
    }
    if (futureType != null) {
      _rejectNullableFutureCollectionElement(field, futureType.runtimeRef);
      final setListSchema = futureType.setListSchema;
      if (setListSchema != null) {
        return _setCodec(
          _applySugar(setListSchema, field),
          futureType.runtimeRef,
        );
      }
      return _applySugar(futureType.schemaExpression, field);
    }
    final type = field.type;
    if (type is InterfaceType &&
        type.isDartCoreSet &&
        type.typeArguments.length == 1) {
      final itemType = type.typeArguments.single;
      _rejectNullableCollectionElement(field, itemType);
      final item = await _schemaForType(itemType, field);
      final list = _applySugar('${_ack('Ack')}.list($item)', field);
      return _setCodec(list, _typeRef(type, field));
    }
    return _applySugar(await _schemaForType(type, field), field);
  }

  String _setCodec(String listSchema, AckInferRef runtimeRef) {
    // Presence adds nullability to the codec; its type argument is the set.
    final setType = switch (runtimeRef) {
      AckNullableTypeRef(:final inner) => inner,
      _ => runtimeRef,
    };
    final rendered = _renderType(_schemaRuntimeRef(setType));
    return '$listSchema.codec<$rendered>('
        'decode: (list) => list.toSet(), '
        'encode: (set) => set.toList(growable: false),'
        ')';
  }

  AckInferRef _schemaRuntimeRef(AckInferRef type) => switch (type) {
    AckNullableTypeRef(:final inner) => AckNullableTypeRef(
      _schemaRuntimeRef(inner),
    ),
    AckModelTypeRef(:final runtimeRef) => _schemaRuntimeRef(runtimeRef),
    AckListTypeRef(:final elementType) => AckListTypeRef(
      _schemaRuntimeRef(elementType),
    ),
    AckSetTypeRef(:final elementType) => AckSetTypeRef(
      _schemaRuntimeRef(elementType),
    ),
    AckMapTypeRef(:final valueType) => AckMapTypeRef(
      _schemaRuntimeRef(valueType),
    ),
    _ => type,
  };

  bool _containsInvalidType(DartType type) =>
      type is InvalidType ||
      (type is InterfaceType && type.typeArguments.any(_containsInvalidType));

  void _rejectResolvedLegacyGeneratedType(DartType type, FieldElement field) {
    if (type is! InterfaceType) return;
    final element = type.element;
    if (element is ExtensionTypeElement) {
      final name = element.name;
      if (name != null && _isGeneratedAckType(element, name)) {
        _rejectLegacyGeneratedType(field, name);
      }
    }
    for (final argument in type.typeArguments) {
      _rejectResolvedLegacyGeneratedType(argument, field);
    }
  }

  bool _isGeneratedAckType(ExtensionTypeElement element, String name) {
    for (final candidate in LibraryReader(element.library).allElements) {
      final declaration = _ackTypeDeclaration(candidate);
      if (declaration != null && _generatedAckTypeName(declaration) == name) {
        return true;
      }
    }
    return false;
  }

  Future<_FutureGeneratedType?> _futureGeneratedType(FieldElement field) async {
    final resolved = await _resolvedLibraryFor(field.library);
    AstNode? node = resolved.getFragmentDeclaration(field.firstFragment)?.node;
    while (node != null && node is! FieldDeclaration) {
      node = node.parent;
    }
    final annotation = node is FieldDeclaration ? node.fields.type : null;
    if (annotation == null) return null;
    return _futureGeneratedTypeForAnnotation(annotation, field);
  }

  _FutureGeneratedType? _futureGeneratedTypeForAnnotation(
    TypeAnnotation annotation,
    FieldElement field,
  ) {
    if (annotation is! NamedType) return null;
    final name = annotation.name.lexeme;
    final prefix = annotation.importPrefix?.name.lexeme;
    final arguments = annotation.typeArguments?.arguments ?? const [];
    _FutureGeneratedType? result;
    if (prefix == null && name == 'List' && arguments.length == 1) {
      final item = _futureGeneratedTypeForAnnotation(arguments.single, field);
      if (item == null) return null;
      result = (
        schemaExpression: '${_ack('Ack')}.list(${item.schemaExpression})',
        runtimeRef: AckListTypeRef(item.runtimeRef),
        setListSchema: null,
      );
    } else if (prefix == null && name == 'Set' && arguments.length == 1) {
      final item = _futureGeneratedTypeForAnnotation(arguments.single, field);
      if (item == null) return null;
      final runtimeRef = AckSetTypeRef(item.runtimeRef);
      final listSchema = '${_ack('Ack')}.list(${item.schemaExpression})';
      result = (
        schemaExpression: _setCodec(listSchema, runtimeRef),
        runtimeRef: runtimeRef,
        setListSchema: listSchema,
      );
    } else {
      final legacyTarget = _futureAckTypeTarget(
        generatedTypeName: name,
        prefix: prefix,
        field: field,
      );
      if (legacyTarget != null) {
        _rejectLegacyGeneratedType(field, name);
      }
      final target = _futureAckInferTarget(
        className: name,
        prefix: prefix,
        field: field,
      );
      if (target == null) return null;
      final visibleName = prefix == null ? name : '$prefix.$name';
      result = (
        schemaExpression: '$visibleName.\$ack.schema',
        runtimeRef: AckModelTypeRef(
          schemaId: AckSchemaId(
            libraryUri: target.library!.uri,
            declarationName: target.name!,
          ),
          className: name,
          runtimeRef: _jsonMapRef,
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

  Element? _futureAckInferTarget({
    required String className,
    required String? prefix,
    required FieldElement field,
  }) {
    final matches = <Element>{};
    final candidates = <Element>{};
    final imports = <LibraryImport>[];
    String? hiddenDeclaration;

    Element? candidateFor(Element element) {
      final declaration = _ackInferDeclaration(element);
      if (declaration == null ||
          _generatedAckInferClassName(declaration) != className) {
        return null;
      }
      return declaration.baseElement;
    }

    if (prefix == null) {
      for (final element in library.allElements) {
        final candidate = candidateFor(element);
        if (candidate != null) matches.add(candidate);
      }
    }
    for (final import in library.element.firstFragment.libraryImports) {
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
        final fieldPath = '${field.enclosingElement.name}.${field.name}';
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
        '${field.enclosingElement.name}.${field.name} resolves future generated '
        'type "$className" ambiguously.',
        element: field,
      );
    }
    return matches.single;
  }

  Element? _futureAckTypeTarget({
    required String generatedTypeName,
    required String? prefix,
    required FieldElement field,
  }) {
    final matches = <Element>{};
    String? hiddenDeclaration;

    void consider(Element element, LibraryImport? import) {
      final declaration = _ackTypeDeclaration(element);
      if (declaration == null ||
          _generatedAckTypeName(declaration) != generatedTypeName) {
        return;
      }
      if (import != null && !_importAllowsName(import, generatedTypeName)) {
        hiddenDeclaration = declaration.name;
        return;
      }
      matches.add(declaration.baseElement);
    }

    if (prefix == null) {
      for (final element in library.allElements) {
        consider(element, null);
      }
    }
    for (final import in library.element.firstFragment.libraryImports) {
      if (import.isSynthetic || (import.prefix?.isDeferred ?? false)) continue;
      final importPrefix = import.prefix?.element.name;
      if (importPrefix != prefix) continue;
      final importedLibrary = import.importedLibrary;
      final elements = <Element>{
        if (importedLibrary != null)
          ...LibraryReader(importedLibrary).allElements,
        ...import.namespace.definedNames2.values,
      };
      for (final element in elements) {
        consider(element, import);
      }
    }
    if (matches.isEmpty) {
      if (hiddenDeclaration != null) {
        throw InvalidGenerationSource(
          'Generated legacy type "$generatedTypeName" is hidden by an '
          'import combinator. Expose $generatedTypeName from the import.',
          element: field,
        );
      }
      return null;
    }
    if (matches.length > 1) {
      throw InvalidGenerationSource(
        '${field.enclosingElement.name}.${field.name} resolves future legacy '
        'generated type "$generatedTypeName" ambiguously.',
        element: field,
      );
    }
    return matches.single;
  }

  Never _rejectLegacyGeneratedType(FieldElement field, String name) {
    throw InvalidGenerationSource(
      '${field.enclosingElement.name}.${field.name} crosses from modern '
      '@AckModel into legacy @AckType generated type "$name". AckType '
      'and modern models intentionally use isolated generators; migrate '
      'this connected graph together.',
      element: field,
    );
  }

  Element? _ackTypeDeclaration(Element element) {
    final declaration = switch (element) {
      GetterElement(isOriginVariable: true) => element.variable.baseElement,
      GetterElement() => element.baseElement,
      TopLevelVariableElement() => element.baseElement,
      _ => null,
    };
    return declaration != null &&
            _ackTypeChecker.hasAnnotationOfExact(declaration)
        ? declaration
        : null;
  }

  String _generatedAckTypeName(Element declaration) {
    final annotation = _ackTypeChecker.firstAnnotationOfExact(declaration)!;
    final configuredName = ConstantReader(annotation).read('name');
    var baseName = configuredName.isNull
        ? declaration.name!
        : configuredName.stringValue.trim();
    if (configuredName.isNull && baseName.endsWith('Schema')) {
      baseName = baseName.substring(0, baseName.length - 'Schema'.length);
    }
    if (baseName.isEmpty) baseName = 'Type';
    baseName = '${baseName[0].toUpperCase()}${baseName.substring(1)}';
    return '${baseName}Type';
  }

  Element? _ackInferDeclaration(Element element) {
    final declaration = switch (element) {
      GetterElement(isOriginVariable: true) => element.variable.baseElement,
      TopLevelVariableElement() => element.baseElement,
      _ => null,
    };
    return declaration != null &&
            _ackInferChecker.hasAnnotationOfExact(declaration)
        ? declaration
        : null;
  }

  String _generatedAckInferClassName(Element declaration) {
    final annotation = _ackInferChecker.firstAnnotationOfExact(declaration)!;
    final custom = ConstantReader(annotation).read('name');
    return ackInferModelClassName(
      declaration.name!,
      override: custom.isNull ? null : custom.stringValue,
    );
  }

  bool _importAllowsName(LibraryImport import, String name) {
    for (final combinator in import.combinators) {
      if (combinator is ShowElementCombinator &&
          !combinator.shownNames.contains(name)) {
        return false;
      }
      if (combinator is HideElementCombinator &&
          combinator.hiddenNames.contains(name)) {
        return false;
      }
    }
    return true;
  }

  Future<String> _escapeHatchExpression(
    FieldElement field,
    ConstantReader annotation,
  ) async {
    final function = annotation.read('schema').objectValue.toFunctionValue();
    if (function is! TopLevelFunctionElement) {
      throw InvalidGenerationSource(
        '${field.enclosingElement.name}.${field.name} @AckField schema must '
        'be a const tear-off of a top-level function.',
        element: field,
      );
    }
    if (function.formalParameters.isNotEmpty ||
        !_ackSchemaChecker.isAssignableFromType(function.returnType)) {
      throw InvalidGenerationSource(
        '${field.enclosingElement.name}.${field.name} @AckField top-level '
        'function must have type AckSchema Function().',
        element: field,
      );
    }
    final resolved = await _resolvedLibraryFor(function.library);
    final declaration = resolved
        .getFragmentDeclaration(function.firstFragment)
        ?.node;
    final bodyExpression = declaration is FunctionDeclaration
        ? _functionBodyExpression(declaration.functionExpression.body)
        : null;
    if (bodyExpression == null) {
      throw InvalidGenerationSource(
        '${field.enclosingElement.name}.${field.name} @AckField function must '
        'have a statically resolvable expression or single return.',
        element: field,
      );
    }
    final oneWaySource = await _oneWayTransformSource(bodyExpression);
    if (oneWaySource != null) {
      throw InvalidGenerationSource(
        '${field.enclosingElement.name}.${field.name} @AckField schema '
        'function ${function.name} reaches one-way schema $oneWaySource. '
        'Migrate this .transform() path to .codec() with an encoder.',
        element: field,
      );
    }
    final prefix = _visiblePrefix(function);
    return '${prefix == null ? '' : '$prefix.'}${function.name}()';
  }

  Future<String> _schemaForType(DartType type, FieldElement field) =>
      _inference.inferType(
        type,
        visibleTypeName: _visibleTypeName,
        renderType: (type) => _renderType(_typeRef(type, field)),
        resolveNamed: (type) => _namedSchemaForType(type, field),
        unsupported: (type) => _unsupportedFieldType(field, type),
        rejectNullableCollectionElement: (type) =>
            _nullableCollectionElementError(field, type.getDisplayString()),
        validateMapKey: (type) => _validateMapKey(field, type),
      );

  Future<String?> _namedSchemaForType(
    InterfaceType interfaceType,
    FieldElement field,
  ) async {
    final target = interfaceType.element;
    if (target is ClassElement) {
      final facadeName = _classFirstFacadeName(target);
      if (facadeName != null) {
        final prefix = _visiblePrefix(target);
        _validateClassFirstFacadeImport(
          target,
          facadeName,
          prefix: prefix,
          field: field,
        );
        return '${prefix == null ? '' : '$prefix.'}$facadeName.schema';
      }
    }
    if (_generatedJsonChecker.hasAnnotationOfExact(target)) {
      return '${_visibleTypeName(interfaceType)}.\$ack.schema';
    }
    return null;
  }

  void _rejectNullableCollectionElement(FieldElement field, DartType itemType) {
    if (!_isNullable(itemType)) return;
    _nullableCollectionElementError(field, itemType.getDisplayString());
  }

  void _rejectNullableFutureCollectionElement(
    FieldElement field,
    AckInferRef type,
  ) {
    switch (type) {
      case AckNullableTypeRef(:final inner):
        _rejectNullableFutureCollectionElement(field, inner);
      case AckListTypeRef(:final elementType) ||
          AckSetTypeRef(:final elementType):
        if (elementType is AckNullableTypeRef) {
          _nullableCollectionElementError(field, _renderType(elementType));
        }
        _rejectNullableFutureCollectionElement(field, elementType);
      case AckMapTypeRef(:final valueType):
        _rejectNullableFutureCollectionElement(field, valueType);
      case AckScalarTypeRef() || AckExternalTypeRef() || AckModelTypeRef():
        return;
    }
  }

  Never _nullableCollectionElementError(FieldElement field, String itemType) {
    throw InvalidGenerationSource(
      '${field.enclosingElement.name}.${field.name} uses nullable collection '
      'elements ($itemType). Ack.list does not support '
      'nullable item schemas; make the element non-nullable or provide an '
      'explicit @AckField(schema: ...) codec.',
      element: field,
    );
  }

  void _validateClassFirstFacadeImport(
    ClassElement target,
    String facadeName, {
    required String? prefix,
    required FieldElement field,
  }) {
    if (target.library == library.element) return;
    final modelName = target.name!;
    var modelVisible = false;
    var facadeVisible = false;
    for (final import in library.element.firstFragment.libraryImports) {
      if (import.isSynthetic || (import.prefix?.isDeferred ?? false)) continue;
      final importPrefix = import.prefix?.element.name;
      if (importPrefix != prefix) continue;
      final candidate = prefix == null
          ? import.namespace.get2(modelName)
          : import.namespace.getPrefixed2(prefix, modelName);
      if (candidate?.baseElement == target.baseElement) {
        modelVisible = true;
      }
      if (importExposesGeneratedCompanion(
        import,
        definingLibrary: target.library,
        generatedName: facadeName,
      )) {
        facadeVisible = true;
      }
    }
    if (modelVisible && facadeVisible) return;
    if (modelVisible) {
      throw InvalidGenerationSource(
        'Generated class-first facade "$facadeName" is hidden by an import '
        'combinator or an upstream export combinator for $modelName. Expose '
        'both through the full import route (for example, show $modelName, '
        '$facadeName).',
        element: field,
      );
    }
  }

  String _applySugar(String schema, FieldElement field) =>
      _inference.applyConstraints(schema, field, field.type);
  void _rejectUnsupportedStaticType(FieldElement field, DartType type) {
    if (type is DynamicType || type is TypeParameterType) {
      _unsupportedFieldType(field, type);
    }
  }

  Never _unsupportedFieldType(FieldElement field, DartType type) {
    final jsonHint = type is DynamicType
        ? ', or Object? for an open JSON value'
        : '';
    throw InvalidGenerationSource(
      '${field.enclosingElement.name}.${field.name} uses unsupported '
      '${type.getDisplayString()}; use a concrete type with a static '
      'class-first schema contract$jsonHint.',
      element: field,
    );
  }

  void _validateMapKey(FieldElement field, DartType type) {
    if (type is! InterfaceType ||
        !type.isDartCoreMap ||
        type.typeArguments.length != 2) {
      return;
    }
    final key = type.typeArguments.first;
    if (key is InterfaceType && _isCore(key, 'String')) return;
    throw InvalidGenerationSource(
      '${field.enclosingElement.name}.${field.name} must use Map<String, V>; '
      'received ${type.getDisplayString()}.',
      element: field,
    );
  }

  AckInferRef _typeRef(DartType type, FieldElement field) {
    if (type is DynamicType || type is TypeParameterType) {
      _unsupportedFieldType(field, type);
    }
    if (type is! InterfaceType) _unsupportedFieldType(field, type);
    final interfaceType = type;
    final nullable = _isNullable(interfaceType);
    late final AckInferRef result;
    if (interfaceType.isDartCoreList &&
        interfaceType.typeArguments.length == 1) {
      result = AckListTypeRef(
        _typeRef(interfaceType.typeArguments.single, field),
      );
    } else if (interfaceType.isDartCoreSet &&
        interfaceType.typeArguments.length == 1) {
      result = AckSetTypeRef(
        _typeRef(interfaceType.typeArguments.single, field),
      );
    } else if (interfaceType.isDartCoreMap &&
        interfaceType.typeArguments.length == 2) {
      _validateMapKey(field, interfaceType);
      result = AckMapTypeRef(_typeRef(interfaceType.typeArguments[1], field));
    } else if (interfaceType.element.library.uri.toString() == 'dart:core' &&
        const {
          'String',
          'int',
          'double',
          'num',
          'bool',
          'Object',
        }.contains(interfaceType.element.name)) {
      result = AckScalarTypeRef(interfaceType.element.name!);
    } else if (_generatedJsonChecker.hasAnnotationOfExact(
      interfaceType.element,
    )) {
      result = AckModelTypeRef(
        schemaId: AckSchemaId(
          libraryUri: interfaceType.element.library.uri,
          declarationName: interfaceType.element.name!,
        ),
        className: interfaceType.element.name!,
        runtimeRef: _jsonMapRef,
        importPrefix: _visiblePrefix(interfaceType.element),
      );
    } else {
      result = AckExternalTypeRef(
        name: interfaceType.element.name!,
        importPrefix: _visiblePrefix(interfaceType.element),
        typeArguments: [
          for (final argument in interfaceType.typeArguments)
            _typeRef(argument, field),
        ],
      );
    }
    return nullable ? AckNullableTypeRef(result) : result;
  }

  Map<String, FieldElement> _instanceFields(ClassElement element) {
    final result = <String, FieldElement>{};
    for (final type in element.allSupertypes.reversed) {
      for (final field in type.element.fields) {
        if (!_isStoredField(field)) {
          continue;
        }
        final name = field.name;
        if (name != null) result[name] = field;
      }
    }
    for (final field in element.fields) {
      if (!_isStoredField(field)) continue;
      final name = field.name;
      if (name != null) result[name] = field;
    }
    return result;
  }

  void _requireFinalConcreteClass(ClassElement element) {
    if (element.isAbstract || element.isSealed || element.isFinal) return;
    throw InvalidGenerationSource(
      '${element.name} must be declared as a final class because @AckModel '
      'generates immutable value semantics.',
      element: element,
      todo: 'Add the final class modifier.',
    );
  }

  bool _isStoredField(FieldElement field) =>
      !field.isStatic &&
      !field.isEnumConstant &&
      (field.isOriginDeclaration || field.isOriginDeclaringFormalParameter);

  FieldElement? _parameterField(FormalParameterElement parameter) {
    if (parameter is FieldFormalParameterElement) return parameter.field;
    if (parameter is SuperFormalParameterElement) {
      final target = parameter.superConstructorParameter;
      return target == null ? null : _parameterField(target);
    }
    return null;
  }

  AckSchemaFieldPresence _fieldPresence(FormalParameterElement? parameter) {
    if (parameter == null || parameter.isRequired) {
      return AckSchemaFieldPresence.required;
    }
    if (parameter.hasDefaultValue) return AckSchemaFieldPresence.defaulted;
    return AckSchemaFieldPresence.optional;
  }

  AckSchemaFieldPresence _effectivePresence(
    FieldElement field, {
    required FormalParameterElement? parameter,
    required bool isDiscriminator,
  }) {
    final inferred = _fieldPresence(parameter);
    final hasOptional = _optionalChecker.hasAnnotationOfExact(field);
    final hasRequired = _requiredChecker.hasAnnotationOfExact(field);
    if (hasOptional && hasRequired) {
      throw InvalidGenerationSource(
        '${field.enclosingElement.name}.${field.name} cannot combine '
        '@Optional() and @Required().',
        element: field,
      );
    }

    final annotation = _ackFieldChecker.firstAnnotationOfExact(field);
    AckSchemaFieldPresence? legacyOverride;
    if (annotation != null) {
      final reader = ConstantReader(annotation);
      final schemaMissing = reader.read('schema').isNull;
      // AckFieldPresence index: 0 inferred, 1 required, 2 optional.
      final presenceIndex = reader
          .read('presence')
          .objectValue
          .getField('index')!
          .toIntValue()!;
      if (schemaMissing && presenceIndex == 0) {
        throw InvalidGenerationSource(
          '${field.enclosingElement.name}.${field.name} @AckField() is a '
          'no-op; set schema or presence.',
          element: field,
        );
      }
      legacyOverride = switch (presenceIndex) {
        0 => null,
        1 => AckSchemaFieldPresence.required,
        2 => AckSchemaFieldPresence.optional,
        _ => throw StateError('Unknown AckFieldPresence index $presenceIndex.'),
      };
    }

    final AckSchemaFieldPresence? annotationOverride;
    if (hasOptional) {
      annotationOverride = AckSchemaFieldPresence.optional;
    } else if (hasRequired) {
      annotationOverride = AckSchemaFieldPresence.required;
    } else {
      annotationOverride = null;
    }

    if (legacyOverride != null &&
        annotationOverride != null &&
        legacyOverride != annotationOverride) {
      throw InvalidGenerationSource(
        '${field.enclosingElement.name}.${field.name} has conflicting '
        'presence declarations.',
        element: field,
      );
    }

    final override = annotationOverride ?? legacyOverride;
    if (override == AckSchemaFieldPresence.optional) {
      final canBeOptional =
          isDiscriminator ||
          (parameter != null &&
              (!parameter.isRequired || _isNullable(parameter.type)));
      if (!canBeOptional) {
        throw InvalidGenerationSource(
          '${field.enclosingElement.name}.${field.name} cannot be optional '
          'because the constructor cannot accept a missing value.',
          element: field,
        );
      }
    }

    if (legacyOverride != null) {
      log.warning(
        '${field.enclosingElement.name}.${field.name} uses '
        '@AckField(presence: ...); use @Optional() or @Required() instead. '
        'AckField.presence will be removed in 2.0.0.',
      );
    }

    return override ?? inferred;
  }

  bool _isExactAdditionalPropertiesType(DartType type) {
    if (type is! InterfaceType ||
        !type.isDartCoreMap ||
        type.typeArguments.length != 2) {
      return false;
    }
    final key = type.typeArguments[0];
    final value = type.typeArguments[1];
    return key is InterfaceType &&
        _isCore(key, 'String') &&
        value is InterfaceType &&
        _isCore(value, 'Object') &&
        value.nullabilitySuffix == NullabilitySuffix.question;
  }

  void _validateDiscriminatorType(ClassElement element, String key) {
    final getter = element.lookUpGetter(name: key, library: library.element);
    if (getter == null) return;
    final type = getter.returnType;
    if (type is InterfaceType &&
        _isCore(type, 'String') &&
        !_isNullable(type)) {
      return;
    }
    throw InvalidGenerationSource(
      '${element.name}.$key discriminator member must be String.',
      element: getter,
    );
  }

  void _validateBranchDiscriminator(
    ClassElement branch,
    String key,
    String expected,
  ) {
    final getter = branch.lookUpGetter(name: key, library: library.element);
    if (getter == null) return;
    final type = getter.returnType;
    if (type is! InterfaceType ||
        !_isCore(type, 'String') ||
        _isNullable(type)) {
      throw InvalidGenerationSource(
        '${branch.name}.$key discriminator member must be String.',
        element: getter,
      );
    }
    final expression = _memberExpression(getter);
    if (expression is SimpleStringLiteral && expression.value == expected) {
      return;
    }
    throw InvalidGenerationSource(
      '${branch.name}.$key must be a String literal matching "$expected".',
      element: getter,
    );
  }

  Expression? _memberExpression(GetterElement getter) {
    Element target = getter;
    if (getter.isOriginVariable) target = getter.variable;
    final resolved = _inputResolved;
    if (resolved == null) return null;
    final node = resolved.getFragmentDeclaration(target.firstFragment)?.node;
    if (node is VariableDeclaration) return node.initializer;
    if (node is FunctionDeclaration) {
      return _functionBodyExpression(node.functionExpression.body);
    }
    if (node is MethodDeclaration) {
      return _functionBodyExpression(node.body);
    }
    return null;
  }

  Expression? _functionBodyExpression(FunctionBody body) {
    if (body is ExpressionFunctionBody) return body.expression;
    if (body is BlockFunctionBody && body.block.statements.length == 1) {
      final statement = body.block.statements.single;
      if (statement is ReturnStatement) return statement.expression;
    }
    return null;
  }

  Future<String?> _oneWayTransformSource(
    Expression expression, {
    Set<Element> visited = const {},
  }) async {
    Expression? current = expression;
    while (current is ParenthesizedExpression) {
      current = current.expression;
    }
    Element? referenced;
    while (current is MethodInvocation) {
      if (_oneWayTransformMethods.contains(current.methodName.name)) {
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
    if (referenced == null) return null;

    Element declaration = referenced.baseElement;
    if (declaration is GetterElement && declaration.isOriginVariable) {
      declaration = declaration.variable.baseElement;
    }
    if (declaration is! TopLevelVariableElement &&
        declaration is! GetterElement &&
        declaration is! TopLevelFunctionElement) {
      return null;
    }
    final canonical = declaration.baseElement;
    if (visited.contains(canonical) || visited.length >= 16) return null;
    final owningLibrary = declaration.library;
    if (owningLibrary == null) return null;
    final resolved = await _resolvedLibraryFor(owningLibrary);
    final node = resolved
        .getFragmentDeclaration(declaration.firstFragment)
        ?.node;
    final referencedExpression = switch (node) {
      VariableDeclaration() => node.initializer,
      FunctionDeclaration() => _functionBodyExpression(
        node.functionExpression.body,
      ),
      _ => null,
    };
    if (referencedExpression == null) return null;
    final nested = await _oneWayTransformSource(
      referencedExpression,
      visited: {...visited, canonical},
    );
    return nested == null ? null : '${declaration.name} → $nested';
  }

  void _requireMixin(ClassElement element) {
    final mixinName = ackClassMixinName(element.name!);
    if (_declaresMixin(element, mixinName)) return;
    throw InvalidGenerationSource(
      '${element.name} must apply mixin $mixinName.',
      element: element,
      todo: 'Add `with $mixinName` to ${element.name}.',
    );
  }

  bool _declaresMixin(ClassElement element, String mixinName) {
    if (element.mixins.any((type) => type.element.name == mixinName)) {
      return true;
    }
    final resolved = _inputResolved;
    if (resolved == null) return false;
    final node = resolved.getFragmentDeclaration(element.firstFragment)?.node;
    if (node is! ClassDeclaration) return false;
    final withClause = node.withClause;
    if (withClause == null) return false;
    return withClause.mixinTypes.any((type) => type.name.lexeme == mixinName);
  }

  void _rejectGeneratedMemberCollisions(
    ClassElement element, {
    required bool includeValueMembers,
  }) {
    final blocked = {
      ..._generatedSerializationMembers,
      if (includeValueMembers) ..._generatedValueMembers,
    };
    for (final method in element.methods) {
      if (method.isStatic) continue;
      final name = method.name;
      if (name != null && blocked.contains(name)) {
        throw InvalidGenerationSource(
          '${element.name}.$name would silently override a generated member.',
          element: method,
        );
      }
    }
    for (final getter in element.getters) {
      if (getter.isStatic) continue;
      final name = getter.name;
      if (name != null && blocked.contains(name)) {
        throw InvalidGenerationSource(
          '${element.name}.$name would silently override a generated member.',
          element: getter,
        );
      }
    }
  }

  void _registerMetadata(
    ClassElement element,
    _ModelOptions options,
    AckSchemaId id,
  ) {
    final facadeName = _facadeName(element, options);
    final backingName = ackClassSchemaBackingName(element.name!);
    if (!RegExp(r'^[A-Z][A-Za-z0-9_$]*$').hasMatch(facadeName) ||
        _dartKeywords.contains(facadeName)) {
      throw InvalidGenerationSource(
        'Invalid @AckModel schema facade name "$facadeName" on '
        '${element.name}; schemaName must be a public UpperCamel identifier.',
        element: element,
      );
    }
    for (final name in [facadeName, backingName]) {
      final prior = _schemaNameOwners[name];
      if (prior != null && prior != element) {
        throw InvalidGenerationSource(
          'Generated schema declaration "$name" for ${element.name} '
          'conflicts with ${prior.name}.',
          element: element,
        );
      }
      _schemaNameOwners[name] = element;
    }
    _graph.setClassMetadata(
      id,
      AckClassModelMetadata(
        facadeName: facadeName,
        backingName: backingName,
        caseStyle: options.caseStyle,
        hasExplicitAnnotation: _explicit.contains(element),
      ),
    );
  }

  _ModelOptions? _options(ClassElement element) {
    final annotation = _ackModelChecker.firstAnnotationOfExact(element);
    if (annotation == null) return null;
    final reader = ConstantReader(annotation);
    final caseStyle = reader.read('caseStyle').objectValue;
    final caseIndex = caseStyle.getField('index')!.toIntValue()!;
    const styles = ['none', 'snake', 'kebab', 'pascal', 'screamingSnake'];
    return (
      schemaName: _nullableString(reader, 'schemaName'),
      caseStyle: styles[caseIndex],
      discriminatorKey: _nullableString(reader, 'discriminatorKey'),
      discriminatorValue: _nullableString(reader, 'discriminatorValue'),
      unknownProperties:
          annotations.AckUnknownPropertyPolicy.values[reader
              .read('unknownProperties')
              .objectValue
              .getField('index')!
              .toIntValue()!],
      captureField: reader.read('captureField').stringValue,
    );
  }

  String? _nullableString(ConstantReader reader, String name) {
    final value = reader.read(name);
    return value.isNull ? null : value.stringValue;
  }

  String _facadeName(ClassElement element, _ModelOptions options) =>
      ackClassSchemaFacadeName(element.name!, override: options.schemaName);

  String? _classFirstFacadeName(ClassElement element) {
    final direct = _options(element);
    if (direct != null) return _facadeName(element, direct);
    final isImplicitUnionBranch = element.allSupertypes.any((supertype) {
      final base = supertype.element;
      return base is ClassElement &&
          base.library == element.library &&
          base.isSealed &&
          _ackModelChecker.hasAnnotationOfExact(base);
    });
    return isImplicitUnionBranch
        ? ackClassSchemaFacadeName(element.name!)
        : null;
  }

  String? _jsonKey(FieldElement field) {
    final annotation = _jsonKeyChecker.firstAnnotationOfExact(field);
    if (annotation == null) return null;
    final reader = ConstantReader(annotation);
    const unsupportedOptions = [
      'defaultValue',
      'disallowNullValue',
      'explicitJsonNullWhenNonNullField',
      'fromJson',
      'ignore',
      'includeFromJson',
      'includeIfNull',
      'includeToJson',
      'readValue',
      'required',
      'toJson',
      'unknownEnumValue',
    ];
    final configuredUnsupported = [
      for (final option in unsupportedOptions)
        if (!reader.read(option).isNull) option,
    ];
    if (configuredUnsupported.isNotEmpty) {
      throw InvalidGenerationSource(
        '${field.enclosingElement.name}.${field.name} uses unsupported '
        '@JsonKey options: ${configuredUnsupported.join(', ')}. @AckModel '
        'supports only @JsonKey(name: ...) on fields so validation and JSON '
        'serialization cannot diverge.',
        element: field,
      );
    }
    final value = reader.read('name');
    return value.isNull ? null : value.stringValue;
  }

  void _rejectJsonKeyOnParameter(
    ClassElement owner,
    FormalParameterElement parameter,
  ) {
    if (!_jsonKeyChecker.hasAnnotationOfExact(parameter)) return;
    throw InvalidGenerationSource(
      '${owner.name}.${parameter.name} places @JsonKey on a constructor '
      'parameter. Put @JsonKey(name: ...) on the field instead.',
      element: parameter,
    );
  }

  String _rename(String name, String style) => switch (style) {
    'none' => name,
    'snake' => _separated(name, '_'),
    'kebab' => _separated(name, '-'),
    'pascal' =>
      name.isEmpty ? name : '${name[0].toUpperCase()}${name.substring(1)}',
    'screamingSnake' => _separated(name, '_').toUpperCase(),
    _ => throw StateError('Unknown Ack case style $style.'),
  };

  String _separated(String value, String separator) => value.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '${match.start == 0 ? '' : separator}${match[0]!.toLowerCase()}',
  );

  String _applyPresence(
    String schema, {
    required AckSchemaFieldPresence presence,
    required bool acceptsNull,
    required String? defaultCode,
    required bool defaultIsNull,
  }) {
    return switch (presence) {
      AckSchemaFieldPresence.defaulted when acceptsNull && defaultIsNull =>
        '$schema.optional().nullable()',
      AckSchemaFieldPresence.defaulted when defaultIsNull =>
        '$schema.optional()',
      AckSchemaFieldPresence.defaulted when acceptsNull =>
        '$schema.nullable().withDefault($defaultCode)',
      AckSchemaFieldPresence.defaulted => '$schema.withDefault($defaultCode)',
      AckSchemaFieldPresence.optional when acceptsNull =>
        '$schema.optional().nullable()',
      AckSchemaFieldPresence.optional => '$schema.optional()',
      AckSchemaFieldPresence.required when acceptsNull => '$schema.nullable()',
      AckSchemaFieldPresence.required => schema,
    };
  }

  bool _isCore(InterfaceType type, String name) =>
      type.element.library.uri.toString() == 'dart:core' &&
      type.element.name == name;

  bool _isNullable(DartType type) =>
      type.nullabilitySuffix == NullabilitySuffix.question;

  String _visibleTypeName(InterfaceType type) {
    final prefix = _visiblePrefix(type.element);
    return '${prefix == null ? '' : '$prefix.'}${type.element.name}';
  }

  String? _visiblePrefix(Element target) {
    if (target.library == library.element) return null;
    final name = target.name;
    if (name == null) return null;
    String? prefixed;
    for (final import in library.element.firstFragment.libraryImports) {
      if (import.isSynthetic || (import.prefix?.isDeferred ?? false)) continue;
      final prefix = import.prefix?.element.name;
      final candidate = prefix == null
          ? import.namespace.get2(name)
          : import.namespace.getPrefixed2(prefix, name);
      if (candidate?.baseElement != target.baseElement) continue;
      if (prefix != null && prefix.isNotEmpty) {
        prefixed ??= prefix;
      }
    }
    return prefixed;
  }

  Future<ResolvedLibraryResult> _resolvedLibraryFor(
    LibraryElement element,
  ) async {
    final cached = _resolvedByUri[element.uri];
    if (cached != null) return cached;
    final result = await element.session.getResolvedLibraryByElement(element);
    if (result is! ResolvedLibraryResult) {
      throw InvalidGenerationSource(
        'Could not resolve ${element.uri} for @AckField generation.',
      );
    }
    _resolvedByUri[element.uri] = result;
    return result;
  }

  void _rejectInvalidMemberName(
    String name,
    Element element, {
    required String memberKind,
  }) {
    if (name.startsWith('_') ||
        !RegExp(r'^[A-Za-z$][A-Za-z0-9_$]*$').hasMatch(name) ||
        _dartKeywords.contains(name)) {
      throw InvalidGenerationSource(
        '${element.name}.$name is not a valid public $memberKind.',
        element: element,
      );
    }
  }

  String _renderType(AckInferRef type) => switch (type) {
    AckNullableTypeRef(:final inner) => '${_renderType(inner)}?',
    AckScalarTypeRef(:final dartType) => dartType,
    AckExternalTypeRef(:final visibleName, :final typeArguments) =>
      typeArguments.isEmpty
          ? visibleName
          : '$visibleName<${typeArguments.map(_renderType).join(', ')}>',
    AckModelTypeRef(:final visibleName) => visibleName,
    AckListTypeRef(:final elementType) => 'List<${_renderType(elementType)}>',
    AckSetTypeRef(:final elementType) => 'Set<${_renderType(elementType)}>',
    AckMapTypeRef(:final valueType) => 'Map<String, ${_renderType(valueType)}>',
  };

  String _ack(String symbol) {
    final prefix = ackPrefix;
    return prefix == null || prefix.isEmpty ? symbol : '$prefix.$symbol';
  }

  String _literal(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll(r'$', r'\$');
    return "'$escaped'";
  }

  AckSchemaId _id(ClassElement element) => AckSchemaId(
    libraryUri: library.element.uri,
    declarationName: element.name!,
  );

  static const AckInferRef _jsonMapRef = AckMapTypeRef(
    AckNullableTypeRef(AckScalarTypeRef('Object')),
  );
}
