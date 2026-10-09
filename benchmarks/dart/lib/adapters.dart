import 'package:acanthis/acanthis.dart' as ac;
import 'package:ack/ack.dart';
import 'package:json_schema/json_schema.dart' as js;
import 'package:validart/validart.dart' as va;

typedef JsonObject = Map<String, Object?>;

const engines = [
  'ack',
  'ack-json-schema',
  'acanthis',
  'validart',
  'json-schema',
];

/// Retains the native result, so timing cannot discard its construction.
/// [snapshot] is consumed outside the timed loop; no error formatting is timed.
final class PreparedValidator {
  const PreparedValidator(this.validate, this.output, this.snapshot);

  final bool Function(Object?) validate;
  final Object? Function() output;
  final Object? Function() snapshot;
}

PreparedValidator prepare(String engine, JsonObject definition) {
  switch (engine) {
    case 'ack':
    case 'ack-json-schema':
      final schema = engine == 'ack'
          ? _ack(definition)
          : Ack.fromJsonSchema({
              ...definition,
              // All corpus keywords have the same meaning in both drafts.
              // Ack imports 2020-12 only; json_schema supports Draft-7.
              r'$schema': 'https://json-schema.org/draft/2020-12/schema',
            });
      late SchemaResult<Object> result;
      return PreparedValidator(
        (input) {
          result = schema.safeParse(input);
          return result.isOk;
        },
        () => result.getOrNull(),
        () => result.isOk ? result.getOrNull() : result.getError().toString(),
      );
    case 'acanthis':
      final schema = _acanthis(definition);
      late ac.AcanthisOutcome<Object?> result;
      return PreparedValidator(
        (input) {
          result = schema.tryParse(input);
          return result.isValid;
        },
        () => result.value,
        () => result.isValid ? result.value : result.issues.toString(),
      );
    case 'validart':
      final schema = _validart(definition);
      late va.VResult<Object?> result;
      Object? output() => switch (result) {
        va.VSuccess(:final value) => value,
        va.VFailure() => null,
      };
      return PreparedValidator(
        (input) {
          result = schema.safeParse(input);
          return result.isValid;
        },
        output,
        () => switch (result) {
          va.VSuccess(:final value) => value,
          va.VFailure(:final errors) => errors.toString(),
        },
      );
    case 'json-schema':
      final schema = js.JsonSchema.create(definition);
      late js.ValidationResults result;
      Object? lastInput;
      return PreparedValidator(
        (input) {
          lastInput = input;
          // This public API collects multiple errors; it is not fail-fast.
          result = schema.validate(input);
          return result.isValid;
        },
        () => lastInput,
        () => result.isValid ? lastInput : result.errors.toString(),
      );
    default:
      throw ArgumentError.value(engine, 'engine', 'Unknown benchmark engine');
  }
}

// These intentionally support only the corpus's strict, required-field subset.
// They are not general JSON Schema converters. Translation runs at setup time.
AckSchema<Object, Object> _ack(JsonObject s) => switch (s['type']) {
  'string' =>
    Ack.string()
        .minLength(s['minLength'] as int)
        .maxLength(s['maxLength'] as int)
        .matches(s['pattern'] as String),
  'integer' => Ack.integer().min(s['minimum'] as int).max(s['maximum'] as int),
  'boolean' => Ack.boolean(),
  'array' => Ack.list(
    _ack(s['items'] as JsonObject),
  ).minLength(s['minItems'] as int).maxLength(s['maxItems'] as int),
  'object' => Ack.object({
    for (final e in (s['properties'] as JsonObject).entries)
      e.key: _ack(e.value as JsonObject),
  }),
  _ => throw UnsupportedError('Unsupported type ${s['type']}'),
};

ac.AcanthisType<Object?> _acanthis(JsonObject s) => switch (s['type']) {
  'string' =>
    ac
        .string()
        .min(s['minLength'] as int)
        .max(s['maxLength'] as int)
        .pattern(RegExp(s['pattern'] as String)),
  'integer' => ac.integer().gte(s['minimum'] as int).lte(s['maximum'] as int),
  'boolean' => ac.boolean(),
  'array' =>
    ac
        .list(_acanthis(s['items'] as JsonObject))
        .min(s['minItems'] as int)
        .max(s['maxItems'] as int),
  'object' =>
    ac
        .object({
          for (final e in (s['properties'] as JsonObject).entries)
            e.key: _acanthis(e.value as JsonObject),
        })
        .unknownKeys(ac.AcanthisUnknownKeys.reject),
  _ => throw UnsupportedError('Unsupported type ${s['type']}'),
};

va.VType<Object?> _validart(JsonObject s) => switch (s['type']) {
  'string' =>
    va.V
        .string()
        .min(s['minLength'] as int)
        .max(s['maxLength'] as int)
        .pattern(s['pattern'] as String),
  'integer' => va.V.int().min(s['minimum'] as int).max(s['maximum'] as int),
  'boolean' => va.V.bool(),
  'array' =>
    va.V
        .array(_validart(s['items'] as JsonObject))
        .min(s['minItems'] as int)
        .max(s['maxItems'] as int),
  'object' => va.V.map({
    for (final e in (s['properties'] as JsonObject).entries)
      e.key: _validart(e.value as JsonObject),
  }).strict(),
  _ => throw UnsupportedError('Unsupported type ${s['type']}'),
};
