import 'package:ack/annotations.dart' as annotations;
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../utils/doc_comment_utils.dart';
import '../utils/string_literal.dart';

/// Inference helper that builds Ack schema expressions from resolved Dart
/// types and annotations.
///
/// The caller resolves application model types and import prefixes. Ack owns
/// scalar, collection, and constraint inference for each generator.
final class AckSchemaInference {
  const AckSchemaInference({this.ackPrefix});

  final String? ackPrefix;

  static const _rule = TypeChecker.typeNamed(
    annotations.AckRule,
    inPackage: 'ack',
  );

  /// Infers a schema expression for [type].
  ///
  /// [resolveNamed] returns a schema expression for an application type,
  /// including an enum that declares its own schema. Return `null` when the
  /// type has no supported model contract; an enum then uses `Ack.enumValues`.
  Future<String> inferType(
    DartType type, {
    required String Function(InterfaceType) visibleTypeName,
    required String Function(InterfaceType) renderType,
    required Future<String?> Function(InterfaceType) resolveNamed,
    required Never Function(DartType) unsupported,
    required void Function(DartType) rejectNullableCollectionElement,
    required void Function(InterfaceType) validateMapKey,
  }) async {
    if (type is! InterfaceType) return unsupported(type);
    if (_core(type, 'DateTime') ||
        _core(type, 'Uri') ||
        _core(type, 'Duration') ||
        (_core(type, 'Object') && !_nullable(type))) {
      final override = await resolveNamed(type);
      if (override != null) return override;
    }
    final scalar = _scalar(type);
    if (scalar != null) return scalar;
    if (type.element is EnumElement) {
      return await resolveNamed(type) ??
          '${_ack('Ack')}.enumValues(${visibleTypeName(type)}.values)';
    }
    if (type.isDartCoreList && type.typeArguments.length == 1) {
      final item = type.typeArguments.single;
      if (_nullable(item)) rejectNullableCollectionElement(item);
      return '${_ack('Ack')}.list(${await inferType(item, visibleTypeName: visibleTypeName, renderType: renderType, resolveNamed: resolveNamed, unsupported: unsupported, rejectNullableCollectionElement: rejectNullableCollectionElement, validateMapKey: validateMapKey)})';
    }
    if (type.isDartCoreSet && type.typeArguments.length == 1) {
      final item = type.typeArguments.single;
      if (_nullable(item)) rejectNullableCollectionElement(item);
      final itemSchema = await inferType(
        item,
        visibleTypeName: visibleTypeName,
        renderType: renderType,
        resolveNamed: resolveNamed,
        unsupported: unsupported,
        rejectNullableCollectionElement: rejectNullableCollectionElement,
        validateMapKey: validateMapKey,
      );
      final runtimeType = type.element.instantiate(
        typeArguments: type.typeArguments,
        nullabilitySuffix: NullabilitySuffix.none,
      );
      return '${_ack('Ack')}.list($itemSchema).codec<${renderType(runtimeType)}>(decode: (list) => list.toSet(), encode: (set) => set.toList(growable: false),)';
    }
    if (type.isDartCoreMap) {
      validateMapKey(type);
      final value = type.typeArguments[1];
      final valueSchema = await inferType(
        value,
        visibleTypeName: visibleTypeName,
        renderType: renderType,
        resolveNamed: resolveNamed,
        unsupported: unsupported,
        rejectNullableCollectionElement: rejectNullableCollectionElement,
        validateMapKey: validateMapKey,
      );
      return '${_ack('Ack')}.map($valueSchema${_nullable(value) ? '.nullable()' : ''})';
    }
    return await resolveNamed(type) ?? unsupported(type);
  }

