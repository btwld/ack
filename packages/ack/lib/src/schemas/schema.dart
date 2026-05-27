import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../common_types.dart';
import '../constraints/constraint.dart';
import '../constraints/number_finite_constraint.dart';
import '../constraints/pattern_constraint.dart';
import '../constraints/validators.dart';
import '../context.dart';
import '../helpers.dart';
import '../schema_model/ack_schema_model_builder.dart';
import '../validation/schema_error.dart';
import '../validation/schema_result.dart';

part 'any_of_schema.dart';
part 'any_schema.dart';
part 'boolean_schema.dart';
part 'codec_schema.dart';
part 'default_schema.dart';
part 'discriminated_object_schema.dart';
part 'enum_schema.dart';
part 'fluent_schema.dart';
part 'instance_schema.dart';
part 'list_schema.dart';
part 'num_schema.dart';
part 'object_schema.dart';
part 'schema_type.dart';
part 'string_schema.dart';
part 'testing/testing_schemas.dart';
part 'wrapper_schema.dart';

typedef Refinement<T> = ({bool Function(T value) validate, String message});

/// Type-erased ACK schema used when traversing heterogeneous schema graphs.
///
/// Use this when both boundary and runtime types are intentionally unknown,
/// such as converter traversal, object properties, or wrapper unwrapping.
/// Keep partially known schemas typed with their specific generic half instead
/// of widening them to [AnyAckSchema].
typedef AnyAckSchema = AckSchema<Object, Object>;

/// Indicates whether a schema operation is parsing inbound data or encoding
/// runtime values back to the boundary representation.
enum SchemaOperation { parse, encode }

/// The bidirectional schema contract.
///
/// Every schema declares two type parameters:
///
/// * [Boundary] is the encoded / wire / JSON-facing value type.
/// * [Runtime] is the parsed Dart application value type.
///
/// All schemas implement three internal operations:
///
/// * [parseWithContext]:  Boundary → Runtime decoding (plus boundary validation).
/// * [validateRuntimeWithContext]: runtime type/invariant validation.
/// * [encodeWithContext]: Runtime → Boundary encoding.
///
/// The public [parse]/[safeParse] and [encode]/[safeEncode] APIs are thin
/// wrappers that build a root [SchemaContext] and delegate to these three
/// methods. Subclasses override the three methods; they should not override
/// the public wrappers.
@immutable
abstract class AckSchema<Boundary extends Object, Runtime extends Object> {
  final bool isNullable;
  final bool isOptional;
  final String? description;
  final List<Constraint<Runtime>> _constraints;
  final List<Refinement<Runtime>> _refinements;

  /// Returns an unmodifiable view of the constraints for this schema.
  List<Constraint<Runtime>> get constraints => List.unmodifiable(_constraints);

  /// Returns an unmodifiable view of the refinements for this schema.
  List<Refinement<Runtime>> get refinements => List.unmodifiable(_refinements);

  Iterable<Object?> get _constraintsForEquality => _constraints;

  Iterable<Object?> get _refinementsForEquality => _refinements;

  const AckSchema({
    this.isNullable = false,
    this.isOptional = false,
    this.description,
    List<Constraint<Runtime>> constraints = const [],
    List<Refinement<Runtime>> refinements = const [],
  }) : _constraints = constraints,
       _refinements = refinements;

  // ---------------------------------------------------------------------------
  // Subclass-facing internal lifecycle
  // ---------------------------------------------------------------------------

  /// Decodes a boundary value into a runtime value.
  ///
  /// The default delegates to [validateRuntimeWithContext], which is correct
  /// for schemas whose parse is just runtime validation. Composite and codec
  /// schemas override this to implement boundary-shape-specific logic.
  @protected
  SchemaResult<Runtime> parseWithContext(
    Object? value,
    SchemaContext context,
  ) => validateRuntimeWithContext(value, context);

