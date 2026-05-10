part of 'schema.dart';

/// Legacy alias for [CodecSchema] retained for source compatibility.
///
/// Before M13, `TransformedSchema<I, O>` was a hand-rolled one-way
/// transform schema. In M13 transforms were unified under [CodecSchema]
/// (a one-way codec is `CodecSchema(..., encoder: null)`), and this
/// typedef preserves type annotations like
/// `TransformedSchema<String, DateTime>` without keeping a parallel
/// implementation.
///
/// The old positional constructor `TransformedSchema(schema, transformer, ...)`
/// is gone — use `schema.transform<R>(...)` (which returns `CodecSchema<T, R>`)
/// or construct [CodecSchema] directly. The legacy `.schema` and
/// `.transformer` fields are gone too — the equivalents are
/// [CodecSchema.inputSchema] and [CodecSchema.decoder].
@Deprecated(
  'TransformedSchema is now an alias for CodecSchema. '
  'Use `schema.transform(...)` or construct CodecSchema directly.',
)
typedef TransformedSchema<InputType extends Object, OutputType extends Object>
    = CodecSchema<InputType, OutputType>;
