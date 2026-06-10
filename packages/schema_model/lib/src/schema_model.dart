import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'schema_model_warning.dart';

part 'schema_model_parser.dart';

const _unset = Object();
const _nullSchemaJson = <String, Object?>{'type': 'null'};

@immutable
final class SchemaDiscriminatorModel {
  const SchemaDiscriminatorModel({required this.propertyName});

  final String propertyName;

  Map<String, Object?> toJson() => {'propertyName': propertyName};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SchemaDiscriminatorModel) return false;
    return propertyName == other.propertyName;
  }

  @override
  int get hashCode => propertyName.hashCode;
}

@immutable
final class _SchemaModelCommon {
  const _SchemaModelCommon({
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
  final List<SchemaModelWarning> warnings;
  final Map<String, Object?> extensions;

  _SchemaModelCommon copyWith({
    Object? title = _unset,
    Object? description = _unset,
    bool? nullable,
    Object? defaultValue = _unset,
    List<SchemaModelWarning>? warnings,
    Map<String, Object?>? extensions,
  }) {
    return _SchemaModelCommon(
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
sealed class AdditionalPropertiesModel {
  const AdditionalPropertiesModel();

  Object? toJsonSchemaValue();
}

final class AdditionalPropertiesAllowed extends AdditionalPropertiesModel {
  const AdditionalPropertiesAllowed();

  @override
  Object toJsonSchemaValue() => true;
}

final class AdditionalPropertiesDisallowed extends AdditionalPropertiesModel {
  const AdditionalPropertiesDisallowed();

  @override
  Object toJsonSchemaValue() => false;
}

final class AdditionalPropertiesSchema extends AdditionalPropertiesModel {
  const AdditionalPropertiesSchema(this.schema);

  final SchemaModel schema;

  @override
  Map<String, Object?> toJsonSchemaValue() => schema.toJsonSchema();
}

@immutable
sealed class SchemaModel {
  const SchemaModel({
    this.title,
    this.description,
    this.nullable = false,
    this.defaultValue,
    this.warnings = const [],
    this.extensions = const {},
  });

  factory SchemaModel.fromJsonSchema(Map<String, Object?> json) {
    return _JsonSchemaParser().parse(json);
  }

  SchemaModel._(_SchemaModelCommon common)
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
  final List<SchemaModelWarning> warnings;
  final Map<String, Object?> extensions;

  _SchemaModelCommon get _common => _SchemaModelCommon(
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
  SchemaModel _rebuildWithCommon(_SchemaModelCommon common);

  SchemaModel withDescription(String? description) =>
      _rebuildWithCommon(_common.copyWith(description: description));

  SchemaModel withNullable(bool nullable) =>
      _rebuildWithCommon(_common.copyWith(nullable: nullable));

  SchemaModel withDefaultValue(Object? defaultValue) =>
      _rebuildWithCommon(_common.copyWith(defaultValue: defaultValue));

  SchemaModel withWarnings(List<SchemaModelWarning> warnings) =>
      _rebuildWithCommon(_common.copyWith(warnings: warnings));

  SchemaModel withExtensions(Map<String, Object?> extensions) =>
      _rebuildWithCommon(_common.copyWith(extensions: extensions));

  SchemaModel withJsonSchemaKeywords(Map<String, Object?> keywords) {
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
      StringSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      IntegerSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      NumberSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      BooleanSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      ArraySchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      ObjectSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      AnyOfSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      OneOfSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      AllOfSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      NullSchemaModel schema => schema._withJsonSchemaKeywords(
        keywords,
        commonHandled,
      ),
      RefSchemaModel schema => schema._withJsonSchemaKeywords(
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
    List<SchemaModel> schemas,
  ) {
    final branches = schemas.map((schema) => schema.toJsonSchema()).toList();
    if (nullable && !schemas.any((schema) => schema is NullSchemaModel)) {
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

  SchemaModel _withUnhandledKeywords(
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
    if (other is! SchemaModel) return false;
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

final class RefSchemaModel extends SchemaModel {
  const RefSchemaModel({
    required this.refName,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  RefSchemaModel._(super.common, {required this.refName}) : super._();

  final String refName;

  @override
  Map<String, Object?> toJsonSchema() {
    final refJson = {r'$ref': '#/definitions/${_jsonPointerToken(refName)}'};
    if (nullable) return finishTypeJson(refJson);

    final commonJson = _common.toJson();
    if (commonJson.isEmpty) return refJson;

    return {
      ...commonJson,
      'allOf': [refJson],
    };
  }

  @override
  RefSchemaModel _rebuildWithCommon(_SchemaModelCommon common) =>
      RefSchemaModel._(common, refName: refName);

  SchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    return _withUnhandledKeywords(keywords, commonHandled);
  }
}

final class StringSchemaModel extends SchemaModel {
  const StringSchemaModel({
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

  StringSchemaModel._(
    super.common, {
    this.format,
    this.enumValues,
    this.constValue,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.formatMinimum,
    this.formatMaximum,
  }) : super._();

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
  StringSchemaModel _rebuildWithCommon(_SchemaModelCommon common) =>
      StringSchemaModel._(
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

  StringSchemaModel _copyWith({
    String? format,
    List<Object?>? enumValues,
    Object? constValue = _unset,
    int? minLength,
    int? maxLength,
    String? pattern,
    String? formatMinimum,
    String? formatMaximum,
  }) {
    return StringSchemaModel._(
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

  SchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    final handled = {...commonHandled};
    var next = this;

    if (keywords['format'] case final String value) {
      handled.add('format');
      next = next._copyWith(format: value);
    }
    if (keywords['enum'] case final List<Object?> values) {
      handled.add('enum');
      next = next._copyWith(enumValues: values);
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

final class IntegerSchemaModel extends SchemaModel {
  const IntegerSchemaModel({
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

  IntegerSchemaModel._(
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
  IntegerSchemaModel _rebuildWithCommon(_SchemaModelCommon common) =>
      IntegerSchemaModel._(
        common,
        format: format,
        constValue: constValue,
        minimum: minimum,
        maximum: maximum,
        exclusiveMinimum: exclusiveMinimum,
        exclusiveMaximum: exclusiveMaximum,
        multipleOf: multipleOf,
      );

  IntegerSchemaModel _copyWith({
    String? format,
    Object? constValue = _unset,
    num? minimum,
    num? maximum,
    num? exclusiveMinimum,
    num? exclusiveMaximum,
    num? multipleOf,
  }) {
    return IntegerSchemaModel._(
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

  SchemaModel _withJsonSchemaKeywords(
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

final class NumberSchemaModel extends SchemaModel {
  const NumberSchemaModel({
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

  NumberSchemaModel._(
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
  NumberSchemaModel _rebuildWithCommon(_SchemaModelCommon common) =>
      NumberSchemaModel._(
        common,
        format: format,
        constValue: constValue,
        minimum: minimum,
        maximum: maximum,
        exclusiveMinimum: exclusiveMinimum,
        exclusiveMaximum: exclusiveMaximum,
        multipleOf: multipleOf,
      );

  NumberSchemaModel _copyWith({
    String? format,
    Object? constValue = _unset,
    num? minimum,
    num? maximum,
    num? exclusiveMinimum,
    num? exclusiveMaximum,
    num? multipleOf,
  }) {
    return NumberSchemaModel._(
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

  SchemaModel _withJsonSchemaKeywords(
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

final class BooleanSchemaModel extends SchemaModel {
  const BooleanSchemaModel({
    this.constValue,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  BooleanSchemaModel._(super.common, {this.constValue}) : super._();

  final bool? constValue;

  @override
  Map<String, Object?> toJsonSchema() => finishTypeJson({
    'type': 'boolean',
    if (constValue != null) 'const': constValue,
  });

  @override
  BooleanSchemaModel _rebuildWithCommon(_SchemaModelCommon common) =>
      BooleanSchemaModel._(common, constValue: constValue);

  SchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    final handled = {...commonHandled};
    var next = this;
    if (keywords['const'] case final bool value) {
      handled.add('const');
      next = BooleanSchemaModel._(_common, constValue: value);
    }
    return next._withUnhandledKeywords(keywords, handled);
  }
}

final class ArraySchemaModel extends SchemaModel {
  const ArraySchemaModel({
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

  ArraySchemaModel._(
    super.common, {
    this.items,
    this.minItems,
    this.maxItems,
    this.uniqueItems,
  }) : super._();

  final SchemaModel? items;
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
  ArraySchemaModel _rebuildWithCommon(_SchemaModelCommon common) =>
      ArraySchemaModel._(
        common,
        items: items,
        minItems: minItems,
        maxItems: maxItems,
        uniqueItems: uniqueItems,
      );

  ArraySchemaModel _copyWith({
    SchemaModel? items,
    int? minItems,
    int? maxItems,
    bool? uniqueItems,
  }) {
    return ArraySchemaModel._(
      _common,
      items: items ?? this.items,
      minItems: minItems ?? this.minItems,
      maxItems: maxItems ?? this.maxItems,
      uniqueItems: uniqueItems ?? this.uniqueItems,
    );
  }

  SchemaModel _withJsonSchemaKeywords(
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

final class ObjectSchemaModel extends SchemaModel {
  const ObjectSchemaModel({
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

  ObjectSchemaModel._(
    super.common, {
    this.properties,
    this.required,
    this.propertyOrdering,
    this.minProperties,
    this.maxProperties,
    this.additionalProperties,
  }) : super._();

  final Map<String, SchemaModel>? properties;
  final List<String>? required;
  final List<String>? propertyOrdering;
  final int? minProperties;
  final int? maxProperties;
  final AdditionalPropertiesModel? additionalProperties;

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
  ObjectSchemaModel _rebuildWithCommon(_SchemaModelCommon common) =>
      ObjectSchemaModel._(
        common,
        properties: properties,
        required: required,
        propertyOrdering: propertyOrdering,
        minProperties: minProperties,
        maxProperties: maxProperties,
        additionalProperties: additionalProperties,
      );

  ObjectSchemaModel _copyWith({
    Map<String, SchemaModel>? properties,
    List<String>? required,
    List<String>? propertyOrdering,
    int? minProperties,
    int? maxProperties,
    AdditionalPropertiesModel? additionalProperties,
  }) {
    return ObjectSchemaModel._(
      _common,
      properties: properties ?? this.properties,
      required: required ?? this.required,
      propertyOrdering: propertyOrdering ?? this.propertyOrdering,
      minProperties: minProperties ?? this.minProperties,
      maxProperties: maxProperties ?? this.maxProperties,
      additionalProperties: additionalProperties ?? this.additionalProperties,
    );
  }

  SchemaModel _withJsonSchemaKeywords(
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
            ? const AdditionalPropertiesAllowed()
            : const AdditionalPropertiesDisallowed(),
      );
    }

    return next._withUnhandledKeywords(keywords, handled);
  }
}

final class NullSchemaModel extends SchemaModel {
  const NullSchemaModel({
    super.title,
    super.description,
    super.defaultValue,
    super.warnings,
    super.extensions,
  }) : super(nullable: false);

  NullSchemaModel._(super.common) : super._();

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'null', ..._common.toJson()};

  @override
  NullSchemaModel _rebuildWithCommon(_SchemaModelCommon common) =>
      NullSchemaModel._(common.copyWith(nullable: false));

  SchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    return _withUnhandledKeywords(keywords, commonHandled);
  }
}

final class AnyOfSchemaModel extends SchemaModel {
  const AnyOfSchemaModel({
    required this.schemas,
    this.discriminator,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AnyOfSchemaModel._(super.common, {required this.schemas, this.discriminator})
    : super._();

  final List<SchemaModel> schemas;
  final SchemaDiscriminatorModel? discriminator;

  @override
  Object? get _metadataEquality => {
    if (discriminator != null) 'discriminator': discriminator,
  };

  @override
  Map<String, Object?> toJsonSchema() =>
      finishCompositionJson('anyOf', schemas);

  @override
  AnyOfSchemaModel _rebuildWithCommon(_SchemaModelCommon common) =>
      AnyOfSchemaModel._(
        common,
        schemas: schemas,
        discriminator: discriminator,
      );

  SchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    return _withUnhandledKeywords(keywords, commonHandled);
  }
}

final class OneOfSchemaModel extends SchemaModel {
  const OneOfSchemaModel({
    required this.schemas,
    this.discriminator,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  OneOfSchemaModel._(super.common, {required this.schemas, this.discriminator})
    : super._();

  final List<SchemaModel> schemas;
  final SchemaDiscriminatorModel? discriminator;

  @override
  Object? get _metadataEquality => {
    if (discriminator != null) 'discriminator': discriminator,
  };

  @override
  Map<String, Object?> toJsonSchema() =>
      finishCompositionJson('oneOf', schemas);

  @override
  OneOfSchemaModel _rebuildWithCommon(_SchemaModelCommon common) =>
      OneOfSchemaModel._(
        common,
        schemas: schemas,
        discriminator: discriminator,
      );

  SchemaModel _withJsonSchemaKeywords(
    Map<String, Object?> keywords,
    Set<String> commonHandled,
  ) {
    return _withUnhandledKeywords(keywords, commonHandled);
  }
}

final class AllOfSchemaModel extends SchemaModel {
  const AllOfSchemaModel({
    required this.schemas,
    super.title,
    super.description,
    super.nullable,
    super.defaultValue,
    super.warnings,
    super.extensions,
  });

  AllOfSchemaModel._(super.common, {required this.schemas}) : super._();

  final List<SchemaModel> schemas;

  @override
  Map<String, Object?> toJsonSchema() =>
      finishCompositionJson('allOf', schemas);

  @override
  AllOfSchemaModel _rebuildWithCommon(_SchemaModelCommon common) =>
      AllOfSchemaModel._(common, schemas: schemas);

  SchemaModel _withJsonSchemaKeywords(
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
