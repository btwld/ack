import '../json/helper_names.dart';
import '../models/schema_model_graph.dart';
import 'data_class_emitter.dart';
import '../utils/string_literal.dart';

/// Emits class-first schema codecs and top-level JSON/runtime glue.
final class AckClassModelEmitter {
  const AckClassModelEmitter({this.ackPrefix});

  final String? ackPrefix;

  AckDataClassEmitter get _dataClasses =>
      AckDataClassEmitter(ackPrefix: ackPrefix);

  String emit(AckModelGraph graph) {
    final nodes = {for (final node in graph.nodes) node.id: node};
    final output = StringBuffer();
    for (final node in graph.nodes) {
      switch (node) {
        case AckObjectModelNode(:final unionId) when unionId != null:
          continue;
        case AckObjectModelNode():
          _emitObject(output, graph, node);
        case AckValueModelNode():
          throw StateError('Class-first graphs cannot contain value roots.');
        case AckUnionModelNode():
          for (final branchId in node.branches.values) {
            final branch = nodes[branchId];
            if (branch is! AckObjectModelNode) {
              throw StateError(
                'Class-first union branch $branchId is not an object.',
              );
            }
            _emitBranch(output, graph, branch);
          }
          _emitUnion(output, graph, node, nodes);
      }
    }
    return output.toString();
  }

  void _emitObject(
    StringBuffer output,
    AckModelGraph graph,
    AckObjectModelNode node,
  ) {
    _emitConcrete(output, graph, node, includeValueMembers: true);
  }

  void _emitBranch(
    StringBuffer output,
    AckModelGraph graph,
    AckObjectModelNode node,
  ) {
    _emitConcrete(output, graph, node, includeValueMembers: true);
  }

  void _emitConcrete(
    StringBuffer output,
    AckModelGraph graph,
    AckObjectModelNode node, {
    required bool includeValueMembers,
  }) {
    final metadata = _metadata(graph, node);
    final rawName = ackClassRawObjectName(node.className);
    final wireName = ackClassWireSchemaName(node.className);
    output
      ..writeln('final $rawName = ${_objectSchema(node)};')
      ..writeln()
      ..writeln('final $wireName = ${_ack('Ack')}.preserveBoundary($rawName);')
      ..writeln()
      ..writeln(
        _codecSchema(node, backingName: metadata.backingName, input: rawName),
      )
      ..writeln()
      ..writeln(_facade(node.className, metadata, wireName: wireName))
      ..writeln()
      ..writeln(_fromRuntimeFunction(node))
      ..writeln()
      ..writeln(_toRuntimeFunction(node))
      ..writeln()
      ..writeln(
        _dataClasses.mixin(
          className: node.className,
          facadeName: metadata.facadeName,
          fields: node.fields,
          constructorParameters: node.constructorParameters,
          includeValueMembers: includeValueMembers,
          captureFieldName: node.captureFieldName,
          copyWithSupertypes: metadata.copyWithSupertypes,
        ),
      )
      ..writeln();
  }

  void _emitUnion(
    StringBuffer output,
    AckModelGraph graph,
    AckUnionModelNode node,
    Map<AckSchemaId, AckModelNode> nodes,
  ) {
    final metadata = _metadata(graph, node);
    final schemaEntries = <String>[];
    final decodeCases = <String>[];
    final encodeCases = <String>[];
    for (final entry in node.branches.entries) {
      final branch = nodes[entry.value]!;
      schemaEntries.add(
        '${dartStringLiteral(entry.key)}: ${ackClassRawObjectName(branch.className)}',
      );
      decodeCases.add(
        '${dartStringLiteral(entry.key)} => '
        '${ackClassFromRuntimeName(branch.className)}(value)',
      );
    }
    // Match descendants before their parent branches in the type switch.
    final pendingEncodeBranches = node.branches.entries.toList();
    while (pendingEncodeBranches.isNotEmpty) {
      final next = pendingEncodeBranches.indexWhere((candidate) {
        final interfaceName = ackCopyWithInterfaceName(
          nodes[candidate.value]!.className,
        );
        return !pendingEncodeBranches.any(
          (other) =>
              other.value != candidate.value &&
              graph
                  .classMetadataFor(other.value)!
                  .copyWithSupertypes
                  .contains(interfaceName),
        );
      });
      if (next < 0) {
        throw StateError(
          'Cyclic union branch inheritance in ${node.className}.',
        );
      }
      final entry = pendingEncodeBranches.removeAt(next);
      final branch = nodes[entry.value]!;
      encodeCases.add(
        '${branch.className}() => '
        '${ackClassToRuntimeName(branch.className)}(model)',
      );
    }
    final rawName = ackClassRawObjectName(node.className);
    final wireName = ackClassWireSchemaName(node.className);
    output
      ..writeln('''
final $rawName = ${_ack('Ack')}.discriminated(
  discriminatorKey: ${dartStringLiteral(node.discriminatorKey)},
  schemas: {${schemaEntries.join(', ')}},
)${_describe(node.description)};

final $wireName = ${_ack('Ack')}.preserveBoundary($rawName);

final ${metadata.backingName} = $rawName.codec<${node.className}>(
  decode: (value) => switch (value[${dartStringLiteral(node.discriminatorKey)}]) {
    ${decodeCases.join(',\n    ')},
    final unknown => throw StateError(
      'Unknown ${node.discriminatorKey}: \$unknown',
    ),
  },
  encode: (model) => switch (model) {
    ${encodeCases.join(',\n    ')},
  },
)${_describe(node.description)};''')
      ..writeln()
      ..writeln(_facade(node.className, metadata, wireName: wireName))
      ..writeln()
      ..writeln(
        _dataClasses.mixin(
          className: node.className,
          facadeName: metadata.facadeName,
          fields: const [],
          constructorParameters: const [],
          includeValueMembers: false,
        ),
      )
      ..writeln();
  }

