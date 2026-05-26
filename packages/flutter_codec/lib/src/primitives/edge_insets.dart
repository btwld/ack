import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show EdgeInsets, EdgeInsetsDirectional, EdgeInsetsGeometry;

import '../numbers.dart';

/// Codec for [EdgeInsets]. A bare number sets all four sides; an object
/// `{"left": ..., "top": ..., "right": ..., "bottom": ...}` (each side optional,
/// defaulting to `0`) sets them individually. Encoding emits a scalar when all
/// sides are equal, otherwise the full object.
final edgeInsetsCodec = Ack.codec<Object, Object, EdgeInsets>(
  input: Ack.anyOf([
    finiteNumber(),
    Ack.object({
      'left': finiteNumber().withDefault(0.0),
      'top': finiteNumber().withDefault(0.0),
      'right': finiteNumber().withDefault(0.0),
      'bottom': finiteNumber().withDefault(0.0),
    }),
  ]),
  decode: _decodeEdgeInsets,
  encode: _encodeEdgeInsets,
);

EdgeInsets _decodeEdgeInsets(Object value) {
  if (value is num) return EdgeInsets.all(value.toDouble());

  final map = value as JsonMap;
  return EdgeInsets.fromLTRB(
    readDouble(map, 'left'),
    readDouble(map, 'top'),
    readDouble(map, 'right'),
    readDouble(map, 'bottom'),
  );
}

Object _encodeEdgeInsets(EdgeInsets value) {
  if (value.left == value.top &&
      value.top == value.right &&
      value.right == value.bottom) {
    return value.left;
  }

  return {
    'left': value.left,
    'top': value.top,
    'right': value.right,
    'bottom': value.bottom,
  };
}

/// Codec for [EdgeInsetsDirectional], an object
/// `{"start": ..., "top": ..., "end": ..., "bottom": ...}` (each side optional,
/// defaulting to `0`). Always encodes to the object form — never a scalar — so
/// the directional type round-trips even when uniform or zero (a bare number is
/// reserved for [EdgeInsets]).
final edgeInsetsDirectionalCodec =
    Ack.object({
      'start': finiteNumber().withDefault(0.0),
      'top': finiteNumber().withDefault(0.0),
      'end': finiteNumber().withDefault(0.0),
      'bottom': finiteNumber().withDefault(0.0),
    }).model<EdgeInsetsDirectional>(
      decode: (data) => EdgeInsetsDirectional.fromSTEB(
        readDouble(data, 'start'),
        readDouble(data, 'top'),
        readDouble(data, 'end'),
        readDouble(data, 'bottom'),
      ),
      encode: (value) => {
        'start': value.start,
        'top': value.top,
        'end': value.end,
        'bottom': value.bottom,
      },
    );

/// Codec for [EdgeInsetsGeometry], unioning [edgeInsetsCodec] and
/// [edgeInsetsDirectionalCodec].
///
/// A scalar, an `{left, top, right, bottom}` object, a shared `top`/`bottom`-only
/// object, and `{}` decode to [EdgeInsets]; objects carrying `start`/`end` decode
/// to [EdgeInsetsDirectional] ([edgeInsetsCodec] is tried first). Encoding
/// dispatches by runtime type. Mixed insets (from adding an [EdgeInsets] to an
/// [EdgeInsetsDirectional]) are not supported.
final edgeInsetsGeometryCodec =
    Ack.anyOf([
      edgeInsetsCodec,
      edgeInsetsDirectionalCodec,
    ]).codec<EdgeInsetsGeometry>(
      decode: (value) => value as EdgeInsetsGeometry,
      encode: (value) => value,
    );
