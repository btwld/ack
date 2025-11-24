library;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'well_known_format.dart';

enum JsonSchemaType {
  string('string'),
  number('number'),
  integer('integer'),
  boolean('boolean'),
  array('array'),
  object('object'),
  null_('null');

  const JsonSchemaType(this.value);
  final String value;

  static JsonSchemaType? fromValue(String? raw) {
    if (raw == null) return null;
    for (final t in JsonSchemaType.values) {
      if (t.value == raw) return t;
    }
    return null;
  }
}

@immutable
class JsonSchemaDiscriminator {
  const JsonSchemaDiscriminator({required this.propertyName, this.mapping});

  final String propertyName;
  final Map<String, String>? mapping;

  Map<String, Object?> toJson() => {
        'propertyName': propertyName,
        if (mapping case final m?) 'mapping': m,
      };

  factory JsonSchemaDiscriminator.fromJson(Map<String, Object?> json) {
    final mapping = json['mapping'];
    return JsonSchemaDiscriminator(
      propertyName: json['propertyName'] as String,
      mapping: mapping is Map
          ? Map<String, String>.fromEntries(
              mapping.entries.map(
                (e) => MapEntry(e.key.toString(), e.value.toString()),
              ),
            )
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JsonSchemaDiscriminator) return false;
    return propertyName == other.propertyName &&
        const MapEquality().equals(mapping, other.mapping);
  }

  @override
  int get hashCode => Object.hash(propertyName, const MapEquality().hash(mapping));
}

@immutable
class JsonSchema {
  const JsonSchema({
    this.type,
    this.format,
    this.title,
    this.description,
    this.nullable,
    this.enumValues,
    this.items,
    this.properties,
    this.required,
    this.propertyOrdering,
    this.allOf,
    this.anyOf,
    this.oneOf,
    this.minItems,
    this.maxItems,
    this.minProperties,
    this.maxProperties,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.minimum,
    this.maximum,
    this.exclusiveMinimum,
    this.exclusiveMaximum,
    this.multipleOf,
    this.discriminator,
    this.uniqueItems,
    this.additionalPropertiesSchema,
    this.additionalPropertiesAllowed,
  })  : assert(
          additionalPropertiesSchema == null || additionalPropertiesAllowed == null,
          'Cannot set both schema and boolean for additionalProperties',
        ),
        assert(
          anyOf == null || oneOf == null,
          'Cannot set both anyOf and oneOf. Choose one composition strategy to avoid ambiguity.',
        );

  final JsonSchemaType? type;
  final String? format;
  final String? title;
  final String? description;
  final bool? nullable;
  final List<Object?>? enumValues;
  final JsonSchema? items;
  final Map<String, JsonSchema>? properties;
  final List<String>? required;
  final List<String>? propertyOrdering;
  final List<JsonSchema>? allOf;
  final List<JsonSchema>? anyOf;
  final List<JsonSchema>? oneOf;
  final int? minItems;
  final int? maxItems;
  final int? minProperties;
  final int? maxProperties;
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final num? minimum;
  final num? maximum;
  final num? exclusiveMinimum;
  final num? exclusiveMaximum;
  final num? multipleOf;
  final JsonSchemaDiscriminator? discriminator;
  final bool? uniqueItems;
  final JsonSchema? additionalPropertiesSchema;
  final bool? additionalPropertiesAllowed;

