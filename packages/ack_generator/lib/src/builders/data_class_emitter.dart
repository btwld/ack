import 'package:code_builder/code_builder.dart';

import '../json/helper_names.dart';
import '../models/schema_model_graph.dart';
import '../utils/string_literal.dart';

/// One generated `copyWith` parameter, typed by the emitter that owns type
/// rendering.
final class AckCopyWithParameter {
  const AckCopyWithParameter({
    required this.name,
    required this.fieldName,
    required this.type,
    required this.nullable,
    required this.positional,
  });

  /// The named `copyWith` parameter.
  final String name;

  /// The stored field kept when the argument is omitted.
  final String fieldName;

  /// The stored field's Dart type.
  final String type;

  /// Whether an explicit `null` must be distinguished from an omission.
  final bool nullable;

  /// Whether the model constructor receives this value positionally.
  final bool positional;
}

/// Shared copy/equality/hash/string emission for class-first and schema-first
/// data classes.
final class AckDataClassEmitter {
  const AckDataClassEmitter({this.ackPrefix});

  static const _copyWithUnset = '_ackCopyWithUnset';

  final String? ackPrefix;

  /// Private mixin applied by a hand-written `@AckModel` class.
  String mixin({
    required String className,
    required String facadeName,
    required List<AckFieldNode> fields,
    required List<AckConstructorParameter> constructorParameters,
    required bool includeValueMembers,
    String? captureFieldName,
    List<String> copyWithSupertypes = const [],
  }) {
    final stored = [
      ...fields,
      if (captureFieldName != null)
        AckFieldNode(
          dartName: captureFieldName,
          jsonKey: captureFieldName,
          presence: AckSchemaFieldPresence.required,
          nullable: false,
          runtimeRef: const AckMapTypeRef(
            AckNullableTypeRef(AckScalarTypeRef('Object')),
          ),
        ),
    ];
    final copyWithParameters = [
      for (final parameter in constructorParameters)
        AckCopyWithParameter(
          name: parameter.name,
          fieldName: parameter.fieldName,
          type: _type(parameter.typeRef),
          nullable: parameter.typeRef is AckNullableTypeRef,
          positional: parameter.kind != AckConstructorParameterKind.named,
        ),
    ];
    final members = [
      if (includeValueMembers) ...[
        copyWithGetter(
          className: className,
          hasParameters: copyWithParameters.isNotEmpty,
          castSelf: true,
        ),
        equalityMembers(className: className, fields: stored, castSelf: true),
        toStringMethod(className: className, fields: stored, castSelf: true),
      ],
      jsonMembers(className: className, facadeName: facadeName),
    ];

    return '''
${includeValueMembers ? '${copyWithContract(className: className, parameters: copyWithParameters, supertypes: copyWithSupertypes)}\n\n' : ''}mixin ${'_\$${className}Ack'} {
  ${members.join('\n\n  ')}
}''';
  }

