import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../utils/json_utils.dart';
import 'ack_schema_model_warning.dart';

const _unset = Object();
const _nullSchemaJson = <String, Object?>{'type': 'null'};

@immutable
final class AckSchemaDiscriminatorModel {
  const AckSchemaDiscriminatorModel({required this.propertyName});

  final String propertyName;

  Map<String, Object?> toJson() => {'propertyName': propertyName};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AckSchemaDiscriminatorModel) return false;
    return propertyName == other.propertyName;
  }

  @override
  int get hashCode => propertyName.hashCode;
}

@immutable
final class _AckSchemaModelCommon {
  const _AckSchemaModelCommon({
    this.title,
    this.description,
    this.nullable = false,
    this.defaultValue,
    this.warnings = const [],
    this.extensions = const {},
  });

  final String? title;
  final String? description;
  final bool nullable;
  final Object? defaultValue;
  final List<AckSchemaModelWarning> warnings;
  final Map<String, Object?> extensions;

  _AckSchemaModelCommon copyWith({
    Object? title = _unset,
    Object? description = _unset,
    bool? nullable,
    Object? defaultValue = _unset,
    List<AckSchemaModelWarning>? warnings,
    Map<String, Object?>? extensions,
  }) {
    return _AckSchemaModelCommon(
      title: identical(title, _unset) ? this.title : title as String?,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      nullable: nullable ?? this.nullable,
      defaultValue: identical(defaultValue, _unset)
          ? this.defaultValue
          : defaultValue,
      warnings: warnings ?? this.warnings,
      extensions: extensions ?? this.extensions,
    );
  }

  Map<String, Object?> toJson({bool includeDefault = true}) => {
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (includeDefault && defaultValue != null) 'default': defaultValue,
    ...extensions,
  };

  /// User-facing metadata that should be hoisted to the top level when a
  /// schema renders as a nullable wrapper (e.g. `{'description': ..., 'anyOf':
  /// [...]}`). Constraint-derived keywords stay inside the inner branch.
  Map<String, Object?> toHoistedJson() => {
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (defaultValue != null) 'default': defaultValue,
  };

  /// Returns the non-hoistable portion (extensions plus type-specific
  /// keywords flow through here) to embed inside the inner branch.
  Map<String, Object?> toEmbeddedJson() {
    final embedded = {...extensions};
    embedded.remove('definitions');
    return embedded;
  }

  Object? get definitions => extensions['definitions'];
}

@immutable
sealed class AckAdditionalPropertiesModel {
  const AckAdditionalPropertiesModel();

  Object? toJsonSchemaValue();
}

final class AckAdditionalPropertiesAllowed
    extends AckAdditionalPropertiesModel {
  const AckAdditionalPropertiesAllowed();

  @override
  Object toJsonSchemaValue() => true;
}

final class AckAdditionalPropertiesDisallowed
    extends AckAdditionalPropertiesModel {
  const AckAdditionalPropertiesDisallowed();

  @override
  Object toJsonSchemaValue() => false;
}

final class AckAdditionalPropertiesSchema extends AckAdditionalPropertiesModel {
  const AckAdditionalPropertiesSchema(this.schema);

  final AckSchemaModel schema;

  @override
  Map<String, Object?> toJsonSchemaValue() => schema.toJsonSchema();
}

@immutable
sealed class AckSchemaModel {
  const AckSchemaModel({
    this.title,
    this.description,
    this.nullable = false,
    this.defaultValue,
    this.warnings = const [],
    this.extensions = const {},
  });

  AckSchemaModel._(_AckSchemaModelCommon common)
    : title = common.title,
      description = common.description,
      nullable = common.nullable,
      defaultValue = common.defaultValue,
      warnings = common.warnings,
      extensions = common.extensions;

  final String? title;
  final String? description;
  final bool nullable;
  final Object? defaultValue;
  final List<AckSchemaModelWarning> warnings;
  final Map<String, Object?> extensions;