  String _codecSchema(
    AckObjectModelNode node, {
    required String backingName,
    String? input,
  }) {
    final expression = input ?? _objectSchema(node);
    return '''
final $backingName = $expression.codec<${node.className}>(
  decode: ${ackClassFromRuntimeName(node.className)},
  encode: ${ackClassToRuntimeName(node.className)},
)${_describe(node.description)};''';
  }

  /// Explicit class descriptions describe the wire object and model codec.
  ///
  /// A codec does not inherit its input schema's description, so describing
  /// only the object would leave `XSchema.schema.description` unset.
  String _describe(String? description) =>
      description == null ? '' : '.describe(${dartStringLiteral(description)})';

  String _facade(
    String className,
    AckClassModelMetadata metadata, {
    required String wireName,
  }) =>
      '''
/// Parses, validates, and encodes [$className] values.
abstract final class ${metadata.facadeName} {
  /// The typed schema, for composing [$className] into other schemas.
  static ${_ack('AckSchema')}<Map<String, Object?>, $className> get schema =>
      ${metadata.backingName};

  /// The structural JSON map schema behind [schema].
  static ${_ack('AckSchema')}<Map<String, Object?>, Map<String, Object?>>
      get wireSchema => $wireName;

  /// Validates [value] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  static $className parse(Object? value, {String? debugName}) =>
      ${metadata.backingName}.parse(value, debugName: debugName)!;

  /// Validates [value] and returns the model or the validation failure.
  static ${_ack('SchemaResult')}<$className> safeParse(
    Object? value, {
    String? debugName,
  }) => ${metadata.backingName}.safeParse(value, debugName: debugName);

  /// Validates decoded [json] and creates the model.
  ///
  /// Throws an `AckException` when validation fails.
  static $className fromJson(Map<String, dynamic> json) => parse(json);

  /// Validates [value] and encodes it as a JSON map.
  ///
  /// Throws an `AckException` when validation fails.
  static Map<String, Object?> encode(
    $className value, {
    String? debugName,
  }) => ${metadata.backingName}.encode(value, debugName: debugName)!;

  /// Validates [value] and encodes it as a JSON map, returning the validation
  /// failure instead of throwing.
  static ${_ack('SchemaResult')}<Map<String, Object?>> safeEncode(
    $className value, {
    String? debugName,
  }) => ${metadata.backingName}.safeEncode(value, debugName: debugName);

  /// The JSON Schema that describes [$className].
  static Map<String, Object?> toJsonSchema() =>
      ${metadata.backingName}.toJsonSchema();

  /// The schema model that describes [$className].
  static ${_ack('AckSchemaModel')} toSchemaModel() =>
      ${_ack('AckSchemaModelExtension')}(${metadata.backingName}).toSchemaModel();
}''';

  String _objectSchema(AckObjectModelNode node) {
    final entries = [
      if (node.discriminatorKey case final key?)
        if (node.discriminatorValue case final value?)
          if (!node.fields.any((field) => field.jsonKey == key))
            '${dartStringLiteral(key)}: ${_ack('Ack')}.literal(${dartStringLiteral(value)}).optional()',
      for (final field in node.fields)
        '${dartStringLiteral(field.jsonKey)}: ${field.schemaExpression}',
    ];
    final additional = node.allowsUnknownProperties
        ? ', additionalProperties: true'
        : '';
    return '${_ack('Ack')}.object({${entries.join(', ')}}$additional)'
        '${_describe(node.description)}';
  }

