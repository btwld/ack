part of 'schema.dart';

/// A schema wrapper that makes any schema optional (field may be omitted).
///
/// ## Semantics
///
/// **`optional()`** means: The field can be **MISSING** from an object.
/// - When field is present: validates normally
/// - When field is missing: uses default if provided, otherwise omits from result
/// - When field is explicitly null: **FAILS** (unless also `.nullable()`)
///
/// **`nullable()`** means: The field/value can be explicitly **NULL**.
/// - Accepts null as a valid value
/// - Does NOT mean the field can be missing
///
/// **`optional().nullable()`** means: Field can be missing OR explicitly null.
///
/// ## Usage Context
///
/// ### In ObjectSchema (most common):
/// ```dart
/// Ack.object({
///   'required': Ack.string(),                    // Must be present, cannot be null
///   'optional': Ack.string().optional(),         // Can be missing, fails if null
///   'nullable': Ack.string().nullable(),         // Must be present, can be null
///   'both': Ack.string().optional().nullable(),  // Can be missing or null
/// });
/// ```
///
/// ### At Top-Level (less common):
/// At top-level, `optional()` has minimal effect since there's no "missing" concept:
/// ```dart
/// Ack.string().optional().validate(null)          // FAILS - null is not missing
/// Ack.string().optional().nullable().validate(null) // OK - nullable accepts it
/// Ack.string().optional().withDefault('x').validate(null) // OK - uses default
/// ```
///
/// ## Default Values
///
/// Defaults apply when the field is **missing** (in ObjectSchema):
/// ```dart
/// Ack.object({'count': Ack.integer().optional().withDefault(0)})
/// .validate({})  // → {'count': 0}
///
/// Ack.object({'count': Ack.integer().optional().withDefault(0)})
/// .validate({'count': null})  // → FAILS (null ≠ missing)
/// ```
@immutable
final class OptionalSchema<DartType extends Object> extends AckSchema<DartType>
    with FluentSchema<DartType, OptionalSchema<DartType>> {
  final AckSchema<DartType> schema;

  OptionalSchema(this.schema)
      : assert(
          schema is! OptionalSchema,
          'Cannot wrap OptionalSchema in OptionalSchema. '
          'The .optional() method is idempotent and will not double-wrap.',
        ),
        super(
          defaultValue: null,
          constraints: const [],
          refinements: const [],
          isNullable: false,
          description: null,
        );

  // Property getters - proxy to wrapped schema for transparent access
  @override
  DartType? get defaultValue => schema.defaultValue;

  @override
  bool get isNullable => schema.isNullable;

  @override
  String? get description => schema.description;

  @override
  List<Constraint<DartType>> get constraints => schema.constraints;

  @override
  List<Refinement<DartType>> get refinements => schema.refinements;

  @override
  JsonType get acceptedType => schema.acceptedType;

  @override
  bool get strictPrimitiveParsing => schema.strictPrimitiveParsing;

  /// OptionalSchema is a pure transparent wrapper - delegates all validation to wrapped schema.
  @override
  @protected
  SchemaResult<DartType> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Pure delegation - wrapped schema handles all logic
    return schema.parseAndValidate(inputValue, context);
  }

  // Fluent method overrides - modify wrapped schema and return new OptionalSchema
  @override
  OptionalSchema<DartType> withDefault(DartType defaultValue) {
    return OptionalSchema(schema.copyWith(defaultValue: defaultValue));
  }

  @override
  OptionalSchema<DartType> nullable({bool value = true}) {
    return OptionalSchema(schema.copyWith(isNullable: value));
  }

  @override
  OptionalSchema<DartType> describe(String description) {
    return OptionalSchema(schema.copyWith(description: description));
  }

  @override
  OptionalSchema<DartType> withConstraint(Constraint<DartType> constraint) {
    return OptionalSchema(
      schema.copyWith(constraints: [...schema.constraints, constraint]),
    );
  }

  @override
  OptionalSchema<DartType> withConstraints(
    List<Constraint<DartType>> newConstraints,
  ) {
    return OptionalSchema(
      schema.copyWith(
        constraints: [...schema.constraints, ...newConstraints],
      ),
    );
  }

  @override
  @protected
  OptionalSchema<DartType> copyWithInternal({
    required bool? isNullable,
    required String? description,
    required DartType? defaultValue,
    required List<Constraint<DartType>>? constraints,
    required List<Refinement<DartType>>? refinements,
  }) {
    // Proxy to wrapped schema's copyWith
    return OptionalSchema(
      schema.copyWithInternal(
        isNullable: isNullable,
        description: description,
        defaultValue: defaultValue,
        constraints: constraints,
        refinements: refinements,
      ),
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    // Pure delegation - wrapped schema owns all properties
    return schema.toJsonSchema();
  }
}
