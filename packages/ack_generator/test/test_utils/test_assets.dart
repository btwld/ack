/// Test assets for ack_generator tests
/// Provides reusable mock file contents
library;

const metaAssets = {
  'meta|lib/meta_meta.dart': '''
enum TargetKind {
  classType,
  field,
  function,
  getter,
  library,
  method,
  setter,
  topLevelVariable,
  type,
  parameter,
}

class Target {
  final Set<TargetKind> kinds;
  const Target(this.kinds);
}
''',
};

const ackAnnotationsAsset = {
  'ack_annotations|lib/ack_annotations.dart': '''
library ack_annotations;

export 'src/ack_model.dart';
export 'src/ack_field.dart';
export 'src/ack_type.dart';
''',
  'ack_annotations|lib/src/ack_model.dart': '''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class AckModel {
  final String? schemaName;
  final String? description;
  final bool additionalProperties;
  final String? additionalPropertiesField;
  final bool model;
  final String? discriminatedKey;
  final String? discriminatedValue;

  const AckModel({
    this.schemaName,
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.model = false,
    this.discriminatedKey,
    this.discriminatedValue,
  }) : assert(
         discriminatedKey == null || discriminatedValue == null,
         'discriminatedKey and discriminatedValue cannot be used together',
       );
}
''',
  'ack_annotations|lib/src/ack_field.dart': '''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.field})
class AckField {
  final bool required;
  final String? jsonKey;
  final String? description;
  final List<String> constraints;

  const AckField({
    this.required = false,
    this.jsonKey,
    this.description,
    this.constraints = const [],
  });
}
''',
  'ack_annotations|lib/src/ack_type.dart': '''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.topLevelVariable, TargetKind.classType, TargetKind.getter})
class AckType {
  final String? name;
  const AckType({this.name});
}
''',
};