  String _fromRuntimeFunction(AckObjectModelNode node) {
    final function = ackClassFromRuntimeName(node.className);
    final fieldsByName = {
      for (final field in node.fields) field.dartName: field,
    };
    final arguments = <String>[];
    for (final parameter in node.constructorParameters) {
      final String expression;
      if (parameter.fieldName == node.captureFieldName) {
        expression =
            '${_ack('deepUnmodifiableJsonMap')}(Map<String, Object?>.fromEntries(\n'
            '      value.entries.where((entry) => !declared.contains(entry.key)),\n'
            '    ))';
      } else {
        final field = fieldsByName[parameter.fieldName];
        if (field == null) {
          throw StateError(
            'Missing field ${parameter.fieldName} on ${node.className}.',
          );
        }
        expression = _decodeParameter(parameter, field);
      }
      arguments.add(
        parameter.kind == AckConstructorParameterKind.named
            ? '${parameter.name}: $expression'
            : expression,
      );
    }

    if (node.captureFieldName == null) {
      return '''
${node.className} $function(Map<String, Object?> value) =>
    ${node.className}(${arguments.join(', ')});''';
    }
    final declared = _declaredKeys(node);
    return '''
${node.className} $function(Map<String, Object?> value) {
  const declared = ${_keySet(declared)};
  return ${node.className}(
    ${arguments.join(',\n    ')},
  );
}''';
  }

  String _decodeParameter(
    AckConstructorParameter parameter,
    AckFieldNode field,
  ) {
    final raw = 'value[${dartStringLiteral(field.jsonKey)}]';
    final defaultExpr =
        parameter.defaultExpression != null &&
            parameter.defaultExpression != 'null'
        ? parameter.defaultExpression
        : null;
    final baseType = _nonNullable(parameter.typeRef);
    final isNullableOrDefaulted =
        parameter.typeRef is AckNullableTypeRef || defaultExpr != null;
    if (!isNullableOrDefaulted) {
      return _fromRuntime(baseType, raw);
    }
    if (baseType is AckScalarTypeRef || baseType is AckExternalTypeRef) {
      final cast = baseType is AckScalarTypeRef && baseType.dartType == 'Object'
          ? raw
          : '$raw as ${_type(baseType)}?';
      return defaultExpr == null ? cast : '$cast ?? $defaultExpr';
    }
    final nullBranch = defaultExpr ?? 'null';
    return 'switch ($raw) {'
        ' null => $nullBranch,'
        ' final fieldValue => ${_fromRuntime(baseType, 'fieldValue')},'
        ' }';
  }

  String _toRuntimeFunction(AckObjectModelNode node) {
    final function = ackClassToRuntimeName(node.className);
    final discriminatorKey = node.discriminatorKey;
    final discriminatorValue = node.discriminatorValue;
    final capture = node.captureFieldName;
    final fieldEntries = <String>[
      for (final field in node.fields)
        if (discriminatorValue == null || field.jsonKey != discriminatorKey)
          '${dartStringLiteral(field.jsonKey)}: '
              '${_omitIfNull(field) ? '?' : ''}${_encodeField(field)}',
      if (discriminatorKey != null && discriminatorValue != null)
        '${dartStringLiteral(discriminatorKey)}: '
            '${dartStringLiteral(discriminatorValue)}',
    ];
    if (capture == null) {
      return '''
Map<String, Object?> $function(${node.className} model) =>
    <String, Object?>{${fieldEntries.join(', ')}};''';
    }
    final entries = <String>[
      'for (final entry in model.$capture.entries)\n'
          '      if (!declared.contains(entry.key)) entry.key: entry.value',
      ...fieldEntries,
    ];
    return '''
Map<String, Object?> $function(${node.className} model) {
  const declared = ${_keySet(_declaredKeys(node))};
  return <String, Object?>{
    ${entries.join(',\n    ')},
  };
}''';
  }

  bool _omitIfNull(AckFieldNode field) =>
      field.nullable && !(field.isRequired && field.acceptsNull);

  String _encodeField(AckFieldNode field) {
    final baseType = _nonNullable(field.runtimeRef);
    final access = 'model.${field.dartName}';
    if (!field.nullable) {
      return _toRuntime(baseType, access);
    }
    if (baseType is AckScalarTypeRef || baseType is AckExternalTypeRef) {
      return access;
    }
    if (baseType is AckListTypeRef ||
        baseType is AckSetTypeRef ||
        baseType is AckMapTypeRef) {
      return _toRuntime(AckNullableTypeRef(baseType), access);
    }
    return 'switch ($access) {'
        ' null => null,'
        ' final fieldValue => ${_toRuntime(baseType, 'fieldValue')},'
        ' }';
  }