  _AckSchemaModelCommon get _common => _AckSchemaModelCommon(
    title: title,
    description: description,
    nullable: nullable,
    defaultValue: defaultValue,
    warnings: warnings,
    extensions: extensions,
  );

  String? get format => null;

  Map<String, Object?> toJsonSchema();

  Object? get _metadataEquality => null;

  @protected
  AckSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common);

  AckSchemaModel withDescription(String? description) =>
      _rebuildWithCommon(_common.copyWith(description: description));

  AckSchemaModel withNullable(bool nullable) =>
      _rebuildWithCommon(_common.copyWith(nullable: nullable));

  AckSchemaModel withDefaultValue(Object? defaultValue) =>
      _rebuildWithCommon(_common.copyWith(defaultValue: defaultValue));

  AckSchemaModel withWarnings(List<AckSchemaModelWarning> warnings) =>
      _rebuildWithCommon(_common.copyWith(warnings: warnings));

  AckSchemaModel withExtensions(Map<String, Object?> extensions) =>
      _rebuildWithCommon(_common.copyWith(extensions: extensions));

  AckSchemaModel withJsonSchemaKeywords(Map<String, Object?> keywords) {
    final commonHandled = <String>{};
    var common = _common;

    if (keywords.containsKey('title')) {
      commonHandled.add('title');
      if (keywords['title'] case final String value) {
        common = common.copyWith(title: value);
      }
    }
    if (keywords.containsKey('description')) {
      commonHandled.add('description');
      if (keywords['description'] case final String value) {
        common = common.copyWith(description: value);
      }
    }
    if (keywords.containsKey('default')) {
      commonHandled.add('default');
      common = common.copyWith(defaultValue: keywords['default']);
    }

    return _rebuildWithCommon(
      common,
    )._withJsonSchemaKeywords(keywords, commonHandled);
  }

  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) => _withUnhandledKeywords(keywords, commonHandled);

  Map<String, Object?> finishTypeJson(Map<String, Object?> typeJson) {
    if (!nullable) {
      return {...typeJson, ..._common.toJson()};
    }

    // Hoist user-facing metadata (title, description, default) to the top
    // level so generic JSON Schema consumers can find it without descending
    // into anyOf branches. Constraint-derived keywords stay inside the inner
    // branch so consumers see them next to the `type` they constrain.
    return {
      ..._common.toHoistedJson(),
      if (_common.definitions != null) 'definitions': _common.definitions,
      'anyOf': [
        {...typeJson, ..._common.toEmbeddedJson()},
        _nullSchemaJson,
      ],
    };
  }

  Map<String, Object?> finishCompositionJson(
    String keyword,
    List<AckSchemaModel> schemas,
  ) {
    final branches = [
      ...schemas.map((schema) => schema.toJsonSchema()),
      if (keyword == 'allOf')
        if (extensions['allOf'] case final List<Object?> extra) ...extra,
    ];
    if (nullable && !schemas.any((schema) => schema is AckNullSchemaModel)) {
      // Match Zod v4's Draft-7 nullable-union shape: keep the composition as
      // one branch, then add null as the other branch. Flattening would validate
      // the same values but loses the distinction between nullability and the
      // composed union.
      return {
        ..._common.toHoistedJson(),
        if (_common.definitions != null) 'definitions': _common.definitions,
        'anyOf': [
          {..._common.toEmbeddedJson(), keyword: branches},
          _nullSchemaJson,
        ],
      };
    }

    return {..._common.toJson(), keyword: branches};
  }

  AckSchemaModel _withUnhandledKeywords(
    Map<String, Object?> keywords,
    Set<String> handled,
  ) {
    final unhandled = Map<String, Object?>.fromEntries(
      keywords.entries.where((entry) => !handled.contains(entry.key)),
    );
    if (unhandled.isEmpty) return this;
    return withExtensions({...extensions, ...unhandled});
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AckSchemaModel) return false;
    const deepEq = DeepCollectionEquality();
    return runtimeType == other.runtimeType &&
        deepEq.equals(toJsonSchema(), other.toJsonSchema()) &&
        deepEq.equals(_metadataEquality, other._metadataEquality) &&
        deepEq.equals(warnings, other.warnings);
  }

  @override
  int get hashCode {
    const deepEq = DeepCollectionEquality();
    return Object.hash(
      runtimeType,
      deepEq.hash(toJsonSchema()),
      deepEq.hash(_metadataEquality),
      deepEq.hash(warnings),
    );
  }
}

