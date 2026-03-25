/// Test assets for ack_generator tests
/// Provides reusable mock file contents
library;

const metaAssets = {
  'meta|lib/meta_meta.dart': '''
enum TargetKind {
  classType,
  constructor,
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

export 'src/schemable.dart';
export 'src/ack_model.dart';
export 'src/ack_field.dart';
export 'src/ack_type.dart';
export 'src/constraints.dart';
''',
  'ack_annotations|lib/src/schemable.dart': '''
import 'package:ack/ack.dart';
import 'package:meta/meta_meta.dart';

enum CaseStyle {
  none,
  camelCase,
  pascalCase,
  snakeCase,
  paramCase,
}

@Target({TargetKind.classType})
class Schemable {
  final String? schemaName;
  final String? description;
  final bool additionalProperties;
  final String? additionalPropertiesField;
  final String? discriminatorKey;
  final String? discriminatorValue;
  final CaseStyle caseStyle;
  final List<Type> useProviders;

  const Schemable({
    this.schemaName,
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.discriminatorKey,
    this.discriminatorValue,
    this.caseStyle = CaseStyle.none,
    this.useProviders = const [],
  });
}

@Target({TargetKind.constructor})
class SchemaConstructor {
  const SchemaConstructor();
}

@Target({TargetKind.parameter})
class SchemaKey {
  final String name;
  const SchemaKey(this.name);
}

@Target({TargetKind.parameter})
class Description {
  final String value;
  const Description(this.value);
}

abstract interface class SchemaProvider<T extends Object> {
  const SchemaProvider();

  AckSchema<T> get schema;
}
''',
  'ack_annotations|lib/src/ack_model.dart': '''
import 'package:meta/meta_meta.dart';
import 'schemable.dart';

@Target({TargetKind.classType})
class AckModel extends Schemable {
  const AckModel({
    super.schemaName,
    super.description,
    super.additionalProperties = false,
    super.additionalPropertiesField,
    super.discriminatorKey,
    super.discriminatorValue,
    super.caseStyle = CaseStyle.none,
    super.useProviders = const [],
  });
}
''',
  'ack_annotations|lib/src/ack_field.dart': '''
import 'package:meta/meta_meta.dart';

enum AckFieldRequiredMode {
  auto,
  required,
  optional,
}

@Target({TargetKind.field})
class AckField {
  final AckFieldRequiredMode requiredMode;
  final String? jsonKey;
  final String? description;
  final List<String> constraints;

  const AckField({
    this.requiredMode = AckFieldRequiredMode.auto,
    this.jsonKey,
    this.description,
    this.constraints = const [],
  });
}
''',
  'ack_annotations|lib/src/constraints.dart': '''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.parameter})
class MinLength {
  final int length;
  const MinLength(this.length);
}

@Target({TargetKind.parameter})
class MaxLength {
  final int length;
  const MaxLength(this.length);
}

@Target({TargetKind.parameter})
class Email {
  const Email();
}

@Target({TargetKind.parameter})
class Url {
  const Url();
}

@Target({TargetKind.parameter})
class Pattern {
  final String pattern;
  const Pattern(this.pattern);
}

@Target({TargetKind.parameter})
class Min {
  final num value;
  const Min(this.value);
}

@Target({TargetKind.parameter})
class Max {
  final num value;
  const Max(this.value);
}

@Target({TargetKind.parameter})
class Positive {
  const Positive();
}

@Target({TargetKind.parameter})
class MultipleOf {
  final num value;
  const MultipleOf(this.value);
}

@Target({TargetKind.parameter})
class MinItems {
  final int count;
  const MinItems(this.count);
}

@Target({TargetKind.parameter})
class MaxItems {
  final int count;
  const MaxItems(this.count);
}

@Target({TargetKind.parameter})
class EnumString {
  final List<String> values;
  const EnumString(this.values);
}
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
  static TransformedSchema<String, Uri> uri() => TransformedSchema<String, Uri>(const StringSchema());
  static TransformedSchema<String, DateTime> date() => TransformedSchema<String, DateTime>(const StringSchema());
  static TransformedSchema<String, DateTime> datetime() => TransformedSchema<String, DateTime>(const StringSchema());
  static TransformedSchema<int, Duration> duration() => TransformedSchema<int, Duration>(const IntegerSchema());

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

  static StringSchema literal(String value) => const StringSchema();
  static StringSchema enumString(List<String> values) => const StringSchema();
  static EnumSchema<T> enumValues<T extends Enum>(List<T> values) => EnumSchema<T>();
}

abstract class AckSchema<T> {
  AckSchema<T> nullable() => this;
  AckSchema<T> optional() => this;
  AckSchema<T> describe(String description) => this;
  TransformedSchema<T, R> transform<R extends Object>(
    R Function(T value) transformer,
  ) => TransformedSchema<T, R>(this);
  Map<String, Object?> toJsonSchema();
}
class TransformedSchema<InputType, OutputType> extends AckSchema<OutputType> {
  final AckSchema<InputType> schema;

  TransformedSchema(this.schema);

  @override
  Map<String, Object?> toJsonSchema() => schema.toJsonSchema();
}
class StringSchema extends AckSchema<String> {
  const StringSchema();
  StringSchema email() => this;
  StringSchema notEmpty() => this;
  StringSchema minLength(int length) => this;
  StringSchema maxLength(int length) => this;
  StringSchema matches(Object pattern) => this;
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
class IntegerSchema extends AckSchema<int> {
  const IntegerSchema();
  IntegerSchema min(int value) => this;
  IntegerSchema max(int value) => this;
  IntegerSchema positive() => this;
  IntegerSchema multipleOf(num value) => this;
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
  ListSchema<T> minItems(int count) => this;
  ListSchema<T> maxItems(int count) => this;
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
class EnumSchema<T> extends AckSchema<T> {
  EnumSchema();
  EnumSchema<T> nullable() => this;
  EnumSchema<T> optional() => this;
  EnumSchema<T> describe(String description) => this;

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'string', 'enum': []};
}
class DiscriminatedSchema extends AckSchema<Map<String, Object?>> {
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
