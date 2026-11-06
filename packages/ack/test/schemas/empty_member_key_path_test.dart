import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('empty-string member keys', () {
    test('JSON Schema additionalProperties reports #/ for an empty key', () {
      final schema = Ack.fromJsonSchema({
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      });

      expect(schema.safeParse({'': 1}).getError().context.path, '#/');
      expect(schema.safeParse({'a': 1}).getError().context.path, '#/a');
    });

    test('nested empty key keeps the empty reference token', () {
      final schema = Ack.fromJsonSchema({
        'type': 'object',
        'additionalProperties': {
          'type': 'object',
          'additionalProperties': {'type': 'string'},
        },
      });

      expect(
        schema
            .safeParse({
              'a': {'': 1},
            })
            .getError()
            .context
            .path,
        '#/a/',
      );
    });

    test('map and object schemas report an empty key at #/', () {
      expect(
        Ack.map(Ack.string()).safeParse({'': 1}).getError(),
        isA<SchemaNestedError>().having(
          (error) => error.errors.single.context.path,
          'map value path',
          '#/',
        ),
      );
      expect(
        Ack.object({'': Ack.string()}).safeParse({'': 1}).getError(),
        isA<SchemaNestedError>().having(
          (error) => error.errors.single.context.path,
          'object property path',
          '#/',
        ),
      );
    });
  });

  group('wrapper contexts add no path segment', () {
    test('anyOf keeps the property path', () {
      final error = Ack.object({
        'value': Ack.anyOf([Ack.string()]),
      }).safeParse({'value': 1}).getError();

      final branch =
          ((error as SchemaNestedError).errors.single as SchemaNestedError)
              .errors
              .single;

      expect(branch.context.path, '#/value');
    });

    test('lazy recursion keeps the nested property path', () {
      late final ObjectSchema node;
      node = Ack.object({
        'label': Ack.string(),
        'child': Ack.lazy<JsonMap, JsonMap>('Node', () => node).optional(),
      });

      final error = node.safeParse({
        'label': 'ok',
        'child': {'label': 1},
      }).getError();
      final childError = (error as SchemaNestedError).errors.single;
      final labelError = (childError as SchemaNestedError).errors.single;

      expect(labelError.context.path, '#/child/label');
    });

    test('discriminated branch keeps the property path', () {
      final schema = Ack.discriminated(
        discriminatorKey: 'kind',
        schemas: {
          'user': Ack.object({
            'kind': Ack.literal('user'),
            'name': Ack.string(),
          }),
        },
      );

      final error = schema.safeParse({'kind': 'user', 'name': 1}).getError();

      expect(error.path, '#');
      expect((error as SchemaNestedError).errors.single.path, '#/name');
    });

    test('boundary encode keeps the property path', () {
      final holder = Ack.object({
        'wire': Ack.preserveBoundary(Ack.object({'name': Ack.string()})),
      });

      final error = holder.safeEncode({
        'wire': {'name': 1},
      }).getError();
      final nested = (error as SchemaNestedError).errors.single;

      expect(nested.path, '#/wire');
      expect((nested as SchemaNestedError).errors.single.path, '#/wire/name');
    });
  });
}
