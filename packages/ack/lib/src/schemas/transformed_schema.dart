part of 'schema.dart';

/// Deprecated alias for [CodecSchema].
///
/// `TransformedSchema` was the previous one-way transform schema. It has been
/// folded into [CodecSchema], which now supports both one-way (created via
/// the `.transform(fn)` extension) and bidirectional (`Ack.codec(...)`) forms.
///
/// **Type annotations only.** This alias preserves source compatibility for
/// declarations like `TransformedSchema<String, DateTime>`. The class's
/// previous positional constructor `TransformedSchema(schema, transformer)`
/// and its `.schema` / `.transformer` field accessors are no longer
/// available — migrate to:
///
/// ```dart
/// CodecSchema<I, O>(
///   inputSchema: ...,
///   outputSchema: ...,
///   decodeFn: ...,
///   encodeFn: ...,
/// );
/// ```
///
/// and use `.inputSchema` / `.decodeFn` (and `.outputSchema` / `.encodeFn`)
/// for field access. The alias will be removed in a future release.
@Deprecated(
  'TransformedSchema is now a typedef alias for CodecSchema. Type annotations '
  'continue to work, but the previous positional constructor and the '
  '.schema / .transformer fields are no longer available — use CodecSchema '
  'with named constructor parameters and .inputSchema / .decodeFn instead. '
  'This alias will be removed in a future release.',
)
typedef TransformedSchema<InputType extends Object, OutputType extends Object> =
    CodecSchema<InputType, OutputType>;
