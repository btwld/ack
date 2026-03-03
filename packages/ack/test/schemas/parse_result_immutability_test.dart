import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Parse Result Immutability', () {
    group('ObjectSchema', () {
      test('flat map is unmodifiable', () {
        final schema = Ack.object({'name': Ack.string(), 'age': Ack.integer()});
        final result = schema.parse({'name': 'Leo', 'age': 30})!;

        expect(() => result['name'] = 'Other', throwsUnsupportedError);
        expect(() => result['new'] = 'field', throwsUnsupportedError);
        expect(() => result.remove('name'), throwsUnsupportedError);
        expect(() => result.clear(), throwsUnsupportedError);
      });

      test('nested object maps are deeply unmodifiable', () {
        final schema = Ack.object({
          'user': Ack.object({
            'name': Ack.string(),
            'settings': Ack.object({'theme': Ack.string()}),
          }),
        });

        final result = schema.parse({
          'user': {
            'name': 'Leo',
            'settings': {'theme': 'dark'},
          },
        })!;

        final user = result['user'] as Map<String, Object?>;
        final settings = user['settings'] as Map<String, Object?>;

        expect(() => result['user'] = {}, throwsUnsupportedError);
        expect(() => user['name'] = 'Other', throwsUnsupportedError);
        expect(() => settings['theme'] = 'light', throwsUnsupportedError);
      });

      test('object with list property — both unmodifiable', () {
        final schema = Ack.object({'tags': Ack.list(Ack.string())});

        final result = schema.parse({
          'tags': ['a', 'b'],
        })!;

        final tags = result['tags'] as List;

        expect(() => result['tags'] = [], throwsUnsupportedError);
        expect(() => tags.add('c'), throwsUnsupportedError);
        expect(() => tags[0] = 'x', throwsUnsupportedError);
      });

      test('safeParse returns unmodifiable on success', () {
        final schema = Ack.object({'name': Ack.string()});
        final result = schema.safeParse({'name': 'Leo'});

        expect(result.isOk, isTrue);
        final value = result.getOrThrow()!;

        expect(() => value['name'] = 'Other', throwsUnsupportedError);
      });
    });

    group('ListSchema', () {
      test('flat list is unmodifiable', () {
        final schema = Ack.list(Ack.string());
        final result = schema.parse(['a', 'b', 'c'])!;

        expect(() => result.add('d'), throwsUnsupportedError);
        expect(() => result[0] = 'x', throwsUnsupportedError);
        expect(() => result.removeAt(0), throwsUnsupportedError);
        expect(() => result.clear(), throwsUnsupportedError);
      });

      test('nested lists are unmodifiable', () {
        final schema = Ack.list(Ack.list(Ack.string()));
        final result = schema.parse([
          ['a', 'b'],
          ['c'],
        ])!;

        final inner = result[0];

        expect(() => result.add(['d']), throwsUnsupportedError);
        expect(() => inner.add('x'), throwsUnsupportedError);
        expect(() => inner[0] = 'y', throwsUnsupportedError);
      });

      test('list of objects — list and each map element unmodifiable', () {
        final schema = Ack.list(Ack.object({'name': Ack.string()}));
        final result = schema.parse([
          {'name': 'Alice'},
          {'name': 'Bob'},
        ])!;

        final first = result[0];

        expect(() => result.add({}), throwsUnsupportedError);
        expect(() => first['name'] = 'Other', throwsUnsupportedError);
      });
    });

    group('DiscriminatedObjectSchema', () {
      test('result map is unmodifiable', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({'type': Ack.string(), 'name': Ack.string()}),
          },
        );

        final result = schema.parse({'type': 'cat', 'name': 'Whiskers'})!;

        expect(() => result['type'] = 'dog', throwsUnsupportedError);
        expect(() => result['name'] = 'Other', throwsUnsupportedError);
        expect(() => result.clear(), throwsUnsupportedError);
      });
    });

    group('Additional properties', () {
      test('top-level map is unmodifiable with additional properties', () {
        final schema = Ack.object({
          'name': Ack.string(),
        }, additionalProperties: true);

        final result = schema.parse({'name': 'Leo', 'extra': 'value'})!;

        expect(result['extra'], equals('value'));
        expect(() => result['name'] = 'Other', throwsUnsupportedError);
        expect(() => result['extra'] = 'modified', throwsUnsupportedError);
        expect(() => result['new'] = 'field', throwsUnsupportedError);
      });

      test(
        'unvalidated additional-property nested structure remains mutable',
        () {
          final schema = Ack.object({
            'name': Ack.string(),
          }, additionalProperties: true);

          // The nested map bypasses schema validation
          final result = schema.parse({
            'name': 'Leo',
            'meta': {'key': 'value'},
          })!;

          // Top-level is unmodifiable
          expect(() => result['meta'] = {}, throwsUnsupportedError);

          // But the nested map was not validated by a schema,
          // so its internal structure remains mutable (known non-goal)
          final meta = result['meta'] as Map<String, Object?>;
          expect(() => meta['key'] = 'modified', returnsNormally);
        },
      );
    });

    group('Constraints work with unmodifiable collections', () {
      test('object refinement works on unmodifiable map', () {
        final schema = Ack.object({'name': Ack.string()}).refine(
          (map) => map['name'] != null,
          message: 'name must not be null',
        );

        final result = schema.safeParse({'name': 'Leo'});
        expect(result.isOk, isTrue);

        final value = result.getOrThrow()!;
        expect(() => value['name'] = 'Other', throwsUnsupportedError);
      });

      test('list refinement works on unmodifiable list', () {
        final schema = Ack.list(
          Ack.string(),
        ).refine((list) => list.isNotEmpty, message: 'must not be empty');
        final result = schema.safeParse(['a', 'b', 'c']);

        expect(result.isOk, isTrue);

        final value = result.getOrThrow()!;
        expect(() => value.add('d'), throwsUnsupportedError);
      });

      test(
        'constraint failure produces proper error, not UnsupportedError',
        () {
          final schema = Ack.list(Ack.string()).refine(
            (list) => list.length > 5,
            message: 'need more than 5 items',
          );
          final result = schema.safeParse(['a', 'b']);

          expect(result.isFail, isTrue);
        },
      );
    });
  });
}
