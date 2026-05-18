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

export 'src/ack_type.dart';
''',
  'ack_annotations|lib/src/ack_type.dart': '''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.topLevelVariable, TargetKind.getter})
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
export 'src/validation/schema_result.dart';
''',
  'ack|lib/src/ack.dart': '''
class Ack {
  static StringSchema string() => const StringSchema();
  static IntegerSchema integer() => const IntegerSchema();
  static DoubleSchema double() => const DoubleSchema();
  static NumberSchema number() => const NumberSchema();
  static BooleanSchema boolean() => const BooleanSchema();
  static AnySchema any() => const AnySchema();
  static CodecSchema<String, Uri> uri() => CodecSchema<String, Uri>(const StringSchema());
  static CodecSchema<String, DateTime> date() => CodecSchema<String, DateTime>(const StringSchema());
  static CodecSchema<String, DateTime> datetime() => CodecSchema<String, DateTime>(const StringSchema());
  static CodecSchema<int, Duration> duration() => CodecSchema<int, Duration>(const IntegerSchema());

  static ListSchema<B, R> list<B extends Object, R extends Object>(
    AckSchema<B, R> itemSchema,
  ) =>
      ListSchema<B, R>(itemSchema);
  static MapSchema<B, R> map<B extends Object, R extends Object>(
    AckSchema<B, R> valueSchema,
  ) =>
      MapSchema<B, R>(valueSchema);
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

  static StringSchema literal(String value) => const StringSchema();
  static StringSchema enumString(List<String> values) => const StringSchema();
  static EnumSchema<T> enumValues<T extends Enum>(List<T> values) => EnumSchema<T>();
}

abstract class AckSchema<Boundary extends Object, Runtime extends Object> {
  CodecSchema<Boundary, R> transform<R extends Object>(
    R Function(Runtime value) transformer,
  ) =>
      CodecSchema<Boundary, R>(this);
  Map<String, Object?> toJsonSchema();
}
class CodecSchema<Boundary extends Object, Runtime extends Object>
    extends AckSchema<Boundary, Runtime> {
  final AckSchema<Boundary, dynamic> schema;
  CodecSchema(this.schema);
  CodecSchema<Boundary, Runtime> nullable() => this;
  CodecSchema<Boundary, Runtime> optional() => this;
  CodecSchema<Boundary, Runtime> describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => schema.toJsonSchema();
}
class StringSchema extends AckSchema<String, String> {
  const StringSchema();
  StringSchema email() => this;
  StringSchema notEmpty() => this;
  StringSchema minLength(int length) => this;
  StringSchema maxLength(int length) => this;
  StringSchema enumString(List<String> values) => this;
  StringSchema uri() => this;
  StringSchema date() => this;
  StringSchema datetime() => this;
  StringSchema nullable() => this;
  StringSchema optional() => this;
  StringSchema describe(String description) => this;
  StringSchema withDefault(String defaultValue) => this;

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'string'};
}
class IntegerSchema extends AckSchema<int, int> {
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
class DoubleSchema extends AckSchema<double, double> {
  const DoubleSchema();
  DoubleSchema nullable() => this;
  DoubleSchema optional() => this;
  DoubleSchema describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'number'};
}
class NumberSchema extends AckSchema<num, num> {
  const NumberSchema();
  NumberSchema nullable() => this;
  NumberSchema optional() => this;
  NumberSchema describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'number'};
}
class BooleanSchema extends AckSchema<bool, bool> {
  const BooleanSchema();
  BooleanSchema nullable() => this;
  BooleanSchema optional() => this;
  BooleanSchema describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'boolean'};
}
class AnySchema extends AckSchema<Object, Object> {
  const AnySchema();
  AnySchema nullable() => this;
  AnySchema optional() => this;

