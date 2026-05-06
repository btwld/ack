import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Object refinements run on runtime map', () {
    test('object-level refine sees runtime DateTime, not encoded String', () {
      final schema = Ack.object({'startsAt': Ack.datetime()}).refine(
        (m) => m['startsAt'] is DateTime,
        message: 'startsAt must still be DateTime when refinement runs',
      );
      final encoded =
          schema.encode({'startsAt': DateTime.utc(2026, 5, 4)})
              as Map<String, Object?>;
      expect(encoded['startsAt'], equals('2026-05-04T00:00:00.000Z'));
    });

    test('failing refinement on runtime map blocks encode', () {
      final schema = Ack.object({
        'a': Ack.integer(),
        'b': Ack.integer(),
      }).refine((m) => (m['a'] as int) < (m['b'] as int), message: 'a < b');
      expect(schema.safeEncode({'a': 5, 'b': 2}).isFail, isTrue);
    });

    test('invalid child values fail before object-level refinements run', () {
      final schema = Ack.object({
        'a': Ack.integer(),
      }).refine((m) => (m['a'] as int) > 0, message: 'a must be positive');

      final result = schema.safeEncode({'a': 'not an int'});

      expect(result.isFail, isTrue);
      final err = result.getError();
      expect(err, isA<SchemaNestedError>());
      expect((err as SchemaNestedError).errors.single.path, equals('#/a'));
    });
  });

  group('List constraints run on type-erased lists', () {
    test('minItems fails when runtime is List<Object?> below limit', () {
      final schema = Ack.list(Ack.integer()).minItems(2);
      final result = schema.safeEncode(<Object?>[1]);
      expect(result.isFail, isTrue);
    });

    test('minItems passes when type-erased list meets the constraint', () {
      final schema = Ack.list(Ack.integer()).minItems(2);
      final encoded = schema.encode(<Object?>[1, 2]) as List<Object?>;
      expect(encoded, equals([1, 2]));
    });

    test('nullable item schemas fail on null item encode like parse', () {
      final schema = Ack.list(Ack.string().nullable());

      final result = schema.safeEncode([null]);

      expect(result.isFail, isTrue);
      final err = result.getError();
      expect(err, isA<SchemaNestedError>());
      expect((err as SchemaNestedError).errors.single.path, equals('#/0'));
    });
  });

  group('Discriminated Map dispatch is strict', () {
    final schema = Ack.discriminated(
      discriminatorKey: 'type',
      schemas: {
        'cat': Ack.object({'type': Ack.literal('cat'), 'name': Ack.string()}),
      },
    );

    test('missing discriminator key fails at #/type', () {
      final result = schema.safeEncode({'name': 'Milo'});
      expect(result.isFail, isTrue);
      expect(result.getError().path, equals('#/type'));
    });

    test('non-string discriminator value fails at #/type', () {
      final result = schema.safeEncode({'type': 123, 'name': 'X'});
      expect(result.isFail, isTrue);
      expect(result.getError().path, equals('#/type'));
    });

    test('valid Map+discriminator still encodes (regression)', () {
      final encoded =
          schema.encode({'type': 'cat', 'name': 'Milo'})
              as Map<String, Object?>;
      expect(encoded['type'], equals('cat'));
      expect(encoded['name'], equals('Milo'));
    });
  });

  group('AnyOf refinements run on runtime input', () {
    test('refinement sees runtime DateTime, not encoded String', () {
      final schema = Ack.anyOf([Ack.datetime(), Ack.string()]).refine(
        (v) => v is DateTime,
        message: 'must still be DateTime when refinement runs',
      );
      expect(
        schema.encode(DateTime.utc(2026, 5, 4)),
        equals('2026-05-04T00:00:00.000Z'),
      );
    });
  });
}
