import 'package:ack/ack.dart';

ObjectSchema searchSchema() => Ack.object({
  'query': Ack.string().minLength(1).describe('Search query'),
  'limit': Ack.integer().min(1).max(100).optional().withDefault(5),
});

class SearchInput {
  const SearchInput(this.query, this.limit);
  final String query;
  final int limit;

  static AckSchema<JsonMap, SearchInput> get schema => searchModel.modelSchema;
}

final searchModel = AckModelAdapter<JsonMap, JsonMap, SearchInput>(
  schema: searchSchema,
  fromRuntime: (value) =>
      SearchInput(value['query'] as String, value['limit'] as int),
  toRuntime: (value) => {'query': value.query, 'limit': value.limit},
);

ObjectSchema recursiveSchema() {
  late final ObjectSchema node;
  node = Ack.object({
    'name': Ack.string(),
    'children': Ack.list(Ack.lazy('node', () => node)).optional(),
  });
  return node;
}

final discriminatedSchema = Ack.discriminated(
  discriminatorKey: 'kind',
  schemas: {
    'text': Ack.object({'kind': Ack.literal('text'), 'text': Ack.string()}),
    'count': Ack.object({'kind': Ack.literal('count'), 'count': Ack.integer()}),
  },
);

// Each fixture includes both valid and invalid wire values. Refinements are
// covered separately because they deliberately strengthen runtime validation.
List<
  ({
    String name,
    ObjectSchema schema,
    List<JsonMap> valid,
    List<JsonMap> invalid,
  })
>
schemaFixtures() => [
  (
    name: 'search',
    schema: searchSchema(),
    valid: [
      {'query': 'dart'},
      {'query': 'dart', 'limit': 2.0},
    ],
    invalid: [
      {},
      {'query': ''},
      {'query': 'dart', 'limit': 2.5},
      {'query': 'dart', 'limit': 101},
    ],
  ),
  (
    name: 'empty',
    schema: Ack.object({}),
    valid: [{}],
    invalid: [
      {'extra': true},
    ],
  ),
  (
    name: 'fields',
    schema: Ack.object({
      'optional': Ack.string().optional(),
      'nullable': Ack.string().nullable(),
      'enum': Ack.enumString(['one', 'two']),
      'bounded': Ack.string().minLength(2).maxLength(5).matches('^[a-z]+\$'),
      'number': Ack.number().min(0).max(10),
      'list': Ack.list(Ack.integer()).minItems(1).maxItems(3).unique(),
      'nested': Ack.object({'value': Ack.boolean()}),
    }),
    valid: [
      {
        'nullable': null,
        'enum': 'one',
        'bounded': 'abc',
        'number': 1.5,
        'list': [1, 2],
        'nested': {'value': true},
      },
    ],
    invalid: [
      {
        'nullable': null,
        'enum': 'three',
        'bounded': 'A',
        'number': 11,
        'list': [],
        'nested': {'value': 2},
      },
      {},
    ],
  ),
  (
    name: 'union',
    schema: Ack.object({
      'value': Ack.anyOf([Ack.string(), Ack.integer()]),
    }),
    valid: [
      {'value': 'a'},
      {'value': 2},
    ],
    invalid: [
      {'value': false},
    ],
  ),
  (
    name: 'discriminated field',
    schema: Ack.object({'value': discriminatedSchema}),
    valid: [
      {
        'value': {'kind': 'count', 'count': 2},
      },
    ],
    invalid: [
      {
        'value': {'kind': 'text', 'count': 2},
      },
    ],
  ),
  (
    name: 'recursive',
    schema: recursiveSchema(),
    valid: [
      {
        'name': 'root',
        'children': [
          {'name': 'leaf'},
        ],
      },
    ],
    invalid: [
      {
        'name': 'root',
        'children': [
          {'name': 2},
        ],
      },
    ],
  ),
  (
    name: 'codecs',
    schema: Ack.object({
      'at': Ack.datetime(),
      'url': Ack.uri(),
      'duration': Ack.duration(),
    }),
    valid: [
      {
        'at': '2026-09-10T12:00:00Z',
        'url': 'https://example.com',
        'duration': 1000,
      },
    ],
    invalid: [
      {'at': 3, 'url': false, 'duration': 'long'},
    ],
  ),
];
