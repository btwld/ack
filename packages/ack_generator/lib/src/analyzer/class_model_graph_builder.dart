import 'package:ack/annotations.dart' as annotations;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../inference/schema_inference.dart';
import '../json/helper_names.dart';
import '../models/schema_model_graph.dart';
import '../utils/doc_comment_utils.dart';
import '../utils/string_literal.dart';
import 'custom_schema_resolver.dart';
import 'model_graph_builder_base.dart';

typedef _ModelOptions = ({
  String? schemaName,
  String? description,
  annotations.AckCaseStyle caseStyle,
  String? discriminatorKey,
  String? discriminatorValue,
  annotations.AckUnknownPropertyPolicy unknownProperties,
  String captureField,
});

typedef _ClassFirstDependency = ({ClassElement target, FieldElement field});

/// Builds normalized Ack model nodes from hand-written `@Schemable` classes.
///
/// Analyzer elements and AST nodes are consumed here; emitters receive only
/// structural type references and source expressions stored in [AckModelGraph].
final class ClassModelGraphBuilder extends ModelGraphBuilderBase {
  ClassModelGraphBuilder(super.library, {super.ackPrefix});

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

  static const _jsonSerializableChecker = TypeChecker.typeNamedLiterally(
    'JsonSerializable',
    inPackage: 'json_annotation',
  );
  static const _jsonKeyChecker = TypeChecker.typeNamedLiterally(
    'JsonKey',
    inPackage: 'json_annotation',
  );
  static const _jsonConverterChecker = TypeChecker.typeNamedLiterally(
    'JsonConverter',
    inPackage: 'json_annotation',
  );

  static const _validateChecker = TypeChecker.typeNamed(
    annotations.Validate,
    inPackage: 'ack',
  );

  AckSchemaInference get _inference => AckSchemaInference(ackPrefix: ackPrefix);
  late final CustomSchemaResolver _customSchemas = CustomSchemaResolver(this);
  final Set<ClassElement> _consumed = {};
  final Map<String, ClassElement> _schemaNameOwners = {};
  final Map<ClassElement, List<_ClassFirstDependency>> _dependencies = {};
  ClassElement? _activeClass;

  Future<AckModelGraph> build(List<ClassElement> annotatedClasses) async {
    await initInputLibrary();

    for (final element in annotatedClasses) {
      _validateAnnotatedClass(element);
    }
    await _customSchemas.initRegisteredAndLibrarySchemas();

    for (final element in annotatedClasses.where((item) => item.isSealed)) {
      await _buildUnion(element);
    }
    for (final element in annotatedClasses) {
      if (_consumed.contains(element)) continue;
      final options = _options(element)!;
      if (options.discriminatorValue != null) {
        throw InvalidGenerationSource(
          '${element.name} sets discriminatorValue but is not a concrete '
          'branch of an annotated sealed ${annotationName(element)} base.',
          element: element,
        );
      }
      if (element.isAbstract || !element.isConstructable) {
        throw InvalidGenerationSource(
          '${annotationName(element)} requires a constructable class; '
          '${element.name} is abstract.',
          element: element,
        );
      }
      await _buildObject(element, options: options);
    }
    _rejectRecursiveClassFirstGraphs();
    _validateGeneratedNames();
    return graph;
  }

  void _validateGeneratedNames() {
    final localNames = localDeclarationNames();
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

    for (final node in graph.nodes) {
      final metadata = graph.classMetadataFor(node.id);
      if (metadata == null) {
        throw StateError('Missing class-first metadata for ${node.id}.');
      }
      claim(metadata.facadeName, node);
      claim(metadata.backingName, node);
      claim(ackClassWireSchemaName(node.className), node);
      claim(ackClassMixinName(node.className), node);
      claim(ackClassRawObjectName(node.className), node);
      if (node is! AckObjectModelNode) continue;
      claim(ackClassFromRuntimeName(node.className), node);
      claim(ackClassToRuntimeName(node.className), node);
      if (node.fields.any((field) => field.nullable || !field.isRequired)) {
        claim(ackCopyWithUnsetTypeName(node.className), node);
      }
      claim(ackCopyWithInterfaceName(node.className), node);
      claim(ackCopyWithImplementationName(node.className), node);
    }
  }

