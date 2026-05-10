import 'package:ack/ack.dart';
import 'package:test/test.dart';

class _Animal {
  final String name;
  const _Animal(this.name);
}

class _Cat extends _Animal {
  const _Cat(super.name);
}

class _Dog extends _Animal {
  const _Dog(super.name);
}

void main() {
  group('DiscriminatedObjectSchema encode (M10)', () {
    group('map runtime values (Case A — discriminator dispatch)', () {
      test('dispatches by discriminator and encodes the matching branch', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({
              'type': Ack.literal('cat'),
              'name': Ack.string(),
            }),
            'dog': Ack.object({
              'type': Ack.literal('dog'),
              'name': Ack.string(),
            }),
          },
        );
        final encoded = schema.encode({'type': 'cat', 'name': 'Milo'});
        expect(encoded, equals({'type': 'cat', 'name': 'Milo'}));
      });

      test('missing discriminator fails at the discriminator path', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({'type': Ack.literal('cat')}),
          },
        );
        final result = schema.safeEncode(<String, Object?>{});
        expect(result.isFail, isTrue);
        expect(result.getError().path, equals('#/type'));
      });

      test('non-string discriminator fails at the discriminator path', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({'type': Ack.literal('cat')}),
          },
        );
        final result = schema.safeEncode({'type': 1});
        expect(result.isFail, isTrue);
        expect(result.getError().path, equals('#/type'));
      });

      test('unknown discriminator fails at the discriminator path', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({'type': Ack.literal('cat')}),
          },
        );
        final result = schema.safeEncode({'type': 'dog'});
        expect(result.isFail, isTrue);
        expect(result.getError().path, equals('#/type'));
      });

      test('does NOT fall through to other branches when dispatch matches '
          'but the matched branch fails to encode', () {
        // {type: cat, name: 1} dispatches to 'cat'. The cat branch's
        // 'name' child is StringSchema and rejects int. The encode must
        // fail under the cat branch — it must NOT try the dog branch.
        // (Discriminated semantics: a matched discriminator locks the branch.)
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({
              'type': Ack.literal('cat'),
              'name': Ack.string(),
            }),
            'dog': Ack.object({
              'type': Ack.literal('dog'),
              'age': Ack.integer(),
            }),
          },
        );
        final result = schema.safeEncode({'type': 'cat', 'name': 1});
        expect(result.isFail, isTrue);

        // Branch errors live in nested SchemaNestedError(s). Walk the tree
        // and confirm every leaf path stays at the parent value path
        // (no synthetic `when type=...` segments).
        final paths = <String>[];
        void collect(SchemaError e) {
          if (e is SchemaNestedError) {
            for (final inner in e.errors) {
              collect(inner);
            }
          } else {
            paths.add(e.path);
          }
        }

        collect(result.getError());
        // The leaf error is from the cat branch's 'name' child → #/name.
        expect(paths, contains('#/name'));
        // No synthetic discriminated branch path.
        expect(paths.any((p) => p.contains('when type')), isFalse);
        expect(paths.any((p) => p.contains('discriminated:')), isFalse);
      });
    });

    group('non-map domain runtime values (Case B — full pipeline trial)', () {
      // Cat / Dog runtime values, codec branches that produce maps.
      CodecSchema<Map<String, Object?>, _Animal> catBranch() => Ack.codec(
            input: Ack.object({
              'type': Ack.literal('cat'),
              'name': Ack.string(),
            }),
            output: Ack.instance<_Animal>(),
            decoder: (m) => _Cat(m['name']! as String),
            encoder: (animal) {
              if (animal is! _Cat) {
                throw StateError('not a cat: ${animal.runtimeType}');
              }
              return {'type': 'cat', 'name': animal.name};
            },
          );

      CodecSchema<Map<String, Object?>, _Animal> dogBranch() => Ack.codec(
            input: Ack.object({
              'type': Ack.literal('dog'),
              'name': Ack.string(),
            }),
            output: Ack.instance<_Animal>(),
            decoder: (m) => _Dog(m['name']! as String),
            encoder: (animal) {
              if (animal is! _Dog) {
                throw StateError('not a dog: ${animal.runtimeType}');
              }
              return {'type': 'dog', 'name': animal.name};
            },
          );

      test('falls through branches until full encode pipeline succeeds', () {
        final schema = Ack.discriminated<_Animal>(
          discriminatorKey: 'type',
          schemas: {
            'cat': catBranch(),
            'dog': dogBranch(),
          },
        );
        final encoded = schema.encode(const _Dog('Rex'));
        expect(encoded, equals({'type': 'dog', 'name': 'Rex'}));
      });

      test('encodes Cat through the cat branch', () {
        final schema = Ack.discriminated<_Animal>(
          discriminatorKey: 'type',
          schemas: {
            'cat': catBranch(),
            'dog': dogBranch(),
          },
        );
        final encoded = schema.encode(const _Cat('Milo'));
        expect(encoded, equals({'type': 'cat', 'name': 'Milo'}));
      });

      test(
          'codec branch is treated as object-backed via unwrap util '
          '(parse path uses inputSchema)', () {
        final schema = Ack.discriminated<_Animal>(
          discriminatorKey: 'type',
          schemas: {'cat': catBranch()},
        );
        // Confirms the unwrap util follows CodecSchema.inputSchema so the
        // "object-backed branch" check in decodeBoundary continues to pass.
        final parsed = schema.parse({'type': 'cat', 'name': 'Milo'});
        expect(parsed, isA<_Cat>());
        expect(parsed!.name, equals('Milo'));
      });

      test('aggregates branch errors when no domain-object branch matches',
          () {
        final schema = Ack.discriminated<_Animal>(
          discriminatorKey: 'type',
          schemas: {
            'cat': catBranch(),
            'dog': dogBranch(),
          },
        );
        // A bare _Animal that's neither Cat nor Dog: every branch fails.
        final result = schema.safeEncode(const _Animal('Mystery'));
        expect(result.isFail, isTrue);
      });
    });

    group('null handling', () {
      test('null on a non-nullable discriminated schema fails on encode', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {'cat': Ack.object({'type': Ack.literal('cat')})},
        );
        final result = schema.safeEncode(null);
        expect(result.isFail, isTrue);
      });

      test('null on a nullable discriminated schema returns Ok(null)', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {'cat': Ack.object({'type': Ack.literal('cat')})},
        ).nullable();
        final result = schema.safeEncode(null);
        expect(result.isOk, isTrue);
        expect(result.getOrNull(), isNull);
      });
    });
  });
}
