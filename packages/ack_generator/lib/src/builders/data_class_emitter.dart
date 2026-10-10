import '../json/helper_names.dart';
import '../models/schema_model_graph.dart';

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
    final implementationName = ackCopyWithImplementationName(className);
    final creation = hasParameters
        ? '$implementationName(${castSelf ? 'this as $className' : 'this'})'
        : 'const $implementationName()';
    return '''
/// Creates a copy of this model with selected fields replaced.
${ackCopyWithInterfaceName(className)}<$className> get copyWith => $creation;''';
  }

  String equalityMembers({
    required String className,
    required List<AckFieldNode> fields,
    bool castSelf = false,
  }) {
    final hashes = [
      'runtimeType',
      for (final field in fields)
        _hash('${castSelf ? 'self' : 'this'}.${field.dartName}'),
    ];
    if (castSelf && fields.isNotEmpty) {
      final fieldEquals = [
        for (final field in fields)
          _equals('self.${field.dartName}', 'other.${field.dartName}'),
      ];
      final equality = fieldEquals.isEmpty ? 'true' : fieldEquals.join(' && ');
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
  return Object.hashAll([${hashes.join(', ')}]);
}''';
    }
    final comparisons = [
      'other is $className',
      'runtimeType == other.runtimeType',
      for (final field in fields)
        _equals('this.${field.dartName}', 'other.${field.dartName}'),
    ];
    return '''
@override
bool operator ==(Object other) =>
    identical(this, other) || (${comparisons.join(' && ')});

@override
int get hashCode => Object.hashAll([${hashes.join(', ')}]);''';
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
    final parts = [
      for (final field in fields) '${field.dartName}: \$${field.dartName}',
    ];
    return '''
@override
String toString() => '$className(${parts.join(', ')})';''';
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
    AckJsonMaybeTypeRef(:final valueType) =>
      '${_ack('JsonMaybe')}<${_type(valueType)}>',
  };

  String _ack(String symbol) {
    final prefix = ackPrefix;
    return prefix == null || prefix.isEmpty ? symbol : '$prefix.$symbol';
  }
}