/// A precompiled JSON Schema resource whose 2020-12 keywords must remain
/// attached to their original resource instead of being lowered to Draft 7.
final class AckRawSchemaModel extends AckSchemaModel {
  const AckRawSchemaModel({
    required this.schema,
    Set<Map<String, Object?>> indexedSchemas = const {},
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  }) : _indexedSchemas = indexedSchemas;

  AckRawSchemaModel._(
    _AckSchemaModelCommon common, {
    required this.schema,
    required Set<Map<String, Object?>> indexedSchemas,
  }) : _indexedSchemas = indexedSchemas,
       super._(common);

  final Map<String, Object?> schema;
  final Set<Map<String, Object?>> _indexedSchemas;

  @override
  Map<String, Object?> toJsonSchema() {
    final body = {
      ...schema,
      ..._common.toJson(),
      if (schema['allOf'] case final List<Object?> sourceAllOf)
        if (extensions['allOf'] case final List<Object?> extraAllOf)
          'allOf': [...sourceAllOf, ...extraAllOf],
    };
    if (!nullable) return body;
    const resourceKeywords = {r'$schema', r'$id', r'$defs', 'definitions'};
    final relocated = _relocateRootPointers(
      body,
      Uri.parse(body[r'$id'] as String),
      resourceKeywords,
      _indexedSchemas,
    );
    final resource = <String, Object?>{
      for (final entry in relocated.entries)
        if (resourceKeywords.contains(entry.key)) entry.key: entry.value,
    };
    final assertion = <String, Object?>{
      for (final entry in relocated.entries)
        if (!resourceKeywords.contains(entry.key)) entry.key: entry.value,
    };
    return {
      ...resource,
      'anyOf': [assertion, _nullSchemaJson],
    };
  }

  @override
  AckRawSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckRawSchemaModel._(
        common,
        schema: schema,
        indexedSchemas: _indexedSchemas,
      );
}

