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

void expectEncodeFailure(
  SchemaResult<Object> result, {
  String? messageContains,
}) {
  expect(result.isFail, isTrue);
  final error = result.getError();
  expect(error, isA<SchemaEncodeError>());
  if (messageContains != null) {
    expect(error.message, contains(messageContains));
  }
}

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
      expectEncodeFailure(result, messageContains: 'Codec encode failed');
    });

    test('invalid Color object fails before encoder runs', () {
      final result = codec.safeEncode(const _Color('not-a-hex'));
      expect(result.isFail, isTrue);
      // Failure comes from the output-side custom validator, not encoder.
      expect(result.getError().message, contains('Invalid Color value'));
    });

    test('encode of wrong runtime type yields SchemaEncodeError', () {
      final result = codec.safeEncode('just a string');
      expectEncodeFailure(result, messageContains: 'Expected runtime type');
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
      expectEncodeFailure(
        result,
        messageContains: 'Encountered unidirectional transform',
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
      expectEncodeFailure(result, messageContains: 'cannot be null');
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
      expectEncodeFailure(wrongType, messageContains: 'Expected int');
    });
  });

  group('CodecSchema.inverse()', () {
    test('round-trips identity through inverse', () {
      final codec = _colorCodec();
      final inverse = codec.inverse();

      final color = codec.decode('#abcdef')!;
      // The inverse decodes from runtime -> boundary, encoding -> back.
      expect(inverse.decode(color), '#ABCDEF');
      expect(inverse.encode('#ABCDEF'), const _Color('#ABCDEF'));
    });

    test('inverse swaps input and output schemas', () {
      final codec = _colorCodec();
      final inv = codec.inverse();
      expect(inv.inputSchema, codec.outputSchema);
      expect(inv.outputSchema, codec.inputSchema);
    });

    test('inverse preserves description, isNullable, isOptional', () {
      final codec = _colorCodec().copyWith(description: 'a hex color');
      final inv = codec.inverse();
      expect(inv.description, 'a hex color');
      expect(inv.isNullable, codec.isNullable);
      expect(inv.isOptional, codec.isOptional);
    });
  });

  group('AnyOfSchema - encode dispatch', () {
    final codec = _colorCodec();
    final schema = Ack.anyOf([codec, Ack.string()]);

    test('encodes through the matching codec branch', () {
      final result = schema.safeEncode(const _Color('#FF0000'));
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), '#FF0000');
    });

    test('encodes through the fallback string branch', () {
      final result = schema.safeEncode('hello');
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), 'hello');
    });

    test('all-fail returns SchemaNestedError with branch errors', () {
      final result = schema.safeEncode(42);
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaNestedError>());
      final nested = result.getError() as SchemaNestedError;
      expect(nested.errors, hasLength(2));
    });
  });

  group('DiscriminatedObjectSchema - encode dispatch', () {
    final schema = Ack.discriminated<Map<String, Object?>>(
      discriminatorKey: 'kind',
      schemas: {
        'point': Ack.object({
          'kind': Ack.literal('point'),
          'x': Ack.integer(),
          'y': Ack.integer(),
        }),
        'circle': Ack.object({
          'kind': Ack.literal('circle'),
          'r': Ack.integer(),
        }),
      },
    );

    test('encodes via discriminator key when value is a Map', () {
      final result = schema.safeEncode({'kind': 'point', 'x': 1, 'y': 2});
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), {'kind': 'point', 'x': 1, 'y': 2});
    });

    test('unknown discriminator yields SchemaEncodeError with field path', () {
      final result = schema.safeEncode({'kind': 'square', 'side': 1});
      expectEncodeFailure(result, messageContains: 'Unknown discriminator');
      expect(result.getError().path, '#/kind');
    });

    test('Map without discriminator key falls back to branch attempts', () {
      final result = schema.safeEncode({'x': 1, 'y': 2});
      expect(result.isFail, isTrue);
      // No branch matches without the discriminator, so we expect the
      // aggregated nested error from the fallback path.
      expect(result.getError(), isA<SchemaNestedError>());
    });

    test('Tier 2 fallback succeeds via the first matching branch', () {
      // A discriminated schema where the runtime value isn't a Map. The
      // branches encode through inner codecs that produce a Map only for
      // the matching shape — so the fallback walks branches and the first
      // one that succeeds wins.
      final fooCodec = Ack.codec<Map<String, Object?>, String>(
        Ack.object({'kind': Ack.literal('foo'), 'v': Ack.string()}),
        Ack.string(),
        decode: (m) => m['v']! as String,
        encode: (s) => {'kind': 'foo', 'v': s},
      );
      final barCodec = Ack.codec<Map<String, Object?>, int>(
        Ack.object({'kind': Ack.literal('bar'), 'n': Ack.integer()}),
        Ack.integer(),
        decode: (m) => m['n']! as int,
        encode: (i) => {'kind': 'bar', 'n': i},
      );
      // We construct the discriminated schema with a common Object output
      // type so both branches fit. (T = Object covers both String and int.)
      final union = Ack.discriminated<Object>(
        discriminatorKey: 'kind',
        schemas: {'foo': fooCodec, 'bar': barCodec},
      );

      final encoded = union.safeEncode('hello');
      expect(encoded.isOk, isTrue);
      expect(encoded.getOrNull(), {'kind': 'foo', 'v': 'hello'});

      final encoded2 = union.safeEncode(42);
      expect(encoded2.isOk, isTrue);
      expect(encoded2.getOrNull(), {'kind': 'bar', 'n': 42});
    });

    test('T1.2: TransformedSchema branch yields named unidirectional error; '
        'codec branch still succeeds', () {
      // Build a union with one unidirectional (transform) branch and one
      // bidirectional (codec) branch.
      final transformBranch = Ack.object({
        'kind': Ack.literal('t'),
        'v': Ack.string(),
      }).transform<String>((m) => m['v']! as String);

      final codecBranch = Ack.codec<Map<String, Object?>, String>(
        Ack.object({'kind': Ack.literal('c'), 'v': Ack.string()}),
        Ack.string(),
        decode: (m) => m['v']! as String,
        encode: (s) => {'kind': 'c', 'v': s},
      );

      final union = Ack.discriminated<Object>(
        discriminatorKey: 'kind',
        schemas: {'t': transformBranch, 'c': codecBranch},
      );

      // Encoding through the transform branch must fail with a clear message.
      final failResult = union.safeEncode({'kind': 't', 'v': 'hello'});
      expect(failResult.isFail, isTrue);
      final error = failResult.getError();
      expect(error, isA<SchemaUnidirectionalEncodeError>());
      expect(error.message, contains('t'));
      expect(error.path, '#/kind');

      // Encoding through the codec branch must succeed.
      final okResult = union.safeEncode('hello');
      expect(okResult.isOk, isTrue);
      expect(okResult.getOrNull(), {'kind': 'c', 'v': 'hello'});
    });
  });

  group('Codec-in-codec composition', () {
    test('outer codec wrapping an inner codec round-trips', () {
      // Inner: String <-> _Color
      final inner = _colorCodec();
      // Outer: int <-> _Color, where int is a codepoint of '#FF00AA' style
      // boundary. Decode treats 0xFF00AA as a hex string and forwards.
      final outer = Ack.codec<int, _Color>(
        Ack.integer(),
        Ack.custom<_Color>(),
        decode: (n) {
          final hex = '#${n.toRadixString(16).padLeft(6, '0').toUpperCase()}';
          return inner.decode(hex)!;
        },
        encode: (color) {
          final hex = inner.encode(color)!.substring(1); // drop '#'
          return int.parse(hex, radix: 16);
        },
      );

      final color = outer.decode(0xFF00AA)!;
      expect(color, const _Color('#FF00AA'));
      expect(outer.encode(color), 0xFF00AA);
    });
  });

  group('ObjectSchema.encodeValue null strictness', () {
    final schema = Ack.object({'name': Ack.string().optional()});

    test('explicit null on optional non-nullable rejects with field path', () {
      final result = schema.safeEncode({'name': null});
      expect(result.isFail, isTrue);
      final nested = result.getError() as SchemaNestedError;
      final inner = nested.errors.single;
      expect(inner, isA<SchemaEncodeError>());
      expect(inner.path, '#/name');
      expect(inner.message, contains('not nullable'));
    });

    test('absent optional field is still omitted (no error)', () {
      final result = schema.safeEncode(<String, Object?>{});
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), <String, Object?>{});
    });

    test('explicit null on nullable optional passes through', () {
      final nullable = Ack.object({'name': Ack.string().nullable().optional()});
      final result = nullable.safeEncode({'name': null});
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), {'name': null});
    });
  });

  group('ObjectSchema.encodeValue additionalProperties', () {
    test('passes unknown keys through verbatim when allowed', () {
      final schema = Ack.object({
        'known': Ack.string(),
      }, additionalProperties: true);
      final result = schema.safeEncode({'known': 'value', 'extra': 99});
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), {'known': 'value', 'extra': 99});
    });
  });

  group('CodecSchema.toJsonSchema', () {
    test('marks codec output and uses input boundary type', () {
      final codec = _colorCodec();
      final json = codec.toJsonSchema();
      expect(json['x-ack-codec'], isTrue);
      expect(json['type'], 'string');
    });

    test('encodes the default into the boundary form', () {
      final codec = _colorCodec().copyWith(
        defaultValue: const _Color('#000000'),
      );
      final json = codec.toJsonSchema();
      expect(json['default'], '#000000');
    });

    test('omits default when encoding it would throw', () {
      final boom = Ack.codec<String, _Color>(
        Ack.string(),
        Ack.custom<_Color>(),
        decode: _Color.fromHex,
        encode: (_) => throw StateError('boom'),
      ).copyWith(defaultValue: const _Color('#000000'));
      final json = boom.toJsonSchema();
      expect(json.containsKey('default'), isFalse);
    });
  });

  group('CustomSchema.toJsonSchema', () {
    test('marks custom and never serializes runtime defaults', () {
      final schema = Ack.custom<_Color>().copyWith(
        defaultValue: const _Color('#000000'),
      );
      final json = schema.toJsonSchema();
      expect(json['x-ack-custom'], isTrue);
      expect(json.containsKey('default'), isFalse);
    });
  });

  group('CodecSchema.copyWith', () {
    test('preserves closures and metadata round-trip', () {
      final original = _colorCodec();
      final copied = original.copyWith(description: 'a hex color');
      // Equality compares closures via identity; copyWith without overriding
      // them keeps the same identity, so the copy stays equal except for
      // metadata.
      expect(copied.description, 'a hex color');
      // Forward + backward still work.
      expect(copied.decode('#abcdef'), const _Color('#ABCDEF'));
      expect(copied.encode(const _Color('#ABCDEF')), '#ABCDEF');
    });
  });
}
