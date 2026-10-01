import 'package:code_builder/code_builder.dart';

import '../json/helper_names.dart';
import '../models/schema_model_graph.dart';
import 'data_class_emitter.dart';
import '../utils/string_literal.dart';

/// Emits immutable model declarations solely from a normalized model graph.
final class AckModelEmitter {
  AckModelEmitter({
    this.ackPrefix,
    this.schemablePrefix,
    this.schemaPrefixInScope = false,
  });

  static const _schemaShorthandName = 'schema';

  final String? ackPrefix;
  final String? schemablePrefix;

  /// Whether the annotated library imports a prefix named `schema`.
  final bool schemaPrefixInScope;

  List<Spec> emit(AckModelGraph graph) {
    final nodes = {for (final node in graph.nodes) node.id: node};
    final output = <Spec>[];
    for (final node in graph.nodes) {
      switch (node) {
        case AckObjectModelNode(:final unionId) when unionId != null:
          continue;
        case AckObjectModelNode():
          output
            ..add(_object(node))
            ..add(_copyWithContract(node.className, _objectDataClass(node)));
        case AckValueModelNode():
          output
            ..add(_value(node))
            ..add(_copyWithContract(node.className, _valueDataClass(node)));
        case AckUnionModelNode():
          output.add(_union(node, nodes));
          for (final branchId in node.branches.values) {
            final branch = nodes[branchId];
            if (branch is AckObjectModelNode) {
              output
                ..add(_branch(branch, node))
                ..add(
                  _copyWithContract(branch.className, _objectDataClass(branch)),
                );
            }
          }
      }
    }
    return output;
  }

  Class _object(AckObjectModelNode node) {
    final fields = _storedFields(node);
    return Class(
      (b) => b
        ..name = node.className
        ..modifier = ClassModifier.final$
        ..annotations.add(_jsonMarker())
        ..docs.addAll(_docs(node, 'Immutable model'))
        ..fields.addAll([
          for (final field in fields) _field(field),
          if (node.additionalProperties) _additionalPropertiesField(),
          _adapter(node, node.id.declarationName),
          if (_exposesSchemaShorthand(
            declarationName: node.id.declarationName,
            fields: fields,
          ))
            _schemaShorthand(node),
        ])
        ..constructors.addAll([
          _objectConstructor(fields, node.additionalProperties),
          _parseFactory(),
          _fromJsonFactory(_objectJsonType),
        ])
        ..methods.addAll([
          _safeParse(node.className),
          _objectToJson(),
          _objectSafeToJson(),
          ..._valueMembers(node.className, _objectDataClass(node)),
          _objectFromRuntime(node, fields: fields),
          _objectToRuntime(node, fields: fields),
          ..._fieldBridges(fields),
          if (node.additionalProperties) ..._additionalPropertyBridges(),
        ]),
    );
  }

  Class _value(AckValueModelNode node) {
    final runtimeRef = _type(node.runtimeRef);
    final boundaryType = _type(node.boundaryType);
    return Class(
      (b) => b
        ..name = node.className
        ..modifier = ClassModifier.final$
        ..annotations.add(_jsonMarker())
        ..docs.addAll(_docs(node, 'Immutable value model'))
        ..fields.addAll([
          Field(
            (f) => f
              ..name = 'value'
              ..docs.add('/// The wrapped value.')
              ..modifier = FieldModifier.final$
              ..type = refer(runtimeRef),
          ),
          _adapter(node, node.id.declarationName),
          if (_exposesSchemaShorthand(
            declarationName: node.id.declarationName,
            fields: [_valueField(node)],
          ))
            _schemaShorthand(node),
        ])
        ..constructors.addAll([
          _valueConstructor(node, runtimeRef),
          _parseFactory(),
          _fromJsonFactory(boundaryType),
        ])
        ..methods.addAll([
          _safeParse(node.className),
          Method(
            (m) => m
              ..name = 'toJson'
              ..docs.addAll(_toJsonDocs)
              ..returns = refer(boundaryType)
              ..lambda = true
              ..body = Code(_valueToJsonBody(node.boundaryType)),
          ),
          Method(
            (m) => m
              ..name = 'safeToJson'
              ..docs.addAll(_safeToJsonDocs)
              ..returns = refer('${_ack('SchemaResult')}<$boundaryType>')
              ..lambda = true
              ..body = const Code(r'$ack.safeEncode(this)'),
          ),
          ..._valueMembers(node.className, _valueDataClass(node)),
          Method(
            (m) => m
              ..name = '_fromAckRuntime'
              ..static = true
              ..returns = refer(node.className)
              ..requiredParameters.add(
                Parameter(
                  (p) => p
                    ..name = 'value'
                    ..type = refer(runtimeRef),
                ),
              )
              ..lambda = true
              ..body = Code(
                '${jsonFromHelperName(node.className)}(<String, dynamic>{\'value\': value})',
              ),
          ),
          Method(
            (m) => m
              ..name = '_toAckRuntime'
              ..returns = refer(runtimeRef)
              ..lambda = true
              ..body = Code(
                '${jsonToHelperName(node.className)}(this)[\'value\'] as $runtimeRef',
              ),
          ),
          ..._valueBridges(node),
        ]),
    );
  }