Map<String, Object?> _relocateRootPointers(
  Map<String, Object?> source,
  Uri rootUri,
  Set<String> retainedKeywords,
  Set<Map<String, Object?>> indexedSchemas,
) {
  const mapKeywords = {
    r'$defs',
    'definitions',
    'properties',
    'patternProperties',
    'dependentSchemas',
  };
  const childKeywords = {
    'items',
    'additionalProperties',
    'not',
    'contains',
    'propertyNames',
    'if',
    'then',
    'else',
    'unevaluatedProperties',
    'unevaluatedItems',
  };
  const listKeywords = {'anyOf', 'allOf', 'oneOf', 'prefixItems'};

  late Object? Function(Object?, Uri) visit;

  Object? visitExtension(Object? value, Uri base) {
    if (value is Map<String, Object?>) {
      if (indexedSchemas.contains(value)) return visit(value, base);
      return {
        for (final entry in value.entries)
          entry.key: visitExtension(entry.value, base),
      };
    }
    if (value is List) {
      return [for (final item in value) visitExtension(item, base)];
    }
    return value;
  }

  visit = (Object? value, Uri base) {
    if (value is! Map<String, Object?>) return value;
    final declaredId = value[r'$id'];
    var currentBase = base;
    if (declaredId is String) {
      try {
        currentBase = base.resolve(declaredId).removeFragment();
      } on FormatException {
        // Dormant malformed $id values in unreachable definitions remain as-is.
      }
    }
    final rewritten = Map<String, Object?>.from(value);
    for (final key in [r'$ref', r'$dynamicRef']) {
      final reference = rewritten[key];
      if (reference is! String) continue;
      final Uri resolved;
      try {
        resolved = currentBase.resolve(reference);
      } on FormatException {
        // Dormant malformed references are not evaluated by the importer.
        continue;
      }
      final fragment = resolved.fragment;
      if (resolved.removeFragment() != rootUri) continue;
      if (fragment.isEmpty) {
        rewritten[key] = rootUri.replace(fragment: '/anyOf/0').toString();
        continue;
      }
      if (!fragment.startsWith('/')) continue;
      final first = fragment.substring(1).split('/').first;
      if (retainedKeywords.contains(first)) continue;
      rewritten[key] = rootUri
          .replace(fragment: '/anyOf/0$fragment')
          .toString();
    }
    for (final key in mapKeywords) {
      if (rewritten[key] case final Map<String, Object?> children) {
        rewritten[key] = children.map(
          (name, child) => MapEntry(name, visit(child, currentBase)),
        );
      }
    }
    for (final key in childKeywords) {
      if (rewritten.containsKey(key)) {
        rewritten[key] = visit(rewritten[key], currentBase);
      }
    }
    for (final key in listKeywords) {
      if (rewritten[key] case final List children) {
        rewritten[key] = [
          for (final child in children) visit(child, currentBase),
        ];
      }
    }
    for (final key in rewritten.keys.toList(growable: false)) {
      if (mapKeywords.contains(key) ||
          childKeywords.contains(key) ||
          listKeywords.contains(key)) {
        continue;
      }
      rewritten[key] = visitExtension(rewritten[key], currentBase);
    }
    return rewritten;
  };

  return visit(source, rootUri)! as Map<String, Object?>;
}