  void _validateAnnotatedClass(ClassElement element) {
    final name = element.name ?? '';
    if (name.startsWith('_')) {
      throw InvalidGenerationSource(
        '${annotationName(element)} requires a public class; received '
        '"$name".',
        element: element,
        todo: 'Annotate a public class.',
      );
    }
    final schemable = ModelGraphBuilderBase.schemableChecker
        .firstAnnotationOfExact(element);
    if (schemable != null && !ConstantReader(schemable).read('name').isNull) {
      throw InvalidGenerationSource(
        '$name sets @Schemable(name: ...), which applies only to top-level '
        'schemas. Use schemaName to name the generated schema facade.',
        element: element,
      );
    }
    _rejectRedirectingFactory(element);
    _validateStaticSchema(element);
    _requireFinalConcreteClass(element);
    if (_jsonSerializableChecker.hasAnnotationOfExact(element)) {
      throw InvalidGenerationSource(
        '$name cannot use ${annotationName(element)} and @JsonSerializable '
        'together because both generate the same _\$$name JSON helpers.',
        element: element,
        todo:
            'Remove @JsonSerializable; ${annotationName(element)} owns JSON '
            'generation.',
      );
    }
    final options = _options(element)!;
    if (element.isSealed && options.discriminatorKey == null) {
      throw InvalidGenerationSource(
        'Sealed ${annotationName(element)} $name requires discriminatorKey.',
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
        'Sealed ${annotationName(element)} $name cannot set '
        'discriminatorValue.',
        element: element,
      );
    }
  }

  /// A model may expose its facade as `static final schema = XSchema.schema;`.
  ///
  /// The facade is generated in this build, so the type is checked only once
  /// it resolves.
  void _validateStaticSchema(ClassElement element) {
    final getter = element.getGetter('schema');
    if (getter == null ||
        !getter.isStatic ||
        containsInvalidType(getter.returnType)) {
      return;
    }
    final runtime = ackSchemaRuntimeType(getter.returnType);
    if (runtime != null &&
        sameTypeIgnoringNullability(runtime, element.thisType)) {
      return;
    }
    throw InvalidGenerationSource(
      '${element.name}.schema must be an AckSchema<Map<String, Object?>, '
      '${element.name}>; it produces '
      '${runtime?.getDisplayString() ?? 'an untyped value'}.',
      element: getter,
    );
  }

  /// json_serializable applies a `JsonConverter` before Ack's runtime bridge,
  /// so the JSON part would skip the schema for that field.
  void _rejectJsonConverters(
    ClassElement element,
    Iterable<FieldElement> fields,
  ) {
    for (final (owner, path) in [
      (element as Element, '${element.name}'),
      for (final field in fields) (field, '${element.name}.${field.name}'),
    ]) {
      for (final annotation in owner.metadata.annotations) {
        final type = annotation.computeConstantValue()?.type;
        if (type == null || !_jsonConverterChecker.isAssignableFromType(type)) {
          continue;
        }
        throw InvalidGenerationSource(
          '$path uses the JsonConverter ${type.getDisplayString()}, which '
          'would bypass Ack validation in the JSON part. Give the type a '
          'static schema or register one in @Schemable(schemas: [...]) instead.',
          element: owner,
        );
      }
    }
  }