  Class _union(AckUnionModelNode node, Map<AckSchemaId, AckModelNode> nodes) {
    final cases = <String>[];
    for (final entry in node.branches.entries) {
      final branch = nodes[entry.value]!;
      cases.add(
        '${dartStringLiteral(entry.key)} => ${branch.className}._fromAckRuntime(value)',
      );
    }
    return Class(
      (b) => b
        ..name = node.className
        ..sealed = true
        ..docs.addAll(_docs(node, 'Discriminated model base'))
        ..fields.addAll([
          _adapter(node, node.id.declarationName),
          if (_exposesSchemaShorthand(
            declarationName: node.id.declarationName,
            discriminatorKey: node.discriminatorKey,
          ))
            _schemaShorthand(node),
        ])
        ..constructors.addAll([
          Constructor(
            (c) => c
              ..constant = true
              ..docs.add('/// Creates a branch of this union.'),
          ),
          _parseFactory(),
          _fromJsonFactory(_objectJsonType),
        ])
        ..methods.addAll([
          _safeParse(node.className),
          Method(
            (m) => m
              ..type = MethodType.getter
              ..name = node.discriminatorKey
              ..docs.add(
                '/// The discriminator value that selects this branch.',
              )
              ..returns = refer('String'),
          ),
          _objectToJson(),
          _objectSafeToJson(),
          Method(
            (m) => m
              ..name = '_fromAckRuntime'
              ..static = true
              ..returns = refer(node.className)
              ..requiredParameters.add(
                Parameter(
                  (p) => p
                    ..name = 'value'
                    ..type = refer(_runtimeMapType),
                ),
              )
              ..body = Code('''
return switch (value[${dartStringLiteral(node.discriminatorKey)}]) {
  ${cases.join(',\n  ')},
  final unknown => throw StateError(
    'Unknown ${node.discriminatorKey}: \$unknown',
  ),
};'''),
          ),
          Method(
            (m) => m
              ..name = '_toAckRuntime'
              ..returns = refer(_runtimeMapType),
          ),
        ]),
    );
  }

  Class _branch(AckObjectModelNode node, AckUnionModelNode union) {
    final discriminator = node.discriminatorKey!;
    final value = node.discriminatorValue!;
    final fields = _storedFields(node);
    return Class(
      (b) => b
        ..name = node.className
        ..modifier = ClassModifier.final$
        ..extend = refer(union.className)
        ..annotations.add(_jsonMarker())
        ..docs.addAll(_docs(node, 'Discriminated model branch'))
        ..fields.addAll([
          for (final field in fields) _field(field),
          if (node.additionalProperties) _additionalPropertiesField(),
          _adapter(
            node,
            '${union.id.declarationName}.effectiveBranch(${dartStringLiteral(value)})',
          ),
          if (_exposesSchemaShorthand(
            declarationName: union.id.declarationName,
            fields: fields,
            discriminatorKey: discriminator,
          ))
            _schemaShorthand(node),
        ])
        ..constructors.addAll([
          _objectConstructor(fields, node.additionalProperties),
          _parseFactory(),
          _fromJsonFactory(_objectJsonType),
        ])
        ..methods.addAll([
          _safeParse(node.className),
          Method(
            (m) => m
              ..annotations.add(refer('override'))
              ..type = MethodType.getter
              ..name = discriminator
              ..returns = refer('String')
              ..lambda = true
              ..body = Code(dartStringLiteral(value)),
          ),
          ..._valueMembers(node.className, _objectDataClass(node)),
          _objectFromRuntime(
            node,
            fields: fields,
            additionalKnownKeys: {discriminator},
          ),
          _objectToRuntime(
            node,
            fields: fields,
            leadingEntries: {discriminator: dartStringLiteral(value)},
            isOverride: true,
          ),
          ..._fieldBridges(fields),
          if (node.additionalProperties) ..._additionalPropertyBridges(),
        ]),
    );
  }

