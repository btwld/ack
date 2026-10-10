// ignore_for_file: deprecated_member_use

import 'package:ack/annotations.dart' as annotations;
import 'package:ack/format_annotations.dart' as formats;
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../utils/doc_comment_utils.dart';
import '../utils/string_literal.dart';

/// Infers Ack schema expressions from resolved Dart types and annotations.
///
/// The caller resolves application model types and import prefixes. Ack owns
/// scalar, collection, and constraint inference for each generator.
final class AckSchemaInference {
  const AckSchemaInference({this.ackPrefix});

  final String? ackPrefix;

  static const _validate = TypeChecker.typeNamed(
    annotations.Validate,
    inPackage: 'ack',
  );
  static const _min = TypeChecker.typeNamed(annotations.Min, inPackage: 'ack');
  static const _max = TypeChecker.typeNamed(annotations.Max, inPackage: 'ack');
  static const _multipleOf = TypeChecker.typeNamed(
    annotations.MultipleOf,
    inPackage: 'ack',
  );
  static const _positive = TypeChecker.typeNamed(
    annotations.Positive,
    inPackage: 'ack',
  );
  static const _negative = TypeChecker.typeNamed(
    annotations.Negative,
    inPackage: 'ack',
  );
  static const _minLength = TypeChecker.typeNamed(
    annotations.MinLength,
    inPackage: 'ack',
  );
  static const _maxLength = TypeChecker.typeNamed(
    annotations.MaxLength,
    inPackage: 'ack',
  );
  static const _matches = TypeChecker.typeNamed(
    annotations.Matches,
    inPackage: 'ack',
  );
  static const _email = TypeChecker.typeNamed(
    annotations.Email,
    inPackage: 'ack',
  );
  static const _url = TypeChecker.typeNamed(annotations.Url, inPackage: 'ack');
  static const _uri = TypeChecker.typeNamed(formats.Uri, inPackage: 'ack');
  static const _uuid = TypeChecker.typeNamed(
    annotations.Uuid,
    inPackage: 'ack',
  );
  static const _date = TypeChecker.typeNamed(
    annotations.Date,
    inPackage: 'ack',
  );
  static const _dateTime = TypeChecker.typeNamed(
    formats.DateTime,
    inPackage: 'ack',
  );
  static const _notEmpty = TypeChecker.typeNamed(
    annotations.NotEmpty,
    inPackage: 'ack',
  );
  static const _minItems = TypeChecker.typeNamed(
    annotations.MinItems,
    inPackage: 'ack',
  );
  static const _maxItems = TypeChecker.typeNamed(
    annotations.MaxItems,
    inPackage: 'ack',
  );
  static const _uniqueItems = TypeChecker.typeNamed(
    annotations.UniqueItems,
    inPackage: 'ack',
  );
  static const _ackField = TypeChecker.typeNamed(
    annotations.AckField,
    inPackage: 'ack',
  );