  void _rejectRedirectingFactory(ClassElement element) {
    final constructor = element.unnamedConstructor;
    if (constructor == null || !constructor.isFactory) return;
    final node = inputResolved == null
        ? null
        : declarationNode(inputResolved!, constructor);
    if (node is! ConstructorDeclaration) return;
    final target = node.redirectedConstructor;
    if (target == null) return;
    throw InvalidGenerationSource(
      '${annotationName(element)} ${element.name} redirects its unnamed '
      'constructor to ${target.toSource()}. Redirecting factory models are '
      'not supported; declare a final class whose unnamed generative '
      'constructor initializes its fields.',
      element: element,
    );
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
        'Sealed ${annotationName(base)} ${base.name} has no concrete '
        'same-library branches.',
        element: base,
      );
    }

    final baseId = _id(base);
    graph.begin(baseId);
    _registerMetadata(base, baseOptions, baseId);
    _consumed.add(base);

    final branches = <String, AckSchemaId>{};
    final valueOwners = <String, ClassElement>{};
    for (final branch in candidates) {
      final branchOptions =
          _options(branch) ??
          (
            schemaName: null,
            description: null,
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
      _customSchemas.unionBaseByBranch[branch] = base;
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

    graph.complete(
      AckUnionModelNode(
        id: baseId,
        className: base.name!,
        discriminatorKey: discriminatorKey,
        branches: branches,
        description: _classDescription(base, baseOptions),
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
    final previousActive = _activeClass;
    _activeClass = element;
    try {
      return await _buildObjectBody(
        element,
        options: options,
        unionId: unionId,
        discriminatorKey: discriminatorKey,
        discriminatorValue: discriminatorValue,
      );
    } finally {
      _activeClass = previousActive;
    }
  }

  Future<AckObjectModelNode> _buildObjectBody(
    ClassElement element, {
    required _ModelOptions options,
    AckSchemaId? unionId,
    String? discriminatorKey,
    String? discriminatorValue,
  }) async {
    final id = _id(element);
    graph.begin(id);
    _registerMetadata(element, options, id);
    final constructor = element.unnamedConstructor;
    if (constructor == null || !constructor.isGenerative) {
      throw InvalidGenerationSource(
        '${annotationName(element)} ${element.name} requires an unnamed '
        'generative constructor.',
        element: element,
      );
    }
    _requireMixin(element);
    _rejectGeneratedMemberCollisions(element, includeValueMembers: true);

    final fields = _instanceFields(element);
    _rejectJsonConverters(element, fields.values);
    for (final field in fields.values) {
      if (field.isFinal) continue;
      throw InvalidGenerationSource(
        '${element.name}.${field.name} must be final because '
        '${annotationName(element)} generates immutable value semantics.',
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

    final futureTypes = <String, FutureGeneratedType>{};
    for (final field in fields.values) {
      final name = field.name;
      if (name == null) continue;
      if (!containsInvalidType(field.type)) continue;
      futureTypes[name] = await _customSchemas.futureGeneratedType(
        field,
        setCodec: _setCodec,
      );
    }

    final parameters = <String, FormalParameterElement>{};
    final constructorParameters = <AckConstructorParameter>[];
    for (final parameter in constructor.formalParameters) {
      _rejectJsonKey(element, parameter);
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
          _jsonKey(extras, parameters[captureFieldName]) ??
          _rename(captureFieldName, options.caseStyle);
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
            '${annotationName(element)} generation.',
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

      if (isJsonMaybeType(field.type) && isNullableType(field.type)) {
        throw InvalidGenerationSource(
          '${element.name}.$name uses nullable '
          '${field.type.getDisplayString()}; use non-nullable JsonMaybe<...> '
          'instead, which already models both absent and null values.',
          element: field,
        );
      }
      final unwrappedFieldType = unwrapJsonMaybeType(field.type);
      _rejectUnsupportedStaticType(field, unwrappedFieldType);
      _validateMapKey(field, unwrappedFieldType);
      final futureType = futureTypes[name];
      if (futureType?.runtimeRef case AckNullableTypeRef(
        inner: AckJsonMaybeTypeRef(),
      )) {
        throw InvalidGenerationSource(
          '${element.name}.$name uses nullable JsonMaybe; use non-nullable '
          'JsonMaybe<...> instead, which already models both absent and null '
          'values.',
          element: field,
        );
      }
      _recordClassFirstDependencies(element, field.type, field);
      final jsonKey =
          _jsonKey(field, parameter) ?? _rename(name, options.caseStyle);
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

      final isJsonMaybe =
          futureType?.runtimeRef is AckJsonMaybeTypeRef ||
          isJsonMaybeType(field.type);
      final dartNullable =
          futureType?.runtimeRef is AckNullableTypeRef ||
          isNullableType(field.type);
      final rejectNull = _hasValidateKind('notNull', field, parameter);

      final acceptsNull = (dartNullable || isJsonMaybe) && !rejectNull;
      final presence = _effectivePresence(
        field,
        parameter: parameter,
        isDiscriminator: isDiscriminator,
        isJsonMaybe: isJsonMaybe,
      );
      var schema = isDiscriminator && discriminatorValue != null
          ? '${ack('Ack')}.literal(${dartStringLiteral(discriminatorValue)})'
          : await _fieldSchema(
              field,
              parameter: parameter,
              futureType: futureType,
            );
      schema = _applyDescription(schema, field, parameter);
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
      unionId: unionId,
      discriminatorKey: discriminatorKey,
      discriminatorValue: discriminatorValue,
      description: _classDescription(element, options),
    );
    graph.complete(node);
    return node;
  }

  void _recordClassFirstDependencies(
    ClassElement owner,
    DartType type,
    FieldElement field,
  ) {
    if (type is! InterfaceType) return;
    final target = type.element;
    if (target is ClassElement && classFirstFacadeName(target) != null) {
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
    FormalParameterElement? parameter,
    FutureGeneratedType? futureType,
  }) async {
    if (futureType != null) {
      _rejectNullableFutureCollectionElement(field, futureType.runtimeRef);
      final setListSchema = futureType.setListSchema;
      if (setListSchema != null) {
        final effectiveRef = switch (futureType.runtimeRef) {
          AckJsonMaybeTypeRef(:final valueType) => valueType,
          final other => other,
        };
        return _setCodec(
          _applySugar(setListSchema, field, parameter),
          effectiveRef,
        );
      }
      return _applySugar(futureType.schemaExpression, field, parameter);
    }
    final type = unwrapJsonMaybeType(field.type);
    if (type is InterfaceType &&
        type.isDartCoreSet &&
        type.typeArguments.length == 1) {
      final itemType = type.typeArguments.single;
      _rejectNullableCollectionElement(field, itemType);
      final item = await _schemaForType(itemType, field);
      final list = _applySugar('${ack('Ack')}.list($item)', field, parameter);
      return _setCodec(list, _typeRef(type, field, allowJsonMaybe: false));
    }
    return _applySugar(await _schemaForType(type, field), field, parameter);
  }

  String _setCodec(String listSchema, AckInferRef runtimeRef) {
    // Presence adds nullability to the codec; its type argument is the set.
    final setType = switch (runtimeRef) {
      AckNullableTypeRef(:final inner) => inner,
      _ => runtimeRef,
    };
    final rendered = _schemaRuntimeRef(setType).render(corePrefix: ackPrefix);
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
    AckJsonMaybeTypeRef(:final valueType) => _schemaRuntimeRef(valueType),
    _ => type,
  };

  Future<String> _schemaForType(DartType type, FieldElement field) =>
      _inference.inferType(
        type,
        visibleTypeName: (type) => _visibleTypeName(type, field),
        renderType: (type) => _typeRef(
          type,
          field,
          allowJsonMaybe: false,
        ).render(ackPrefix: ackPrefix),
        resolveNamed: (type) => _customSchemas.namedSchemaForType(
          type,
          field,
          activeClass: _activeClass,
          schemaForType: _schemaForType,
          typeRef: (t, f) => _typeRef(t, f, allowJsonMaybe: false),
          typeArgumentRef: _typeArgumentRef,
        ),
        unsupported: (type) => _unsupportedFieldType(field, type),
        rejectNullableCollectionElement: (type) =>
            _nullableCollectionElementError(field, type.getDisplayString()),
        validateMapKey: (type) => _validateMapKey(field, type),
      );

  void _rejectNullableCollectionElement(FieldElement field, DartType itemType) {
    if (!isNullableType(itemType)) return;
    _nullableCollectionElementError(field, itemType.getDisplayString());
  }

  void _rejectNullableFutureCollectionElement(
    FieldElement field,
    AckInferRef type,
  ) {
    switch (type) {
      case AckNullableTypeRef(:final inner):
        _rejectNullableFutureCollectionElement(field, inner);
      case AckJsonMaybeTypeRef(:final valueType):
        _rejectNullableFutureCollectionElement(field, valueType);
      case AckListTypeRef(:final elementType) ||
          AckSetTypeRef(:final elementType):
        if (elementType is AckNullableTypeRef) {
          _nullableCollectionElementError(
            field,
            elementType.render(ackPrefix: ackPrefix),
          );
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
      'nullable item schemas; make the element non-nullable.',
      element: field,
    );
  }

  String _applySugar(
    String schema,
    FieldElement field,
    FormalParameterElement? parameter,
  ) {
    final effectiveType = unwrapJsonMaybeType(field.type);
    if (field.isOriginDeclaringFormalParameter) {
      final target = field.metadata.annotations.isNotEmpty
          ? field
          : (parameter ?? field);
      return _inference.applyConstraints(schema, target, effectiveType);
    }
    var output = _inference.applyConstraints(schema, field, effectiveType);
    if (parameter != null && !identical(parameter, field)) {
      output = _inference.applyConstraints(output, parameter, effectiveType);
    }
    return output;
  }

  String _applyDescription(
    String schema,
    FieldElement field,
    FormalParameterElement? parameter,
  ) {
    return _inference.applyDescription(
      schema,
      field,
      sourceComment: _fieldDocumentationComment(field, parameter),
    );
  }

  String? _fieldDocumentationComment(
    FieldElement field,
    FormalParameterElement? parameter,
  ) {
    final direct =
        field.documentationComment ?? parameter?.documentationComment;
    if (direct != null) return direct;
    final resolved = inputResolved;
    if (resolved == null) return null;
    for (final element in [field, if (parameter != null) parameter]) {
      final node = declarationNode(resolved, element);
      if (node is FormalParameter) {
        final comment = node.documentationComment;
        if (comment != null && comment.tokens.isNotEmpty) {
          return comment.tokens.map((token) => token.lexeme).join('\n');
        }
      }
    }
    return null;
  }

  DartObject? _firstAnnotation(
    TypeChecker checker,
    FieldElement field, [
    FormalParameterElement? parameter,
  ]) =>
      checker.firstAnnotationOfExact(field) ??
      (parameter == null ? null : checker.firstAnnotationOfExact(parameter));

  bool _hasValidateKind(
    String kind,
    FieldElement field, [
    FormalParameterElement? parameter,
  ]) =>
      _elementHasValidateKind(field, kind) ||
      (parameter != null && _elementHasValidateKind(parameter, kind));

  bool _elementHasValidateKind(Element element, String kind) {
    for (final metadata in element.metadata.annotations) {
      final value = metadata.computeConstantValue();
      final valueType = value?.type;
      if (value == null || valueType == null) continue;
      if (_validateChecker.isExactlyType(valueType) &&
          value.getField('kind')?.toStringValue() == kind) {
        return true;
      }
    }
    return false;
  }

  void _rejectUnsupportedStaticType(FieldElement field, DartType type) {
    if (type is DynamicType || type is TypeParameterType) {
      _unsupportedFieldType(field, type);
    }
  }

  Never _unsupportedFieldType(FieldElement field, DartType type) {
    final path = '${field.enclosingElement.name}.${field.name}';
    final display = type.getDisplayString();
    if (type is InterfaceType) {
      throw InvalidGenerationSource(
        '$path uses unsupported $display. Declare a static schema on '
        '${type.element.name}, or register one in @Schemable(schemas: [...]).',
        element: field,
      );
    }
    final jsonHint = type is DynamicType
        ? ', or Object? for an open JSON value'
        : '';
    throw InvalidGenerationSource(
      '$path uses unsupported $display; use a concrete type$jsonHint.',
      element: field,
    );
  }

  void _validateMapKey(FieldElement field, DartType type) {
    if (type is! InterfaceType ||
        !type.isDartCoreMap ||
        type.typeArguments.length != 2) {
      return;
    }
    if (isSupportedMapKey(type)) return;
    throw InvalidGenerationSource(
      '${field.enclosingElement.name}.${field.name} must use Map<String, V>; '
      'received ${type.getDisplayString()}.',
      element: field,
    );
  }

  /// A type argument of an application type, where `void` is also valid,
  /// as in `Trigger<void>`. It is never a field or collection item type.
  AckInferRef _typeArgumentRef(DartType type, FieldElement field) =>
      inferTypeArgumentRef(
        type,
        path: '${field.enclosingElement.name}.${field.name}',
        context: field,
        onUnsupportedType: (t) => _unsupportedFieldType(field, t),
        validateMapKey: (mapType) => _validateMapKey(field, mapType),
        resolveModelType: (element) => _resolveModelTypeRef(element, field),
      );

  AckInferRef _typeRef(
    DartType type,
    FieldElement field, {
    bool allowJsonMaybe = true,
  }) => inferTypeRef(
    type,
    path: '${field.enclosingElement.name}.${field.name}',
    context: field,
    allowJsonMaybe: allowJsonMaybe,
    onUnsupportedType: (t) => _unsupportedFieldType(field, t),
    validateMapKey: (mapType) => _validateMapKey(field, mapType),
    resolveModelType: (element) => _resolveModelTypeRef(element, field),
  );

  AckInferRef? _resolveModelTypeRef(
    InterfaceElement element,
    FieldElement field,
  ) {
    final runtimeRef = _customSchemas.schemaFirstRuntimeRef(
      element,
      field,
      typeRef: (t, f) => _typeRef(t, f, allowJsonMaybe: false),
    );
    if (runtimeRef == null) return null;
    final path = '${field.enclosingElement.name}.${field.name}';
    return AckModelTypeRef(
      schemaId: AckSchemaId(
        libraryUri: element.library.uri,
        declarationName: element.name!,
      ),
      className: element.name!,
      runtimeRef: runtimeRef,
      importPrefix: visiblePrefixFor(element, path: path, context: field),
    );
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
      '${element.name} must be declared as a final class because '
      '${annotationName(element)} generates immutable value semantics.',
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
    bool isJsonMaybe = false,
  }) {
    final inferred = _fieldPresence(parameter);
    final hasOptional = _hasValidateKind('optional', field, parameter);
    final hasRequired = _hasValidateKind('required', field, parameter);
    if (hasOptional && hasRequired) {
      throw InvalidGenerationSource(
        '${field.enclosingElement.name}.${field.name} cannot combine '
        '@Validate.optional() and @Validate.required().',
        element: field,
      );
    }

    if (isJsonMaybe) {
      return hasRequired
          ? AckSchemaFieldPresence.required
          : AckSchemaFieldPresence.optional;
    }

    final AckSchemaFieldPresence? override;
    if (hasOptional) {
      override = AckSchemaFieldPresence.optional;
    } else if (hasRequired) {
      override = AckSchemaFieldPresence.required;
    } else {
      override = null;
    }

    if (override == AckSchemaFieldPresence.optional) {
      final canBeOptional =
          isDiscriminator ||
          (parameter != null &&
              (!parameter.isRequired || isNullableType(parameter.type)));
      if (!canBeOptional) {
        throw InvalidGenerationSource(
          '${field.enclosingElement.name}.${field.name} cannot be optional '
          'because the constructor cannot accept a missing value.',
          element: field,
        );
      }
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
        isCoreType(key, 'String') &&
        value is InterfaceType &&
        isCoreType(value, 'Object') &&
        value.nullabilitySuffix == NullabilitySuffix.question;
  }

  void _validateDiscriminatorType(ClassElement element, String key) {
    final getter = element.lookUpGetter(name: key, library: library.element);
    if (getter == null) return;
    final type = getter.returnType;
    if (type is InterfaceType &&
        isCoreType(type, 'String') &&
        !isNullableType(type)) {
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
        !isCoreType(type, 'String') ||
        isNullableType(type)) {
      throw InvalidGenerationSource(
        '${branch.name}.$key discriminator member must be String.',
        element: getter,
      );
    }
    final resolved = inputResolved;
    final expression = resolved == null
        ? null
        : declarationExpression(resolved, propertyDeclaration(getter));
    if (expression is SimpleStringLiteral && expression.value == expected) {
      return;
    }
    throw InvalidGenerationSource(
      '${branch.name}.$key must be a String literal matching "$expected".',
      element: getter,
    );
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
    final resolved = inputResolved;
    if (resolved == null) return false;
    final node = declarationNode(resolved, element);
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
        isDartKeyword(facadeName)) {
      throw InvalidGenerationSource(
        'Invalid ${annotationName(element)} schema facade name "$facadeName" on '
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
    graph.setClassMetadata(
      id,
      AckClassModelMetadata(
        facadeName: facadeName,
        backingName: backingName,
        copyWithSupertypes: {
          for (final supertype in element.allSupertypes)
            if (supertype.element case final ClassElement parent)
              // Implicit sealed-union branches also receive value members.
              if (parent.library == element.library &&
                  !parent.isSealed &&
                  classFirstFacadeName(parent) != null)
                ackCopyWithInterfaceName(parent.name!),
        }.toList(),
      ),
    );
  }

  _ModelOptions? _options(ClassElement element) {
    final annotation = ModelGraphBuilderBase.schemableChecker
        .firstAnnotationOfExact(element);
    if (annotation == null) return null;
    final reader = ConstantReader(annotation);
    final caseStyle = reader.read('caseStyle').objectValue;
    final caseIndex = caseStyle.getField('index')!.toIntValue()!;
    return (
      schemaName: _nullableString(reader, 'schemaName'),
      description: _nullableString(reader, 'description'),
      caseStyle: annotations.AckCaseStyle.values[caseIndex],
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

  String? _classDescription(ClassElement element, _ModelOptions options) {
    final tag = _descriptionTag(element);
    final explicit = options.description;
    if (explicit != null && explicit.trim().isEmpty) {
      throw InvalidGenerationSource(
        '${element.name} ${annotationName(element)}.description must not be '
        'blank.',
        element: element,
      );
    }
    return explicit ?? tag;
  }

  String? _descriptionTag(Element element) {
    try {
      return parseDescriptionTag(element.documentationComment);
    } on FormatException catch (error) {
      throw InvalidGenerationSource(
        '${element.name} ${error.message}',
        element: element,
      );
    }
  }

  String? _nullableString(ConstantReader reader, String name) {
    final value = reader.read(name);
    return value.isNull ? null : value.stringValue;
  }

  String _facadeName(ClassElement element, _ModelOptions options) =>
      ackClassSchemaFacadeName(element.name!, override: options.schemaName);

  String? _jsonKey(FieldElement field, [FormalParameterElement? parameter]) {
    _rejectJsonKey(field.enclosingElement as ClassElement, field);
    if (parameter != null) {
      _rejectJsonKey(field.enclosingElement as ClassElement, parameter);
    }
    final ackKey = _firstAnnotation(
      ModelGraphBuilderBase.ackKeyChecker,
      field,
      parameter,
    );
    if (ackKey == null) return null;
    final nameReader = ConstantReader(ackKey).read('name');
    if (nameReader.isNull) return null;
    final ackKeyName = nameReader.stringValue;
    if (ackKeyName.trim().isEmpty) {
      throw InvalidGenerationSource(
        '${field.enclosingElement.name}.${field.name} @AckKey.name must '
        'not be blank.',
        element: field,
      );
    }
    return ackKeyName;
  }

  void _rejectJsonKey(ClassElement owner, Element element) {
    if (!_jsonKeyChecker.hasAnnotationOfExact(element)) return;
    throw InvalidGenerationSource(
      '${owner.name}.${element.name} uses @JsonKey, which is not supported on '
      '${annotationName(owner)} classes in Ack 2.0. Use @AckKey(...) '
      'instead.',
      element: element,
    );
  }

  String _rename(String name, annotations.AckCaseStyle style) =>
      switch (style) {
        annotations.AckCaseStyle.none => name,
        annotations.AckCaseStyle.snake => _separated(name, '_'),
        annotations.AckCaseStyle.kebab => _separated(name, '-'),
        annotations.AckCaseStyle.pascal =>
          name.isEmpty ? name : '${name[0].toUpperCase()}${name.substring(1)}',
        annotations.AckCaseStyle.screamingSnake => _separated(
          name,
          '_',
        ).toUpperCase(),
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

  String _visibleTypeName(InterfaceType type, FieldElement field) =>
      visibleTypeNameFor(
        type,
        path: '${field.enclosingElement.name}.${field.name}',
        context: field,
      );

  void _rejectInvalidMemberName(
    String name,
    Element element, {
    required String memberKind,
  }) {
    if (name == 'dynamic') {
      throw InvalidGenerationSource(
        '${element.name}.$name shadows the dynamic type used by generated '
        'JSON methods.',
        element: element,
      );
    }
    if (name.startsWith('_') ||
        !RegExp(r'^[A-Za-z$][A-Za-z0-9_$]*$').hasMatch(name) ||
        isDartReservedWord(name)) {
      throw InvalidGenerationSource(
        '${element.name}.$name is not a valid public $memberKind.',
        element: element,
      );
    }
  }

  AckSchemaId _id(ClassElement element) => AckSchemaId(
    libraryUri: library.element.uri,
    declarationName: element.name!,
  );
}
