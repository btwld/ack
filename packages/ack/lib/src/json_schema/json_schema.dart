library;

import 'package:meta/meta.dart';
import 'well_known_format.dart';

enum JsonSchemaType { string, number, integer, boolean, array, object, null_ }

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

    // base structural keywords
    if (type != null && type != JsonSchemaType.null_) {
      map['type'] = typeString(type!);
    } else if (type == JsonSchemaType.null_) {
      map['type'] = 'null';
    }

    if (format != null) map['format'] = format;
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (enumValues != null) map['enum'] = enumValues;
    if (items != null) map['items'] = items!.toJson();

    if (properties != null) {
      map['properties'] = {
        for (final e in properties!.entries) e.key: e.value.toJson(),
      };
    }

    if (required != null) map['required'] = required;
    if (propertyOrdering != null) map['propertyOrdering'] = propertyOrdering;

    if (allOf != null) map['allOf'] = allOf!.map((s) => s.toJson()).toList();
    if (anyOf != null) map['anyOf'] = anyOf!.map((s) => s.toJson()).toList();
    if (oneOf != null) map['oneOf'] = oneOf!.map((s) => s.toJson()).toList();

    if (minItems != null) map['minItems'] = minItems;
    if (maxItems != null) map['maxItems'] = maxItems;
    if (minProperties != null) map['minProperties'] = minProperties;
    if (maxProperties != null) map['maxProperties'] = maxProperties;
    if (minLength != null) map['minLength'] = minLength;
    if (maxLength != null) map['maxLength'] = maxLength;
    if (pattern != null) map['pattern'] = pattern;
    if (minimum != null) map['minimum'] = minimum;
    if (maximum != null) map['maximum'] = maximum;
    if (exclusiveMinimum != null) map['exclusiveMinimum'] = exclusiveMinimum;
    if (exclusiveMaximum != null) map['exclusiveMaximum'] = exclusiveMaximum;
    if (multipleOf != null) map['multipleOf'] = multipleOf;
    if (uniqueItems != null) map['uniqueItems'] = uniqueItems;
    if (discriminator != null) map['discriminator'] = discriminator!.toJson();

    if (additionalPropertiesSchema != null) {
      map['additionalProperties'] = additionalPropertiesSchema!.toJson();
    } else if (additionalPropertiesAllowed != null) {
      map['additionalProperties'] = additionalPropertiesAllowed;
    }

    // nullable handling: emit draft-style anyOf with null when appropriate
    if (nullable == true && type != null && map['anyOf'] == null && map['oneOf'] == null) {
      final base = Map<String, Object?>.from(map);
      base.remove('nullable');
      return {
        'anyOf': [base, {'type': 'null'}],
      };
    }

    if (nullable == true && map['anyOf'] != null) {
      final list = List<Object?>.from(map['anyOf'] as List);
      final hasNullBranch = list.any((e) => e is Map && e['type'] == 'null');
      if (!hasNullBranch) list.add({'type': 'null'});
      map['anyOf'] = list;
    }

    map.removeWhere((_, v) => v == null);
    return map;
  }

  factory JsonSchema.fromJson(Map<String, Object?> json) {
    int? parseInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return null;
    }

    num? parseNum(Object? v) => v is num ? v : null;
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
    bool nullableFlag = json['nullable'] as bool? ?? _inferNullable(rawType, json['anyOf']);
    if (rawType is String) {
      type = _typeFromString(rawType);
    } else if (rawType is List) {
      final parsed = rawType
          .map((e) => _typeFromString(e?.toString()))
          .whereType<JsonSchemaType>()
          .toList();

      final containsNull = parsed.contains(JsonSchemaType.null_);
      final nonNullTypes = parsed.where((t) => t != JsonSchemaType.null_).toList();

      if (nonNullTypes.isNotEmpty) {
        type = nonNullTypes.first;
      }

      if (nonNullTypes.length > 1) {
        unionTypes = nonNullTypes.map((t) => JsonSchema(type: t)).toList();
        type = null;
      }

      // If the union was only a single non-null type plus null, treat as nullable
      nullableFlag = nullableFlag || containsNull;
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
      nullable: nullableFlag,
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
    );
  }

  // Compatibility helpers
  List<String>? get enum_ => enumValues?.map((e) => e?.toString() ?? '').toList();
  bool get acceptsNull => nullable == true || (type == JsonSchemaType.null_);
  JsonSchemaType? get singleType => type;
  bool get isEnum => enumValues != null && enumValues!.isNotEmpty;
  bool? get additionalProperties => additionalPropertiesAllowed;
  WellKnownFormat? get wellKnownFormat => WellKnownFormat.fromValue(format);

  bool acceptsType(JsonSchemaType checkType) {
    if (type == null) return false;
    return type == checkType;
  }

  JsonSchema copyWith({
    String? title,
    String? description,
    bool? nullable,
  }) {
    return JsonSchema(
      type: type,
      format: format,
      title: title ?? this.title,
      description: description ?? this.description,
      nullable: nullable ?? this.nullable,
      enumValues: enumValues,
      items: items,
      properties: properties,
      required: required,
      propertyOrdering: propertyOrdering,
      allOf: allOf,
      anyOf: anyOf,
      oneOf: oneOf,
      minItems: minItems,
      maxItems: maxItems,
      minProperties: minProperties,
      maxProperties: maxProperties,
      minLength: minLength,
      maxLength: maxLength,
      pattern: pattern,
      minimum: minimum,
      maximum: maximum,
      multipleOf: multipleOf,
      discriminator: discriminator,
      additionalPropertiesSchema: additionalPropertiesSchema,
      additionalPropertiesAllowed: additionalPropertiesAllowed,
    );
  }
}

String typeString(JsonSchemaType type) => switch (type) {
      JsonSchemaType.string => 'string',
      JsonSchemaType.number => 'number',
      JsonSchemaType.integer => 'integer',
      JsonSchemaType.boolean => 'boolean',
      JsonSchemaType.array => 'array',
      JsonSchemaType.object => 'object',
      JsonSchemaType.null_ => 'null',
    };

JsonSchemaType? _typeFromString(String? raw) {
  if (raw == null) return null;
  return switch (raw) {
    'string' => JsonSchemaType.string,
    'number' => JsonSchemaType.number,
    'integer' => JsonSchemaType.integer,
    'boolean' => JsonSchemaType.boolean,
    'array' => JsonSchemaType.array,
    'object' => JsonSchemaType.object,
    'null' => JsonSchemaType.null_,
    _ => null,
  };
}

bool _inferNullable(Object? rawType, Object? anyOfRaw) {
  if (rawType is List && rawType.map((e) => e.toString()).contains('null')) {
    return true;
  }
  if (anyOfRaw is List) {
    for (final branch in anyOfRaw) {
      if (branch is Map && branch['type'] == 'null') return true;
    }
  }
  return false;
}
