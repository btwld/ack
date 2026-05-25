import 'package:ack/ack.dart';
import 'package:flutter/painting.dart' show Color;

final colorCodec = Ack.codec<Object, Object, Color>(
  input: Ack.anyOf([
    Ack.string().matches(r'^#[0-9A-Fa-f]{6}$'),
    Ack.string().matches(r'^#[0-9A-Fa-f]{8}$'),
    Ack.string().matches(r'^rgb\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*\)$'),
    Ack.string().matches(
      r'^rgba\(\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*(?:0|1|0?\.\d+|1\.0+)\s*\)$',
    ),
  ]),
  decode: (value) => _parseColor(value as String),
  encode: _encodeColor,
);

Color _parseColor(String value) {
  if (value.startsWith('#')) {
    return _parseHexColor(value);
  }
  if (value.startsWith('rgb(')) {
    return _parseRgbColor(value);
  }
  if (value.startsWith('rgba(')) {
    return _parseRgbaColor(value);
  }
  throw FormatException('Unsupported color format: $value');
}

Color _parseHexColor(String value) {
  final hex = value.substring(1);
  final argb = hex.length == 6 ? 'FF$hex' : hex;
  return Color(int.parse(argb, radix: 16));
}

Color _parseRgbColor(String value) {
  final channels = _parseChannelList(value, prefix: 'rgb(', count: 3);
  return Color.fromARGB(0xFF, channels[0], channels[1], channels[2]);
}

Color _parseRgbaColor(String value) {
  final channels = _parseChannelList(value, prefix: 'rgba(', count: 4);
  final alpha = channels[3];
  return Color.fromARGB(alpha, channels[0], channels[1], channels[2]);
}

List<int> _parseChannelList(
  String value, {
  required String prefix,
  required int count,
}) {
  final rawParts = value.substring(prefix.length, value.length - 1).split(',');
  if (rawParts.length != count) {
    throw FormatException('Expected $count color channels.');
  }

  final rgb = rawParts
      .take(3)
      .map((part) {
        final channel = int.parse(part.trim());
        if (channel < 0 || channel > 255) {
          throw FormatException('Color channel out of range: $channel');
        }
        return channel;
      })
      .toList(growable: false);

  if (count == 3) return rgb;

  final alpha = double.parse(rawParts[3].trim());
  if (alpha < 0 || alpha > 1) {
    throw FormatException('Alpha channel out of range: $alpha');
  }
  return [...rgb, (alpha * 255).round()];
}

Object _encodeColor(Color value) {
  final argb = value.toARGB32();
  final alpha = (argb >> 24) & 0xFF;
  final red = (argb >> 16) & 0xFF;
  final green = (argb >> 8) & 0xFF;
  final blue = argb & 0xFF;

  if (alpha == 0xFF) {
    return '#${_hex2(red)}${_hex2(green)}${_hex2(blue)}';
  }

  return '#${_hex2(alpha)}${_hex2(red)}${_hex2(green)}${_hex2(blue)}';
}

String _hex2(int value) =>
    value.toRadixString(16).padLeft(2, '0').toUpperCase();