  AckInferRef _nonNullable(AckInferRef type) => switch (type) {
    AckNullableTypeRef(:final inner) => inner,
    _ => type,
  };

  String _fromRuntime(AckInferRef type, String expression) => switch (type) {
    // Any input is already assignable to Object?; a cast would be redundant.
    AckNullableTypeRef(inner: AckScalarTypeRef(dartType: 'Object')) =>
      expression,
    AckNullableTypeRef(:final inner)
        when inner is AckScalarTypeRef || inner is AckExternalTypeRef =>
      '$expression as ${_type(type)}',
    AckNullableTypeRef(:final inner) =>
      '$expression == null ? null : '
          '${_fromRuntime(inner, expression)}',
    AckModelTypeRef(:final runtimeRef, :final visibleName) =>
      '$visibleName.\$ack.fromRuntime('
          '$expression as ${_type(runtimeRef)})',
    AckListTypeRef(:final elementType) =>
      'List<${_type(elementType)}>.unmodifiable(('
          '$expression as List).map((item) => '
          '${_fromRuntime(elementType, 'item')}))',
    AckSetTypeRef(:final elementType) =>
      'Set<${_type(elementType)}>.unmodifiable(('
          '$expression as Set).map((item) => '
          '${_fromRuntime(elementType, 'item')}))',
    AckMapTypeRef(:final valueType) =>
      'Map<String, ${_type(valueType)}>.unmodifiable(('
          '$expression as Map).map((key, item) => MapEntry('
          'key as String, ${_fromRuntime(valueType, 'item')})))',
    _ => '$expression as ${_type(type)}',
  };

  String _toRuntime(AckInferRef type, String expression) => switch (type) {
    AckNullableTypeRef(:final inner)
        when inner is AckScalarTypeRef || inner is AckExternalTypeRef =>
      expression,
    // `value?.map(...)` satisfies prefer_null_aware_operators.
    AckNullableTypeRef(:final inner)
        when inner is AckListTypeRef ||
            inner is AckSetTypeRef ||
            inner is AckMapTypeRef =>
      _toRuntime(inner, '$expression?'),
    AckNullableTypeRef(:final inner) =>
      '$expression == null ? null : ${_toRuntime(inner, expression)}',
    AckModelTypeRef(:final visibleName) =>
      '$visibleName.\$ack.toRuntime($expression)',
    AckListTypeRef(:final elementType) =>
      '$expression.map((item) => ${_toRuntime(elementType, 'item')})'
          '.toList(growable: false)',
    AckSetTypeRef(:final elementType) =>
      '$expression.map((item) => ${_toRuntime(elementType, 'item')}).toSet()',
    AckMapTypeRef(:final valueType) =>
      '$expression.map((key, item) => '
          'MapEntry(key, ${_toRuntime(valueType, 'item')}))',
    _ => expression,
  };

  String _type(AckInferRef type) => switch (type) {
    AckNullableTypeRef(:final inner) => '${_type(inner)}?',
    AckScalarTypeRef(:final dartType) => dartType,
    AckExternalTypeRef(:final visibleName, :final typeArguments) =>
      typeArguments.isEmpty
          ? visibleName
          : '$visibleName<${typeArguments.map(_type).join(', ')}>',
    AckModelTypeRef(:final visibleName) => visibleName,
    AckListTypeRef(:final elementType) => 'List<${_type(elementType)}>',
    AckSetTypeRef(:final elementType) => 'Set<${_type(elementType)}>',
    AckMapTypeRef(:final valueType) => 'Map<String, ${_type(valueType)}>',
  };

  Set<String> _declaredKeys(AckObjectModelNode node) => {
    for (final field in node.fields) field.jsonKey,
    if (node.discriminatorKey case final discriminator?) discriminator,
  };

  String _keySet(Set<String> keys) =>
      '<String>{${keys.map(dartStringLiteral).join(', ')}}';

  AckClassModelMetadata _metadata(AckModelGraph graph, AckModelNode node) {
    final metadata = graph.classMetadataFor(node.id);
    if (metadata == null) {
      throw StateError('Missing class-first metadata for ${node.id}.');
    }
    return metadata;
  }

  String _ack(String symbol) {
    final prefix = ackPrefix;
    return prefix == null || prefix.isEmpty ? symbol : '$prefix.$symbol';
  }
}