  Field _field(AckFieldNode field) => Field(
    (f) => f
      ..name = field.dartName
      ..modifier = FieldModifier.final$
      ..type = refer(_fieldType(field))
      ..docs.addAll([
        if (field.description != null) '/// ${field.description}',
      ]),
  );

  Field _additionalPropertiesField() => Field(
    (f) => f
      ..name = 'additionalProperties'
      ..modifier = FieldModifier.final$
      ..type = refer(_runtimeMapType)
      ..docs.add(
        '/// Properties accepted by a schema with additional properties.',
      ),
  );

  Field _adapter(AckModelNode node, String schemaExpression) => Field(
    (f) => f
      ..name = r'$ack'
      ..static = true
      ..docs.add('/// The Ack adapter that parses and encodes this model.')
      ..modifier = FieldModifier.final$
      ..assignment = Code('''
${_ack('AckModelAdapter')}(
  schema: () => $schemaExpression,
  fromRuntime: ${node.className}._fromAckRuntime,
  toRuntime: (model) => model._toAckRuntime(),
)'''),
  );

  /// Whether a model class can declare the static `schema` shorthand.
  ///
  /// Dart rejects a static and an instance member with the same name, so a
  /// field or discriminator getter named `schema` suppresses the shorthand.
  /// A schema declaration named `schema` suppresses it too, because the
  /// static would shadow the declaration that [_adapter] reads. An import
  /// prefix named `schema` suppresses it for the same reason: generated code
  /// may qualify Ack or nested model types through that prefix. The model
  /// still exposes the same schema as `$ack.modelSchema`.
  bool _exposesSchemaShorthand({
    required String declarationName,
    Iterable<AckFieldNode> fields = const [],
    String? discriminatorKey,
  }) =>
      !schemaPrefixInScope &&
      declarationName != _schemaShorthandName &&
      discriminatorKey != _schemaShorthandName &&
      fields.every((field) => field.dartName != _schemaShorthandName);

  Field _schemaShorthand(AckModelNode node) => Field(
    (f) => f
      ..name = _schemaShorthandName
      ..static = true
      ..modifier = FieldModifier.final$
      ..docs.addAll([
        '/// The Ack schema that parses input into [${node.className}] and '
            'encodes it back.',
        '///',
        '/// A shorthand for `\$ack.modelSchema`, created once.',
      ])
      ..assignment = const Code(r'$ack.modelSchema'),
  );

  Constructor _objectConstructor(
    List<AckFieldNode> fields,
    bool additionalProperties,
  ) => Constructor((c) {
    c.docs.addAll([
      '/// Creates a model without validating it.',
      '///',
      '/// Use `parse` or `fromJson` for untrusted input. `toJson` validates',
      '/// the model while encoding it.',
    ]);
    for (final field in fields) {
      final copyType = _nonNullable(field.runtimeRef);
      final needsCopy = _requiresImmutableCopy(copyType);
      c.optionalParameters.add(
        Parameter(
          (p) => p
            ..name = field.dartName
            ..named = true
            ..required = field.isRequired
            ..toThis = !needsCopy
            ..type = needsCopy ? refer(_fieldType(field)) : null,
        ),
      );
      if (!needsCopy) continue;

      final value = field.dartName;
      final copy = _immutableCopy(copyType, value);
      var initializer = copy;
      if (!field.isRequired || field.nullable) {
        initializer =
            'switch ($value) {'
            ' null => null,'
            ' final fieldValue => ${_immutableCopy(copyType, 'fieldValue')},'
            ' }';
      }
      c.initializers.add(Code('${field.dartName} = $initializer'));
    }
    if (additionalProperties) {
      c.optionalParameters.add(
        Parameter(
          (p) => p
            ..name = 'additionalProperties'
            ..named = true
            ..type = refer(_runtimeMapType)
            ..defaultTo = const Code('const {}'),
        ),
      );
      c.initializers.add(
        Code(
          'additionalProperties = '
          '${_ack('deepUnmodifiableJsonMap')}(additionalProperties)',
        ),
      );
    }
  });