  @override
  Map<String, Object?> toJsonSchema() => {};
}
class ListSchema<ItemBoundary extends Object, ItemRuntime extends Object>
    extends AckSchema<List<ItemBoundary>, List<ItemRuntime>> {
  final AckSchema<ItemBoundary, ItemRuntime> itemSchema;
  const ListSchema(this.itemSchema);
  ListSchema<ItemBoundary, ItemRuntime> nullable() => this;
  ListSchema<ItemBoundary, ItemRuntime> optional() => this;
  ListSchema<ItemBoundary, ItemRuntime> unique() => this;
  ListSchema<ItemBoundary, ItemRuntime> describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => {
    'type': 'array',
    'items': itemSchema.toJsonSchema(),
  };
}
class MapSchema<ValueBoundary extends Object, ValueRuntime extends Object>
    extends AckSchema<Map<String, ValueBoundary>, Map<String, ValueRuntime>> {
  final AckSchema<ValueBoundary, ValueRuntime> valueSchema;
  const MapSchema(this.valueSchema);
  MapSchema<ValueBoundary, ValueRuntime> nullable() => this;
  MapSchema<ValueBoundary, ValueRuntime> optional() => this;
  MapSchema<ValueBoundary, ValueRuntime> describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => {
    'type': 'object',
    'additionalProperties': valueSchema.toJsonSchema(),
  };
}
class ObjectSchema extends AckSchema<Map<String, Object?>, Map<String, Object?>> {
  final Map<String, AckSchema> properties;
  final List<String>? required;
  final bool additionalProperties;
  const ObjectSchema(this.properties, {this.required, this.additionalProperties = false});

  ObjectSchema copyWith({
    Map<String, AckSchema>? properties,
    List<String>? required,
    bool? additionalProperties,
  }) {
    return ObjectSchema(
      properties ?? this.properties,
      required: required ?? this.required,
      additionalProperties: additionalProperties ?? this.additionalProperties,
    );
  }

  Map<String, Object?> toJsonSchema() {
    return {
      'type': 'object',
      'properties': properties.map((k, v) => MapEntry(k, v.toJsonSchema())),
      if (required != null && required!.isNotEmpty) 'required': required,
      'additionalProperties': additionalProperties,
    };
  }
}

extension ObjectSchemaExtensions on ObjectSchema {
  ObjectSchema passthrough() => copyWith(additionalProperties: true);
}
class EnumSchema<T extends Enum> extends AckSchema<String, T> {
  EnumSchema();
  EnumSchema<T> nullable() => this;
  EnumSchema<T> optional() => this;
  EnumSchema<T> describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'string', 'enum': []};
}
class DiscriminatedSchema
    extends AckSchema<Map<String, Object?>, Map<String, Object?>> {
  final String discriminatorKey;
  final Map<String, AckSchema> schemas;
  const DiscriminatedSchema({required this.discriminatorKey, required this.schemas});

  // Test stub no-op: generator nullability checks inspect the AST chain.
  DiscriminatedSchema nullable() => this;

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
    // Parse test input into the schema model contract used by test fixtures.
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
  'ack|lib/src/validation/schema_result.dart': '''
sealed class SchemaResult<T> {
  const SchemaResult();

  factory SchemaResult.ok(T value) = SchemaSuccess<T>;
  factory SchemaResult.fail(String error) = SchemaFailure<T>;

  R match<R>({
    required R Function(T value) onOk,
    required R Function(String error) onFail,
  });
}

class SchemaSuccess<T> extends SchemaResult<T> {
  final T value;
  const SchemaSuccess(this.value);

  @override
  R match<R>({
    required R Function(T value) onOk,
    required R Function(String error) onFail,
  }) => onOk(value);
}

class SchemaFailure<T> extends SchemaResult<T> {
  final String error;
  const SchemaFailure(this.error);

  @override
  R match<R>({
    required R Function(T value) onOk,
    required R Function(String error) onFail,
  }) => onFail(error);
}
''',
};

/// Combine all assets for easy use in tests
Map<String, String> get allAssets => {
  ...metaAssets,
  ...ackAnnotationsAsset,
  ...ackPackageAsset,
};
