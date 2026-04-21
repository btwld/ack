import 'package:ack/ack.dart';
import 'package:test/test.dart';

class _Color {
  final String hex;
  const _Color(this.hex);

  factory _Color.fromHex(String value) => _Color(value.toUpperCase());

  String toHex() => hex;

  @override
  bool operator ==(Object other) => other is _Color && other.hex == hex;

  @override
  int get hashCode => hex.hashCode;
}

final _hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

CodecSchema<String, _Color> _colorCodec() => Ack.codec<String, _Color>(
  Ack.string().matches(r'^#[0-9A-Fa-f]{6}$'),
  Ack.custom<_Color>(
    validate: (c) => _hexPattern.hasMatch(c.hex),
    message: 'Invalid Color value',
  ),
  decode: _Color.fromHex,
  encode: (c) => c.toHex(),
);

void main() {
  group('CodecSchema - basics (same-type)', () {
    final schema = Ack.codec<String, String>(
      Ack.string().matches(r'^#[0-9A-Fa-f]{6}$'),
      Ack.string().matches(r'^#[0-9A-Fa-f]{6}$'),
      decode: (hex) => hex.toUpperCase(),
      encode: (hex) => hex.toUpperCase(),
    );

    test('decode valid lowercase hex -> uppercase hex', () {
      final result = schema.safeDecode('#ff00aa');
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), '#FF00AA');
    });

    test('encode uppercase hex -> uppercase hex', () {
      final result = schema.safeEncode('#FF00AA');
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), '#FF00AA');
    });

    test('invalid input fails before decoder runs', () {
      final result = schema.safeDecode('nope');
      expect(result.isFail, isTrue);
    });

    test('round trip is stable', () {
      final decoded = schema.decode('#abcdef');
      final encoded = schema.encode(decoded);
      expect(encoded, '#ABCDEF');
    });
  });

  group('CodecSchema - String <-> Color', () {
    final codec = _colorCodec();

    test('decode valid hex -> Color', () {
      final color = codec.decode('#ff00aa');
      expect(color, isA<_Color>());
      expect(color!.hex, '#FF00AA');
    });

    test('parse() is equivalent to decode()', () {
      expect(codec.parse('#abcdef'), const _Color('#ABCDEF'));
    });

    test('encode valid Color -> hex', () {
      final encoded = codec.safeEncode(const _Color('#ABCDEF'));
      expect(encoded.isOk, isTrue);
      expect(encoded.getOrNull(), '#ABCDEF');
    });

    test('decoder exception is wrapped as SchemaTransformError', () {
      final boom = Ack.codec<String, _Color>(
        Ack.string(),
        Ack.custom<_Color>(),
        decode: (_) => throw StateError('boom'),
        encode: (c) => c.hex,
      );
      final result = boom.safeDecode('anything');
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaTransformError>());
      expect(result.getError().message, contains('Codec decode failed'));
    });

    test('encoder exception is wrapped as SchemaEncodeError', () {
      final boom = Ack.codec<String, _Color>(
        Ack.string().matches(r'^#[0-9A-Fa-f]{6}$'),
        Ack.custom<_Color>(),
        decode: _Color.fromHex,
        encode: (_) => throw StateError('boom'),
      );
      final result = boom.safeEncode(const _Color('#FF00AA'));
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
      expect(result.getError().message, contains('Codec encode failed'));
    });

    test('invalid Color object fails before encoder runs', () {
      final result = codec.safeEncode(const _Color('not-a-hex'));
      expect(result.isFail, isTrue);
      // Failure comes from the output-side custom validator, not encoder.
      expect(result.getError().message, contains('Invalid Color value'));
    });

    test('encode of wrong runtime type yields SchemaEncodeError', () {
      final result = codec.safeEncode('just a string');
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });
  });

  group('CodecSchema - object integration', () {
    final codec = _colorCodec();
    final userSchema = Ack.object({
      'name': Ack.string(),
      'favoriteColor': codec,
    });

    test('decode converts codec fields', () {
      final result = userSchema.safeParse({
        'name': 'Ada',
        'favoriteColor': '#ff0000',
      });
      expect(result.isOk, isTrue);
      final decoded = result.getOrNull()!;
      expect(decoded['name'], 'Ada');
      expect(decoded['favoriteColor'], const _Color('#FF0000'));
    });

    test('encode serializes codec fields', () {
      final encoded = userSchema.safeEncode({
        'name': 'Ada',
        'favoriteColor': const _Color('#FF0000'),
      });
      expect(encoded.isOk, isTrue);
      expect(encoded.getOrNull(), {'name': 'Ada', 'favoriteColor': '#FF0000'});
    });

    test('invalid nested codec input preserves field path', () {
      final result = userSchema.safeParse({
        'name': 'Ada',
        'favoriteColor': 'not-hex',
      });
      expect(result.isFail, isTrue);
      final error = result.getError() as SchemaNestedError;
      expect(error.errors.single.path, '#/favoriteColor');
    });

    test('invalid nested codec output preserves field path on encode', () {
      final result = userSchema.safeEncode({
        'name': 'Ada',
        'favoriteColor': const _Color('bad'),
      });
      expect(result.isFail, isTrue);
      final error = result.getError() as SchemaNestedError;
      expect(error.errors.single.path, '#/favoriteColor');
    });
  });

  group('CodecSchema - list integration', () {
    final codec = _colorCodec();
    final palette = Ack.list(codec);

    test('list decode converts codec items', () {
      final result = palette.safeParse(['#ff0000', '#00ff00']);
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), [
        const _Color('#FF0000'),
        const _Color('#00FF00'),
      ]);
    });

    test('list encode serializes codec items', () {
      final result = palette.safeEncode([
        const _Color('#FF0000'),
        const _Color('#00FF00'),
      ]);
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), ['#FF0000', '#00FF00']);
    });

    test('invalid list item reports indexed path', () {
      final result = palette.safeParse(['#ff0000', 'nope']);
      expect(result.isFail, isTrue);
      final error = result.getError() as SchemaNestedError;
      expect(error.errors.single.path, '#/1');
    });
  });

  group('TransformedSchema - unidirectional', () {
    test('safeEncode fails clearly with SchemaEncodeError', () {
      final schema = Ack.string().transform<int>((s) => s.length);
      final result = schema.safeEncode(5);
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
      expect(
        result.getError().message,
        contains('Encountered unidirectional transform'),
      );
    });

    test('encode inside object bubbles up the error with field path', () {
      final schema = Ack.object({
        'len': Ack.string().transform<int>((s) => s.length),
      });
      final result = schema.safeEncode({'len': 5});
      expect(result.isFail, isTrue);
      final error = result.getError() as SchemaNestedError;
      expect(error.errors.single, isA<SchemaEncodeError>());
      expect(error.errors.single.path, '#/len');
    });
  });

  group('CodecSchema - optional/default behavior', () {
    final codec = _colorCodec();

    test('optional field absent on encode is omitted', () {
      final schema = Ack.object({
        'name': Ack.string(),
        'color': codec.optional(),
      });
      final result = schema.safeEncode({'name': 'Ada'});
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), {'name': 'Ada'});
    });

    test('defaults are used during decode', () {
      final defaulted = _colorCodec().copyWith(
        defaultValue: const _Color('#000000'),
      );
      final schema = Ack.object({'color': defaulted.optional()});
      final result = schema.safeParse(<String, Object?>{});
      expect(result.isOk, isTrue);
      expect(result.getOrNull()!['color'], const _Color('#000000'));
    });

    test('defaults are NOT synthesized during encode', () {
      final defaulted = _colorCodec().copyWith(
        defaultValue: const _Color('#000000'),
      );
      final schema = Ack.object({'color': defaulted});
      final result = schema.safeEncode(<String, Object?>{});
      expect(result.isFail, isTrue);
      final error = result.getError() as SchemaNestedError;
      expect(error.errors.single, isA<SchemaEncodeError>());
    });

    test('nullable codec accepts null on encode', () {
      final schema = _colorCodec().nullable();
      expect(schema.safeEncode(null).isOk, isTrue);
    });

    test('non-nullable codec rejects null on encode', () {
      final schema = _colorCodec();
      final result = schema.safeEncode(null);
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });
  });

  group('Ack.custom<T>()', () {
    test('accepts matching runtime type', () {
      final schema = Ack.custom<_Color>();
      final result = schema.safeParse(const _Color('#112233'));
      expect(result.isOk, isTrue);
    });

    test('rejects wrong runtime type', () {
      final schema = Ack.custom<_Color>();
      final result = schema.safeParse('not a color');
      expect(result.isFail, isTrue);
    });

    test('runs predicate after type check', () {
      final schema = Ack.custom<_Color>(
        validate: (c) => c.hex.startsWith('#'),
        message: 'must start with #',
      );
      expect(schema.safeParse(const _Color('#112233')).isOk, isTrue);
      final bad = schema.safeParse(const _Color('112233'));
      expect(bad.isFail, isTrue);
      expect(bad.getError().message, 'must start with #');
    });
  });

  group('Plain schemas - forward-only encode passthrough', () {
    test('string safeEncode validates already-runtime string', () {
      final schema = Ack.string().minLength(3);
      expect(schema.safeEncode('hello').isOk, isTrue);
      expect(schema.safeEncode('no').isFail, isTrue);
    });

    test('integer safeEncode validates already-runtime int', () {
      final schema = Ack.integer();
      expect(schema.safeEncode(42).isOk, isTrue);
      final wrongType = schema.safeEncode('42');
      expect(wrongType.isFail, isTrue);
      expect(wrongType.getError(), isA<SchemaEncodeError>());
    });
  });
}