  Constructor _valueConstructor(AckValueModelNode node, String runtimeType) {
    final needsCopy = _requiresImmutableCopy(node.runtimeRef);
    return Constructor((c) {
      c.docs.addAll([
        '/// Creates a model without validating it.',
        '///',
        '/// Use `parse` or `fromJson` for untrusted input. `toJson` validates',
        '/// the model while encoding it.',
      ]);
      c.requiredParameters.add(
        Parameter(
          (p) => p
            ..name = 'value'
            ..toThis = !needsCopy
            ..type = needsCopy ? refer(runtimeType) : null,
        ),
      );
      if (needsCopy) {
        c.initializers.add(
          Code('value = ${_immutableCopy(node.runtimeRef, 'value')}'),
        );
      }
    });
  }

  Constructor _parseFactory() => Constructor(
    (c) => c
      ..factory = true
      ..name = 'parse'
      ..docs.addAll([
        '/// Validates [input] and creates the model.',
        '///',
        '/// Throws an `AckException` when validation fails.',
      ])
      ..requiredParameters.add(
        Parameter(
          (p) => p
            ..name = 'input'
            ..type = refer('Object?'),
        ),
      )
      ..body = const Code(r'return $ack.parse(input);'),
  );

  Constructor _fromJsonFactory(String boundaryType) => Constructor(
    (c) => c
      ..factory = true
      ..name = 'fromJson'
      ..docs.addAll([
        '/// Validates decoded [json] and creates the model.',
        '///',
        '/// Throws an `AckException` when validation fails.',
      ])
      ..requiredParameters.add(
        Parameter(
          (p) => p
            ..name = 'json'
            ..type = refer(boundaryType),
        ),
      )
      ..body = const Code(r'return $ack.parse(json);'),
  );

  Method _safeParse(String className) => Method(
    (m) => m
      ..name = 'safeParse'
      ..static = true
      ..docs.add(
        '/// Validates [input] and returns the model or the validation failure.',
      )
      ..returns = refer('${_ack('SchemaResult')}<$className>')
      ..requiredParameters.add(
        Parameter(
          (p) => p
            ..name = 'input'
            ..type = refer('Object?'),
        ),
      )
      ..lambda = true
      ..body = const Code(r'$ack.safeParse(input)'),
  );

  /// Stored fields and constructor parameters shared by an object model's
  /// value members and its `copyWith` contract.
  _AckDataClass _objectDataClass(AckObjectModelNode node) {
    final stored = [
      ..._storedFields(node),
      if (node.captureFieldName case final capture?)
        AckFieldNode(
          dartName: capture,
          jsonKey: capture,
          presence: AckSchemaFieldPresence.required,
          nullable: false,
          runtimeRef: const AckMapTypeRef(
            AckNullableTypeRef(AckScalarTypeRef('Object')),
          ),
        ),
    ];
    final storedNames = {for (final field in stored) field.dartName};
    final constructorParameters = [
      for (final parameter in node.constructorParameters)
        if (storedNames.contains(parameter.fieldName)) parameter,
    ];
    return (
      fields: stored,
      constructorParameters: constructorParameters.isEmpty
          ? [
              for (final field in stored)
                AckConstructorParameter(
                  name: field.dartName,
                  kind: AckConstructorParameterKind.named,
                  fieldName: field.dartName,
                  typeRef: field.runtimeRef,
                ),
            ]
          : constructorParameters,
    );
  }

  _AckDataClass _valueDataClass(AckValueModelNode node) => (
    fields: [_valueField(node)],
    constructorParameters: [
      AckConstructorParameter(
        name: 'value',
        kind: AckConstructorParameterKind.positional,
        fieldName: 'value',
        typeRef: node.runtimeRef,
      ),
    ],
  );