const ackPackageAsset = {
  'ack|lib/ack.dart': '''
library ack;

export 'src/ack.dart';
export 'src/schemas/schema_model.dart';
export 'src/schemas/object_schema.dart';
export 'src/validation/ack_exception.dart';
''',
  'ack|lib/src/ack.dart': '''
class Ack {
  static StringSchema string() => const StringSchema();
  static IntegerSchema integer() => const IntegerSchema();
  static DoubleSchema double() => const DoubleSchema();
  static NumberSchema number() => const NumberSchema();
  static BooleanSchema boolean() => const BooleanSchema();
  static AnySchema any() => const AnySchema();

  static ListSchema<T> list<T>(AckSchema<T> itemSchema) => ListSchema(itemSchema);
  static MapSchema<T> map<T>(AckSchema<T> valueSchema) => MapSchema(valueSchema);
  static ObjectSchema object(
    Map<String, AckSchema> properties, {
    List<String>? required,
    bool additionalProperties = false,
  }) =>
      ObjectSchema(
        properties,
        required: required,
        additionalProperties: additionalProperties,
      );

  static DiscriminatedSchema discriminated({
    required String discriminatorKey,
    required Map<String, AckSchema> schemas,
  }) =>
      DiscriminatedSchema(
        discriminatorKey: discriminatorKey,
        schemas: schemas,
      );
}

abstract class AckSchema<T> {
  Map<String, Object?> toJsonSchema();
}
class StringSchema extends AckSchema<String> {
  const StringSchema();
  StringSchema email() => this;
  StringSchema notEmpty() => this;
  StringSchema minLength(int length) => this;
  StringSchema maxLength(int length) => this;
  StringSchema enumString(List<String> values) => this;
  StringSchema nullable() => this;
  StringSchema optional() => this;
  StringSchema describe(String description) => this;
  StringSchema withDefault(String defaultValue) => this;

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'string'};
}
class IntegerSchema extends AckSchema<int> {
  const IntegerSchema();
  IntegerSchema min(int value) => this;
  IntegerSchema max(int value) => this;
  IntegerSchema positive() => this;
  IntegerSchema nullable() => this;
  IntegerSchema optional() => this;
  IntegerSchema describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'integer'};
}
class DoubleSchema extends AckSchema<double> {
  const DoubleSchema();
  DoubleSchema nullable() => this;
  DoubleSchema optional() => this;
  DoubleSchema describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'number'};
}
class NumberSchema extends AckSchema<num> {
  const NumberSchema();
  NumberSchema nullable() => this;
  NumberSchema optional() => this;
  NumberSchema describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'number'};
}
class BooleanSchema extends AckSchema<bool> {
  const BooleanSchema();
  BooleanSchema nullable() => this;
  BooleanSchema optional() => this;
  BooleanSchema describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'boolean'};
}
class AnySchema extends AckSchema<dynamic> {
  const AnySchema();
  AnySchema nullable() => this;
  AnySchema optional() => this;

  @override
  Map<String, Object?> toJsonSchema() => {};
}
class ListSchema<T> extends AckSchema<List<T>> {
  final AckSchema<T> itemSchema;
  const ListSchema(this.itemSchema);
  ListSchema<T> nullable() => this;
  ListSchema<T> optional() => this;
  ListSchema<T> unique() => this;
  ListSchema<T> describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => {
    'type': 'array',
    'items': itemSchema.toJsonSchema(),
  };
}
class MapSchema<T> extends AckSchema<Map<String, T>> {
  final AckSchema<T> valueSchema;
  const MapSchema(this.valueSchema);
  MapSchema<T> nullable() => this;
  MapSchema<T> optional() => this;
  MapSchema<T> describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => {
    'type': 'object',
    'additionalProperties': valueSchema.toJsonSchema(),
  };
}
class ObjectSchema extends AckSchema<Map<String, Object?>> {
  final Map<String, AckSchema> properties;
  final List<String>? required;
  final bool additionalProperties;
  const ObjectSchema(this.properties, {this.required, this.additionalProperties = false});
  
  Map<String, Object?> toJsonSchema() {
    return {
      'type': 'object',
      'properties': properties.map((k, v) => MapEntry(k, v.toJsonSchema())),
      if (required != null && required!.isNotEmpty) 'required': required,
      'additionalProperties': additionalProperties,
    };
  }
}
class DiscriminatedSchema extends AckSchema<Map<String, Object?>> {
  final String discriminatorKey;
  final Map<String, AckSchema> schemas;
  const DiscriminatedSchema({required this.discriminatorKey, required this.schemas});
  
  @override
  Map<String, Object?> toJsonSchema() => {
    'oneOf': schemas.values.map((schema) => schema.toJsonSchema()).toList(),
    'discriminator': {'propertyName': discriminatorKey},
  };
}
''',
  'ack|lib/src/schemas/schema_model.dart': '''
import 'package:meta/meta.dart';

abstract class SchemaModel<T> {
  final Map<String, Object?>? _data;
  
  const SchemaModel() : _data = null;
  
  @protected
  const SchemaModel.validated(Map<String, Object?> data) : _data = data;
  
  @protected
  ObjectSchema get schema;
  
  bool get hasData => _data != null;
  
  SchemaModel parse(Object? input) {
    // Simplified implementation for testing
    return createValidated(input as Map<String, Object?>);
  }
  
  SchemaModel? tryParse(Object? input) {
    try {
      return parse(input);
    } catch (_) {
      return null;
    }
  }
  
  @protected
  SchemaModel createValidated(Map<String, Object?> data);
  
  T createFromMap(Map<String, dynamic> map);
  
  @protected
  TValue getValue<TValue extends Object>(String key) {
    if (_data == null) {
      throw StateError('No data available - use parse() first');
    }
    return _data![key] as TValue;
  }
  
  @protected
  TValue? getValueOrNull<TValue extends Object>(String key) {
    if (_data == null) return null;
    return _data![key] as TValue?;
  }
  
  Map<String, Object?> toMap() {
    if (_data == null) return const {};
    return Map.unmodifiable(_data!);
  }
  
  Map<String, Object?> toJsonSchema() {
    return schema.toJsonSchema();
  }
}
''',
};

/// Combine all assets for easy use in tests
Map<String, String> get allAssets => {
  ...metaAssets,
  ...ackAnnotationsAsset,
  ...ackPackageAsset,
};
