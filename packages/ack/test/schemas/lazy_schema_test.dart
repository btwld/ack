import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  test('parses and encodes a recursive object graph', () {
    late final ObjectSchema categorySchema;
    categorySchema = Ack.object({
      'name': Ack.string(),
      'children': Ack.list(
        Ack.lazy<JsonMap, JsonMap>('Category', () => categorySchema),
      ),
    });

    final json = <String, Object?>{
      'name': 'root',
      'children': [
        {
          'name': 'first',
          'children': [
            {'name': 'leaf', 'children': <Object?>[]},
          ],
        },
      ],
    };

    final parsed = categorySchema.parse(json);
    expect(parsed, equals(json));

    final encoded = categorySchema.encode(parsed);
    expect(encoded, equals(json));
    expect(categorySchema.encode(categorySchema.parse(json)), equals(json));
  });

  test('exports recursive object graph via definitions and refs', () {
    late final ObjectSchema categorySchema;
    categorySchema = Ack.object({
      'name': Ack.string(),
      'children': Ack.list(
        Ack.lazy<JsonMap, JsonMap>('Category', () => categorySchema),
      ),
    });

    final jsonSchema = categorySchema.toJsonSchema();
    final properties = jsonSchema['properties']! as Map;
    final children = properties['children']! as Map;
    final definitions = jsonSchema['definitions']! as Map;
    final categoryDef = definitions['Category']! as Map;
    final categoryProperties = categoryDef['properties']! as Map;
    final nestedChildren = categoryProperties['children']! as Map;

    expect(children['items'], {r'$ref': '#/definitions/Category'});
    expect(nestedChildren['items'], {r'$ref': '#/definitions/Category'});
    expect(definitions.keys, ['Category']);
  });

  test('deduplicates lazies with the same name and same target', () {
    final target = Ack.object({'name': Ack.string()});
    final first = Ack.lazy<JsonMap, JsonMap>('Category', () => target);
    final second = Ack.lazy<JsonMap, JsonMap>('Category', () => target);
    final schema = Ack.object({'first': first, 'second': second});

    final jsonSchema = schema.toJsonSchema();
    final properties = jsonSchema['properties']! as Map;
    final definitions = jsonSchema['definitions']! as Map;

    expect(definitions.keys, ['Category']);
    expect(properties['first'], {r'$ref': '#/definitions/Category'});
    expect(properties['second'], {r'$ref': '#/definitions/Category'});
  });

  test('escapes lazy names in JSON Pointer refs', () {
    final target = Ack.object({'name': Ack.string()});
    final schema = Ack.object({
      'node': Ack.lazy<JsonMap, JsonMap>('Tree/Node~1', () => target),
    });

    final jsonSchema = schema.toJsonSchema();
    final properties = jsonSchema['properties']! as Map;
    final definitions = jsonSchema['definitions']! as Map;

    expect(definitions.keys, ['Tree/Node~1']);
    expect(properties['node'], {r'$ref': '#/definitions/Tree~1Node~01'});
  });

  test('merges custom root definitions with lazy definitions', () {
    late final AckSchema<JsonMap, JsonMap> categorySchema;
    categorySchema =
        Ack.object({
          'name': Ack.string(),
          'slug': Ack.string(),
          'child': Ack.lazy<JsonMap, JsonMap>('Category', () => categorySchema),
        }).withConstraint(
          const _TestJsonSchemaKeywordConstraint<JsonMap>({
            'definitions': {
              'Slug': {'type': 'string', 'pattern': r'^[a-z0-9-]+$'},
            },
          }),
        );

    final jsonSchema = categorySchema.toJsonSchema();
    final definitions = jsonSchema['definitions']! as Map;

    expect(definitions['Slug'], {'type': 'string', 'pattern': r'^[a-z0-9-]+$'});
    expect(definitions['Category'], isA<Map>());
  });

  test('rejects custom root definitions that collide with lazy names', () {
    late final AckSchema<JsonMap, JsonMap> categorySchema;
    categorySchema =
        Ack.object({
          'name': Ack.string(),
          'child': Ack.lazy<JsonMap, JsonMap>('Category', () => categorySchema),
        }).withConstraint(
          const _TestJsonSchemaKeywordConstraint<JsonMap>({
            'definitions': {
              'Category': {'type': 'string'},
            },
          }),
        );

    expect(
      categorySchema.toJsonSchema,
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('collides with an existing root JSON Schema definition'),
        ),
      ),
    );
  });

  test('rejects lazies with the same name and different targets', () {
    final firstTarget = Ack.object({'name': Ack.string()});
    final secondTarget = Ack.object({'title': Ack.string()});
    final schema = Ack.object({
      'first': Ack.lazy<JsonMap, JsonMap>('Category', () => firstTarget),
      'second': Ack.lazy<JsonMap, JsonMap>('Category', () => secondTarget),
    });

    expect(
      schema.toJsonSchema,
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('share name "Category"'),
        ),
      ),
    );
  });

  test('wraps non-null lazy metadata without ref siblings', () {
    late final ObjectSchema categorySchema;
    categorySchema = Ack.object({
      'name': Ack.string(),
      'child': Ack.lazy<JsonMap, JsonMap>(
        'Category',
        () => categorySchema,
      ).describe('Child category'),
    });

    final jsonSchema = categorySchema.toJsonSchema();
    final properties = jsonSchema['properties']! as Map;

    expect(properties['child'], {
      'description': 'Child category',
      'allOf': [
        {r'$ref': '#/definitions/Category'},
      ],
    });
    expect(properties['child'], isNot(contains(r'$ref')));
  });

  test('exports nullable lazy references with metadata', () {
    late final ObjectSchema categorySchema;
    categorySchema = Ack.object({
      'name': Ack.string(),
      'parent': Ack.lazy<JsonMap, JsonMap>(
        'Category',
        () => categorySchema,
      ).describe('Parent category').nullable(),
    });

    final jsonSchema = categorySchema.toJsonSchema();
    final properties = jsonSchema['properties']! as Map;

    expect(properties['parent'], {
      'description': 'Parent category',
      'anyOf': [
        {r'$ref': '#/definitions/Category'},
        {'type': 'null'},
      ],
    });
    expect(jsonSchema['definitions'], isNotNull);
  });

  test('warns when lazy runtime checks cannot be exported', () {
    late final ObjectSchema categorySchema;
    categorySchema = Ack.object({
      'name': Ack.string(),
      'child': Ack.lazy<JsonMap, JsonMap>(
        'Category',
        () => categorySchema,
      ).refine((value) => true),
    });

    final model = categorySchema.toSchemaModel() as AckObjectSchemaModel;
    final child = model.properties!['child']!;

    expect(child.toJsonSchema(), {r'$ref': '#/definitions/Category'});
    expect(child.warnings, hasLength(1));
    expect(child.warnings.single.code, 'lazy_runtime_checks_not_export_safe');
    expect(child.warnings.single.context, {
      'constraintCount': 0,
      'refinementCount': 1,
    });
  });

  test('does not add definitions to non-lazy schemas', () {
    final schema = Ack.object({
      'name': Ack.string().minLength(2),
      'children': Ack.list(Ack.string()),
    });

    expect(schema.toJsonSchema(), {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'minLength': 2},
        'children': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
      'required': ['name', 'children'],
      'additionalProperties': false,
    });
    expect(schema.toJsonSchema(), isNot(contains('definitions')));
  });

  test('memoizes the builder result', () {
    var calls = 0;
    late final ObjectSchema categorySchema;
    final lazy = Ack.lazy<JsonMap, JsonMap>('Category', () {
      calls++;
      return categorySchema;
    });
    categorySchema = Ack.object({
      'name': Ack.string(),
      'children': Ack.list(lazy),
    });

    final json = <String, Object?>{
      'name': 'root',
      'children': [
        {'name': 'leaf', 'children': <Object?>[]},
      ],
    };

    final parsed = categorySchema.parse(json);
    expect(parsed, equals(json));
    expect(categorySchema.encode(parsed), equals(json));
    expect(calls, 1);
  });

  test('uses closure identity for equality', () {
    final target = Ack.object({'name': Ack.string()});
    final first = Ack.lazy<JsonMap, JsonMap>('Category', () => target);
    final second = Ack.lazy<JsonMap, JsonMap>('Category', () => target);

    expect(first, equals(first));
    expect(first, isNot(equals(second)));
  });

  test('encode runs lazy refinement once per nested node (no double '
      'validation)', () {
    var calls = 0;
    late final ObjectSchema categorySchema;
    final lazy = Ack.lazy<JsonMap, JsonMap>('Category', () => categorySchema)
        .refine((value) {
          calls++;
          return true;
        });
    categorySchema = Ack.object({
      'name': Ack.string(),
      'children': Ack.list(lazy),
    });

    final json = <String, Object?>{
      'name': 'root',
      'children': [
        {
          'name': 'a',
          'children': [
            {
              'name': 'b',
              'children': [
                {'name': 'c', 'children': <Object?>[]},
              ],
            },
          ],
        },
      ],
    };

    final parsed = categorySchema.parse(json);
    calls = 0;
    final encoded = categorySchema.encode(parsed);
    expect(encoded, equals(json));

    // Parent ObjectSchema/ListSchema validate-then-encode passes already drive
    // a fixed number of refinement runs per lazy edge. The double-validation
    // bug added an extra recursive validate inside LazySchema.encodeWithContext
    // on top of that, inflating this count. Locks in the fixed call profile.
    expect(calls, 15);
  });
}

final class _TestJsonSchemaKeywordConstraint<T extends Object>
    extends Constraint<T>
    with Validator<T>, JsonSchemaSpec<T> {
  const _TestJsonSchemaKeywordConstraint(this.keywords)
    : super(
        constraintKey: 'test_schema_model_keywords',
        description: 'Adds test-only JSON Schema keywords.',
      );

  final Map<String, Object?> keywords;

  @override
  bool isValid(T value) => true;

  @override
  String buildMessage(T value) => 'ok';

  @override
  Map<String, Object?> toJsonSchema() => keywords;
}