final class AckRefSchemaModel extends AckSchemaModel {
  const AckRefSchemaModel({
    required this.refName,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AckRefSchemaModel._(_AckSchemaModelCommon common, {required this.refName})
    : super._(common);

  final String refName;

  @override
  Map<String, Object?> toJsonSchema() {
    final refJson = {
      r'$ref': '#/definitions/${escapeJsonPointerToken(refName)}',
    };
    if (nullable) return finishTypeJson(refJson);

    final commonJson = _common.toJson();
    if (commonJson.isEmpty) return refJson;

    return {
      ...commonJson,
      'allOf': [
        refJson,
        if (commonJson['allOf'] case final List<Object?> extra) ...extra,
      ],
    };
  }

  @override
  AckRefSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckRefSchemaModel._(common, refName: refName);
}

final class AckStringSchemaModel extends AckSchemaModel {
  const AckStringSchemaModel({
    this.format,
    this.enumValues,
    this.constValue,
    this.minLength,
    this.maxLength,
    this.pattern,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AckStringSchemaModel._(
    _AckSchemaModelCommon common, {
    this.format,
    this.enumValues,
    this.constValue,
    this.minLength,
    this.maxLength,
    this.pattern,
  }) : super._(common);

  @override
  final String? format;
  final List<Object?>? enumValues;
  final String? constValue;
  final int? minLength;
  final int? maxLength;
  final String? pattern;

  @override
  Map<String, Object?> toJsonSchema() => finishTypeJson({
    'type': 'string',
    if (format != null) 'format': format,
    if (constValue != null) 'const': constValue,
    if (constValue == null && enumValues != null) 'enum': enumValues,
    if (minLength != null) 'minLength': minLength,
    if (maxLength != null) 'maxLength': maxLength,
    if (pattern != null) 'pattern': pattern,
  });

  @override
  AckStringSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckStringSchemaModel._(
        common,
        format: format,
        enumValues: enumValues,
        constValue: constValue,
        minLength: minLength,
        maxLength: maxLength,
        pattern: pattern,
      );

  @override
  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    final handled = {...commonHandled};
    var nextFormat = format;
    var nextEnum = enumValues;
    var nextConst = constValue;
    var nextMinLength = minLength;
    var nextMaxLength = maxLength;
    var nextPattern = pattern;

    if (keywords['format'] case final String value) {
      handled.add('format');
      nextFormat = value;
    }
    if (keywords['enum'] case final List values) {
      handled.add('enum');
      nextEnum = List<Object?>.from(values);
    }
    if (keywords['const'] case final String value) {
      handled.add('const');
      nextConst = value;
    }
    if (_readIntKeyword(keywords, 'minLength') case final value?) {
      handled.add('minLength');
      nextMinLength = value;
    }
    if (_readIntKeyword(keywords, 'maxLength') case final value?) {
      handled.add('maxLength');
      nextMaxLength = value;
    }
    if (keywords['pattern'] case final String value) {
      handled.add('pattern');
      nextPattern = value;
    }

    return AckStringSchemaModel._(
      _common,
      format: nextFormat,
      enumValues: nextEnum,
      constValue: nextConst,
      minLength: nextMinLength,
      maxLength: nextMaxLength,
      pattern: nextPattern,
    )._withUnhandledKeywords(keywords, handled);
  }
}

sealed class _AckNumericSchemaModel<T extends num> extends AckSchemaModel {
  const _AckNumericSchemaModel({
    this.format,
    this.constValue,
    this.minimum,
    this.maximum,
    this.exclusiveMinimum,
    this.exclusiveMaximum,
    this.multipleOf,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  _AckNumericSchemaModel._(
    super.common, {
    this.format,
    this.constValue,
    this.minimum,
    this.maximum,
    this.exclusiveMinimum,
    this.exclusiveMaximum,
    this.multipleOf,
  }) : super._();

  @override
  final String? format;
  final T? constValue;
  final num? minimum;
  final num? maximum;
  final num? exclusiveMinimum;
  final num? exclusiveMaximum;
  final num? multipleOf;

  String get _jsonType;

  _AckNumericSchemaModel<T> _rebuildNumeric(
    _AckSchemaModelCommon common, {
    required String? format,
    required T? constValue,
    required num? minimum,
    required num? maximum,
    required num? exclusiveMinimum,
    required num? exclusiveMaximum,
    required num? multipleOf,
  });

  @override
  Map<String, Object?> toJsonSchema() => finishTypeJson({
    'type': _jsonType,
    if (format != null) 'format': format,
    if (constValue != null) 'const': constValue,
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
    if (exclusiveMinimum != null) 'exclusiveMinimum': exclusiveMinimum,
    if (exclusiveMaximum != null) 'exclusiveMaximum': exclusiveMaximum,
    if (multipleOf != null) 'multipleOf': multipleOf,
  });

  @override
  _AckNumericSchemaModel<T> _rebuildWithCommon(_AckSchemaModelCommon common) =>
      _rebuildNumeric(
        common,
        format: format,
        constValue: constValue,
        minimum: minimum,
        maximum: maximum,
        exclusiveMinimum: exclusiveMinimum,
        exclusiveMaximum: exclusiveMaximum,
        multipleOf: multipleOf,
      );

  @override
  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    final handled = {...commonHandled};
    var nextFormat = format;
    var nextConst = constValue;
    var nextMin = minimum;
    var nextMax = maximum;
    var nextExMin = exclusiveMinimum;
    var nextExMax = exclusiveMaximum;
    var nextMultipleOf = multipleOf;

    if (keywords['format'] case final String value) {
      handled.add('format');
      nextFormat = value;
    }
    if (keywords['const'] case final T value) {
      handled.add('const');
      nextConst = value;
    }
    if (_readNumKeyword(keywords, 'minimum') case final value?) {
      handled.add('minimum');
      nextMin = value;
    }
    if (_readNumKeyword(keywords, 'maximum') case final value?) {
      handled.add('maximum');
      nextMax = value;
    }
    if (_readNumKeyword(keywords, 'exclusiveMinimum') case final value?) {
      handled.add('exclusiveMinimum');
      nextExMin = value;
    }
    if (_readNumKeyword(keywords, 'exclusiveMaximum') case final value?) {
      handled.add('exclusiveMaximum');
      nextExMax = value;
    }
    if (_readNumKeyword(keywords, 'multipleOf') case final value?) {
      handled.add('multipleOf');
      nextMultipleOf = value;
    }

    return _rebuildNumeric(
      _common,
      format: nextFormat,
      constValue: nextConst,
      minimum: nextMin,
      maximum: nextMax,
      exclusiveMinimum: nextExMin,
      exclusiveMaximum: nextExMax,
      multipleOf: nextMultipleOf,
    )._withUnhandledKeywords(keywords, handled);
  }
}

final class AckIntegerSchemaModel extends _AckNumericSchemaModel<int> {
  const AckIntegerSchemaModel({
    super.format,
    super.constValue,
    super.minimum,
    super.maximum,
    super.exclusiveMinimum,
    super.exclusiveMaximum,
    super.multipleOf,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AckIntegerSchemaModel._(
    super.common, {
    super.format,
    super.constValue,
    super.minimum,
    super.maximum,
    super.exclusiveMinimum,
    super.exclusiveMaximum,
    super.multipleOf,
  }) : super._();

  @override
  String get _jsonType => 'integer';

  @override
  AckIntegerSchemaModel _rebuildNumeric(
    _AckSchemaModelCommon common, {
    required String? format,
    required int? constValue,
    required num? minimum,
    required num? maximum,
    required num? exclusiveMinimum,
    required num? exclusiveMaximum,
    required num? multipleOf,
  }) => AckIntegerSchemaModel._(
    common,
    format: format,
    constValue: constValue,
    minimum: minimum,
    maximum: maximum,
    exclusiveMinimum: exclusiveMinimum,
    exclusiveMaximum: exclusiveMaximum,
    multipleOf: multipleOf,
  );
}

final class AckNumberSchemaModel extends _AckNumericSchemaModel<num> {
  const AckNumberSchemaModel({
    super.format,
    super.constValue,
    super.minimum,
    super.maximum,
    super.exclusiveMinimum,
    super.exclusiveMaximum,
    super.multipleOf,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AckNumberSchemaModel._(
    super.common, {
    super.format,
    super.constValue,
    super.minimum,
    super.maximum,
    super.exclusiveMinimum,
    super.exclusiveMaximum,
    super.multipleOf,
  }) : super._();

  @override
  String get _jsonType => 'number';

  @override
  AckNumberSchemaModel _rebuildNumeric(
    _AckSchemaModelCommon common, {
    required String? format,
    required num? constValue,
    required num? minimum,
    required num? maximum,
    required num? exclusiveMinimum,
    required num? exclusiveMaximum,
    required num? multipleOf,
  }) => AckNumberSchemaModel._(
    common,
    format: format,
    constValue: constValue,
    minimum: minimum,
    maximum: maximum,
    exclusiveMinimum: exclusiveMinimum,
    exclusiveMaximum: exclusiveMaximum,
    multipleOf: multipleOf,
  );
}

final class AckBooleanSchemaModel extends AckSchemaModel {
  const AckBooleanSchemaModel({
    this.constValue,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AckBooleanSchemaModel._(_AckSchemaModelCommon common, {this.constValue})
    : super._(common);

  final bool? constValue;

  @override
  Map<String, Object?> toJsonSchema() => finishTypeJson({
    'type': 'boolean',
    if (constValue != null) 'const': constValue,
  });

  @override
  AckBooleanSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckBooleanSchemaModel._(common, constValue: constValue);

  @override
  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    final handled = {...commonHandled};
    var next = this;
    if (keywords['const'] case final bool value) {
      handled.add('const');
      next = AckBooleanSchemaModel._(_common, constValue: value);
    }
    return next._withUnhandledKeywords(keywords, handled);
  }
}

final class AckArraySchemaModel extends AckSchemaModel {
  const AckArraySchemaModel({
    this.items,
    this.minItems,
    this.maxItems,
    this.uniqueItems,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AckArraySchemaModel._(
    _AckSchemaModelCommon common, {
    this.items,
    this.minItems,
    this.maxItems,
    this.uniqueItems,
  }) : super._(common);

  final AckSchemaModel? items;
  final int? minItems;
  final int? maxItems;
  final bool? uniqueItems;

  @override
  Map<String, Object?> toJsonSchema() => finishTypeJson({
    'type': 'array',
    if (items != null) 'items': items!.toJsonSchema(),
    if (minItems != null) 'minItems': minItems,
    if (maxItems != null) 'maxItems': maxItems,
    if (uniqueItems != null) 'uniqueItems': uniqueItems,
  });

  @override
  AckArraySchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckArraySchemaModel._(
        common,
        items: items,
        minItems: minItems,
        maxItems: maxItems,
        uniqueItems: uniqueItems,
      );

  @override
  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    final handled = {...commonHandled};
    var nextMinItems = minItems;
    var nextMaxItems = maxItems;
    var nextUniqueItems = uniqueItems;

    if (_readIntKeyword(keywords, 'minItems') case final value?) {
      handled.add('minItems');
      nextMinItems = value;
    }
    if (_readIntKeyword(keywords, 'maxItems') case final value?) {
      handled.add('maxItems');
      nextMaxItems = value;
    }
    if (keywords['uniqueItems'] case final bool value) {
      handled.add('uniqueItems');
      nextUniqueItems = value;
    }

    return AckArraySchemaModel._(
      _common,
      items: items,
      minItems: nextMinItems,
      maxItems: nextMaxItems,
      uniqueItems: nextUniqueItems,
    )._withUnhandledKeywords(keywords, handled);
  }
}

final class AckObjectSchemaModel extends AckSchemaModel {
  const AckObjectSchemaModel({
    this.properties,
    this.required,
    this.propertyOrdering,
    this.minProperties,
    this.maxProperties,
    this.additionalProperties,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AckObjectSchemaModel._(
    _AckSchemaModelCommon common, {
    this.properties,
    this.required,
    this.propertyOrdering,
    this.minProperties,
    this.maxProperties,
    this.additionalProperties,
  }) : super._(common);

  final Map<String, AckSchemaModel>? properties;
  final List<String>? required;
  final List<String>? propertyOrdering;
  final int? minProperties;
  final int? maxProperties;
  final AckAdditionalPropertiesModel? additionalProperties;

  @override
  Object? get _metadataEquality => {
    if (propertyOrdering != null) 'propertyOrdering': propertyOrdering,
  };

  @override
  Map<String, Object?> toJsonSchema() {
    return finishTypeJson({
      'type': 'object',
      if (properties != null)
        'properties': properties!.map(
          (key, value) => MapEntry(key, value.toJsonSchema()),
        ),
      if (required != null && required!.isNotEmpty) 'required': required,
      if (minProperties != null) 'minProperties': minProperties,
      if (maxProperties != null) 'maxProperties': maxProperties,
      if (additionalProperties != null)
        'additionalProperties': additionalProperties!.toJsonSchemaValue(),
    });
  }

  @override
  AckObjectSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckObjectSchemaModel._(
        common,
        properties: properties,
        required: required,
        propertyOrdering: propertyOrdering,
        minProperties: minProperties,
        maxProperties: maxProperties,
        additionalProperties: additionalProperties,
      );

  @override
  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    final handled = {...commonHandled};
    var nextMinProperties = minProperties;
    var nextMaxProperties = maxProperties;
    var nextAdditionalProperties = additionalProperties;

    if (_readIntKeyword(keywords, 'minProperties') case final value?) {
      handled.add('minProperties');
      nextMinProperties = value;
    }
    if (_readIntKeyword(keywords, 'maxProperties') case final value?) {
      handled.add('maxProperties');
      nextMaxProperties = value;
    }
    if (keywords['additionalProperties'] case final bool value) {
      handled.add('additionalProperties');
      nextAdditionalProperties = value
          ? const AckAdditionalPropertiesAllowed()
          : const AckAdditionalPropertiesDisallowed();
    }

    return AckObjectSchemaModel._(
      _common,
      properties: properties,
      required: required,
      propertyOrdering: propertyOrdering,
      minProperties: nextMinProperties,
      maxProperties: nextMaxProperties,
      additionalProperties: nextAdditionalProperties,
    )._withUnhandledKeywords(keywords, handled);
  }
}

final class AckNullSchemaModel extends AckSchemaModel {
  const AckNullSchemaModel({
    super.title,
    super.description,
    super.defaultValue,
    super.warnings,
    super.extensions,
  }) : super(nullable: false);

  AckNullSchemaModel._(_AckSchemaModelCommon common) : super._(common);

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'null', ..._common.toJson()};

  @override
  AckNullSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckNullSchemaModel._(common.copyWith(nullable: false));
}

sealed class _AckCompositionSchemaModel extends AckSchemaModel {
  const _AckCompositionSchemaModel({
    required this.schemas,
    this.discriminator,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  _AckCompositionSchemaModel._(
    super.common, {
    required this.schemas,
    this.discriminator,
  }) : super._();

  final List<AckSchemaModel> schemas;
  final AckSchemaDiscriminatorModel? discriminator;

  String get _compositionKeyword;

  @override
  Object? get _metadataEquality => {
    if (discriminator != null) 'discriminator': discriminator,
  };

  @override
  Map<String, Object?> toJsonSchema() =>
      finishCompositionJson(_compositionKeyword, schemas);
}

final class AckAnyOfSchemaModel extends _AckCompositionSchemaModel {
  const AckAnyOfSchemaModel({
    required super.schemas,
    super.discriminator,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AckAnyOfSchemaModel._(
    super.common, {
    required super.schemas,
    super.discriminator,
  }) : super._();

  @override
  String get _compositionKeyword => 'anyOf';

  @override
  AckAnyOfSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckAnyOfSchemaModel._(
        common,
        schemas: schemas,
        discriminator: discriminator,
      );
}

final class AckOneOfSchemaModel extends _AckCompositionSchemaModel {
  const AckOneOfSchemaModel({
    required super.schemas,
    super.discriminator,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AckOneOfSchemaModel._(
    super.common, {
    required super.schemas,
    super.discriminator,
  }) : super._();

  @override
  String get _compositionKeyword => 'oneOf';

  @override
  AckOneOfSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckOneOfSchemaModel._(
        common,
        schemas: schemas,
        discriminator: discriminator,
      );
}

final class AckAllOfSchemaModel extends _AckCompositionSchemaModel {
  const AckAllOfSchemaModel({
    required super.schemas,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AckAllOfSchemaModel._(super.common, {required super.schemas}) : super._();

  @override
  String get _compositionKeyword => 'allOf';

  @override
  AckAllOfSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckAllOfSchemaModel._(common, schemas: schemas);
}

int? _readIntKeyword(Map<String, Object?> keywords, String key) {
  final value = keywords[key];
  if (value is int) return value;
  if (value is num) {
    final intValue = value.toInt();
    if (value == intValue) return intValue;
  }
  return null;
}

num? _readNumKeyword(Map<String, Object?> keywords, String key) {
  final value = keywords[key];
  return value is num ? value : null;
}
