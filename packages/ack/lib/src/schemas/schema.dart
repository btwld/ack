import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../common_types.dart';
import '../constraints/constraint.dart';
import '../constraints/pattern_constraint.dart';
import '../constraints/validators.dart';
import '../context.dart';
import '../helpers.dart';
import '../validation/schema_error.dart';
import '../validation/schema_result.dart';

part 'any_of_schema.dart';
part 'any_schema.dart';
part 'boolean_schema.dart';
part 'codec_schema.dart';
part 'configurable_schema.dart';
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
part 'transformed_schema.dart';
part 'testing/testing_schemas.dart';

typedef Refinement<T> = ({bool Function(T value) validate, String message});

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

  const AckSchema({
    this.isNullable = false,
    this.isOptional = false,
    this.description,
    List<Constraint<Runtime>> constraints = const [],
    List<Refinement<Runtime>> refinements = const [],
  }) : _constraints = constraints,
       _refinements = refinements;

  /// Utility method to get the schema type of any value.
  static SchemaType getSchemaType(Object? value) {
    return SchemaType.of(value);
  }

  // ---------------------------------------------------------------------------
  // Subclass-facing internal lifecycle
  // ---------------------------------------------------------------------------

  /// Decodes a boundary value into a runtime value.
  ///
  /// Subclasses MUST implement this. The context passed in carries operation
  /// information and JSON Pointer path state.
  @protected
  SchemaResult<Runtime> parseWithContext(
    Object? value,
    SchemaContext context,
  );

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
  /// Implementations should call [validateRuntimeWithContext] first so the
  /// runtime is checked before encoding.
  @protected
  SchemaResult<Boundary> encodeWithContext(
    Runtime value,
    SchemaContext context,
  );

  // ---------------------------------------------------------------------------
  // Shared helpers used by subclasses
  // ---------------------------------------------------------------------------

  /// Applies constraints and refinements to a runtime value.
  @protected
  SchemaResult<Runtime> applyConstraintsAndRefinements(
    Runtime value,
    SchemaContext context,
  ) {
    final constraintViolations = _checkConstraints(value, context);
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

  @protected
  List<ConstraintError> _checkConstraints(
    Runtime value,
    SchemaContext context,
  ) {
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

  @protected
  SchemaResult<Runtime> _runRefinements(
    Runtime value,
    SchemaContext context,
  ) {
    for (final refinement in _refinements) {
      if (!refinement.validate(value)) {
        return SchemaResult.fail(
          SchemaValidationError(message: refinement.message, context: context),
        );
      }
    }

    return SchemaResult.ok(value);
  }

  /// Merges constraint JSON schemas into a base schema.
  @protected
  Map<String, Object?> mergeConstraintSchemas(Map<String, Object?> baseSchema) {
    final constraintSchemas = <Map<String, Object?>>[];
    for (final constraint in _constraints) {
      if (constraint is JsonSchemaSpec<Runtime>) {
        constraintSchemas.add(constraint.toJsonSchema());
      }
    }
    return constraintSchemas.fold(
      baseSchema,
      (prev, current) => deepMerge(prev, current),
    );
  }

  /// Builds a JSON Schema map with proper nullable handling.
  @protected
  Map<String, Object?> buildJsonSchemaWithNullable({
    required Map<String, Object?> typeSchema,
    Object? serializedDefault,
  }) {
    if (isNullable) {
      final baseSchema = {
        ...typeSchema,
        if (description != null) 'description': description,
      };
      final mergedSchema = mergeConstraintSchemas(baseSchema);
      return {
        if (serializedDefault != null) 'default': serializedDefault,
        'anyOf': [
          mergedSchema,
          {'type': 'null'},
        ],
      };
    }

    final schema = {
      ...typeSchema,
      if (description != null) 'description': description,
      if (serializedDefault != null) 'default': serializedDefault,
    };

    return mergeConstraintSchemas(schema);
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
    return SchemaResult.fail(
      SchemaEncodeError.nonNullable(context: context),
    );
  }

  /// Centralized null gate for the parse/validate paths. Returns null when
  /// [inputValue] is non-null; otherwise returns Ok(null) if [acceptsParseNull]
  /// is true or a non-nullable failure.
  @protected
  SchemaResult<Runtime>? handleNullInput(
    Object? inputValue,
    SchemaContext context,
  ) {
    if (inputValue != null) return null;

    if (acceptsParseNull) {
      return SchemaResult.ok(null);
    }

    return failNonNullable(context);
  }

  /// Whether `parse(null)` (and the parse-side null gate inside
  /// [handleNullInput]) should accept null without raising a non-nullable
  /// failure. Defaults to [isNullable]; subclasses with branch-level null
  /// policies (e.g. [AnyOfSchema]) override this hook.
  @protected
  bool get acceptsParseNull => isNullable;

  /// Whether `encode(null)` should produce `Ok(null)` rather than a
  /// non-nullable encode failure. Defaults to [isNullable]; subclasses with
  /// branch-level null policies override this hook.
  @protected
  bool get acceptsEncodeNull => isNullable;

  /// The schema type category for this schema.
  @protected
  SchemaType get schemaType;

  /// Human-readable type name for error messages and debugging.
  String get schemaTypeName => schemaType.typeName;

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
  /// non-null values. The null gate consults [acceptsEncodeNull] so
  /// subclasses with branch-level null policies (e.g. [AnyOfSchema]) can
  /// participate without overriding this public wrapper.
  SchemaResult<Boundary> safeEncode(Runtime? value, {String? debugName}) {
    final context = _createRootContext(
      value,
      debugName: debugName,
      operation: SchemaOperation.encode,
    );
    if (value == null) {
      if (acceptsEncodeNull) return SchemaResult.ok(null);
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

  /// Legacy alias for [safeParse].
  @Deprecated('Use safeParse(...) instead.')
  SchemaResult<Runtime> validate(Object? value, {String? debugName}) =>
      safeParse(value, debugName: debugName);

  /// Legacy helper that returns the parsed value or `null` when validation fails.
  @Deprecated('Use safeParse(...).getOrNull() instead.')
  Runtime? tryParse(Object? value, {String? debugName}) {
    final result = safeParse(value, debugName: debugName);
    return result.getOrNull();
  }

  /// Converts this schema to a JSON Schema Draft-7 representation.
  Map<String, Object?> toJsonSchema();

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
  bool baseFieldsEqual(AckSchema other) {
    const listEq = ListEquality<Object?>();
    return isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description &&
        listEq.equals(
          _constraints as List<Object?>,
          other._constraints as List<Object?>,
        ) &&
        listEq.equals(
          _refinements as List<Object?>,
          other._refinements as List<Object?>,
        );
  }

  /// Computes hash code for base schema fields.
  @protected
  int get baseFieldsHashCode {
    const listEq = ListEquality<Object?>();
    return Object.hash(
      isNullable,
      isOptional,
      description,
      listEq.hash(_constraints),
      listEq.hash(_refinements),
    );
  }
}

/// Returns [value] if it is composed entirely of JSON-safe primitives
/// (`null`, `num`, `bool`, `String`, `List`, string-keyed `Map`), recursively.
/// Returns `null` if any nested value is not JSON-safe. Used by
/// [DefaultSchema] to avoid emitting runtime-only objects (e.g. raw
/// `DateTime` instances) as JSON Schema defaults.
Object? jsonSafeOrNull(Object? value) {
  if (value == null) return null;
  if (value is num || value is bool || value is String) return value;
  if (value is List) {
    final result = <Object?>[];
    for (final item in value) {
      if (item == null) {
        result.add(null);
        continue;
      }
      final converted = jsonSafeOrNull(item);
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
      final converted = jsonSafeOrNull(entry.value);
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
JsonMap? coerceJsonMap(Object? value) {
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