  Code _copyWithContract(String className, _AckDataClass data) {
    final byField = {for (final field in data.fields) field.dartName: field};
    return Code(
      AckDataClassEmitter(ackPrefix: ackPrefix).copyWithContract(
        className: className,
        parameters: [
          for (final parameter in data.constructorParameters)
            AckCopyWithParameter(
              name: parameter.name,
              fieldName: parameter.fieldName,
              type: _fieldType(
                byField[parameter.fieldName] ?? _syntheticField(parameter),
              ),
              nullable: switch (byField[parameter.fieldName]) {
                final field? => !field.isRequired || field.nullable,
                null => parameter.typeRef is AckNullableTypeRef,
              },
              positional: parameter.kind != AckConstructorParameterKind.named,
            ),
        ],
      ),
    );
  }

  AckFieldNode _valueField(AckValueModelNode node) => AckFieldNode(
    dartName: 'value',
    jsonKey: 'value',
    presence: AckSchemaFieldPresence.required,
    nullable: node.runtimeRef is AckNullableTypeRef,
    runtimeRef: node.runtimeRef,
  );

  List<Method> _valueMembers(String className, _AckDataClass data) {
    final fields = data.fields;
    final comparisons = [
      'other is $className',
      'runtimeType == other.runtimeType',
      for (final field in fields)
        '${_ack('deepEquals')}(${field.dartName}, other.${field.dartName})',
    ];
    final hashes = [
      'runtimeType',
      for (final field in fields) '${_ack('deepHashCode')}(${field.dartName})',
    ];
    final toStringPreview = [
      for (final field in fields) '${field.dartName}: \$${field.dartName}',
    ].join(', ');
    final implementation = ackCopyWithImplementationName(className);
    return [
      Method(
        (m) => m
          ..name = 'copyWith'
          ..type = MethodType.getter
          ..returns = refer(
            '${ackCopyWithInterfaceName(className)}<$className>',
          )
          ..docs.add(
            '/// Creates a copy of this model with selected fields replaced.',
          )
          ..lambda = true
          ..body = Code(
            data.constructorParameters.isEmpty
                ? 'const $implementation()'
                : '$implementation(this)',
          ),
      ),
      Method(
        (m) => m
          ..name = 'operator =='
          ..annotations.add(refer('override'))
          ..returns = refer('bool')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'other'
                ..type = refer('Object'),
            ),
          )
          ..lambda = true
          ..body = Code(
            'identical(this, other) || (${comparisons.join(' && ')})',
          ),
      ),
      Method(
        (m) => m
          ..name = 'hashCode'
          ..annotations.add(refer('override'))
          ..type = MethodType.getter
          ..returns = refer('int')
          ..lambda = true
          ..body = Code('Object.hashAll([${hashes.join(', ')}])'),
      ),
      Method(
        (m) => m
          ..name = 'toString'
          ..annotations.add(refer('override'))
          ..returns = refer('String')
          ..lambda = true
          ..body = literalString('$className($toStringPreview)').code,
      ),
    ];
  }

  AckFieldNode _syntheticField(AckConstructorParameter parameter) =>
      AckFieldNode(
        dartName: parameter.fieldName,
        jsonKey: parameter.fieldName,
        presence: AckSchemaFieldPresence.required,
        nullable: parameter.typeRef is AckNullableTypeRef,
        runtimeRef: parameter.typeRef,
      );

  Method _objectToJson() => Method(
    (m) => m
      ..name = 'toJson'
      ..docs.addAll(_toJsonDocs)
      ..returns = refer(_objectJsonType)
      ..lambda = true
      ..body = const Code('Map<String, dynamic>.from(\$ack.encode(this))'),
  );

  Method _objectSafeToJson() => Method(
    (m) => m
      ..name = 'safeToJson'
      ..docs.addAll(_safeToJsonDocs)
      ..returns = refer('${_ack('SchemaResult')}<$_runtimeMapType>')
      ..lambda = true
      ..body = const Code(r'$ack.safeEncode(this)'),
  );

  Method _objectFromRuntime(
    AckObjectModelNode node, {
    List<AckFieldNode>? fields,
    Set<String> additionalKnownKeys = const {},
  }) {
    final helper = jsonFromHelperName(node.className);
    if (!node.additionalProperties) {
      return Method(
        (m) => m
          ..name = '_fromAckRuntime'
          ..static = true
          ..returns = refer(node.className)
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'value'
                ..type = refer(_runtimeMapType),
            ),
          )
          ..lambda = true
          ..body = Code('$helper(Map<String, dynamic>.from(value))'),
      );
    }

    final effectiveFields = fields ?? _storedFields(node);
    final keys = _declaredJsonKeys(
      effectiveFields,
      additionalKeys: additionalKnownKeys,
    );
    return Method(
      (m) => m
        ..name = '_fromAckRuntime'
        ..static = true
        ..returns = refer(node.className)
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = refer(_runtimeMapType),
          ),
        )
        ..body = Code('''
const declared = ${_declaredKeysLiteral(keys)};
return $helper(<String, dynamic>{
  ...value,
  'additionalProperties': Map<String, Object?>.fromEntries(
    value.entries.where((entry) => !declared.contains(entry.key)),
  ),
});'''),
    );
  }

  Method _objectToRuntime(
    AckObjectModelNode node, {
    List<AckFieldNode>? fields,
    Map<String, String> leadingEntries = const {},
    bool isOverride = false,
  }) {
    final effectiveFields = fields ?? _storedFields(node);
    final requiredNulls = [
      for (final field in effectiveFields)
        if (field.isRequired && field.nullable) field,
    ];
    final helper = jsonToHelperName(node.className);
    final needsBlock = node.additionalProperties || requiredNulls.isNotEmpty;
    final declaredLiteral = node.additionalProperties
        ? _declaredKeysLiteral(
            _declaredJsonKeys(
              effectiveFields,
              additionalKeys: leadingEntries.keys,
            ),
          )
        : null;

    return Method((m) {
      m
        ..name = '_toAckRuntime'
        ..returns = refer(_runtimeMapType);
      if (isOverride) m.annotations.add(refer('override'));

      if (!needsBlock) {
        final entries = <String>[
          for (final entry in leadingEntries.entries)
            '${dartStringLiteral(entry.key)}: ${entry.value}',
          '...$helper(this)',
        ];
        m
          ..lambda = true
          ..body = Code('$_runtimeMapLiteral{${entries.join(', ')}}');
        return;
      }

      final lines = <String>[
        if (declaredLiteral != null) 'const declared = $declaredLiteral;',
        'final result = $_runtimeMapLiteral{...$helper(this)};',
        if (declaredLiteral != null) "result.remove('additionalProperties');",
      ];
      for (final field in requiredNulls) {
        lines.add(
          'if (${field.dartName} == null) {'
          ' result[${dartStringLiteral(field.jsonKey)}] = null;'
          ' }',
        );
      }
      final returnEntries = <String>[
        if (declaredLiteral != null)
          'for (final entry in additionalProperties.entries)\n'
              '    if (!declared.contains(entry.key)) entry.key: entry.value',
        for (final entry in leadingEntries.entries)
          '${dartStringLiteral(entry.key)}: ${entry.value}',
        '...result',
      ];
      lines.add(
        'return $_runtimeMapLiteral{\n  ${returnEntries.join(',\n  ')},\n};',
      );
      m.body = Code(lines.join('\n'));
    });
  }

  List<Method> _fieldBridges(List<AckFieldNode> fields) => [
    for (final field in fields) ...[_fromBridge(field), _toBridge(field)],
  ];

  List<Method> _valueBridges(AckValueModelNode node) {
    final type = _type(node.runtimeRef);
    return [
      Method(
        (m) => m
          ..name = ackFromRuntimeBridgeName('value')
          ..static = true
          ..returns = refer(type)
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'value'
                ..type = refer('Object?'),
            ),
          )
          ..lambda = true
          ..body = Code(_fromRuntime(node.runtimeRef, 'value')),
      ),
      Method(
        (m) => m
          ..name = ackToRuntimeBridgeName('value')
          ..static = true
          ..returns = refer('Object?')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'value'
                ..type = refer(type),
            ),
          )
          ..lambda = true
          ..body = Code(_toRuntime(node.runtimeRef, 'value')),
      ),
    ];
  }

  List<Method> _additionalPropertyBridges() => [
    Method(
      (m) => m
        ..name = ackFromRuntimeBridgeName('additionalProperties')
        ..static = true
        ..returns = refer('$_runtimeMapType?')
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = refer('Object?'),
          ),
        )
        ..lambda = true
        ..body = const Code('value as Map<String, Object?>?'),
    ),
    Method(
      (m) => m
        ..name = ackToRuntimeBridgeName('additionalProperties')
        ..static = true
        ..returns = refer('Object?')
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = refer(_runtimeMapType),
          ),
        )
        ..lambda = true
        ..body = const Code('value'),
    ),
  ];

  Method _fromBridge(AckFieldNode field) {
    final runtimeRef = _nonNullable(field.runtimeRef);
    final needsNullGuard = !field.isRequired || field.nullable;
    late final String body;
    if (!needsNullGuard) {
      body = _fromRuntime(runtimeRef, 'value');
    } else if (!_requiresRuntimeConversion(runtimeRef)) {
      final type = '${_type(runtimeRef)}?';
      // The bridge parameter is already Object?.
      body = type == 'Object?' ? 'value' : 'value as $type';
    } else {
      body =
          'switch (value) {'
          ' null => null,'
          ' final fieldValue => ${_fromRuntime(runtimeRef, 'fieldValue')},'
          ' }';
    }
    return Method(
      (m) => m
        ..name = ackFromRuntimeBridgeName(field.dartName)
        ..static = true
        ..returns = refer(_fieldType(field))
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = refer('Object?'),
          ),
        )
        ..lambda = true
        ..body = Code(body),
    );
  }

  Method _toBridge(AckFieldNode field) {
    final runtimeRef = _nonNullable(field.runtimeRef);
    final needsNullGuard = !field.isRequired || field.nullable;
    late final String body;
    if (!needsNullGuard) {
      body = _toRuntime(runtimeRef, 'value');
    } else if (!_requiresRuntimeConversion(runtimeRef)) {
      body = 'value';
    } else {
      body =
          'switch (value) {'
          ' null => null,'
          ' final fieldValue => ${_toRuntime(runtimeRef, 'fieldValue')},'
          ' }';
    }
    return Method(
      (m) => m
        ..name = ackToRuntimeBridgeName(field.dartName)
        ..static = true
        ..returns = refer('Object?')
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = refer(_fieldType(field)),
          ),
        )
        ..lambda = true
        ..body = Code(body),
    );
  }

  String _fromRuntime(AckInferRef type, String expression) {
    return switch (type) {
      // Any input is already assignable to Object?; a cast would be redundant.
      AckNullableTypeRef(inner: AckScalarTypeRef(dartType: 'Object')) =>
        expression,
      AckNullableTypeRef(:final inner) =>
        '$expression == null ? null : ${_fromRuntime(inner, '$expression!')}',
      AckModelTypeRef(:final runtimeRef, :final visibleName) =>
        '$visibleName.\$ack.fromRuntime($expression as ${_type(runtimeRef)})',
      AckListTypeRef(:final elementType) =>
        '($expression as List).map((item) => ${_fromRuntime(elementType, 'item')}).toList()',
      AckSetTypeRef(:final elementType) =>
        '($expression as Set).map((item) => ${_fromRuntime(elementType, 'item')}).toSet()',
      AckMapTypeRef(:final valueType) =>
        '($expression as Map).map((key, item) => MapEntry(key as String, ${_fromRuntime(valueType, 'item')}))',
      _ => '$expression as ${_type(type)}',
    };
  }

  String _toRuntime(AckInferRef type, String expression) {
    return switch (type) {
      AckNullableTypeRef(:final inner)
          when inner is AckScalarTypeRef || inner is AckExternalTypeRef =>
        expression,
      // `value?.map(...)` satisfies prefer_null_aware_operators.
      AckNullableTypeRef(:final inner)
          when inner is AckListTypeRef ||
              inner is AckSetTypeRef ||
              inner is AckMapTypeRef =>
        _toRuntime(inner, '$expression?'),
      // Expressions are promotable locals, so the null check needs no `!`.
      AckNullableTypeRef(:final inner) =>
        '$expression == null ? null : ${_toRuntime(inner, expression)}',
      AckModelTypeRef(:final visibleName) =>
        '$visibleName.\$ack.toRuntime($expression)',
      AckListTypeRef(:final elementType) =>
        '$expression.map((item) => ${_toRuntime(elementType, 'item')}).toList(growable: false)',
      AckSetTypeRef(:final elementType) =>
        '$expression.map((item) => ${_toRuntime(elementType, 'item')}).toSet()',
      AckMapTypeRef(:final valueType) =>
        '$expression.map((key, item) => MapEntry(key, ${_toRuntime(valueType, 'item')}))',
      _ => expression,
    };
  }

  String _immutableCopy(AckInferRef type, String expression) {
    return switch (type) {
      AckNullableTypeRef(:final inner) when !_requiresImmutableCopy(inner) =>
        expression,
      AckNullableTypeRef(:final inner) =>
        '$expression == null ? null : ${_immutableCopy(inner, expression)}',
      AckListTypeRef(:final elementType) =>
        'List<${_type(elementType)}>.unmodifiable($expression.map((item) => ${_immutableCopy(elementType, 'item')}))',
      AckSetTypeRef(:final elementType) =>
        'Set<${_type(elementType)}>.unmodifiable($expression.map((item) => ${_immutableCopy(elementType, 'item')}))',
      AckMapTypeRef(:final valueType) =>
        'Map<String, ${_type(valueType)}>.unmodifiable($expression.map((key, item) => MapEntry(key, ${_immutableCopy(valueType, 'item')})))',
      _ => expression,
    };
  }

  String _fieldType(AckFieldNode field) {
    final base = _type(field.runtimeRef);
    if (field.isRequired && !field.nullable) return base;
    return field.runtimeRef is AckNullableTypeRef ? base : '$base?';
  }

  List<AckFieldNode> _storedFields(AckObjectModelNode node) {
    final discriminator = node.discriminatorKey;
    if (discriminator == null) return node.fields;
    return [
      for (final field in node.fields)
        if (field.jsonKey != discriminator) field,
    ];
  }

  Set<String> _declaredJsonKeys(
    Iterable<AckFieldNode> fields, {
    Iterable<String> additionalKeys = const [],
  }) => {...additionalKeys, for (final field in fields) field.jsonKey};

  String _declaredKeysLiteral(Set<String> keys) =>
      '<String>{${keys.map(dartStringLiteral).join(', ')}}';

  AckInferRef _nonNullable(AckInferRef type) => switch (type) {
    AckNullableTypeRef(:final inner) => inner,
    _ => type,
  };

  bool _requiresImmutableCopy(AckInferRef type) => switch (type) {
    AckNullableTypeRef(:final inner) => _requiresImmutableCopy(inner),
    AckListTypeRef() || AckSetTypeRef() || AckMapTypeRef() => true,
    _ => false,
  };

  bool _requiresRuntimeConversion(AckInferRef type) => switch (type) {
    AckNullableTypeRef(:final inner) => _requiresRuntimeConversion(inner),
    AckModelTypeRef() ||
    AckListTypeRef() ||
    AckSetTypeRef() ||
    AckMapTypeRef() => true,
    _ => false,
  };

  String _valueToJsonBody(AckInferRef boundaryType) {
    return switch (boundaryType) {
      AckListTypeRef(:final elementType) =>
        'List<${_type(elementType)}>.of(\$ack.encode(this))',
      AckSetTypeRef(:final elementType) =>
        'Set<${_type(elementType)}>.of(\$ack.encode(this))',
      _ => r'$ack.encode(this)',
    };
  }

  String _type(AckInferRef type) {
    return switch (type) {
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
  }

  List<String> _docs(AckModelNode node, String kind) => [
    '/// $kind generated from `${node.id.declarationName}`.',
    if (node.description != null) '/// ${node.description}',
  ];

  Expression _jsonMarker() {
    final prefix = schemablePrefix;
    final typeName = prefix == null || prefix.isEmpty
        ? 'Schemable'
        : '$prefix.Schemable';
    return refer(typeName).property('generatedJson');
  }

  String _ack(String symbol) {
    final prefix = ackPrefix;
    return prefix == null || prefix.isEmpty ? symbol : '$prefix.$symbol';
  }

  static const _runtimeMapType = 'Map<String, Object?>';
  static const _runtimeMapLiteral = '<String, Object?>';
  static const _objectJsonType = 'Map<String, dynamic>';
}

typedef _AckDataClass = ({
  List<AckFieldNode> fields,
  List<AckConstructorParameter> constructorParameters,
});

const _toJsonDocs = [
  '/// Validates this model and encodes it for JSON.',
  '///',
  '/// Throws an `AckException` when validation fails.',
];

const _safeToJsonDocs = [
  '/// Validates this model and encodes it for JSON, returning the validation',
  '/// failure instead of throwing.',
];
