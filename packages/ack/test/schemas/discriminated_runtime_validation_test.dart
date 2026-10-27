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