  Map<String, Object?> toJson() {
    final map = <String, Object?>{};

    void addIfNotNull(String key, Object? value) {
      if (value != null) map[key] = value;
    }

    if (type != null) {
      map['type'] = type!.value;
    }

    addIfNotNull('format', format);
    addIfNotNull('title', title);
    addIfNotNull('description', description);
    addIfNotNull('enum', enumValues);
    addIfNotNull('items', items?.toJson());

    if (properties != null) {
      map['properties'] = properties!.map((k, v) => MapEntry(k, v.toJson()));
    }

    addIfNotNull('required', required);
    addIfNotNull('propertyOrdering', propertyOrdering);

    if (allOf != null) map['allOf'] = allOf!.map((s) => s.toJson()).toList();

    // Helper to check if a composition already contains a null type
    bool compositionHasNull(List<JsonSchema>? schemas) =>
        schemas?.any((s) => s.type == JsonSchemaType.null_) ?? false;

    final nullSchema = {'type': JsonSchemaType.null_.value};

    // Handle anyOf with nullable - add null branch if needed (JSON Schema style)
    if (anyOf != null) {
      final anyOfList = anyOf!.map((s) => s.toJson()).toList();
      if (nullable == true && !compositionHasNull(anyOf)) {
        anyOfList.add(nullSchema);
      }
      map['anyOf'] = anyOfList;
    }

    // Handle oneOf with nullable - add null branch if needed (JSON Schema style)
    if (oneOf != null) {
      final oneOfList = oneOf!.map((s) => s.toJson()).toList();
      if (nullable == true && !compositionHasNull(oneOf)) {
        oneOfList.add(nullSchema);
      }
      map['oneOf'] = oneOfList;
    }

    addIfNotNull('minItems', minItems);
    addIfNotNull('maxItems', maxItems);
    addIfNotNull('minProperties', minProperties);
    addIfNotNull('maxProperties', maxProperties);
    addIfNotNull('minLength', minLength);
    addIfNotNull('maxLength', maxLength);
    addIfNotNull('pattern', pattern);
    addIfNotNull('minimum', minimum);
    addIfNotNull('maximum', maximum);
    addIfNotNull('exclusiveMinimum', exclusiveMinimum);
    addIfNotNull('exclusiveMaximum', exclusiveMaximum);
    addIfNotNull('multipleOf', multipleOf);
    addIfNotNull('uniqueItems', uniqueItems);
    addIfNotNull('discriminator', discriminator?.toJson());

    if (additionalPropertiesSchema != null) {
      map['additionalProperties'] = additionalPropertiesSchema!.toJson();
    } else if (additionalPropertiesAllowed != null) {
      map['additionalProperties'] = additionalPropertiesAllowed;
    }

    // Handle simple type + nullable: wrap in anyOf with null branch
    if (nullable == true && type != null && map['anyOf'] == null && map['oneOf'] == null) {
      final base = Map<String, Object?>.from(map);
      return {
        'anyOf': [
          base,
          nullSchema,
        ],
      };
    }

    return map;
  }

  factory JsonSchema.fromJson(Map<String, Object?> json) {
    int? parseInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    num? parseNum(Object? v) {
      if (v is num) return v;
      if (v is String) return num.tryParse(v);
      return null;
    }

    bool? parseBool(Object? v) => v is bool ? v : null;
    List<Object?>? parseList(Object? raw) => raw is List ? List<Object?>.from(raw) : null;
    List<JsonSchema>? parseSchemaList(Object? raw) {
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((m) => JsonSchema.fromJson(Map<String, Object?>.from(m)))
            .toList();
      }
      return null;
    }
    List<String>? parseStringList(Object? raw) =>
        raw is List ? raw.map((e) => e.toString()).toList() : null;

    JsonSchema? parseSchema(Object? raw) {
      if (raw is Map) return JsonSchema.fromJson(Map<String, Object?>.from(raw));
      return null;
    }

    final rawType = json['type'];
    JsonSchemaType? type;
    List<JsonSchema>? unionTypes;
    bool? nullableFlag = parseBool(json['nullable']);

    if (rawType is String) {
      type = JsonSchemaType.fromValue(rawType);
    } else if (rawType is List) {
      final parsedTypes = rawType.map((e) => e.toString()).toList();
      final hasNull = parsedTypes.contains('null');
      final nonNullTypes = parsedTypes
          .where((t) => t != 'null')
          .map(JsonSchemaType.fromValue)
          .whereType<JsonSchemaType>()
          .toList();

      if (nonNullTypes.length == 1 && hasNull) {
        type = nonNullTypes.first;
        nullableFlag ??= true;
      } else if (nonNullTypes.length == 1 && !hasNull) {
        type = nonNullTypes.first;
      } else {
        unionTypes = [
          ...nonNullTypes.map((t) => JsonSchema(type: t)),
          if (hasNull) const JsonSchema(type: JsonSchemaType.null_),
        ];
        if (hasNull) nullableFlag ??= true;
      }
    }

