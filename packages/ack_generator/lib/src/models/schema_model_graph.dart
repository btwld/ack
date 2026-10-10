/// Stable identity for a schema declaration across libraries.
final class AckSchemaId {
  const AckSchemaId({required this.libraryUri, required this.declarationName});

  final Uri libraryUri;
  final String declarationName;

  @override
  bool operator ==(Object other) {
    return other is AckSchemaId &&
        other.libraryUri == libraryUri &&
        other.declarationName == declarationName;
  }

  @override
  int get hashCode => Object.hash(libraryUri, declarationName);

  @override
  String toString() => '$libraryUri::$declarationName';
}

/// Input-presence semantics for an object field in the normalized graph.
///
/// This is distinct from the public `@Optional()` / `@Required()` annotations
/// and the deprecated `AckFieldPresence` override. Presence and nullability
/// stay separate: a field can be required and nullable, optional and
/// non-nullable, or defaulted by the schema.
enum AckSchemaFieldPresence { required, optional, defaulted }

/// How an object model treats undeclared properties.
enum AckUnknownPropertyPolicy { reject, discard, capture }

/// Whether a reconstructed constructor argument is positional or named.
enum AckConstructorParameterKind { positional, named }

/// A constructor parameter used to reconstruct a class-first model.
final class AckConstructorParameter {
  const AckConstructorParameter({
    required this.name,
    required this.kind,
    required this.fieldName,
    required this.typeRef,
    this.isSuper = false,
    this.defaultExpression,
  });

  final String name;
  final AckConstructorParameterKind kind;
  final String fieldName;
  final AckInferRef typeRef;
  final bool isSuper;
  final String? defaultExpression;
}

/// A normalized Dart/runtime type used by generation.
///
/// Analyzer objects and output-specific cast strings must not escape the
/// analysis layer. Emitters consume this structural representation instead.
sealed class AckInferRef {
  const AckInferRef();
}

/// A nullable structural type reference.
final class AckNullableTypeRef extends AckInferRef {
  const AckNullableTypeRef(this.inner);

  final AckInferRef inner;
}

/// A core scalar such as `String`, `int`, `double`, `bool`, or `num`.
final class AckScalarTypeRef extends AckInferRef {
  const AckScalarTypeRef(this.dartType);

  final String dartType;
}

/// A visible type declared outside the generated model graph.
final class AckExternalTypeRef extends AckInferRef {
  const AckExternalTypeRef({
    required this.name,
    this.importPrefix,
    this.typeArguments = const [],
  });

  final String name;
  final String? importPrefix;
  final List<AckInferRef> typeArguments;

  String get visibleName {
    final prefix = importPrefix;
    return prefix == null || prefix.isEmpty ? name : '$prefix.$name';
  }
}

/// A reference to another generated Ack model.
final class AckModelTypeRef extends AckInferRef {
  const AckModelTypeRef({
    required this.schemaId,
    required this.className,
    required this.runtimeRef,
    this.importPrefix,
  });

  final AckSchemaId schemaId;
  final String className;
  final AckInferRef runtimeRef;
  final String? importPrefix;

  String get visibleName {
    final prefix = importPrefix;
    return prefix == null || prefix.isEmpty ? className : '$prefix.$className';
  }
}

final class AckListTypeRef extends AckInferRef {
  const AckListTypeRef(this.elementType);

  final AckInferRef elementType;
}

final class AckSetTypeRef extends AckInferRef {
  const AckSetTypeRef(this.elementType);

  final AckInferRef elementType;
}

final class AckMapTypeRef extends AckInferRef {
  const AckMapTypeRef(this.valueType);

  final AckInferRef valueType;
}

final class AckJsonMaybeTypeRef extends AckInferRef {
  const AckJsonMaybeTypeRef(this.valueType);

  final AckInferRef valueType;
}

/// A field in a normalized object model.
final class AckFieldNode {
  const AckFieldNode({
    required this.dartName,
    required this.jsonKey,
    required this.presence,
    required this.nullable,
    required this.runtimeRef,
    bool? acceptsNull,
    this.description,
    this.schemaExpression,
    this.defaultExpression,
  }) : acceptsNull = acceptsNull ?? nullable;

  final String dartName;
  final String jsonKey;
  final AckSchemaFieldPresence presence;
  final bool nullable;

  /// Whether a present JSON value may be `null`.
  ///
  /// This is independent of [nullable] Dart storage and of key [presence].
  /// `@NotNull()` sets it to false while leaving the Dart type unchanged.
  final bool acceptsNull;
  final AckInferRef runtimeRef;
  final String? description;

  /// Source expression for a schema inferred from a hand-written field.
  ///
  /// Schema-first nodes leave this unset because the authored declaration is
  /// already the schema source.
  final String? schemaExpression;

  /// Constructor default expression for a class-first field, when present.
  final String? defaultExpression;

  bool get isRequired => presence != AckSchemaFieldPresence.optional;
}

