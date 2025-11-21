library;

import 'package:meta/meta.dart';

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
  final JsonSchemaDiscriminator? discriminator;
  final bool? uniqueItems;
  final JsonSchema? additionalPropertiesSchema;
  final bool? additionalPropertiesAllowed;

  Map<String, Object?> toJson() {
    return {
      if (type != null && type != JsonSchemaType.null_) 'type': typeString(type!),
      if (type == JsonSchemaType.null_) 'type': 'null',
      if (format != null) 'format': format,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (nullable != null) 'nullable': nullable,
      if (enumValues != null) 'enum': enumValues,
      if (items != null) 'items': items!.toJson(),
      if (properties != null)
        'properties': {
          for (final e in properties!.entries) e.key: e.value.toJson(),
        },
      if (required != null) 'required': required,
      if (propertyOrdering != null) 'propertyOrdering': propertyOrdering,
      if (anyOf != null) 'anyOf': anyOf!.map((s) => s.toJson()).toList(),
      if (oneOf != null) 'oneOf': oneOf!.map((s) => s.toJson()).toList(),
      if (minItems != null) 'minItems': minItems,
      if (maxItems != null) 'maxItems': maxItems,
      if (minProperties != null) 'minProperties': minProperties,
      if (maxProperties != null) 'maxProperties': maxProperties,
      if (minLength != null) 'minLength': minLength,
      if (maxLength != null) 'maxLength': maxLength,
      if (pattern != null) 'pattern': pattern,
      if (minimum != null) 'minimum': minimum,
      if (maximum != null) 'maximum': maximum,
      if (exclusiveMinimum != null) 'exclusiveMinimum': exclusiveMinimum,
      if (exclusiveMaximum != null) 'exclusiveMaximum': exclusiveMaximum,
      if (uniqueItems != null) 'uniqueItems': uniqueItems,
      if (discriminator != null) 'discriminator': discriminator!.toJson(),
      if (additionalPropertiesSchema != null)
        'additionalProperties': additionalPropertiesSchema!.toJson()
      else if (additionalPropertiesAllowed != null)
        'additionalProperties': additionalPropertiesAllowed,
    }..removeWhere((_, v) => v == null);
  }

  factory JsonSchema.fromJson(Map<String, Object?> json) {
    JsonSchema? parseSchema(Object? raw) {
      if (raw is Map) return JsonSchema.fromJson(Map<String, Object?>.from(raw));
      return null;
    }

    List<JsonSchema>? parseList(Object? raw) {
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((m) => JsonSchema.fromJson(Map<String, Object?>.from(m)))
            .toList();
      }
      return null;
    }

    final rawType = json['type'];
    JsonSchemaType? type;
    if (rawType is String) {
      type = _typeFromString(rawType);
    } else if (rawType is List) {
      // If union includes null, mark nullable and pick first non-null type if available
      final types = rawType.cast<String?>();
      final parsed = types.map(_typeFromString).whereType<JsonSchemaType>().toList();
      if (parsed.contains(JsonSchemaType.null_)) {
        // Keep nullable flag; choose first non-null as type
        final firstNonNull = parsed.firstWhere(
          (t) => t != JsonSchemaType.null_,
          orElse: () => JsonSchemaType.object,
        );
        type = firstNonNull;
      } else if (parsed.isNotEmpty) {
        type = parsed.first;
      }
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
      nullable: json['nullable'] as bool? ?? _inferNullable(rawType, json['anyOf']),
      enumValues: (json['enum'] as List?)?.cast<Object?>(),
      items: parseSchema(json['items']),
      properties: properties,
      required: (json['required'] as List?)?.map((e) => e.toString()).toList(),
      propertyOrdering: (json['propertyOrdering'] as List?)?.map((e) => e.toString()).toList(),
      anyOf: parseList(json['anyOf']),
      oneOf: parseList(json['oneOf']),
      minItems: json['minItems'] as int?,
      maxItems: json['maxItems'] as int?,
      minProperties: json['minProperties'] as int?,
      maxProperties: json['maxProperties'] as int?,
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      pattern: json['pattern'] as String?,
      minimum: json['minimum'] as num?,
      maximum: json['maximum'] as num?,
      exclusiveMinimum: json['exclusiveMinimum'] as num?,
      exclusiveMaximum: json['exclusiveMaximum'] as num?,
      uniqueItems: json['uniqueItems'] as bool?,
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
  String? get wellKnownFormat => format;

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