  /// Applies constraint annotations declared on a field or parameter.
  String applyConstraints(String schema, Element declaration, DartType type) {
    var output = schema;
    final isCollection =
        type is InterfaceType && (type.isDartCoreList || type.isDartCoreSet);
    final isSet = type is InterfaceType && type.isDartCoreSet;
    final scalarType = isCollection && type.typeArguments.length == 1
        ? type.typeArguments.single
        : type;
    final isNumeric =
        scalarType is InterfaceType &&
        (_core(scalarType, 'int') ||
            _core(scalarType, 'double') ||
            _core(scalarType, 'num'));
    final isString = scalarType is InterfaceType && _core(scalarType, 'String');
    final itemConstraints = <String>[];
    final setConstraints = <String>[];
    var hasUniqueConstraint = false;

    void addScalarConstraint(String constraint) {
      if (isCollection) {
        itemConstraints.add(constraint);
      } else {
        output = '$output$constraint';
      }
    }

    void addCollectionConstraint(String constraint, {bool isUnique = false}) {
      if (isSet) {
        if (isUnique) hasUniqueConstraint = true;
        setConstraints.add(constraint);
      } else {
        output = '$output$constraint';
      }
    }

    for (final metadata in declaration.metadata.annotations) {
      final value = metadata.computeConstantValue();
      final valueType = value?.type;
      if (value == null || valueType is! InterfaceType) continue;
      if (!_rule.isAssignableFromType(valueType)) continue;
      final rule = _ruleName(valueType);
      final annotation = '@$rule';
      switch (rule) {
        case 'IsOptional' || 'IsRequired' || 'IsNotNull':
          break;
        case 'HasMin':
          _require(declaration, type, annotation, isNumeric, '@HasMinLength');
          addScalarConstraint(
            '.min(${_number(declaration, annotation, value, 'min')})',
          );
        case 'HasMax':
          _require(declaration, type, annotation, isNumeric, '@HasMaxLength');
          addScalarConstraint(
            '.max(${_number(declaration, annotation, value, 'max')})',
          );
        case 'IsMultipleOf':
          _require(declaration, type, annotation, isNumeric, 'numeric field');
          addScalarConstraint(
            '.multipleOf(${_number(declaration, annotation, value, 'divisor')})',
          );
        case 'IsPositive':
          _require(declaration, type, annotation, isNumeric, 'numeric field');
          addScalarConstraint('.positive()');
        case 'IsNegative':
          _require(declaration, type, annotation, isNumeric, 'numeric field');
          addScalarConstraint('.negative()');
        case 'HasMinLength':
          _require(declaration, type, annotation, isString, '@HasMin');
          addScalarConstraint('.minLength(${_int(value, 'length')})');
        case 'HasMaxLength':
          _require(declaration, type, annotation, isString, '@HasMax');
          addScalarConstraint('.maxLength(${_int(value, 'length')})');
        case 'HasMatch':
          _require(declaration, type, annotation, isString, 'String field');
          addScalarConstraint(
            '.matches(${dartStringLiteral(_field(value, 'pattern')!.toStringValue()!)})',
          );
        case 'IsNotEmpty':
          _require(
            declaration,
            type,
            annotation,
            isString || isCollection,
            'String, List, or Set field',
          );
          if (isCollection) {
            addCollectionConstraint('.notEmpty()');
          } else {
            output = '$output.notEmpty()';
          }
        case 'IsEmail':
          _require(declaration, type, annotation, isString, 'String field');
          addScalarConstraint('.email()');
        case 'IsUrl':
          _require(declaration, type, annotation, isString, 'String field');
          addScalarConstraint('.url()');
        case 'IsUri':
          _require(declaration, type, annotation, isString, 'String field');
          addScalarConstraint('.uri()');
        case 'IsUuid':
          _require(declaration, type, annotation, isString, 'String field');
          addScalarConstraint('.uuid()');
        case 'IsDate':
          _require(declaration, type, annotation, isString, 'String field');
          addScalarConstraint('.date()');
        case 'IsDateTime':
          _require(declaration, type, annotation, isString, 'String field');
          addScalarConstraint('.datetime()');
        case 'IsIp':
          _require(declaration, type, annotation, isString, 'String field');
          final version = _field(value, 'version')?.toIntValue();
          if (version != null) {
            if (version != 4 && version != 6) {
              throw InvalidGenerationSource(
                '${_qualifiedName(declaration)} has @IsIp(version: '
                '$version); version must be 4 or 6.',
                element: declaration,
              );
            }
            addScalarConstraint('.ip(version: $version)');
          } else {
            addScalarConstraint('.ip()');
          }
        case 'HasMinItems':
          _require(
            declaration,
            type,
            annotation,
            isCollection,
            'List or Set field',
          );
          addCollectionConstraint('.minItems(${_int(value, 'count')})');
        case 'HasMaxItems':
          _require(
            declaration,
            type,
            annotation,
            isCollection,
            'List or Set field',
          );
          addCollectionConstraint('.maxItems(${_int(value, 'count')})');
        case 'HasUniqueItems':
          _require(
            declaration,
            type,
            annotation,
            isCollection,
            'List or Set field',
          );
          addCollectionConstraint('.unique()', isUnique: true);
        default:
          throw InvalidGenerationSource(
            '${_qualifiedName(declaration)} has unsupported rule $annotation.',
            element: declaration,
          );
      }
    }
    if (itemConstraints.isNotEmpty) {
      output = _appendListItemConstraints(output, itemConstraints.join());
    }
    if (setConstraints.isNotEmpty) {
      if (isSet && !hasUniqueConstraint) {
        // A Set cannot retain duplicate values after decoding. Validate the
        // boundary with the same cardinality before the codec runs.
        setConstraints.add('.unique()');
      }
      output = _beforeOuterCodec(output, setConstraints.join());
    }
    return output;
  }