    if (nullableFlag != true && json['anyOf'] is List) {
      final list = json['anyOf'] as List;
      nullableFlag = list.any((e) => e is Map && e['type'] == 'null');
    }

    final propsRaw = json['properties'];
    final properties = propsRaw is Map
        ? propsRaw.map(
            (k, v) => MapEntry(
              k.toString(),
              JsonSchema.fromJson(Map<String, Object?>.from(v as Map)),
            ),
          )
        : null;

    final rawAddProps = json['additionalProperties'];

    return JsonSchema(
      type: type,
      format: json['format'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      enumValues: parseList(json['enum']),
      items: parseSchema(json['items']),
      properties: properties,
      required: parseStringList(json['required']),
      propertyOrdering: parseStringList(json['propertyOrdering']),
      allOf: parseSchemaList(json['allOf']),
      anyOf: parseSchemaList(json['anyOf']) ?? unionTypes,
      oneOf: parseSchemaList(json['oneOf']),
      minItems: parseInt(json['minItems']),
      maxItems: parseInt(json['maxItems']),
      minProperties: parseInt(json['minProperties']),
      maxProperties: parseInt(json['maxProperties']),
      minLength: parseInt(json['minLength']),
      maxLength: parseInt(json['maxLength']),
      pattern: json['pattern'] as String?,
      minimum: parseNum(json['minimum']),
      maximum: parseNum(json['maximum']),
      exclusiveMinimum: parseNum(json['exclusiveMinimum']),
      exclusiveMaximum: parseNum(json['exclusiveMaximum']),
      multipleOf: parseNum(json['multipleOf']),
      uniqueItems: parseBool(json['uniqueItems']),
      discriminator: json['discriminator'] is Map
          ? JsonSchemaDiscriminator.fromJson(
              Map<String, Object?>.from(json['discriminator'] as Map),
            )
          : null,
      additionalPropertiesSchema: parseSchema(rawAddProps),
      additionalPropertiesAllowed: rawAddProps is bool ? rawAddProps : null,
      nullable: nullableFlag ?? false,
    );
  }

  // Compatibility helpers
  List<String>? get enum_ => enumValues?.map((e) => e?.toString() ?? '').toList();
  bool get acceptsNull =>
      nullable == true ||
      type == JsonSchemaType.null_ ||
      (anyOf?.any((s) => s.type == JsonSchemaType.null_) ?? false) ||
      (oneOf?.any((s) => s.type == JsonSchemaType.null_) ?? false);
  JsonSchemaType? get singleType => type;
  bool get isEnum => enumValues != null && enumValues!.isNotEmpty;
  bool? get additionalProperties => additionalPropertiesAllowed;
  WellKnownFormat? get wellKnownFormat => WellKnownFormat.fromValue(format);

  bool acceptsType(JsonSchemaType checkType) {
    if (type == null) return false;
    return type == checkType;
  }

