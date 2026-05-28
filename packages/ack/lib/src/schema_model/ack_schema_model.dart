import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

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

    return switch (_rebuildWithCommon(common)) {
      AckStringSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      AckIntegerSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      AckNumberSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      AckBooleanSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      AckArraySchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      AckObjectSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      AckAnyOfSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      AckOneOfSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      AckAllOfSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      AckNullSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      AckRefSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
    };
  }

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
    final branches = schemas.map((schema) => schema.toJsonSchema()).toList();
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
  Map<String, Object?> toJsonSchema() =>
      finishTypeJson({r'$ref': '#/definitions/${_jsonPointerToken(refName)}'});

  @override
  AckRefSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckRefSchemaModel._(common, refName: refName);

  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    return _withUnhandledKeywords(keywords, commonHandled);
  }
}

final class AckStringSchemaModel extends AckSchemaModel {
  const AckStringSchemaModel({
    this.format,
    this.enumValues,
    this.constValue,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.formatMinimum,
    this.formatMaximum,
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
    this.formatMinimum,
    this.formatMaximum,
  }) : super._(common);

  @override
  final String? format;
  final List<Object?>? enumValues;
  final String? constValue;
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final String? formatMinimum;
  final String? formatMaximum;

  @override
  Object? get _metadataEquality => {
    if (formatMinimum != null) 'formatMinimum': formatMinimum,
    if (formatMaximum != null) 'formatMaximum': formatMaximum,
  };

  List<String>? get allowedStringValues {
    if (constValue case final value?) return [value];
    final values = enumValues;
    if (values == null || values.isEmpty) return null;
    return values.map((value) => value.toString()).toList();
  }

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
        formatMinimum: formatMinimum,
        formatMaximum: formatMaximum,
      );

  AckStringSchemaModel _copyWith({
    String? format,
    List<Object?>? enumValues,
    Object? constValue = _unset,
    int? minLength,
    int? maxLength,
    String? pattern,
    String? formatMinimum,
    String? formatMaximum,
  }) {
    return AckStringSchemaModel._(
      _common,
      format: format ?? this.format,
      enumValues: enumValues ?? this.enumValues,
      constValue: identical(constValue, _unset)
          ? this.constValue
          : constValue as String?,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      pattern: pattern ?? this.pattern,
      formatMinimum: formatMinimum ?? this.formatMinimum,
      formatMaximum: formatMaximum ?? this.formatMaximum,
    );
  }

  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    final handled = {...commonHandled};
    var next = this;

    if (keywords['format'] case final String value) {
      handled.add('format');
      next = next._copyWith(format: value);
    }
    if (keywords['enum'] case final List values) {
      handled.add('enum');
      next = next._copyWith(enumValues: List<Object?>.from(values));
    }
    if (keywords['const'] case final String value) {
      handled.add('const');
      next = next._copyWith(constValue: value);
    }
    if (_readIntKeyword(keywords, 'minLength') case final value?) {
      handled.add('minLength');
      next = next._copyWith(minLength: value);
    }
    if (_readIntKeyword(keywords, 'maxLength') case final value?) {
      handled.add('maxLength');
      next = next._copyWith(maxLength: value);
    }
    if (keywords['pattern'] case final String value) {
      handled.add('pattern');
      next = next._copyWith(pattern: value);
    }
    if (keywords['formatMinimum'] case final String value) {
      handled.add('formatMinimum');
      next = next._copyWith(formatMinimum: value);
    }
    if (keywords['formatMaximum'] case final String value) {
      handled.add('formatMaximum');
      next = next._copyWith(formatMaximum: value);
    }

    return next._withUnhandledKeywords(keywords, handled);
  }
}