  /// Infers a schema expression for [type].
  ///
  /// [resolveNamed] returns a schema expression for an application type,
  /// including an enum that declares its own schema. Return null when the type
  /// has no supported model contract; an enum then uses `Ack.enumValues`.
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
        _core(type, 'Duration')) {
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
    final isSet = type is InterfaceType && type.isDartCoreSet;
    final setConstraints = <String>[];
    var hasUniqueConstraint = false;

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
      if (value == null || valueType == null) continue;
      if (_validate.isExactlyType(valueType)) {
        final kind = value.getField('kind')!.toStringValue()!;
        switch (kind) {
          case 'min':
            _require(
              declaration,
              type,
              '@Validate.min',
              isNumeric,
              '@Validate.minLength',
            );
            output =
                '$output.min(${_number(declaration, '@Validate.min', value)})';
          case 'max':
            _require(
              declaration,
              type,
              '@Validate.max',
              isNumeric,
              '@Validate.maxLength',
            );
            output =
                '$output.max(${_number(declaration, '@Validate.max', value)})';
          case 'multipleOf':
            _require(
              declaration,
              type,
              '@Validate.multipleOf',
              isNumeric,
              'numeric field',
            );
            output =
                '$output.multipleOf(${_number(declaration, '@Validate.multipleOf', value)})';
          case 'positive':
            _require(
              declaration,
              type,
              '@Validate.positive',
              isNumeric,
              'numeric field',
            );
            output = '$output.positive()';
          case 'negative':
            _require(
              declaration,
              type,
              '@Validate.negative',
              isNumeric,
              'numeric field',
            );
            output = '$output.negative()';
          case 'minLength':
            _require(
              declaration,
              type,
              '@Validate.minLength',
              isString,
              '@Validate.min',
            );
            output =
                '$output.minLength(${value.getField('value')!.toIntValue()})';
          case 'maxLength':
            _require(
              declaration,
              type,
              '@Validate.maxLength',
              isString,
              '@Validate.max',
            );
            output =
                '$output.maxLength(${value.getField('value')!.toIntValue()})';
          case 'matches':
            _require(
              declaration,
              type,
              '@Validate.matches',
              isString,
              'String field',
            );
            output =
                '$output.matches(${dartStringLiteral(value.getField('value')!.toStringValue()!)})';
          case 'notEmpty':
            _require(
              declaration,
              type,
              '@Validate.notEmpty',
              isString,
              'String field',
            );
            output = '$output.notEmpty()';
          case 'email':
            _require(
              declaration,
              type,
              '@Validate.email',
              isString,
              'String field',
            );
            output = '$output.email()';
          case 'url':
            _require(
              declaration,
              type,
              '@Validate.url',
              isString,
              'String field',
            );
            output = '$output.url()';
          case 'uri':
            _require(
              declaration,
              type,
              '@Validate.uri',
              isString,
              'String field',
            );
            output = '$output.uri()';
          case 'uuid':
            _require(
              declaration,
              type,
              '@Validate.uuid',
              isString,
              'String field',
            );
            output = '$output.uuid()';
          case 'date':
            _require(
              declaration,
              type,
              '@Validate.date',
              isString,
              'String field',
            );
            output = '$output.date()';
          case 'dateTime' || 'datetime':
            _require(
              declaration,
              type,
              '@Validate.$kind',
              isString,
              'String field',
            );
            output = '$output.datetime()';
          case 'ip':
            _require(
              declaration,
              type,
              '@Validate.ip',
              isString,
              'String field',
            );
            final version = value.getField('value')?.toIntValue();
            if (version != null) {
              if (version != 4 && version != 6) {
                throw InvalidGenerationSource(
                  '${_qualifiedName(declaration)} has @Validate.ip(version: '
                  '$version); version must be 4 or 6.',
                  element: declaration,
                );
              }
              output = '$output.ip(version: $version)';
            } else {
              output = '$output.ip()';
            }
          case 'ipv4':
            _require(
              declaration,
              type,
              '@Validate.ipv4',
              isString,
              'String field',
            );
            output = '$output.ipv4()';
          case 'ipv6':
            _require(
              declaration,
              type,
              '@Validate.ipv6',
              isString,
              'String field',
            );
            output = '$output.ipv6()';
          case 'minItems':
            _require(
              declaration,
              type,
              '@Validate.minItems',
              isCollection,
              'List or Set field',
            );
            addCollectionConstraint(
              '.minItems(${value.getField('value')!.toIntValue()})',
            );
          case 'maxItems':
            _require(
              declaration,
              type,
              '@Validate.maxItems',
              isCollection,
              'List or Set field',
            );
            addCollectionConstraint(
              '.maxItems(${value.getField('value')!.toIntValue()})',
            );
          case 'uniqueItems' || 'unique':
            _require(
              declaration,
              type,
              '@Validate.$kind',
              isCollection,
              'List or Set field',
            );
            addCollectionConstraint('.unique()', isUnique: true);
        }
      } else if (_min.isExactlyType(valueType)) {
        _require(declaration, type, '@Min', isNumeric, '@MinLength');
        output = '$output.min(${_number(declaration, '@Min', value)})';
      } else if (_max.isExactlyType(valueType)) {
        _require(declaration, type, '@Max', isNumeric, '@MaxLength');
        output = '$output.max(${_number(declaration, '@Max', value)})';
      } else if (_multipleOf.isExactlyType(valueType)) {
        _require(declaration, type, '@MultipleOf', isNumeric, 'numeric field');
        output =
            '$output.multipleOf(${_number(declaration, '@MultipleOf', value)})';
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
      } else if (_matches.isExactlyType(valueType)) {
        _require(declaration, type, '@Matches', isString, 'String field');
        output =
            '$output.matches(${dartStringLiteral(value.getField('pattern')!.toStringValue()!)})';
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
        addCollectionConstraint(
          '.minItems(${value.getField('count')!.toIntValue()})',
        );
      } else if (_maxItems.isExactlyType(valueType)) {
        _require(
          declaration,
          type,
          '@MaxItems',
          isCollection,
          'List or Set field',
        );
        addCollectionConstraint(
          '.maxItems(${value.getField('count')!.toIntValue()})',
        );
      } else if (_uniqueItems.isExactlyType(valueType)) {
        _require(
          declaration,
          type,
          '@UniqueItems',
          isCollection,
          'List or Set field',
        );
        addCollectionConstraint('.unique()', isUnique: true);
      }
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

  /// Adds an explicit Ack description or a tagged documentation description.
  ///
  /// Analyzer does not attach parameter doc comments to parameter elements.
  /// A function generator passes the comment from its source AST.
  String applyDescription(
    String schema,
    Element declaration, {
    String? sourceComment,
  }) {
    final String? tag;
    try {
      tag = parseDescriptionTag(
        sourceComment ?? declaration.documentationComment,
      );
    } on FormatException catch (error) {
      throw InvalidGenerationSource(
        '${declaration.name} ${error.message}',
        element: declaration,
      );
    }
    final annotation = _ackField.firstAnnotationOfExact(declaration);
    final value = annotation == null
        ? null
        : ConstantReader(annotation).read('description');
    final explicit = value == null || value.isNull ? null : value.stringValue;
    if (explicit != null && explicit.trim().isEmpty) {
      throw InvalidGenerationSource(
        '${declaration.name} @AckField.description must not be blank.',
        element: declaration,
      );
    }
    final description = explicit ?? tag;
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

  String _ack(String symbol) {
    final prefix = ackPrefix;
    return prefix == null || prefix.isEmpty ? symbol : '$prefix.$symbol';
  }

  String _number(Element declaration, String annotation, DartObject value) {
    final field = value.getField('value')!;
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
