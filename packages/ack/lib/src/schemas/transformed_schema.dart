part of 'schema.dart';

/// Deprecated alias for [CodecSchema].
///
/// `TransformedSchema` was the previous one-way transform schema. It has been
/// folded into [CodecSchema], which now supports both one-way (created via
/// the `.transform(fn)` extension) and bidirectional (`Ack.codec(...)`) forms.
/// Use [CodecSchema] directly in new code; this alias will be removed in a
/// future release.
@Deprecated('Use CodecSchema instead. This alias will be removed in a future release.')
typedef TransformedSchema<InputType extends Object, OutputType extends Object>
    = CodecSchema<InputType, OutputType>;