final class AckIntegerSchemaModel extends AckSchemaModel {
  const AckIntegerSchemaModel({
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

  AckIntegerSchemaModel._(
    _AckSchemaModelCommon common, {
    this.format,
    this.constValue,
    this.minimum,
    this.maximum,
    this.exclusiveMinimum,
    this.exclusiveMaximum,
    this.multipleOf,
  }) : super._(common);

  @override
  final String? format;
  final int? constValue;
  final num? minimum;
  final num? maximum;
  final num? exclusiveMinimum;
  final num? exclusiveMaximum;
  final num? multipleOf;

  @override
  Map<String, Object?> toJsonSchema() => finishTypeJson({
    'type': 'integer',
    if (format != null) 'format': format,
    if (constValue != null) 'const': constValue,
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
    if (exclusiveMinimum != null) 'exclusiveMinimum': exclusiveMinimum,
    if (exclusiveMaximum != null) 'exclusiveMaximum': exclusiveMaximum,
    if (multipleOf != null) 'multipleOf': multipleOf,
  });

  @override
  AckIntegerSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckIntegerSchemaModel._(
        common,
        format: format,
        constValue: constValue,
        minimum: minimum,
        maximum: maximum,
        exclusiveMinimum: exclusiveMinimum,
        exclusiveMaximum: exclusiveMaximum,
        multipleOf: multipleOf,
      );

  AckIntegerSchemaModel _copyWith({
    String? format,
    Object? constValue = _unset,
    num? minimum,
    num? maximum,
    num? exclusiveMinimum,
    num? exclusiveMaximum,
    num? multipleOf,
  }) {
    return AckIntegerSchemaModel._(
      _common,
      format: format ?? this.format,
      constValue: identical(constValue, _unset)
          ? this.constValue
          : constValue as int?,
      minimum: minimum ?? this.minimum,
      maximum: maximum ?? this.maximum,
      exclusiveMinimum: exclusiveMinimum ?? this.exclusiveMinimum,
      exclusiveMaximum: exclusiveMaximum ?? this.exclusiveMaximum,
      multipleOf: multipleOf ?? this.multipleOf,
    );
  }

  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    final handled = {...commonHandled};
    var next = this;

    if (keywords['format'] case final String value) {
      handled.add('format');
      next = next._copyWith(format: value);
    }
    if (keywords['const'] case final int value) {
      handled.add('const');
      next = next._copyWith(constValue: value);
    }
    if (_readNumKeyword(keywords, 'minimum') case final value?) {
      handled.add('minimum');
      next = next._copyWith(minimum: value);
    }
    if (_readNumKeyword(keywords, 'maximum') case final value?) {
      handled.add('maximum');
      next = next._copyWith(maximum: value);
    }
    if (_readNumKeyword(keywords, 'exclusiveMinimum') case final value?) {
      handled.add('exclusiveMinimum');
      next = next._copyWith(exclusiveMinimum: value);
    }
    if (_readNumKeyword(keywords, 'exclusiveMaximum') case final value?) {
      handled.add('exclusiveMaximum');
      next = next._copyWith(exclusiveMaximum: value);
    }
    if (_readNumKeyword(keywords, 'multipleOf') case final value?) {
      handled.add('multipleOf');
      next = next._copyWith(multipleOf: value);
    }

    return next._withUnhandledKeywords(keywords, handled);
  }
}

final class AckNumberSchemaModel extends AckSchemaModel {
  const AckNumberSchemaModel({
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

  AckNumberSchemaModel._(
    _AckSchemaModelCommon common, {
    this.format,
    this.constValue,
    this.minimum,
    this.maximum,
    this.exclusiveMinimum,
    this.exclusiveMaximum,
    this.multipleOf,
  }) : super._(common);

  @override
  final String? format;
  final num? constValue;
  final num? minimum;
  final num? maximum;
  final num? exclusiveMinimum;
  final num? exclusiveMaximum;
  final num? multipleOf;

  @override
  Map<String, Object?> toJsonSchema() => finishTypeJson({
    'type': 'number',
    if (format != null) 'format': format,
    if (constValue != null) 'const': constValue,
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
    if (exclusiveMinimum != null) 'exclusiveMinimum': exclusiveMinimum,
    if (exclusiveMaximum != null) 'exclusiveMaximum': exclusiveMaximum,
    if (multipleOf != null) 'multipleOf': multipleOf,
  });

  @override
  AckNumberSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckNumberSchemaModel._(
        common,
        format: format,
        constValue: constValue,
        minimum: minimum,
        maximum: maximum,
        exclusiveMinimum: exclusiveMinimum,
        exclusiveMaximum: exclusiveMaximum,
        multipleOf: multipleOf,
      );

  AckNumberSchemaModel _copyWith({
    String? format,
    Object? constValue = _unset,
    num? minimum,
    num? maximum,
    num? exclusiveMinimum,
    num? exclusiveMaximum,
    num? multipleOf,
  }) {
    return AckNumberSchemaModel._(
      _common,
      format: format ?? this.format,
      constValue: identical(constValue, _unset)
          ? this.constValue
          : constValue as num?,
      minimum: minimum ?? this.minimum,
      maximum: maximum ?? this.maximum,
      exclusiveMinimum: exclusiveMinimum ?? this.exclusiveMinimum,
      exclusiveMaximum: exclusiveMaximum ?? this.exclusiveMaximum,
      multipleOf: multipleOf ?? this.multipleOf,
    );
  }

  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    final handled = {...commonHandled};
    var next = this;

    if (keywords['format'] case final String value) {
      handled.add('format');
      next = next._copyWith(format: value);
    }
    if (keywords['const'] case final num value) {
      handled.add('const');
      next = next._copyWith(constValue: value);
    }
    if (_readNumKeyword(keywords, 'minimum') case final value?) {
      handled.add('minimum');
      next = next._copyWith(minimum: value);
    }
    if (_readNumKeyword(keywords, 'maximum') case final value?) {
      handled.add('maximum');
      next = next._copyWith(maximum: value);
    }
    if (_readNumKeyword(keywords, 'exclusiveMinimum') case final value?) {
      handled.add('exclusiveMinimum');
      next = next._copyWith(exclusiveMinimum: value);
    }
    if (_readNumKeyword(keywords, 'exclusiveMaximum') case final value?) {
      handled.add('exclusiveMaximum');
      next = next._copyWith(exclusiveMaximum: value);
    }
    if (_readNumKeyword(keywords, 'multipleOf') case final value?) {
      handled.add('multipleOf');
      next = next._copyWith(multipleOf: value);
    }

    return next._withUnhandledKeywords(keywords, handled);
  }
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

  AckArraySchemaModel _copyWith({
    AckSchemaModel? items,
    int? minItems,
    int? maxItems,
    bool? uniqueItems,
  }) {
    return AckArraySchemaModel._(
      _common,
      items: items ?? this.items,
      minItems: minItems ?? this.minItems,
      maxItems: maxItems ?? this.maxItems,
      uniqueItems: uniqueItems ?? this.uniqueItems,
    );
  }

  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    final handled = {...commonHandled};
    var next = this;

    if (_readIntKeyword(keywords, 'minItems') case final value?) {
      handled.add('minItems');
      next = next._copyWith(minItems: value);
    }
    if (_readIntKeyword(keywords, 'maxItems') case final value?) {
      handled.add('maxItems');
      next = next._copyWith(maxItems: value);
    }
    if (keywords['uniqueItems'] case final bool value) {
      handled.add('uniqueItems');
      next = next._copyWith(uniqueItems: value);
    }

    return next._withUnhandledKeywords(keywords, handled);
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

  AckObjectSchemaModel _copyWith({
    Map<String, AckSchemaModel>? properties,
    List<String>? required,
    List<String>? propertyOrdering,
    int? minProperties,
    int? maxProperties,
    AckAdditionalPropertiesModel? additionalProperties,
  }) {
    return AckObjectSchemaModel._(
      _common,
      properties: properties ?? this.properties,
      required: required ?? this.required,
      propertyOrdering: propertyOrdering ?? this.propertyOrdering,
      minProperties: minProperties ?? this.minProperties,
      maxProperties: maxProperties ?? this.maxProperties,
      additionalProperties: additionalProperties ?? this.additionalProperties,
    );
  }

  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    final handled = {...commonHandled};
    var next = this;

    if (_readIntKeyword(keywords, 'minProperties') case final value?) {
      handled.add('minProperties');
      next = next._copyWith(minProperties: value);
    }
    if (_readIntKeyword(keywords, 'maxProperties') case final value?) {
      handled.add('maxProperties');
      next = next._copyWith(maxProperties: value);
    }
    if (keywords['additionalProperties'] case final bool value) {
      handled.add('additionalProperties');
      next = next._copyWith(
        additionalProperties: value
            ? const AckAdditionalPropertiesAllowed()
            : const AckAdditionalPropertiesDisallowed(),
      );
    }

    return next._withUnhandledKeywords(keywords, handled);
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

  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    return _withUnhandledKeywords(keywords, commonHandled);
  }
}

final class AckAnyOfSchemaModel extends AckSchemaModel {
  const AckAnyOfSchemaModel({
    required this.schemas,
    this.discriminator,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AckAnyOfSchemaModel._(
    _AckSchemaModelCommon common, {
    required this.schemas,
    this.discriminator,
  }) : super._(common);

  final List<AckSchemaModel> schemas;
  final AckSchemaDiscriminatorModel? discriminator;

  @override
  Object? get _metadataEquality => {
    if (discriminator != null) 'discriminator': discriminator,
  };

  @override
  Map<String, Object?> toJsonSchema() =>
      finishCompositionJson('anyOf', schemas);

  @override
  AckAnyOfSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckAnyOfSchemaModel._(
        common,
        schemas: schemas,
        discriminator: discriminator,
      );

  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    return _withUnhandledKeywords(keywords, commonHandled);
  }
}

final class AckOneOfSchemaModel extends AckSchemaModel {
  const AckOneOfSchemaModel({
    required this.schemas,
    this.discriminator,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AckOneOfSchemaModel._(
    _AckSchemaModelCommon common, {
    required this.schemas,
    this.discriminator,
  }) : super._(common);

  final List<AckSchemaModel> schemas;
  final AckSchemaDiscriminatorModel? discriminator;

  @override
  Object? get _metadataEquality => {
    if (discriminator != null) 'discriminator': discriminator,
  };

  @override
  Map<String, Object?> toJsonSchema() =>
      finishCompositionJson('oneOf', schemas);

  @override
  AckOneOfSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckOneOfSchemaModel._(
        common,
        schemas: schemas,
        discriminator: discriminator,
      );

  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    return _withUnhandledKeywords(keywords, commonHandled);
  }
}

final class AckAllOfSchemaModel extends AckSchemaModel {
  const AckAllOfSchemaModel({
    required this.schemas,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AckAllOfSchemaModel._(_AckSchemaModelCommon common, {required this.schemas})
    : super._(common);

  final List<AckSchemaModel> schemas;

  @override
  Map<String, Object?> toJsonSchema() =>
      finishCompositionJson('allOf', schemas);

  @override
  AckAllOfSchemaModel _rebuildWithCommon(_AckSchemaModelCommon common) =>
      AckAllOfSchemaModel._(common, schemas: schemas);

  AckSchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    return _withUnhandledKeywords(keywords, commonHandled);
  }
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

String _jsonPointerToken(String value) {
  return value.replaceAll('~', '~0').replaceAll('/', '~1');
}
