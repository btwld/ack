import 'dart:convert';

import 'package:ack/src/helpers.dart';

/// The definition of an input or output data types.
///
/// These types can be objects, but also primitives and arrays.
/// Represents a select subset of an
/// [OpenAPI 3.0 schema object](https://spec.openapis.org/oas/v3.0.3#schema).
final class Schema {
  /// The type of this value.
  SchemaType type;

  /// The format of the data.
  ///
  /// This is used only for primitive datatypes.
  ///
  /// Supported formats:
  ///  for [SchemaType.number] type: float, double
  ///  for [SchemaType.integer] type: int32, int64
  ///  for [SchemaType.string] type: enum, date-time See [enumValues]
  String? format;

  /// A brief description of the parameter.
  ///
  /// This could contain examples of use.
  /// Parameter description may be formatted as Markdown.
  String? description;

  /// Whether the value mey be null.
  bool? nullable;

  /// Possible values if this is a [SchemaType.string] with an enum format.
  List<String>? enumValues;

  /// Schema for the elements if this is a [SchemaType.array].
  Schema? items;

  /// Properties of this type if this is a [SchemaType.object].
  Map<String, Schema>? properties;

  /// The keys from [properties] for properties that are required if this is a
  /// [SchemaType.object].
  List<String>? requiredProperties;

  // TODO: Add named constructors for the types?
  Schema(
    this.type, {
    this.format,
    this.description,
    this.nullable,
    this.enumValues,
    this.items,
    this.properties,
    this.requiredProperties,
  });

  /// Construct a schema for a String value.
  Schema.string({String? description, bool? nullable})
      : this(SchemaType.string, description: description, nullable: nullable);

  /// Construct a schema for String value with enumerated possible values.
  Schema.enumString({
    required List<String> enumValues,
    String? description,
    bool? nullable,
  }) : this(
          SchemaType.string,
          enumValues: enumValues,
          description: description,
          nullable: nullable,
          format: 'enum',
        );

  /// Construct a schema for a non-integer number.
  ///
  /// The [format] may be "float" or "double".
  Schema.number({String? description, bool? nullable, String? format})
      : this(
          SchemaType.number,
          description: description,
          nullable: nullable,
          format: format,
        );

  /// Construct a schema for an integer number.
  ///
  /// The [format] may be "int32" or "int64".
  Schema.integer({String? description, bool? nullable, String? format})
      : this(
          SchemaType.integer,
          description: description,
          nullable: nullable,
          format: format,
        );

  /// Construct a schema for bool value.
  Schema.boolean({String? description, bool? nullable})
      : this(
          SchemaType.boolean,
          description: description,
          nullable: nullable,
        );

  Schema.dateTime({String? description, bool? nullable})
      : this(
          SchemaType.string,
          description: description,
          nullable: nullable,
          format: 'date-time',
        );

  /// Construct a schema for an array of values with a specified type.
  Schema.array({required Schema items, String? description, bool? nullable})
      : this(
          SchemaType.array,
          description: description,
          nullable: nullable,
          items: items,
        );

  /// Construct a schema for an object with one or more properties.
  Schema.object({
    required Map<String, Schema> properties,
    List<String>? requiredProperties,
    String? description,
    bool? nullable,
  }) : this(
          SchemaType.object,
          properties: properties,
          requiredProperties: requiredProperties,
          description: description,
          nullable: nullable,
        );

  static List<String>? _castListString(dynamic value) {
    final list = value as List<dynamic>?;
    if (list == null) return null;

    return list.cast();
  }

  static Schema fromMap(Map<String, dynamic> map) {
    final properties = map['properties'] as Map<String, dynamic>?;
    final items = map['items'] as Map<String, dynamic>?;

    return Schema(
      SchemaType.fromMap(map['type'] as String),
      format: map['format'] as String?,
      description: map['description'] as String?,
      nullable: map['nullable'] as bool?,
      enumValues: _castListString(map['enum']),
      items: items != null ? fromMap(items) : null,
      properties: properties != null
          ? (properties).map((key, value) =>
              MapEntry(key, fromMap(value as Map<String, dynamic>)))
          : null,
      requiredProperties: _castListString(map['required']),
    );
  }

  static Schema fromJson(String json) {
    return fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  Map<String, Object> toMap() => {
        'type': type.toJson(),
        if (format case final format?) 'format': format,
        if (description case final description?) 'description': description,
        if (nullable case final nullable?) 'nullable': nullable,
        if (enumValues case final enumValues?) 'enum': enumValues,
        if (items case final items?) 'items': items.toMap(),
        if (properties case final properties?)
          'properties': {
            for (final MapEntry(:key, :value) in properties.entries)
              key: value.toMap(),
          },
        if (requiredProperties case final requiredProperties?)
          'required': requiredProperties,
      };

  String toJson() => prettyJson(toMap());

  @override
  String toString() {
    return 'Schema(type: $type'
        '${format != null ? ', format: $format' : ''}'
        '${description != null ? ', description: $description' : ''}'
        '${nullable != null ? ', nullable: $nullable' : ''}'
        '${enumValues?.isNotEmpty == true ? ', enumValues: $enumValues' : ''}'
        '${items != null ? ', items: $items' : ''}'
        '${properties?.isNotEmpty == true ? ', properties: $properties' : ''}'
        '${requiredProperties?.isNotEmpty == true ? ', requiredProperties: $requiredProperties' : ''}'
        ')';
  }
}

/// The value type of a [Schema].
enum SchemaType {
  string,
  number,
  integer,
  boolean,
  array,
  object;

  static SchemaType fromMap(String value) {
    return values.byName(value.toLowerCase());
  }

  String toJson() => switch (this) {
        string => 'string',
        number => 'number',
        integer => 'integer',
        boolean => 'boolean',
        array => 'array',
        object => 'object',
      };
}
