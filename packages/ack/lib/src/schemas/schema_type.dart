part of 'schema.dart';

/// Schema type enumeration covering JSON primitives and schema-specific categories.
///
/// Unifies type detection and schema categorization so validation, JSON
/// Schema export, and error messages share a single source of truth.
///
/// ## Type Categories
///
/// **JSON Primitives**: string, integer, number, boolean, object, array, null_
/// **Schema-Specific**: any, anyOf, enum_, discriminated
///
/// ## Strict primitives
///
/// All primitive schemas accept exact-type matches only. Implicit
/// conversions between primitives (e.g. `string → int`) are not part of
/// the public surface — use [Ack.codec] for explicit boundary conversion.
/// Runnable migration recipes live in
/// `packages/ack/test/migration_recipes_test.dart`.
///
/// ```dart
/// Ack.integer().parse(42);    // ok
/// Ack.integer().parse('42');  // fail — use Ack.codec(...) instead
/// Ack.double().parse(3.14);   // ok
/// Ack.double().parse(42);     // fail
/// Ack.boolean().parse(true);  // ok
/// Ack.boolean().parse('true');// fail
/// Ack.string().parse('hi');   // ok
/// Ack.string().parse(42);     // fail
/// ```
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
  discriminated('discriminated');

  const SchemaType(this.typeName);

  /// The string representation used in JSON Schema and error messages.
  final String typeName;

  /// Determines if this type can accept/parse values from [sourceType].
  ///
  /// All primitive schemas are strict — only exact-type matches are
  /// accepted. Conversions belong in [CodecSchema] (`Ack.codec(...)`).
  ///
  /// The [strict] parameter is retained for source compatibility but
  /// is no longer load-bearing; the result is the same regardless of
  /// the flag.
  bool canAcceptFrom(SchemaType sourceType, {bool strict = true}) {
    return this == sourceType;
  }

  /// Parses [value] from [sourceType] into this type.
  ///
  /// Precondition: [canAcceptFrom] must already have returned true,
  /// i.e. `this == sourceType`. With strict primitives, this method is
  /// effectively a typed identity passthrough.
  SchemaResult<T> parse<T extends Object>(
    Object value,
    SchemaType sourceType,
    SchemaContext context,
  ) {
    if (this == sourceType) {
      return SchemaResult.ok(value as T);
    }
    return SchemaResult.fail(
      SchemaValidationError(
        message: 'Cannot parse ${sourceType.typeName} to $typeName',
        context: context,
      ),
    );
  }

  /// Infers the [SchemaType] for [value].
  static SchemaType of(Object? value) => switch (value) {
    null => SchemaType.null_,
    Map() => SchemaType.object,
    List() => SchemaType.array,
    Enum() => SchemaType.enum_,
    String() => SchemaType.string,
    bool() => SchemaType.boolean,
    int() => SchemaType.integer,
    num() => SchemaType.number,
    _ => throw ArgumentError('Unknown schema type for value: $value'),
  };
}
