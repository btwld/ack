import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show Alignment, AlignmentDirectional, AlignmentGeometry;

import '../json_readers.dart';

/// Named [Alignment] constants, encoded as string aliases.
enum _Alignment {
  topLeft(Alignment.topLeft),
  topCenter(Alignment.topCenter),
  topRight(Alignment.topRight),
  centerLeft(Alignment.centerLeft),
  center(Alignment.center),
  centerRight(Alignment.centerRight),
  bottomLeft(Alignment.bottomLeft),
  bottomCenter(Alignment.bottomCenter),
  bottomRight(Alignment.bottomRight);

  const _Alignment(this.value);

  final Alignment value;
}

/// Codec for [Alignment]. Named constants (`"center"`, `"topLeft"`, …) encode
/// and decode as strings; arbitrary values use `{"x": ..., "y": ...}`. Encoding
/// emits the name when the value matches a constant, otherwise the object.
final alignmentCodec = Ack.codec<Object, Object, Alignment>(
  input: Ack.anyOf([
    Ack.enumCodec(_Alignment.values),
    Ack.object({'x': Ack.number(), 'y': Ack.number()}),
  ]),
  decode: _decodeAlignment,
  encode: _encodeAlignment,
);

Alignment _decodeAlignment(Object value) {
  if (value is _Alignment) return value.value;

  final map = value as JsonMap;
  return Alignment(readDouble(map, 'x'), readDouble(map, 'y'));
}

Object _encodeAlignment(Alignment value) {
  for (final named in _Alignment.values) {
    if (named.value == value) return named;
  }

  return {'x': value.x, 'y': value.y};
}

/// Named [AlignmentDirectional] constants, encoded as string aliases.
enum _AlignmentDirectional {
  topStart(AlignmentDirectional.topStart),
  topCenter(AlignmentDirectional.topCenter),
  topEnd(AlignmentDirectional.topEnd),
  centerStart(AlignmentDirectional.centerStart),
  center(AlignmentDirectional.center),
  centerEnd(AlignmentDirectional.centerEnd),
  bottomStart(AlignmentDirectional.bottomStart),
  bottomCenter(AlignmentDirectional.bottomCenter),
  bottomEnd(AlignmentDirectional.bottomEnd);

  const _AlignmentDirectional(this.value);

  final AlignmentDirectional value;
}

/// Codec for [AlignmentDirectional]. Named constants (`"centerStart"`,
/// `"topEnd"`, …) encode and decode as strings; arbitrary values use
/// `{"start": ..., "y": ...}`. Encoding emits the name when the value matches a
/// constant, otherwise the object.
final alignmentDirectionalCodec =
    Ack.codec<Object, Object, AlignmentDirectional>(
      input: Ack.anyOf([
        Ack.enumCodec(_AlignmentDirectional.values),
        Ack.object({'start': Ack.number(), 'y': Ack.number()}),
      ]),
      decode: _decodeAlignmentDirectional,
      encode: _encodeAlignmentDirectional,
    );

AlignmentDirectional _decodeAlignmentDirectional(Object value) {
  if (value is _AlignmentDirectional) return value.value;

  final map = value as JsonMap;
  return AlignmentDirectional(readDouble(map, 'start'), readDouble(map, 'y'));
}

Object _encodeAlignmentDirectional(AlignmentDirectional value) {
  for (final named in _AlignmentDirectional.values) {
    if (named.value == value) return named;
  }

  return {'start': value.start, 'y': value.y};
}

/// Codec for [AlignmentGeometry].
///
/// Decoding: the regular names and `{x, y}` produce [Alignment]; the
/// directional names and `{start, y}` produce [AlignmentDirectional]. The
/// shared center-column names (`"center"`, `"topCenter"`, `"bottomCenter"`)
/// decode to [Alignment], since the [Alignment] forms are tried first.
///
/// Encoding: an [Alignment] uses its name or `{x, y}`. An [AlignmentDirectional]
/// uses its name too, except the three center-column constants
/// ([AlignmentDirectional.topCenter], `.center`, `.bottomCenter`) whose names
/// collide with [Alignment] and would otherwise decode back as [Alignment];
/// those are emitted as `{start, y}` so they round-trip as directional values.
/// (The standalone [alignmentDirectionalCodec] has no such collision and keeps
/// emitting names.)
///
/// Mixed alignments (the result of adding an [Alignment] to an
/// [AlignmentDirectional]) are not supported.
final alignmentGeometryCodec = Ack.codec<Object, Object, AlignmentGeometry>(
  input: Ack.anyOf([
    Ack.enumCodec(_Alignment.values),
    Ack.object({'x': Ack.number(), 'y': Ack.number()}),
    Ack.enumCodec(_AlignmentDirectional.values),
    Ack.object({'start': Ack.number(), 'y': Ack.number()}),
  ]),
  decode: _decodeAlignmentGeometry,
  encode: _encodeAlignmentGeometry,
);

AlignmentGeometry _decodeAlignmentGeometry(Object value) {
  final isDirectional =
      value is _AlignmentDirectional ||
      (value is JsonMap && value.containsKey('start'));
  return isDirectional
      ? _decodeAlignmentDirectional(value)
      : _decodeAlignment(value);
}

/// The center-column directional constants share a spelling with [Alignment]
/// names, so they must not be emitted as names through [alignmentGeometryCodec].
/// (Not `const`: [AlignmentDirectional] overrides `==`.)
final _centerColumnDirectionals = <AlignmentDirectional>{
  AlignmentDirectional.topCenter,
  AlignmentDirectional.center,
  AlignmentDirectional.bottomCenter,
};

Object _encodeAlignmentGeometry(AlignmentGeometry value) {
  if (value is Alignment) return _encodeAlignment(value);
  if (value is AlignmentDirectional) {
    // The center-column names would decode back as Alignment; emit the
    // {start, y} object form for them so they stay directional.
    return _centerColumnDirectionals.contains(value)
        ? {'start': value.start, 'y': value.y}
        : _encodeAlignmentDirectional(value);
  }
  throw UnsupportedError(
    'alignmentGeometryCodec cannot encode ${value.runtimeType}; only '
    'Alignment and AlignmentDirectional are supported.',
  );
}
