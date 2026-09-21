import 'package:ack/ack.dart';
// `Refinement` is intentionally hidden from the public ack.dart export; the
// test-local schema below reaches into the source path to declare it.
import 'package:ack/src/schemas/schema.dart' show Refinement;
import 'package:test/test.dart';

/// A codec whose encoder always throws [error].
CodecSchema<String, int> _throwingCodec(Object error) {
  return Ack.string().codec<int>(decode: int.parse, encode: (_) => throw error);
}

/// A codec that records how many times its encoder ran.
CodecSchema<String, int> _countingCodec(List<int> calls) {
  return Ack.string().codec<int>(
    decode: int.parse,
    encode: (value) {
      calls.add(value);

      return value.toString();
    },
  );
}

/// A non-codec schema whose encode throws an ordinary [Exception], used to pin
/// that composite catch blocks still attribute a child path.
final class _ThrowingLeafSchema extends AckSchema<String, String>
    with FluentSchema<String, String, _ThrowingLeafSchema> {
  const _ThrowingLeafSchema({
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  SchemaType get schemaType => SchemaType.string;

  @override
  SchemaResult<String> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) => SchemaResult.ok(value as String);

  @override
  SchemaResult<String> encodeWithContext(String value, SchemaContext context) {
    throw const FormatException('leaf encode refused');
  }

  @override
  _ThrowingLeafSchema copyWith({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<String>>? constraints,
    List<Refinement<String>>? refinements,
  }) {
    return _ThrowingLeafSchema(
      isNullable: isNullable ?? this.isNullable,
      isOptional: isOptional ?? this.isOptional,
      description: description ?? this.description,
      constraints: constraints ?? this.constraints,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _ThrowingLeafSchema && baseFieldsEqual(other);

  @override
  int get hashCode => baseFieldsHashCode;
}

Iterable<SchemaError> _flatten(SchemaError error) sync* {
  yield error;
  if (error is SchemaNestedError) {
    for (final child in error.errors) {
      yield* _flatten(child);
    }
  }
}

/// Runs [encode] and returns the thrown object, failing if nothing is thrown.
({Object error, StackTrace stackTrace}) _captureThrow(void Function() encode) {
  try {
    encode();
  } catch (e, st) {
    return (error: e, stackTrace: st);
  }
  fail('Expected the encoder Error to propagate.');
}

void main() {
  group('encoder Errors propagate at every nesting level', () {
    test('root codec rethrows the identical Error with its stack trace', () {
      final thrown = StateError('boom');
      final schema = _throwingCodec(thrown);

      final captured = _captureThrow(() => schema.safeEncode(1));

      expect(captured.error, same(thrown));
      expect(captured.stackTrace.toString(), contains('_throwingCodec'));
    });

    test('Ack.object rethrows a property encoder Error', () {
      final thrown = StateError('boom');
      final schema = Ack.object({'count': _throwingCodec(thrown)});

      final captured = _captureThrow(() => schema.safeEncode({'count': 1}));

      expect(captured.error, same(thrown));
      expect(captured.stackTrace.toString(), contains('_throwingCodec'));
    });

    test('Ack.list rethrows an item encoder Error', () {
      final thrown = StateError('boom');
      final schema = Ack.list(_throwingCodec(thrown));

      final captured = _captureThrow(() => schema.safeEncode([1]));

      expect(captured.error, same(thrown));
      expect(captured.stackTrace.toString(), contains('_throwingCodec'));
    });

    test('Ack.map rethrows a value encoder Error', () {
      final thrown = StateError('boom');
      final schema = Ack.map(_throwingCodec(thrown));

      final captured = _captureThrow(() => schema.safeEncode({'k': 1}));

      expect(captured.error, same(thrown));
      expect(captured.stackTrace.toString(), contains('_throwingCodec'));
    });

    test('Ack.anyOf rethrows a branch encoder Error', () {
      final thrown = StateError('boom');
      final schema = Ack.anyOf([_throwingCodec(thrown), Ack.string()]);

      final captured = _captureThrow(() => schema.safeEncode(1));

      expect(captured.error, same(thrown));
      expect(captured.stackTrace.toString(), contains('_throwingCodec'));
    });

    test('Ack.discriminated rethrows a branch encoder Error', () {
      final thrown = StateError('boom');
      final schema = Ack.discriminated<JsonMap>(
        discriminatorKey: 'type',
        schemas: {
          'a': Ack.object({
            'type': Ack.literal('a'),
            'count': _throwingCodec(thrown),
          }),
        },
      );

      final captured = _captureThrow(
        () => schema.safeEncode({'type': 'a', 'count': 1}),
      );

      expect(captured.error, same(thrown));
      expect(captured.stackTrace.toString(), contains('_throwingCodec'));
    });

    test('a later union branch encoder is not invoked after an Error', () {
      final calls = <int>[];
      final schema = Ack.anyOf([
        _throwingCodec(StateError('boom')),
        _countingCodec(calls),
      ]);

      _captureThrow(() => schema.safeEncode(1));

      expect(calls, isEmpty);
    });
  });

  group('ordinary Exceptions still become encode failures', () {
    test('root codec Exception fails with the encoderThrew kind', () {
      final schema = _throwingCodec(const FormatException('bad'));

      final result = schema.safeEncode(1);

      expect(result.isFail, isTrue);
      final error = result.getError();
      expect(error, isA<SchemaEncodeError>());
      expect(
        (error as SchemaEncodeError).kind,
        SchemaEncodeFailureKind.encoderThrew,
      );
    });

    test('object property Exception fails at #/count', () {
      final schema = Ack.object({
        'count': _throwingCodec(const FormatException('bad')),
      });

      final result = schema.safeEncode({'count': 1});

      expect(result.isFail, isTrue);
      expect(
        _flatten(result.getError()).any(
          (e) =>
              e.path == '#/count' &&
              e is SchemaEncodeError &&
              e.kind == SchemaEncodeFailureKind.encoderThrew,
        ),
        isTrue,
        reason: _describe(result.getError()),
      );
    });

    test('list item Exception fails at #/0', () {
      final schema = Ack.list(_throwingCodec(const FormatException('bad')));

      final result = schema.safeEncode([1]);

      expect(result.isFail, isTrue);
      expect(
        _flatten(result.getError()).any(
          (e) =>
              e.path == '#/0' &&
              e is SchemaEncodeError &&
              e.kind == SchemaEncodeFailureKind.encoderThrew,
        ),
        isTrue,
        reason: _describe(result.getError()),
      );
    });

    test('map value Exception fails at #/k', () {
      final schema = Ack.map(_throwingCodec(const FormatException('bad')));

      final result = schema.safeEncode({'k': 1});

      expect(result.isFail, isTrue);
      expect(
        _flatten(result.getError()).any(
          (e) =>
              e.path == '#/k' &&
              e is SchemaEncodeError &&
              e.kind == SchemaEncodeFailureKind.encoderThrew,
        ),
        isTrue,
        reason: _describe(result.getError()),
      );
    });

    test('a non-codec child Exception is still attributed to #/leaf', () {
      final schema = Ack.object({'leaf': const _ThrowingLeafSchema()});

      final result = schema.safeEncode({'leaf': 'v'});

      expect(result.isFail, isTrue);
      expect(
        _flatten(result.getError()).any((e) => e.path == '#/leaf'),
        isTrue,
        reason: _describe(result.getError()),
      );
    });
  });

  group('union fallback is preserved for non-Error failures', () {
    test('falls back to the next branch on an ordinary validation failure', () {
      final schema = Ack.anyOf([Ack.integer(), Ack.string()]);

      final result = schema.safeEncode('hello');

      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals('hello'));
    });

    test('falls back to the next branch when a branch encoder throws', () {
      final calls = <int>[];
      final schema = Ack.anyOf([
        _throwingCodec(const FormatException('bad')),
        _countingCodec(calls),
      ]);

      final result = schema.safeEncode(1);

      expect(result.isOk, isTrue, reason: _describeResult(result));
      expect(result.getOrNull(), equals('1'));
      expect(calls, equals([1]));
    });
  });

  group('decoder policy is unchanged', () {
    test('a decoder Error still becomes a SchemaTransformError', () {
      final schema = Ack.string().codec<int>(
        decode: (_) => throw StateError('decode boom'),
        encode: (value) => value.toString(),
      );

      final result = schema.safeParse('1');

      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaTransformError>());
    });
  });
}

String _describeResult(SchemaResult<Object?> result) =>
    result.isFail ? _describe(result.getError()) : 'ok';

String _describe(SchemaError error) =>
    _flatten(error).map((e) => '${e.path} ${e.runtimeType}').join(', ');
