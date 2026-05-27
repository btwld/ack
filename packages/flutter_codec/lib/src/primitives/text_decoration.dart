import 'dart:ui' show TextDecoration;

import 'package:ack/ack.dart';

// Atomic TextDecoration aliases, encoded as string names.
enum _TextDecoration { none, underline, overline, lineThrough }

final _atomicCodec = Ack.enumCodec(_TextDecoration.values);

/// Codec for [TextDecoration].
///
/// Accepts atomic aliases such as `"underline"` and combined arrays such as
/// `["underline", "overline"]`. Encoding emits the shortest canonical form:
/// a bare string for atomic values and an array for composed values.
final textDecorationCodec = Ack.codec<Object, Object, TextDecoration>(
  input: Ack.anyOf([_atomicCodec, Ack.list(_atomicCodec)]),
  decode: _decodeTextDecoration,
  encode: _encodeTextDecoration,
);

TextDecoration _decodeTextDecoration(Object value) {
  if (value is _TextDecoration) return _atomicToTextDecoration(value);

  final decorations = (value as List)
      .cast<_TextDecoration>()
      .where((atomic) => atomic != _TextDecoration.none)
      .map(_atomicToTextDecoration)
      .toList();
  if (decorations.isEmpty) return TextDecoration.none;

  return TextDecoration.combine(decorations);
}

TextDecoration _atomicToTextDecoration(_TextDecoration value) {
  return switch (value) {
    _TextDecoration.none => TextDecoration.none,
    _TextDecoration.underline => TextDecoration.underline,
    _TextDecoration.overline => TextDecoration.overline,
    _TextDecoration.lineThrough => TextDecoration.lineThrough,
  };
}

Object _encodeTextDecoration(TextDecoration value) {
  if (value == TextDecoration.none) return _TextDecoration.none;
  if (value == TextDecoration.underline) return _TextDecoration.underline;
  if (value == TextDecoration.overline) return _TextDecoration.overline;
  if (value == TextDecoration.lineThrough) return _TextDecoration.lineThrough;

  return [
    if (value.contains(TextDecoration.underline)) _TextDecoration.underline,
    if (value.contains(TextDecoration.overline)) _TextDecoration.overline,
    if (value.contains(TextDecoration.lineThrough)) _TextDecoration.lineThrough,
  ];
}
