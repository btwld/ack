import 'package:ack/ack.dart';
import 'package:flutter/rendering.dart' show BoxConstraints, Constraints;

/// Codec for [BoxConstraints].
///
/// Bounds are emitted as a full canonical map. `double.infinity` is encoded as
/// `null` because JSON has no non-finite number literal. Omitted min bounds
/// decode to `0`; explicit null min bounds decode to `double.infinity`.
/// Omitted or null max bounds decode to `double.infinity`.
final boxConstraintsCodec =
    Ack.object({
          'minWidth': Ack.number().min(0).nullable().optional(),
          'maxWidth': Ack.number().min(0).nullable().optional(),
          'minHeight': Ack.number().min(0).nullable().optional(),
          'maxHeight': Ack.number().min(0).nullable().optional(),
        })
        // Reject inverted bounds. The same null/infinity resolution the decoder
        // uses is applied first, so this matches the BoxConstraints actually
        // produced (and keeps the invariant in release builds, where Flutter's
        // own `isNormalized` assert is stripped).
        .refine(
          (data) =>
              _readMinBound(data, 'minWidth') <=
                  _readMaxBound(data, 'maxWidth') &&
              _readMinBound(data, 'minHeight') <=
                  _readMaxBound(data, 'maxHeight'),
          message:
              'BoxConstraints require minWidth <= maxWidth and '
              'minHeight <= maxHeight.',
        )
        .codec<BoxConstraints>(
          decode: (data) => BoxConstraints(
            minWidth: _readMinBound(data, 'minWidth'),
            maxWidth: _readMaxBound(data, 'maxWidth'),
            minHeight: _readMinBound(data, 'minHeight'),
            maxHeight: _readMaxBound(data, 'maxHeight'),
          ),
          encode: (value) => {
            'minWidth': _encodeBound(value.minWidth),
            'maxWidth': _encodeBound(value.maxWidth),
            'minHeight': _encodeBound(value.minHeight),
            'maxHeight': _encodeBound(value.maxHeight),
          },
        );

/// Codec for Flutter [Constraints], discriminated by `"type"`.
///
/// Fields that are statically typed as [BoxConstraints] should continue to use
/// [boxConstraintsCodec] directly. Use this union only where the runtime
/// constraints subtype is ambiguous.
final DiscriminatedObjectSchema<Constraints> constraintsCodec =
    Ack.discriminated<Constraints>(
      discriminatorKey: 'type',
      schemas: {'box': boxConstraintsCodec},
    );

double _readMinBound(JsonMap data, String key) {
  if (!data.containsKey(key)) return 0;
  final value = data[key];
  if (value == null) return double.infinity;
  return (value as num).toDouble();
}

double _readMaxBound(JsonMap data, String key) {
  final value = data[key];
  if (value == null) return double.infinity;
  return (value as num).toDouble();
}

double? _encodeBound(double value) {
  return value == double.infinity ? null : value;
}