  JsonSchema copyWith({
    JsonSchemaType? type,
    String? format,
    String? title,
    String? description,
    bool? nullable,
    List<Object?>? enumValues,
    JsonSchema? items,
    Map<String, JsonSchema>? properties,
    List<String>? required,
    List<String>? propertyOrdering,
    List<JsonSchema>? allOf,
    List<JsonSchema>? anyOf,
    List<JsonSchema>? oneOf,
    int? minItems,
    int? maxItems,
    int? minProperties,
    int? maxProperties,
    int? minLength,
    int? maxLength,
    String? pattern,
    num? minimum,
    num? maximum,
    num? exclusiveMinimum,
    num? exclusiveMaximum,
    num? multipleOf,
    JsonSchemaDiscriminator? discriminator,
    bool? uniqueItems,
    JsonSchema? additionalPropertiesSchema,
    bool? additionalPropertiesAllowed,
  }) {
    return JsonSchema(
      type: type ?? this.type,
      format: format ?? this.format,
      title: title ?? this.title,
      description: description ?? this.description,
      nullable: nullable ?? this.nullable,
      enumValues: enumValues ?? this.enumValues,
      items: items ?? this.items,
      properties: properties ?? this.properties,
      required: required ?? this.required,
      propertyOrdering: propertyOrdering ?? this.propertyOrdering,
      allOf: allOf ?? this.allOf,
      anyOf: anyOf ?? this.anyOf,
      oneOf: oneOf ?? this.oneOf,
      minItems: minItems ?? this.minItems,
      maxItems: maxItems ?? this.maxItems,
      minProperties: minProperties ?? this.minProperties,
      maxProperties: maxProperties ?? this.maxProperties,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      pattern: pattern ?? this.pattern,
      minimum: minimum ?? this.minimum,
      maximum: maximum ?? this.maximum,
      exclusiveMinimum: exclusiveMinimum ?? this.exclusiveMinimum,
      exclusiveMaximum: exclusiveMaximum ?? this.exclusiveMaximum,
      multipleOf: multipleOf ?? this.multipleOf,
      discriminator: discriminator ?? this.discriminator,
      uniqueItems: uniqueItems ?? this.uniqueItems,
      additionalPropertiesSchema:
          additionalPropertiesSchema ?? this.additionalPropertiesSchema,
      additionalPropertiesAllowed:
          additionalPropertiesAllowed ?? this.additionalPropertiesAllowed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JsonSchema) return false;

    const deepEq = DeepCollectionEquality();
    return type == other.type &&
        format == other.format &&
        title == other.title &&
        description == other.description &&
        nullable == other.nullable &&
        deepEq.equals(enumValues, other.enumValues) &&
        items == other.items &&
        deepEq.equals(properties, other.properties) &&
        deepEq.equals(required, other.required) &&
        deepEq.equals(propertyOrdering, other.propertyOrdering) &&
        deepEq.equals(allOf, other.allOf) &&
        deepEq.equals(anyOf, other.anyOf) &&
        deepEq.equals(oneOf, other.oneOf) &&
        minItems == other.minItems &&
        maxItems == other.maxItems &&
        minProperties == other.minProperties &&
        maxProperties == other.maxProperties &&
        minLength == other.minLength &&
        maxLength == other.maxLength &&
        pattern == other.pattern &&
        minimum == other.minimum &&
        maximum == other.maximum &&
        exclusiveMinimum == other.exclusiveMinimum &&
        exclusiveMaximum == other.exclusiveMaximum &&
        multipleOf == other.multipleOf &&
        discriminator == other.discriminator &&
        uniqueItems == other.uniqueItems &&
        additionalPropertiesSchema == other.additionalPropertiesSchema &&
        additionalPropertiesAllowed == other.additionalPropertiesAllowed;
  }

  @override
  int get hashCode {
    const deepEq = DeepCollectionEquality();
    return Object.hashAll([
      type,
      format,
      title,
      description,
      nullable,
      deepEq.hash(enumValues),
      items,
      deepEq.hash(properties),
      deepEq.hash(required),
      deepEq.hash(propertyOrdering),
      deepEq.hash(allOf),
      deepEq.hash(anyOf),
      deepEq.hash(oneOf),
      minItems,
      maxItems,
      minProperties,
      maxProperties,
      minLength,
      maxLength,
      pattern,
      minimum,
      maximum,
      exclusiveMinimum,
      exclusiveMaximum,
      multipleOf,
      discriminator,
      uniqueItems,
      additionalPropertiesSchema,
      additionalPropertiesAllowed,
    ]);
  }
}

// Deprecated helpers removed: value-based enum covers string mapping.