  String _appendListItemConstraints(String schema, String modifiers) {
    const prefix = 'final schema = ';
    final unit = parseString(
      content: '$prefix$schema;',
      throwIfDiagnostics: false,
    ).unit;
    final declaration = unit.declarations.single as TopLevelVariableDeclaration;
    Expression? current = declaration.variables.variables.single.initializer;
    while (current is MethodInvocation) {
      if (current.methodName.name == 'list' &&
          current.argumentList.arguments.length == 1) {
        final itemArg = current.argumentList.arguments.single;
        final end = itemArg.end - prefix.length;
        return '${schema.substring(0, end)}$modifiers${schema.substring(end)}';
      }
      current = current.target;
    }
    return '$schema$modifiers';
  }

  /// Inserts [modifiers] before the codec that ends [schema], or appends them
  /// when [schema] is the list schema that the set codec will wrap.
  String _beforeOuterCodec(String schema, String modifiers) {
    const prefix = 'final schema = ';
    final unit = parseString(
      content: '$prefix$schema;',
      throwIfDiagnostics: false,
    ).unit;
    final declaration = unit.declarations.single as TopLevelVariableDeclaration;
    final expression = declaration.variables.variables.single.initializer;
    if (expression is MethodInvocation &&
        expression.methodName.name == 'codec' &&
        expression.target != null) {
      final end = expression.target!.end - prefix.length;
      return '${schema.substring(0, end)}$modifiers${schema.substring(end)}';
    }
    return '$schema$modifiers';
  }

  /// Adds a tagged documentation description (`/// @description ...`) to [schema].
  ///
  /// Analyzer does not attach parameter doc comments to parameter elements.
  /// A function generator passes the comment from its source AST.
  String applyDescription(
    String schema,
    Element declaration, {
    String? sourceComment,
  }) {
    final String? description;
    try {
      description = parseDescriptionTag(
        sourceComment ?? declaration.documentationComment,
      );
    } on FormatException catch (error) {
      throw InvalidGenerationSource(
        '${declaration.name} ${error.message}',
        element: declaration,
      );
    }
    return description == null
        ? schema
        : '$schema.describe(${dartStringLiteral(description)})';
  }

  String? _scalar(InterfaceType type) {
    for (final entry in const {
      'String': 'string',
      'int': 'integer',
      'double': 'double',
      'num': 'number',
      'bool': 'boolean',
      'DateTime': 'datetime',
      'Uri': 'uri',
      'Duration': 'duration',
      'Object': 'any',
    }.entries) {
      if (_core(type, entry.key)) return '${_ack('Ack')}.${entry.value}()';
    }
    return null;
  }

  bool _core(InterfaceType type, String name) =>
      type.element.library.uri.toString() == 'dart:core' &&
      type.element.name == name;

  bool _nullable(DartType type) =>
      type.nullabilitySuffix == NullabilitySuffix.question;

  String _ack(String symbol) => qualifySymbol(ackPrefix, symbol);

  /// The public rule class of [type]: `IsIp` for the private subclasses that
  /// back the deprecated `ipv4()` and `ipv6()` aliases.
  String _ruleName(InterfaceType type) {
    InterfaceType? current = type;
    while (current != null && current.element.isPrivate) {
      current = current.superclass;
    }
    return current!.element.name!;
  }

  /// Reads [name] from [value] or from the rule class it extends.
  DartObject? _field(DartObject value, String name) {
    DartObject? current = value;
    while (current != null) {
      final field = current.getField(name);
      if (field != null) return field;
      current = current.getField('(super)');
    }
    return null;
  }

  int _int(DartObject value, String name) => _field(value, name)!.toIntValue()!;

  String _number(
    Element declaration,
    String annotation,
    DartObject value,
    String name,
  ) {
    final field = _field(value, name)!;
    final number = (field.toIntValue() ?? field.toDoubleValue())!;
    if (!number.isFinite) {
      throw InvalidGenerationSource(
        '${_qualifiedName(declaration)} has '
        '$annotation($number); the value must be a finite number.',
        element: declaration,
      );
    }
    return number.toString();
  }

  void _require(
    Element declaration,
    DartType type,
    String annotation,
    bool valid,
    String alternative,
  ) {
    if (valid) return;
    throw InvalidGenerationSource(
      '${_qualifiedName(declaration)} has '
      '$annotation on ${type.getDisplayString()}; use $alternative instead.',
      element: declaration,
    );
  }

  String _qualifiedName(Element declaration) {
    final owner = switch (declaration.enclosingElement) {
      ConstructorElement(:final enclosingElement) => enclosingElement.name,
      final enclosing? => enclosing.name,
      null => null,
    };
    return owner == null || owner.isEmpty
        ? '${declaration.name}'
        : '$owner.${declaration.name}';
  }
}
