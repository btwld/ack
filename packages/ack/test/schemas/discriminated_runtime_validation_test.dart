import 'package:ack/ack.dart';
import 'package:test/test.dart';

final class _Cat {
  const _Cat(this.name);
  final String name;
}

final class _Dog {
  const _Dog(this.name);
  final String name;
}

enum _Role { member }

CodecSchema<String, T> _codecWithOutput<T extends Object>(
  AckSchema<dynamic, T> output,
  T decoded,
) => Ack.codec<String, String, T>(
  input: Ack.string(),
  decode: (_) => decoded,
  encode: (_) => 'wire',
  output: output,
);

Iterable<String> _errorPaths(SchemaError error) sync* {
  yield error.path;
  if (error is SchemaNestedError) {
    for (final child in error.errors) {
      yield* _errorPaths(child);
    }
  }
}

void main() {
  group('discriminated codec output validation', () {
    final output = Ack.discriminated<JsonMap>(
      discriminatorKey: 'kind',
      schemas: {
        'a': Ack.object({'count': Ack.integer()}),
      },
    );
    final invalidCases = <({String name, JsonMap value, String errorPath})>[
      (
        name: 'wrong property runtime type',
        value: {'kind': 'a', 'count': 'bad'},
        errorPath: '#/count',
      ),
      (
        name: 'unknown discriminator',
        value: {'kind': 'unknown', 'count': 1},
        errorPath: '#/kind',
      ),
      (name: 'missing discriminator', value: {'count': 1}, errorPath: '#/kind'),
      (
        name: 'missing required property',
        value: {'kind': 'a'},
        errorPath: '#/count',
      ),
    ];
    for (final testCase in invalidCases) {
      test('rejects ${testCase.name} on decode and before encode', () {
        var encodeCalls = 0;
        final codec = Ack.codec<String, String, JsonMap>(
          input: Ack.string(),
          decode: (_) => testCase.value,
          encode: (_) {
            encodeCalls++;
            return 'wire';
          },
          output: output,
        );
        for (final result in [
          codec.safeParse('wire'),
          codec.safeEncode(testCase.value),
        ]) {
          expect(result.isFail, isTrue);
          expect(_errorPaths(result.getError()), contains(testCase.errorPath));
        }
        expect(encodeCalls, 0);
      });
    }

    test('validates already-decoded nested codec and enum runtimes', () {
      final output = Ack.discriminated<JsonMap>(
        discriminatorKey: 'kind',
        schemas: {
          'a': Ack.object({
            'createdAt': Ack.datetime(),
            'role': Ack.enumValues(_Role.values),
          }),
        },
      );
      final runtime = <String, Object?>{
        'kind': 'a',
        'createdAt': DateTime.utc(2026, 1, 1),
        'role': _Role.member,
      };
      final codec = _codecWithOutput(output, runtime);
      expect(codec.parse('wire'), runtime);
      expect(codec.encode(runtime), 'wire');
    });

    test('typed runtimes must satisfy at least one branch runtime schema', () {
      final output = Ack.discriminated<Object>(
        discriminatorKey: 'kind',
        schemas: {
          'cat': Ack.object({'name': Ack.string()}).codec<_Cat>(
            decode: (map) => _Cat(map['name']! as String),
            encode: (cat) => {'name': cat.name},
            output: Ack.instance<_Cat>().refine((cat) => cat.name.isNotEmpty),
          ),
          'dog': Ack.object({'name': Ack.string()}).codec<_Dog>(
            decode: (map) => _Dog(map['name']! as String),
            encode: (dog) => {'name': dog.name},
          ),
        },
      );
      for (final invalid in <Object>[Object(), const _Cat('')]) {
        final codec = _codecWithOutput(output, invalid);
        expect(codec.safeParse('wire').isFail, isTrue);
        expect(codec.safeEncode(invalid).isFail, isTrue);
      }
      for (final valid in <Object>[const _Cat('Mittens'), const _Dog('Spot')]) {
        final codec = _codecWithOutput(output, valid);
        expect(codec.parse('wire'), same(valid));
        expect(codec.encode(valid), 'wire');
      }
    });

    test('branch membership checks never execute branch codecs', () {
      var decodeCalls = 0;
      var encodeCalls = 0;
      final output = Ack.discriminated<_Cat>(
        discriminatorKey: 'kind',
        schemas: {
          'cat': Ack.object({'name': Ack.string()}).codec<_Cat>(
            decode: (map) {
              decodeCalls++;
              return _Cat(map['name']! as String);
            },
            encode: (cat) {
              encodeCalls++;
              return {'name': cat.name};
            },
          ),
        },
      );
      const value = _Cat('Mittens');
      final codec = _codecWithOutput(output, value);
      expect(codec.parse('wire'), same(value));
      expect(codec.encode(value), 'wire');
      expect(decodeCalls, 0);
      expect(encodeCalls, 0);
    });

    test('ambiguous runtime membership remains an encode-only failure', () {
      final branch = Ack.object({'name': Ack.string()}).codec<_Cat>(
        decode: (map) => _Cat(map['name']! as String),
        encode: (cat) => {'name': cat.name},
      );
      final union = Ack.discriminated<_Cat>(
        discriminatorKey: 'kind',
        schemas: {'a': branch, 'b': branch},
      );
      final parsed = union.parse({'kind': 'a', 'name': 'Mittens'})!;
      final codec = _codecWithOutput(union, parsed);
      expect(codec.parse('wire'), same(parsed));
      expect(codec.encode(parsed), 'wire');
      expect(union.safeEncode(parsed).isFail, isTrue);
    });
  });

  group('map codec outputs with union-owned discriminators', () {
    for (final wrapped in [false, true]) {
      for (final emitsDiscriminator in [false, true]) {
        test('round-trips strict ${wrapped ? 'wrapped' : 'plain'} outputs '
            '${emitsDiscriminator ? 'with' : 'without'} a discriminator', () {
          final output = Ack.object({'name': Ack.string()});
          final branch = Ack.object({'name': Ack.string()}).codec<JsonMap>(
            decode: (map) => {
              if (emitsDiscriminator) 'kind': 'cat',
              'name': map['name'],
            },
            encode: (map) => {'name': map['name']},
            output: wrapped ? output.withDefault({'name': 'Mittens'}) : output,
          );
          final union = Ack.discriminated<JsonMap>(
            discriminatorKey: 'kind',
            schemas: {
              'cat': wrapped ? branch.withDefault({'name': 'Mittens'}) : branch,
            },
          );
          final wire = <String, Object?>{'kind': 'cat', 'name': 'Mittens'};
          final parsed = union.parse(wire)!;
          expect(parsed, wire);
          expect(() => parsed['kind'] = 'dog', throwsUnsupportedError);
          expect(union.encode(parsed), wire);
          final codec = _codecWithOutput(union, parsed);
          expect(codec.parse('wire'), same(parsed));
          expect(codec.encode(parsed), 'wire');
          // Adapting a branch must not widen the original output schema.
          expect(
            _codecWithOutput(output, wire).safeParse('wire').isFail,
            isTrue,
          );
        });
      }
    }

    test('round-trips through chained map codecs', () {
      final inner = Ack.object({'name': Ack.string()}).codec<JsonMap>(
        decode: (map) => {'name': map['name']},
        encode: (map) => {'name': map['name']},
        output: Ack.object({'name': Ack.string()}),
      );
      final union = Ack.discriminated<JsonMap>(
        discriminatorKey: 'kind',
        schemas: {
          'cat': inner.codec<JsonMap>(
            decode: (map) => map,
            encode: (map) => map,
            output: Ack.object({'name': Ack.string()}),
          ),
        },
      );
      final wire = <String, Object?>{'kind': 'cat', 'name': 'Mittens'};
      expect(union.encode(union.parse(wire)!), wire);
    });

    test('adapts a nested codec output without running its conversions', () {
      final output = Ack.object({'name': Ack.string()}).codec<JsonMap>(
        decode: (_) => throw StateError('Output decoder must not run'),
        encode: (_) => throw StateError('Output encoder must not run'),
        output: Ack.object({'name': Ack.string()}),
      );
      final union = Ack.discriminated<JsonMap>(
        discriminatorKey: 'kind',
        schemas: {
          'cat': Ack.object({'name': Ack.string()}).codec<JsonMap>(
            decode: (map) => {'name': map['name']},
            encode: (map) => {'name': map['name']},
            output: output,
          ),
        },
      );
      final wire = <String, Object?>{'kind': 'cat', 'name': 'Mittens'};
      final parsed = union.parse(wire)!;
      expect(union.encode(parsed), wire);
      final codec = _codecWithOutput(union, parsed);
      expect(codec.parse('wire'), same(parsed));
      expect(codec.encode(parsed), 'wire');
    });

    test('round-trips strict object outputs inside a union', () {
      final union = Ack.discriminated<Object>(
        discriminatorKey: 'kind',
        schemas: {
          'cat': Ack.object({'name': Ack.string()}).codec<Object>(
            decode: (map) => {'name': map['name']},
            encode: (value) => value as JsonMap,
            output: Ack.anyOf([
              Ack.object({'name': Ack.string()}),
              Ack.instance<int>(),
            ]),
          ),
        },
      );
      final wire = <String, Object?>{'kind': 'cat', 'name': 'Mittens'};
      final parsed = union.parse(wire)!;
      expect(union.encode(parsed), wire);
      final codec = _codecWithOutput(union, parsed);
      expect(codec.parse('wire'), same(parsed));
      expect(codec.encode(parsed), 'wire');
      expect(codec.safeEncode({...wire, 'extra': true}).isFail, isTrue);
    });

    final union = Ack.discriminated<JsonMap>(
      discriminatorKey: 'kind',
      schemas: {
        'cat': Ack.object({'name': Ack.string()}).codec<JsonMap>(
          decode: (map) => {'name': map['name']},
          encode: (map) => {'name': map['name']},
          output: Ack.object({
            'name': Ack.string(),
            'details': Ack.object({'age': Ack.integer()}).optional(),
          }),
        ),
      },
    );
    final invalidCases = <({String name, JsonMap value, String path})>[
      (name: 'missing name', value: {'kind': 'cat'}, path: '#/name'),
      (
        name: 'wrong name type',
        value: {'kind': 'cat', 'name': 42},
        path: '#/name',
      ),
      (
        name: 'unrelated extra property',
        value: {'kind': 'cat', 'name': 'Mittens', 'extra': true},
        path: '#/extra',
      ),
      (
        name: 'nested discriminator property',
        value: {
          'kind': 'cat',
          'name': 'Mittens',
          'details': {'age': 1, 'kind': 'cat'},
        },
        path: '#/details/kind',
      ),
    ];
    for (final testCase in invalidCases) {
      test('still rejects ${testCase.name}', () {
        final codec = _codecWithOutput(union, testCase.value);
        for (final result in [
          codec.safeParse('wire'),
          codec.safeEncode(testCase.value),
          union.safeEncode(testCase.value),
        ]) {
          expect(result.isFail, isTrue);
          expect(_errorPaths(result.getError()), contains(testCase.path));
        }
      });
    }

    test('preserves an explicitly authored output discriminator', () {
      final union = Ack.discriminated<JsonMap>(
        discriminatorKey: 'kind',
        schemas: {
          'cat': Ack.object({'name': Ack.string()}).codec<JsonMap>(
            decode: (map) => {'kind': 'dog', 'name': map['name']},
            encode: (map) => {'name': map['name']},
            output: Ack.object({
              'kind': Ack.literal('dog'),
              'name': Ack.string(),
            }),
          ),
        },
      );
      final runtime = <String, Object?>{'kind': 'cat', 'name': 'Mittens'};
      final codec = _codecWithOutput(union, runtime);
      expect(codec.safeParse('wire').isFail, isTrue);
      expect(codec.safeEncode(runtime).isFail, isTrue);
      expect(union.safeEncode(runtime).isFail, isTrue);
    });

    test('membership never reruns branch conversions or refinements', () {
      var decodes = 0;
      var encodes = 0;
      var refinements = 0;
      final union = Ack.discriminated<JsonMap>(
        discriminatorKey: 'kind',
        schemas: {
          'cat': Ack.object({'name': Ack.string()}).codec<JsonMap>(
            decode: (map) {
              decodes++;
              return {'name': map['name']};
            },
            encode: (map) {
              encodes++;
              return {'name': map['name']};
            },
            output: Ack.object({'name': Ack.string()}).refine((_) {
              refinements++;
              return true;
            }),
          ),
        },
      );
      final runtime = <String, Object?>{'kind': 'cat', 'name': 'Mittens'};
      final codec = _codecWithOutput(union, runtime);
      expect(codec.parse('wire'), same(runtime));
      expect(refinements, 1);
      expect(codec.encode(runtime), 'wire');
      expect(refinements, 2);
      expect(decodes, 0);
      expect(encodes, 0);
    });
  });

  group('direct discriminated encoding callback counts', () {
    test('map branches do not acquire an extra runtime refinement pass', () {
      var refinements = 0;
      var encoders = 0;
      final union = Ack.discriminated<JsonMap>(
        discriminatorKey: 'kind',
        schemas: {
          'a': Ack.object({'count': Ack.integer()}).codec<JsonMap>(
            decode: (map) => map,
            encode: (map) {
              encoders++;
              return {'count': map['count']};
            },
            output: Ack.instance<JsonMap>().refine((_) {
              refinements++;
              return true;
            }),
          ),
        },
      );
      expect(union.encode({'kind': 'a', 'count': 1}), {
        'kind': 'a',
        'count': 1,
      });
      expect(refinements, 1);
      expect(encoders, 1);
    });

    test('typed branches retain one membership probe and one encode pass', () {
      var refinements = 0;
      var encoders = 0;
      final union = Ack.discriminated<_Cat>(
        discriminatorKey: 'kind',
        schemas: {
          'cat': Ack.object({'name': Ack.string()}).codec<_Cat>(
            decode: (map) => _Cat(map['name']! as String),
            encode: (cat) {
              encoders++;
              return {'name': cat.name};
            },
            output: Ack.instance<_Cat>().refine((_) {
              refinements++;
              return true;
            }),
          ),
        },
      );
      expect(union.encode(const _Cat('Mittens')), {
        'kind': 'cat',
        'name': 'Mittens',
      });
      expect(refinements, 2);
      expect(encoders, 1);
    });
  });
}
