import 'package:ack/ack.dart';
import 'package:test/test.dart';

sealed class _Pet {
  const _Pet();
}

final class _Cat extends _Pet {
  const _Cat(this.lives);

  final int lives;
}

final class _Dog extends _Pet {
  const _Dog(this.friendly);

  final bool friendly;
}

void main() {
  test('raw object branches can back a codec-wrapped discriminated model', () {
    final catObject = Ack.object({'lives': Ack.integer()});
    final dogObject = Ack.object({'friendly': Ack.boolean()});

    final catSchema = catObject.codec<_Cat>(
      decode: (value) => _Cat(value['lives']! as int),
      encode: (cat) => {'lives': cat.lives},
    );
    final dogSchema = dogObject.codec<_Dog>(
      decode: (value) => _Dog(value['friendly']! as bool),
      encode: (dog) => {'friendly': dog.friendly},
    );

    final petSchema =
        Ack.discriminated<JsonMap>(
          discriminatorKey: 'type',
          schemas: {'cat': catObject, 'dog': dogObject},
        ).codec<_Pet>(
          decode: (value) => switch (value['type']) {
            'cat' => _Cat(value['lives']! as int),
            'dog' => _Dog(value['friendly']! as bool),
            final unknown => throw StateError('Unknown type: $unknown'),
          },
          encode: (pet) => switch (pet) {
            _Cat() => {'type': 'cat', ...catSchema.encode(pet)!},
            _Dog() => {'type': 'dog', ...dogSchema.encode(pet)!},
          },
        );

    final cat = petSchema.parse({'type': 'cat', 'lives': 9});
    expect(cat, isA<_Cat>());
    expect((cat! as _Cat).lives, 9);
    expect(petSchema.encode(cat), {'type': 'cat', 'lives': 9});
    expect(catSchema.parse({'lives': 7})!.lives, 7);
    expect(dogSchema.parse({'friendly': true})!.friendly, isTrue);
  });

  test('codec JSON Schema export preserves the input schema shape', () {
    final input = Ack.object({
      'name': Ack.string().minLength(1),
      'createdAt': Ack.datetime(),
    });
    final codec = input.codec<_Cat>(
      decode: (_) => const _Cat(1),
      encode: (_) => {'name': 'cat', 'createdAt': DateTime.utc(2026)},
    );

    expect(codec.toJsonSchema(), input.toJsonSchema());
  });
}
