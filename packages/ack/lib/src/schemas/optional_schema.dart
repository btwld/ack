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
  final AckSchema<DartType> wrappedSchema;

  OptionalSchema({
    required this.wrappedSchema,
    super.description,
    super.defaultValue,
    super.constraints = const [],
    super.refinements = const [],
    super.isNullable = false,
  });

  @override
  JsonType get acceptedType => wrappedSchema.acceptedType;

  @override
  bool get strictPrimitiveParsing => wrappedSchema.strictPrimitiveParsing;

  /// OptionalSchema delegates to wrapped schema for parsing.
  @override
  @protected
  SchemaResult<DartType> parseAndValidate(
    Object? inputValue,
    SchemaContext context,
  ) {
    // Simplified Optional semantics:
    // - Optional is intended for object properties ("missing" semantics)
    // - At the top-level (no parent context), null should not trigger Optional defaults
    //   or special handling; treat as non-nullable unless explicitly nullable.
    if (inputValue == null) {
      final isTopLevel = context.parent == null;
      if (isTopLevel) {
        if (isNullable) return SchemaResult.ok(null);
        return failNonNullable(context);
      }
      // Nested usage (e.g., object property): fall back to base handling
      return handleNullInput(context);
    }

    // Delegate full validation to wrapped schema, which includes wrapped schema's
    // constraints and refinements. After this, we'll apply OptionalSchema's own constraints/refinements.
    final result = wrappedSchema.parseAndValidate(inputValue, context);
    if (result.isFail) return result;

    final validatedValue = result.getOrThrow()!;

    // Use centralized constraints and refinements check for OptionalSchema's own constraints
    return applyConstraintsAndRefinements(validatedValue, context);
  }

  @override
  @protected
  OptionalSchema<DartType> copyWithInternal({
    bool? isNullable,
    String? description,
    DartType? defaultValue,
    List<Constraint<DartType>>? constraints,
    List<Refinement<DartType>>? refinements,
  }) {
    return OptionalSchema(
      wrappedSchema: wrappedSchema,
      description: description ?? this.description,
      defaultValue: defaultValue ?? this.defaultValue,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
      isNullable: isNullable ?? this.isNullable,
    );
  }

  @override
  Map<String, Object?> toJsonSchema() {
    // Get the wrapped schema's JSON Schema representation
    final base = Map<String, Object?>.from(wrappedSchema.toJsonSchema());

    // If this OptionalSchema is also marked nullable, add null to the type
    if (isNullable) {
      final existingType = base['type'];
      if (existingType is String && existingType != 'null') {
        base['type'] = [existingType, 'null'];
      } else if (existingType is List && !existingType.contains('null')) {
        base['type'] = [...existingType, 'null'];
      }
    }

    // Override with OptionalSchema's own properties
    if (description != null) base['description'] = description;
    if (defaultValue != null) base['default'] = defaultValue;

    // Merge OptionalSchema's constraints into the JSON Schema
    return mergeConstraintSchemas(base);
  }
}