  /// Emits `copyWith`, `operator ==`, `hashCode`, and `toString` for a
  /// schema-first model class.
  List<Method> valueMethods({
    required String className,
    required List<AckFieldNode> fields,
    required bool hasParameters,
  }) => [
    Method(
      (m) => m
        ..name = 'copyWith'
        ..type = MethodType.getter
        ..returns = refer('${ackCopyWithInterfaceName(className)}<$className>')
        ..docs.add(
          '/// Creates a copy of this model with selected fields replaced.',
        )
        ..lambda = true
        ..body = Code(
          _copyWithCreation(className, hasParameters: hasParameters),
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
        ..body = Code(_directEqualsExpression(className, fields)),
    ),
    Method(
      (m) => m
        ..name = 'hashCode'
        ..annotations.add(refer('override'))
        ..type = MethodType.getter
        ..returns = refer('int')
        ..lambda = true
        ..body = Code(_hashExpression(fields)),
    ),
    Method(
      (m) => m
        ..name = 'toString'
        ..annotations.add(refer('override'))
        ..returns = refer('String')
        ..lambda = true
        ..body = literalString(_toStringPreview(className, fields)).code,
    ),
  ];

  /// The typed `copyWith` interface and its implementation, plus the private
  /// sentinel type when a nullable field needs one.
  ///
  /// The public interface types every parameter, so a wrong argument type is
  /// a compile-time error. The implementation widens nullable parameters to
  /// `Object?` with a sentinel default, so an omitted argument keeps the
  /// current value while an explicit `null` clears the field. A single method
  /// cannot do both because a default value must match the parameter type.
  ///
  /// The interface is generic in its result, like the `freezed` and
  /// `dart_mappable` interfaces. Without the type parameter,
  /// `avoid_redundant_argument_values` reports `copyWith(field: null)` as
  /// redundant, and `dart fix` would delete the argument, turning "clear"
  /// into "keep".
  String copyWithContract({
    required String className,
    required List<AckCopyWithParameter> parameters,
    List<String> supertypes = const [],
  }) {
    final interfaceName = ackCopyWithInterfaceName(className);
    final implementationName = ackCopyWithImplementationName(className);
    final sentinelType = ackCopyWithUnsetTypeName(className);
    final needsSentinel = parameters.any((parameter) => parameter.nullable);
    final hasSource = parameters.isNotEmpty;
    String named(List<String> declarations) =>
        declarations.isEmpty ? '' : '{${declarations.join(', ')}}';
    final interfaceParameters = [
      for (final parameter in parameters)
        '${_optional(parameter.type)} ${parameter.name}',
    ];
    final implementationParameters = [
      for (final parameter in parameters)
        parameter.nullable
            ? 'Object? ${parameter.name} = $_copyWithUnset'
            : '${_optional(parameter.type)} ${parameter.name}',
    ];
    final arguments = [
      for (final parameter in parameters) _copyWithArgument(parameter),
    ];
    final sentinelClass = needsSentinel
        ? 'final class $sentinelType {\n  const $sentinelType();\n}\n\n'
        : '';
    final sentinelField = needsSentinel
        ? '  static const $sentinelType $_copyWithUnset = $sentinelType();\n\n'
        : '';
    final sourceField = hasSource ? '  final $className _source;\n\n' : '';
    return '''
$sentinelClass/// Creates copies of [$className] with selected fields replaced.
abstract interface class $interfaceName<\$Result> ${supertypes.isEmpty ? '' : 'implements ${supertypes.map((name) => '$name<\$Result>').join(', ')}'} {
  /// Returns a copy with the given fields replaced.
  ///
  /// An omitted argument keeps the current value. An explicit `null` clears a
  /// nullable field.
  \$Result call(${named(interfaceParameters)});
}

final class $implementationName implements $interfaceName<$className> {
  const $implementationName(${hasSource ? 'this._source' : ''});

$sentinelField$sourceField  @override
  $className call(${named(implementationParameters)}) =>
      $className(${arguments.join(', ')});
}''';
  }

  /// The `copyWith` getter that exposes [copyWithContract]'s interface.
  String copyWithGetter({
    required String className,
    required bool hasParameters,
    bool castSelf = false,
  }) {
    final creation = _copyWithCreation(
      className,
      hasParameters: hasParameters,
      castSelf: castSelf,
    );
    return '''
/// Creates a copy of this model with selected fields replaced.
${ackCopyWithInterfaceName(className)}<$className> get copyWith => $creation;''';
  }

  String equalityMembers({
    required String className,
    required List<AckFieldNode> fields,
    bool castSelf = false,
  }) {
    if (castSelf && fields.isNotEmpty) {
      final fieldEquals = [
        for (final field in fields)
          _equals('self.${field.dartName}', 'other.${field.dartName}'),
      ];
      final equality = fieldEquals.isEmpty ? 'true' : fieldEquals.join(' && ');
      final hashes = _hashExpression(fields, receiver: 'self');
      return '''
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  if (other is! $className || runtimeType != other.runtimeType) {
    return false;
  }
  final self = this as $className;
  return $equality;
}

@override
int get hashCode {
  final self = this as $className;
  return $hashes;
}''';
    }
    return '''
@override
bool operator ==(Object other) =>
    ${_directEqualsExpression(className, fields)};

@override
int get hashCode => ${_hashExpression(fields)};''';
  }

  String toStringMethod({
    required String className,
    required List<AckFieldNode> fields,
    bool castSelf = false,
  }) {
    if (castSelf && fields.isNotEmpty) {
      final parts = [
        for (final field in fields)
          '${field.dartName}: \${self.${field.dartName}}',
      ];
      return '''
@override
String toString() {
  final self = this as $className;
  return '$className(${parts.join(', ')})';
}''';
    }
    return '''
@override
String toString() => '${_toStringPreview(className, fields)}';''';
  }

  String jsonMembers({required String className, required String facadeName}) {
    return '''
/// Validates this model and encodes it for JSON.
///
/// Throws an `AckException` when validation fails.
Map<String, dynamic> toJson() =>
    Map<String, dynamic>.from($facadeName.encode(this as $className));

/// Validates this model and encodes it for JSON, returning the validation
/// failure instead of throwing.
${_ack('SchemaResult')}<Map<String, Object?>> safeToJson() =>
    $facadeName.safeEncode(this as $className);''';
  }

  String _copyWithCreation(
    String className, {
    required bool hasParameters,
    bool castSelf = false,
  }) {
    final implementationName = ackCopyWithImplementationName(className);
    return hasParameters
        ? '$implementationName(${castSelf ? 'this as $className' : 'this'})'
        : 'const $implementationName()';
  }

  String _directEqualsExpression(String className, List<AckFieldNode> fields) {
    final comparisons = [
      'other is $className',
      'runtimeType == other.runtimeType',
      for (final field in fields)
        _equals(field.dartName, 'other.${field.dartName}'),
    ];
    return 'identical(this, other) || (${comparisons.join(' && ')})';
  }

  String _hashExpression(List<AckFieldNode> fields, {String? receiver}) {
    final prefix = receiver == null ? '' : '$receiver.';
    final hashes = [
      'runtimeType',
      for (final field in fields) _hash('$prefix${field.dartName}'),
    ];
    return 'Object.hashAll([${hashes.join(', ')}])';
  }

  String _toStringPreview(String className, List<AckFieldNode> fields) {
    final parts = [
      for (final field in fields) '${field.dartName}: \$${field.dartName}',
    ];
    return '$className(${parts.join(', ')})';
  }

  String _optional(String type) => type.endsWith('?') ? type : '$type?';

  String _copyWithArgument(AckCopyWithParameter parameter) {
    // Sentinel parameters are already typed Object?.
    final value = parameter.type == 'Object?'
        ? parameter.name
        : '${parameter.name} as ${parameter.type}';
    final replacement = parameter.nullable
        ? 'identical(${parameter.name}, $_copyWithUnset) '
              '? _source.${parameter.fieldName} '
              ': $value'
        : '${parameter.name} ?? _source.${parameter.fieldName}';
    return parameter.positional
        ? replacement
        : '${parameter.name}: $replacement';
  }

  String _equals(String left, String right) =>
      '${_ack('deepEquals')}($left, $right)';

  String _hash(String expression) => '${_ack('deepHashCode')}($expression)';

  AckInferRef nonNullable(AckInferRef type) => switch (type) {
    AckNullableTypeRef(:final inner) => inner,
    _ => type,
  };

  bool requiresImmutableCopy(AckInferRef type) => switch (type) {
    AckNullableTypeRef(:final inner) => requiresImmutableCopy(inner),
    AckScalarTypeRef(dartType: 'Object', isJsonValue: true) ||
    AckListTypeRef() ||
    AckSetTypeRef() ||
    AckMapTypeRef() => true,
    _ => false,
  };

  bool requiresRuntimeConversion(AckInferRef type) => switch (type) {
    AckNullableTypeRef(:final inner) => requiresRuntimeConversion(inner),
    AckModelTypeRef() ||
    AckListTypeRef() ||
    AckSetTypeRef() ||
    AckMapTypeRef() => true,
    _ => false,
  };

  String immutableCopy(AckInferRef type, String expression) {
    return switch (type) {
      AckNullableTypeRef(
        inner: AckScalarTypeRef(dartType: 'Object', isJsonValue: true),
      ) =>
        '${_ack('deepUnmodifiableCopy')}($expression)',
      // A non-null input stays non-null; no generic collection casts are used.
      AckScalarTypeRef(dartType: 'Object', isJsonValue: true) =>
        '${_ack('deepUnmodifiableCopy')}($expression)!',
      AckNullableTypeRef(:final inner) when !requiresImmutableCopy(inner) =>
        expression,
      AckNullableTypeRef(:final inner) =>
        '$expression == null ? null : ${immutableCopy(inner, expression)}',
      AckListTypeRef(:final elementType) =>
        'List<${_type(elementType)}>.unmodifiable($expression.map((item) => ${immutableCopy(elementType, 'item')}))',
      AckSetTypeRef(:final elementType) =>
        'Set<${_type(elementType)}>.unmodifiable($expression.map((item) => ${immutableCopy(elementType, 'item')}))',
      AckMapTypeRef(:final valueType) when !requiresImmutableCopy(valueType) =>
        'Map<String, ${_type(valueType)}>.unmodifiable($expression)',
      AckMapTypeRef(:final valueType) =>
        'Map<String, ${_type(valueType)}>.unmodifiable($expression.map((key, item) => MapEntry(key, ${immutableCopy(valueType, 'item')})))',
      _ => expression,
    };
  }

  String fromRuntime(
    AckInferRef type,
    String expression, {
    bool wrapImmutableCollections = false,
  }) {
    return switch (type) {
      // Any input is already assignable to Object?; a cast would be redundant.
      AckNullableTypeRef(inner: AckScalarTypeRef(dartType: 'Object')) =>
        expression,
      AckNullableTypeRef(:final inner)
          when wrapImmutableCollections &&
              (inner is AckScalarTypeRef || inner is AckExternalTypeRef) =>
        '$expression as ${_type(type)}',
      AckNullableTypeRef(:final inner) =>
        '$expression == null ? null : ${fromRuntime(inner, wrapImmutableCollections ? expression : '$expression!', wrapImmutableCollections: wrapImmutableCollections)}',
      AckModelTypeRef(:final runtimeRef, :final visibleName) =>
        '$visibleName.\$ack.fromRuntime($expression as ${_type(runtimeRef)})',
      AckListTypeRef(:final elementType) => _listFromRuntime(
        elementType,
        expression,
        wrapImmutableCollections: wrapImmutableCollections,
      ),
      AckSetTypeRef(:final elementType) => _setFromRuntime(
        elementType,
        expression,
        wrapImmutableCollections: wrapImmutableCollections,
      ),
      AckMapTypeRef(:final valueType) => _mapFromRuntime(
        valueType,
        expression,
        wrapImmutableCollections: wrapImmutableCollections,
      ),
      _ => '$expression as ${_type(type)}',
    };
  }

  String _listFromRuntime(
    AckInferRef elementType,
    String expression, {
    required bool wrapImmutableCollections,
  }) {
    final elementTypeName = _type(elementType);
    if (wrapImmutableCollections) {
      return 'List<$elementTypeName>.unmodifiable(($expression as List).map('
          '(item) => ${fromRuntime(elementType, 'item', wrapImmutableCollections: true)}))';
    }
    if (!requiresRuntimeConversion(elementType)) {
      return '($expression as List).cast<$elementTypeName>()';
    }
    return '($expression as List).map('
        '(item) => ${fromRuntime(elementType, 'item')}).toList()';
  }

  String _setFromRuntime(
    AckInferRef elementType,
    String expression, {
    required bool wrapImmutableCollections,
  }) {
    final elementTypeName = _type(elementType);
    if (wrapImmutableCollections) {
      return 'Set<$elementTypeName>.unmodifiable(($expression as Set).map('
          '(item) => ${fromRuntime(elementType, 'item', wrapImmutableCollections: true)}))';
    }
    if (!requiresRuntimeConversion(elementType)) {
      return '($expression as Set).cast<$elementTypeName>()';
    }
    return '($expression as Set).map('
        '(item) => ${fromRuntime(elementType, 'item')}).toSet()';
  }

  String _mapFromRuntime(
    AckInferRef valueType,
    String expression, {
    required bool wrapImmutableCollections,
  }) {
    final valueTypeName = _type(valueType);
    if (wrapImmutableCollections) {
      return 'Map<String, $valueTypeName>.unmodifiable(($expression as Map).map('
          '(key, item) => MapEntry(key as String, '
          '${fromRuntime(valueType, 'item', wrapImmutableCollections: true)})))';
    }
    if (!requiresRuntimeConversion(valueType)) {
      return '($expression as Map).cast<String, $valueTypeName>()';
    }
    return '($expression as Map).map((key, item) => MapEntry('
        'key as String, ${fromRuntime(valueType, 'item')}))';
  }

  String toRuntime(AckInferRef type, String expression) {
    return switch (type) {
      AckNullableTypeRef(:final inner)
          when inner is AckScalarTypeRef || inner is AckExternalTypeRef =>
        expression,
      // `value?.map(...)` satisfies prefer_null_aware_operators.
      AckNullableTypeRef(:final inner)
          when inner is AckListTypeRef ||
              inner is AckSetTypeRef ||
              inner is AckMapTypeRef =>
        toRuntime(inner, '$expression?'),
      // Expressions are promotable locals, so the null check needs no `!`.
      AckNullableTypeRef(:final inner) =>
        '$expression == null ? null : ${toRuntime(inner, expression)}',
      AckModelTypeRef(:final visibleName) =>
        '$visibleName.\$ack.toRuntime($expression)',
      AckListTypeRef(:final elementType) =>
        '$expression.map((item) => ${toRuntime(elementType, 'item')}).toList(growable: false)',
      AckSetTypeRef(:final elementType) =>
        '$expression.map((item) => ${toRuntime(elementType, 'item')}).toSet()',
      AckMapTypeRef(:final valueType) =>
        '$expression.map((key, item) => MapEntry(key, ${toRuntime(valueType, 'item')}))',
      _ => expression,
    };
  }

  String encodeField(
    AckInferRef runtimeRef,
    String access, {
    required bool nullable,
  }) {
    final baseType = nonNullable(runtimeRef);
    if (!nullable || !requiresRuntimeConversion(baseType)) {
      return toRuntime(baseType, access);
    }
    if (baseType is AckListTypeRef ||
        baseType is AckSetTypeRef ||
        baseType is AckMapTypeRef) {
      return toRuntime(AckNullableTypeRef(baseType), access);
    }
    return 'switch ($access) {'
        ' null => null,'
        ' final fieldValue => ${toRuntime(baseType, 'fieldValue')},'
        ' }';
  }

  String declaredKeysLiteral(Iterable<String> keys) =>
      '<String>{${keys.map(dartStringLiteral).join(', ')}}';

  String _type(AckInferRef type) => type.render(ackPrefix: ackPrefix);

  String _ack(String symbol) => qualifySymbol(ackPrefix, symbol);
}
