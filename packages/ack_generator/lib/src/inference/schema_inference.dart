import 'package:ack_annotations/ack_annotations.dart' as annotations;
import 'package:ack_annotations/format_annotations.dart' as formats;
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../utils/doc_comment_utils.dart';

/// Infers Ack schema expressions from resolved Dart types and annotations.
///
/// The caller resolves application model types and import prefixes. Ack owns
/// scalar, collection, and constraint inference for each generator.
final class AckSchemaInference {
  const AckSchemaInference({this.ackPrefix});

  final String? ackPrefix;

  static const _min = TypeChecker.typeNamed(
    annotations.Min,
    inPackage: 'ack_annotations',
  );
  static const _max = TypeChecker.typeNamed(
    annotations.Max,
    inPackage: 'ack_annotations',
  );
  static const _multipleOf = TypeChecker.typeNamed(
    annotations.MultipleOf,
    inPackage: 'ack_annotations',
  );
  static const _positive = TypeChecker.typeNamed(
    annotations.Positive,
    inPackage: 'ack_annotations',
  );
  static const _negative = TypeChecker.typeNamed(
    annotations.Negative,
    inPackage: 'ack_annotations',
  );
  static const _minLength = TypeChecker.typeNamed(
    annotations.MinLength,
    inPackage: 'ack_annotations',
  );
  static const _maxLength = TypeChecker.typeNamed(
    annotations.MaxLength,
    inPackage: 'ack_annotations',
  );
  static const _pattern = TypeChecker.typeNamed(
    annotations.Pattern,
    inPackage: 'ack_annotations',
  );
  static const _email = TypeChecker.typeNamed(
    annotations.Email,
    inPackage: 'ack_annotations',
  );
  static const _url = TypeChecker.typeNamed(
    annotations.Url,
    inPackage: 'ack_annotations',
  );
  static const _uri = TypeChecker.typeNamed(
    formats.Uri,
    inPackage: 'ack_annotations',
  );
  static const _uuid = TypeChecker.typeNamed(
    annotations.Uuid,
    inPackage: 'ack_annotations',
  );
  static const _date = TypeChecker.typeNamed(
    annotations.Date,
    inPackage: 'ack_annotations',
  );
  static const _dateTime = TypeChecker.typeNamed(
    formats.DateTime,
    inPackage: 'ack_annotations',
  );
  static const _notEmpty = TypeChecker.typeNamed(
    annotations.NotEmpty,
    inPackage: 'ack_annotations',
  );
  static const _minItems = TypeChecker.typeNamed(
    annotations.MinItems,
    inPackage: 'ack_annotations',
  );
  static const _maxItems = TypeChecker.typeNamed(
    annotations.MaxItems,
    inPackage: 'ack_annotations',
  );
  static const _uniqueItems = TypeChecker.typeNamed(
    annotations.UniqueItems,
    inPackage: 'ack_annotations',
  );

