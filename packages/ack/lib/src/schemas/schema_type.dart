part of 'schema.dart';

/// Schema type enumeration covering JSON primitives and schema-specific
/// categories.
///
/// Numeric inference follows JSON Schema semantics: any finite number with a
/// zero fractional part is an `integer`, regardless of its Dart representation.
enum SchemaType {
  string('string'),
  integer('integer'),
  number('number'),
  boolean('boolean'),
  object('object'),
  array('array'),
  null_('null'),
  any('any'),
  anyOf('anyOf'),
  enum_('enum'),
  lazy('lazy'),
  discriminated('discriminated');

  const SchemaType(this.typeName);

  /// The string representation used in JSON Schema and error messages.
  final String typeName;

  /// Infers the [SchemaType] for [value].
  static SchemaType of(Object? value) =>
      tryOf(value) ??
      (throw ArgumentError('Unknown schema type for value: $value'));

  /// Infers the [SchemaType] for [value], or returns `null` for unsupported
  /// Dart runtime objects outside ACK's JSON-ish schema categories.
  static SchemaType? tryOf(Object? value) => switch (value) {
    null => SchemaType.null_,
    Map() => SchemaType.object,
    List() => SchemaType.array,
    Enum() => SchemaType.enum_,
    String() => SchemaType.string,
    bool() => SchemaType.boolean,
    final num value when value.isFinite && value.remainder(1) == 0 =>
      SchemaType.integer,
    num() => SchemaType.number,
    _ => null,
  };
}