  /// Validates that [value] is a valid runtime value for this schema.
  ///
  /// This is the single source of truth for runtime invariants. Subclasses
  /// MUST implement it; codecs call it on their output to validate decoded /
  /// pre-encode runtime values, and [encodeWithContext] uses it as a
  /// precondition.
  @protected
  SchemaResult<Runtime> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  );

  /// Encodes a runtime value into a boundary value. The base class strips
  /// `null` before calling this; subclasses receive a non-null [value].
  ///
  /// The default delegates to [encodeAsBoundary], which is correct for schemas
  /// where `Boundary == Runtime`. Schemas where the two types differ (codecs,
  /// objects, lists, enums, …) override this to implement encoding logic.
  @protected
  SchemaResult<Boundary> encodeWithContext(
    Runtime value,
    SchemaContext context,
  ) => encodeAsBoundary(value, context);

  // ---------------------------------------------------------------------------
  // Shared helpers used by subclasses
  // ---------------------------------------------------------------------------

  /// Applies constraints and refinements to a runtime value.
  @protected
  SchemaResult<Runtime> applyConstraintsAndRefinements(
    Runtime value,
    SchemaContext context,
  ) {
    final constraintViolations = _checkConstraints(value);
    if (constraintViolations.isNotEmpty) {
      return SchemaResult.fail(
        SchemaConstraintsError(
          constraints: constraintViolations,
          context: context,
        ),
      );
    }
    return _runRefinements(value, context);
  }

  List<ConstraintError> _checkConstraints(Runtime value) {
    if (_constraints.isEmpty) return const [];
    final errors = <ConstraintError>[];
    for (final constraint in _constraints) {
      if (constraint is Validator<Runtime>) {
        final error = constraint.validate(value);
        if (error != null) {
          errors.add(error);
        }
      }
    }
    return errors;
  }

  SchemaResult<Runtime> _runRefinements(Runtime value, SchemaContext context) {
    for (final refinement in _refinements) {
      if (!refinement.validate(value)) {
        return SchemaResult.fail(
          SchemaValidationError(message: refinement.message, context: context),
        );
      }
    }

    return SchemaResult.ok(value);
  }

  /// Helper for schemas whose boundary == runtime: validates the runtime
  /// value and, if it passes, returns it as the boundary value unchanged.
  /// Only safe to call when `Boundary` and `Runtime` are the same type.
  @protected
  SchemaResult<Boundary> encodeAsBoundary(
    Runtime value,
    SchemaContext context,
  ) {
    final validated = validateRuntimeWithContext(value, context);
    if (validated.isFail) return SchemaResult.fail(validated.getError());
    return SchemaResult.ok(value as Boundary);
  }

  /// Runtime-side non-nullable failure.
  @protected
  SchemaResult<Runtime> failNonNullable(SchemaContext context) {
    final constraintError = NonNullableConstraint().validate(null);
    return SchemaResult.fail(
      SchemaConstraintsError(
        constraints: constraintError != null ? [constraintError] : [],
        context: context,
      ),
    );
  }

  /// Encode-side non-nullable failure.
  @protected
  SchemaResult<Boundary> failNonNullableEncode(SchemaContext context) {
    return SchemaResult.fail(SchemaEncodeError.nonNullable(context: context));
  }

  /// Centralized null gate for the parse/validate paths. Returns null when
  /// [inputValue] is non-null; otherwise returns Ok(null) if [acceptsNull]
  /// is true or a non-nullable failure.
  @protected
  SchemaResult<Runtime>? handleNullInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue != null) return null;

    if (acceptsNull) {
      return SchemaResult.ok(null);
    }

    return failNonNullable(context);
  }

  /// Whether `parse(null)` and `encode(null)` should accept null without
  /// raising a non-nullable failure. Defaults to [isNullable]; subclasses with
  /// branch-level null policies (e.g. [AnyOfSchema]) override this hook.
  @protected
  bool get acceptsNull => isNullable;

  /// The schema type category for this schema.
  @protected
  SchemaType get schemaType;

  /// Human-readable type name for error messages and debugging.
  String get schemaTypeName => schemaType.typeName;

  /// Returns a copy of this schema with runtime-side configuration replaced.
  AckSchema<Boundary, Runtime> withRuntimeConfig({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<Runtime>>? constraints,
    List<Refinement<Runtime>>? refinements,
  });

  /// Marks the schema as nullable.
  AckSchema<Boundary, Runtime> nullable({bool value = true}) {
    if (isNullable == value) return this;
    return withRuntimeConfig(isNullable: value);
  }

  /// Marks the schema as optional so the field can be omitted from an object.
  AckSchema<Boundary, Runtime> optional({bool value = true}) {
    if (isOptional == value) return this;
    return withRuntimeConfig(isOptional: value);
  }

  /// Sets the description for the schema.
  AckSchema<Boundary, Runtime> describe(String description) {
    return withRuntimeConfig(description: description);
  }

  /// Wraps this schema in a [DefaultSchema] that supplies [defaultValue] when
  /// the parse input is null. Object encode also injects encoded defaults for
  /// missing default-wrapped fields.
  DefaultSchema<Boundary, Runtime> withDefault(Runtime defaultValue) {
    return DefaultSchema<Boundary, Runtime>(
      inner: this,
      defaultValue: defaultValue,
    );
  }

  /// Adds a validation constraint to the schema.
  AckSchema<Boundary, Runtime> withConstraint(Constraint<Runtime> constraint) {
    return withRuntimeConfig(constraints: [...constraints, constraint]);
  }

  /// Adds validation constraints to the schema.
  AckSchema<Boundary, Runtime> withConstraints(
    List<Constraint<Runtime>> newConstraints,
  ) {
    return withRuntimeConfig(constraints: [...constraints, ...newConstraints]);
  }

  /// Adds a custom validation check that runs after all other validations have
  /// passed for this schema.
  AckSchema<Boundary, Runtime> refine(
    bool Function(Runtime value) validate, {
    String message = 'The value did not pass the custom validation.',
  }) {
    final newRefinement = (validate: validate, message: message);
    return withRuntimeConfig(refinements: [...refinements, newRefinement]);
  }

  /// Adds a raw [constraint] to the schema.
  AckSchema<Boundary, Runtime> constrain(
    Constraint<Runtime> constraint, {
    String? message,
  }) {
    if (constraint is! Validator<Runtime>) {
      throw ArgumentError(
        'Constraint ${constraint.runtimeType} must implement Validator<Runtime>.',
      );
    }
    final effectiveConstraint = message == null
        ? constraint
        : _ConstraintMessageOverride<Runtime>(constraint, message);
    return withConstraint(effectiveConstraint);
  }

  // ---------------------------------------------------------------------------
  // Public API (thin wrappers around the internal lifecycle)
  // ---------------------------------------------------------------------------

  /// Parses and validates a value, throwing an [AckException] if it fails.
  Runtime? parse(Object? value, {String? debugName}) {
    final result = safeParse(value, debugName: debugName);
    return result.getOrThrow();
  }

  /// Parses and validates a value, then maps the validated value to [TOut].
  TOut parseAs<TOut extends Object>(
    Object? value,
    TOut Function(Runtime? validated) map, {
    String? debugName,
  }) {
    final result = safeParseAs(value, map, debugName: debugName);
    return result.getOrThrow()!;
  }

  /// Parses and validates a value, returning a [SchemaResult].
  SchemaResult<Runtime> safeParse(Object? value, {String? debugName}) {
    final context = _createRootContext(
      value,
      debugName: debugName,
      operation: SchemaOperation.parse,
    );
    return parseWithContext(value, context);
  }

  /// Parses and validates a value, then maps the validated value to [TOut].
  SchemaResult<TOut> safeParseAs<TOut extends Object>(
    Object? value,
    TOut Function(Runtime? validated) map, {
    String? debugName,
  }) {
    final result = safeParse(value, debugName: debugName);
    if (result case Fail(error: final error)) {
      return SchemaResult.fail(error);
    }

    final validated = result.getOrNull();
    try {
      return SchemaResult.ok(map(validated));
    } catch (e, st) {
      return SchemaResult.fail(
        SchemaTransformError(
          message: 'Transformation failed: ${e.toString()}',
          context: _createRootContext(
            value,
            debugName: debugName,
            operation: SchemaOperation.parse,
          ),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Encodes a runtime value to a boundary value, returning a [SchemaResult].
  ///
  /// Null handling lives here so subclass [encodeWithContext] receives
  /// non-null values. The null gate consults [acceptsNull] so subclasses
  /// with branch-level null policies (e.g. [AnyOfSchema]) can participate
  /// without overriding this public wrapper.
  SchemaResult<Boundary> safeEncode(Runtime? value, {String? debugName}) {
    final context = _createRootContext(
      value,
      debugName: debugName,
      operation: SchemaOperation.encode,
    );
    if (value == null) {
      if (acceptsNull) return SchemaResult.ok(null);
      return failNonNullableEncode(context);
    }
    try {
      return encodeWithContext(value, context);
    } catch (e, st) {
      return SchemaResult.fail(
        SchemaEncodeError.encoderThrew(
          message: 'Encoder threw: ${e.toString()}',
          context: context,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Encodes a runtime value to a boundary value, throwing on failure.
  Boundary? encode(Runtime? value, {String? debugName}) {
    final result = safeEncode(value, debugName: debugName);
    return result.getOrThrow();
  }

  SchemaContext _createRootContext(
    Object? value, {
    String? debugName,
    required SchemaOperation operation,
  }) {
    final typeName = runtimeType
        .toString()
        .replaceFirst(RegExp(r'Schema$'), '')
        .toLowerCase();
    final effectiveDebugName = debugName ?? typeName;
    return SchemaContext(
      name: effectiveDebugName,
      schema: this,
      value: value,
      operation: operation,
    );
  }

  /// Converts this schema to a JSON Schema Draft-7 representation.
  ///
  /// Delegates to the sealed [AckSchemaModel] boundary so all renderers share
  /// the same Draft-7 output. Subclasses should not override this directly;
  /// instead they are dispatched in `ack_schema_model_builder.dart`.
  Map<String, Object?> toJsonSchema() => toSchemaModel().toJsonSchema();

  Map<String, Object?> toMap() {
    return {
      'type': schemaType.typeName,
      'isNullable': isNullable,
      'description': description,
      'constraints': _constraints.map((c) => c.toMap()).toList(),
    };
  }

  /// Compares base schema fields for equality.
  @protected
  bool baseFieldsEqual(AckSchema<dynamic, dynamic> other) {
    const iterableEq = IterableEquality<Object?>();
    return isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description &&
        iterableEq.equals(
          _constraintsForEquality,
          other._constraintsForEquality,
        ) &&
        iterableEq.equals(
          _refinementsForEquality,
          other._refinementsForEquality,
        );
  }

  /// Computes hash code for base schema fields.
  @protected
  int get baseFieldsHashCode {
    const iterableEq = IterableEquality<Object?>();
    return Object.hash(
      isNullable,
      isOptional,
      description,
      iterableEq.hash(_constraintsForEquality),
      iterableEq.hash(_refinementsForEquality),
    );
  }
}

/// Builds a type-mismatch error without throwing when [actualValue] is an
/// unsupported Dart runtime object outside ACK's JSON-ish schema categories.
SchemaError _buildTypeMismatch({
  required SchemaType expectedType,
  required Object? actualValue,
  required SchemaContext context,
}) {
  final actualType = SchemaType.tryOf(actualValue);
  if (actualType == null) {
    return SchemaValidationError(
      message:
          'Expected ${expectedType.typeName}, got ${actualValue.runtimeType}.',
      context: context,
    );
  }

  return TypeMismatchError(
    expectedType: expectedType,
    actualType: actualType,
    context: context,
  );
}

class _ConstraintMessageOverride<T extends Object> extends Constraint<T>
    with Validator<T>, JsonSchemaSpec<T> {
  _ConstraintMessageOverride(this.inner, this.customMessage)
    : super(constraintKey: inner.constraintKey, description: inner.description);

  final Constraint<T> inner;
  final String customMessage;

  Validator<T> get _validator => inner as Validator<T>;

  @override
  bool isValid(T value) => _validator.isValid(value);

  @override
  String buildMessage(T value) => customMessage;

  @override
  Map<String, Object?> buildContext(T value) {
    return _validator.buildContext(value);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    if (inner is JsonSchemaSpec<T>) {
      return (inner as JsonSchemaSpec<T>).toJsonSchema();
    }
    return const {};
  }
}

/// Returns [value] if it is composed entirely of JSON-safe primitives
/// (`null`, finite `num`, `bool`, `String`, `List`, string-keyed `Map`),
/// recursively.
/// Returns `null` if any nested value is not JSON-safe. Used by
/// [DefaultSchema] to avoid emitting runtime-only objects (e.g. raw
/// `DateTime` instances) as JSON Schema defaults.
Object? _jsonSafeOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value.isFinite ? value : null;
  if (value is bool || value is String) return value;
  if (value is List) {
    final result = <Object?>[];
    for (final item in value) {
      if (item == null) {
        result.add(null);
        continue;
      }
      final converted = _jsonSafeOrNull(item);
      if (converted == null) return null;
      result.add(converted);
    }
    return result;
  }
  if (value is Map) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) return null;
      if (entry.value == null) {
        result[entry.key as String] = null;
        continue;
      }
      final converted = _jsonSafeOrNull(entry.value);
      if (converted == null) return null;
      result[entry.key as String] = converted;
    }
    return result;
  }
  return null;
}

/// Safely converts a value into a [JsonMap]. Returns `null` if the value is
/// not map-shaped or contains non-string keys. This eager check replaces
/// `cast<String, Object?>()`, whose lazy semantics can throw at access time
/// when a non-string key is hit.
JsonMap? jsonMapOrNull(Object? value) {
  if (value == null) return null;
  if (value is JsonMap) return value;
  if (value is! Map) return null;
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) return null;
    result[entry.key as String] = entry.value;
  }
  return result;
}
