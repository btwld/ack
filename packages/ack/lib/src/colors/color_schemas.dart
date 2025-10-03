import '../ack.dart';
import '../schemas/extensions/ack_schema_extensions.dart';
import '../schemas/extensions/numeric_extensions.dart';
import '../schemas/extensions/string_schema_extensions.dart';
import '../schemas/schema.dart';

/// Accepts integer colors in the Flutter-style AARRGGBB packing.
final AckSchema<int> integerColorSchema = Ack.integer()
    .min(0)
    .max(0xFFFFFFFF)
    .describe('Integer 0..0xFFFFFFFF (AARRGGBB)');

/// Accepts strings like #RGB, #RGBA, #RRGGBB, or #RRGGBBAA.
final AckSchema<int> hashHexColorSchema = Ack.string()
    .strictParsing(value: true)
    .describe('Hash hex (#RGB/#RGBA/#RRGGBB/#RRGGBBAA)')
    .matches(
      r'^#(?:[0-9A-Fa-f]{3}|[0-9A-Fa-f]{4}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$',
      example: '#80336699',
    )
    .transform((value) => value!.substring(1))
    .transform<int>((value) => _normalizeHexString(value!));

/// Accepts strings like 0xAARRGGBB (no shorthand) to match Flutter's Color ints.
final AckSchema<int> zeroXHexColorSchema = Ack.string()
    .strictParsing(value: true)
    .describe('0x-prefixed ARGB hex (0xAARRGGBB)')
    .matches(r'^(?:0x|0X)[0-9A-Fa-f]{8}$', example: '0xFF112233')
    .transform((value) => value!.substring(2))
    .transform<int>((value) => _normalizeHexString(value!));

/// Accepts bare hex strings (RGB, RGBA, RRGGBB, AARRGGBB).
final AckSchema<int> bareHexColorSchema = Ack.string()
    .strictParsing(value: true)
    .describe('Bare hex (RGB/RGBA/RRGGBB/AARRGGBB)')
    .matches(
      r'^(?:[0-9A-Fa-f]{3}|[0-9A-Fa-f]{4}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$',
      example: '80336699',
    )
    .transform<int>((value) => _normalizeHexString(value!));

/// Union of all supported representations, normalized to an AARRGGBB integer.
final AckSchema<int> colorSchema = Ack.anyOf([
  integerColorSchema,
  hashHexColorSchema,
  zeroXHexColorSchema,
  bareHexColorSchema,
]).transform<int>((value) {
  if (value is int) return value;
  throw StateError('Expected normalized int, got ${value.runtimeType}.');
});

int _normalizeHexString(String source) {
  final upper = source.trim().toUpperCase();

  final expanded = switch (upper.length) {
    8 => upper,
    6 => 'FF$upper',
    4 => _duplicateEachChar(upper),
    3 => 'FF${_duplicateEachChar(upper)}',
    _ => throw FormatException('Unsupported hex length ${upper.length}.'),
  };

  return int.parse(expanded, radix: 16);
}

String _duplicateEachChar(String value) {
  final buffer = StringBuffer();
  for (final char in value.split('')) {
    buffer
      ..write(char)
      ..write(char);
  }
  return buffer.toString();
}