/// Class-first-only metadata attached to a normalized model node.
///
/// Keeping this alongside [AckModelGraph] lets both generation directions use
/// the same object/value/union node shapes without leaking analyzer elements
/// into emitters.
final class AckClassModelMetadata {
  const AckClassModelMetadata({
    required this.facadeName,
    required this.backingName,
    required this.caseStyle,
    this.hasExplicitAnnotation = true,
    this.copyWithSupertypes = const [],
  });

  final String facadeName;
  final String backingName;
  final String caseStyle;
  final bool hasExplicitAnnotation;
  final List<String> copyWithSupertypes;
}

/// Base node for a generated class or value object.
sealed class AckModelNode {
  const AckModelNode({
    required this.id,
    required this.className,
    required this.boundaryType,
    required this.runtimeRef,
    this.description,
  });

  final AckSchemaId id;
  final String className;
  final AckInferRef boundaryType;
  final AckInferRef runtimeRef;
  final String? description;
}

/// A regular immutable class generated from `Ack.object(...)`.
final class AckObjectModelNode extends AckModelNode {
  AckObjectModelNode({
    required super.id,
    required super.className,
    required super.boundaryType,
    required super.runtimeRef,
    required Iterable<AckFieldNode> fields,
    Iterable<AckConstructorParameter> constructorParameters = const [],
    this.unknownPropertyPolicy = AckUnknownPropertyPolicy.reject,
    this.captureFieldName,
    this.captureJsonKey,
    this.unionId,
    this.discriminatorKey,
    this.discriminatorValue,
    super.description,
  }) : fields = List.unmodifiable(fields),
       constructorParameters = List.unmodifiable(constructorParameters);

  final List<AckFieldNode> fields;
  final List<AckConstructorParameter> constructorParameters;
  final AckUnknownPropertyPolicy unknownPropertyPolicy;
  final String? captureFieldName;
  final String? captureJsonKey;
  final AckSchemaId? unionId;
  final String? discriminatorKey;
  final String? discriminatorValue;

  /// Schema-first and class-first capture both store unknown properties.
  bool get additionalProperties =>
      unknownPropertyPolicy == AckUnknownPropertyPolicy.capture;

  /// Unknown properties are valid on the wire for discard and capture.
  bool get allowsUnknownProperties =>
      unknownPropertyPolicy != AckUnknownPropertyPolicy.reject;
}

/// A value class generated from primitive, codec, list, or map root schemas.
final class AckValueModelNode extends AckModelNode {
  const AckValueModelNode({
    required super.id,
    required super.className,
    required super.boundaryType,
    required super.runtimeRef,
    super.description,
  });
}

/// A sealed class generated from `Ack.discriminated(...)`.
final class AckUnionModelNode extends AckModelNode {
  AckUnionModelNode({
    required super.id,
    required super.className,
    required super.boundaryType,
    required super.runtimeRef,
    required this.discriminatorKey,
    required Map<String, AckSchemaId> branches,
    super.description,
  }) : branches = Map.unmodifiable(branches);

  final String discriminatorKey;
  final Map<String, AckSchemaId> branches;
}

/// Resolution state used while building recursive model graphs.
enum AckResolutionState { unseen, visiting, resolved }

/// Mutable graph assembly with immutable model nodes.
///
/// A declaration is registered before its fields are analyzed. References to a
/// `visiting` declaration become graph edges instead of recursively expanding a
/// duplicate model. This supports self-recursive and mutually-recursive models.
final class AckModelGraph {
  final Map<AckSchemaId, AckModelNode> _nodes = {};
  final Map<AckSchemaId, AckResolutionState> _states = {};
  final List<AckSchemaId> _sourceOrder = [];
  final Map<AckSchemaId, AckClassModelMetadata> _classMetadata = {};

  Iterable<AckModelNode> get nodes sync* {
    for (final id in _sourceOrder) {
      final node = _nodes[id];
      if (node != null) yield node;
    }
  }

  AckResolutionState stateOf(AckSchemaId id) =>
      _states[id] ?? AckResolutionState.unseen;

  void begin(AckSchemaId id) {
    final state = stateOf(id);
    if (state == AckResolutionState.resolved) {
      throw StateError('Schema $id is already resolved.');
    }
    if (state == AckResolutionState.unseen) {
      _sourceOrder.add(id);
    }
    _states[id] = AckResolutionState.visiting;
  }

  void complete(AckModelNode node) {
    final state = stateOf(node.id);
    if (state != AckResolutionState.visiting) {
      throw StateError(
        'Schema ${node.id} must be visiting before it can be completed.',
      );
    }
    _nodes[node.id] = node;
    _states[node.id] = AckResolutionState.resolved;
  }

  AckModelNode? nodeFor(AckSchemaId id) => _nodes[id];

  AckClassModelMetadata? classMetadataFor(AckSchemaId id) => _classMetadata[id];

  void setClassMetadata(AckSchemaId id, AckClassModelMetadata metadata) {
    _classMetadata[id] = metadata;
  }

  void replace(AckModelNode node) {
    if (stateOf(node.id) != AckResolutionState.resolved) {
      throw StateError(
        'Schema ${node.id} must be resolved before replacement.',
      );
    }
    _nodes[node.id] = node;
  }
}