  /// Infers a schema expression for [type].
  ///
  /// [resolveNamed] returns a schema expression for an application type.
  /// Return null when the type has no supported model contract.
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
    final scalar = _scalar(type);
    if (scalar != null) return scalar;
    if (type.element is EnumElement) {
      return '${_ack('Ack')}.enumValues(${visibleTypeName(type)}.values)';
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
      return '${_ack('Ack')}.list($itemSchema).codec<${renderType(type)}>(decode: (list) => list.toSet(), encode: (set) => set.toList(growable: false),)';
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
    final isNumeric =
        type is InterfaceType &&
        (_core(type, 'int') || _core(type, 'double') || _core(type, 'num'));
    final isString = type is InterfaceType && _core(type, 'String');
    final isCollection =
        type is InterfaceType && (type.isDartCoreList || type.isDartCoreSet);
    for (final metadata in declaration.metadata.annotations) {
      final value = metadata.computeConstantValue();
      final valueType = value?.type;
      if (value == null || valueType == null) continue;
      if (_min.isExactlyType(valueType)) {
        _require(declaration, type, '@Min', isNumeric, '@MinLength');
        output = '$output.min(${_number(value, 'value')})';
      } else if (_max.isExactlyType(valueType)) {
        _require(declaration, type, '@Max', isNumeric, '@MaxLength');
        output = '$output.max(${_number(value, 'value')})';
      } else if (_multipleOf.isExactlyType(valueType)) {
        _require(declaration, type, '@MultipleOf', isNumeric, 'numeric field');
        output = '$output.multipleOf(${_number(value, 'value')})';
      } else if (_positive.isExactlyType(valueType)) {
        _require(declaration, type, '@Positive', isNumeric, 'numeric field');
        output = '$output.positive()';
      } else if (_negative.isExactlyType(valueType)) {
        _require(declaration, type, '@Negative', isNumeric, 'numeric field');
        output = '$output.negative()';
      } else if (_minLength.isExactlyType(valueType)) {
        _require(declaration, type, '@MinLength', isString, '@Min');
        output = '$output.minLength(${value.getField('length')!.toIntValue()})';
      } else if (_maxLength.isExactlyType(valueType)) {
        _require(declaration, type, '@MaxLength', isString, '@Max');
        output = '$output.maxLength(${value.getField('length')!.toIntValue()})';
      } else if (_pattern.isExactlyType(valueType)) {
        _require(declaration, type, '@Pattern', isString, 'String field');
        output =
            '$output.matches(${_literal(value.getField('pattern')!.toStringValue()!)})';
      } else if (_email.isExactlyType(valueType)) {
        _require(declaration, type, '@Email', isString, 'String field');
        output = '$output.email()';
      } else if (_url.isExactlyType(valueType)) {
        _require(declaration, type, '@Url', isString, 'String field');
        output = '$output.url()';
      } else if (_uri.isExactlyType(valueType)) {
        _require(declaration, type, '@Uri', isString, 'String field');
        output = '$output.uri()';
      } else if (_uuid.isExactlyType(valueType)) {
        _require(declaration, type, '@Uuid', isString, 'String field');
        output = '$output.uuid()';
      } else if (_date.isExactlyType(valueType)) {
        _require(declaration, type, '@Date', isString, 'String field');
        output = '$output.date()';
      } else if (_dateTime.isExactlyType(valueType)) {
        _require(declaration, type, '@DateTime', isString, 'String field');
        output = '$output.datetime()';
      } else if (_notEmpty.isExactlyType(valueType)) {
        _require(declaration, type, '@NotEmpty', isString, 'String field');
        output = '$output.notEmpty()';
      } else if (_minItems.isExactlyType(valueType)) {
        _require(
          declaration,
          type,
          '@MinItems',
          isCollection,
          'List or Set field',
        );
        output = '$output.minItems(${value.getField('count')!.toIntValue()})';
      } else if (_maxItems.isExactlyType(valueType)) {
        _require(
          declaration,
          type,
          '@MaxItems',
          isCollection,
          'List or Set field',
        );
        output = '$output.maxItems(${value.getField('count')!.toIntValue()})';
      } else if (_uniqueItems.isExactlyType(valueType)) {
        _require(
          declaration,
          type,
          '@UniqueItems',
          isCollection,
          'List or Set field',
        );
        output = '$output.unique()';
      }
    }
    return output;
  }

  /// Adds documentation as an Ack description.
  ///
  /// Analyzer does not attach parameter doc comments to parameter elements.
  /// A function generator passes the comment from its source AST.
  String applyDescription(
    String schema,
    Element declaration, {
    String? sourceComment,
  }) {
    final description = parseDocComment(
      sourceComment ?? declaration.documentationComment,
    );
    return description == null
        ? schema
        : '$schema.describe(${_literal(description)})';
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

  String _ack(String symbol) {
    final prefix = ackPrefix;
    return prefix == null || prefix.isEmpty ? symbol : '$prefix.$symbol';
  }

  String _number(DartObject value, String name) {
    final number = value.getField(name)!;
    return (number.toIntValue() ?? number.toDoubleValue())!.toString();
  }

  String _literal(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll(r'$', r'\$');
    return "'$escaped'";
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
      '${declaration.enclosingElement?.name}.${declaration.name} has '
      '$annotation on ${type.getDisplayString()}; use $alternative instead.',
      element: declaration,
    );
  }
}
