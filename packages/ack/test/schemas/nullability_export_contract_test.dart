import 'package:ack/ack.dart';
import 'package:test/test.dart';

AnyOfSchema _nullableUnion() => Ack.anyOf([
  Ack.anyOf([Ack.string().nullable(), Ack.integer()]),
  Ack.boolean(),
]);

final _record = Ack.object({'name': Ack.string()});
const _recordSample = {'name': 'ok'};

AckSchema<Object, Object> _nullableImport() => Ack.fromJsonSchema({
  'anyOf': [
    {'type': 'string'},
    {'type': 'null'},
  ],
  'allOf': [
    {'minLength': 2},
  ],
});

void main() {
  final cases =
      <
        ({
          String name,
          AckSchema<Object, Object> schema,
          bool acceptsNull,
          Object sample,
        })
      >[
        (
          name: 'boundary widens a non-null object',
          schema: Ack.preserveBoundary(_record).nullable(),
          acceptsNull: true,
          sample: _recordSample,
        ),
        (
          name: 'boundary narrows a nullable object',
          schema: Ack.preserveBoundary(
            _record.nullable(),
          ).nullable(value: false),
          acceptsNull: false,
          sample: _recordSample,
        ),
        (
          name: 'codec narrows a nullable primitive',
          schema: Ack.string()
              .nullable()
              .codec<String>(decode: (value) => value, encode: (value) => value)
              .nullable(value: false),
          acceptsNull: false,
          sample: 'ok',
        ),
        (
          name: 'codec narrows a nested nullable union',
          schema: _nullableUnion()
              .codec<Object>(decode: (value) => value, encode: (value) => value)
              .nullable(value: false),
          acceptsNull: false,
          sample: 'ok',
        ),
        (
          name: 'codec narrows imported source nullability',
          schema: _nullableImport()
              .codec<Object>(decode: (value) => value, encode: (value) => value)
              .nullable(value: false),
          acceptsNull: false,
          sample: 'ok',
        ),
        (
          name: 'lazy uses its non-null flag over a nullable primitive',
          schema: Ack.lazy('NullableString', () => Ack.string().nullable()),
          acceptsNull: false,
          sample: 'ok',
        ),
        (
          name: 'lazy narrows a nested nullable union',
          schema: Ack.lazy(
            'NullableUnion',
            _nullableUnion,
          ).nullable().nullable(value: false),
          acceptsNull: false,
          sample: 'ok',
        ),
        (
          name: 'lazy uses its non-null flag over imported source nullability',
          schema: Ack.lazy('NullableImport', _nullableImport),
          acceptsNull: false,
          sample: 'ok',
        ),
        (
          name: 'lazy widens a non-null target',
          schema: Ack.lazy('NonNullString', Ack.string).nullable(),
          acceptsNull: true,
          sample: 'ok',
        ),
      ];

  for (final testCase in cases) {
    group(testCase.name, () {
      final schema = testCase.schema;
      final nested = Ack.object({'value': schema});

      test('parse and encode honor the same root and property null policy', () {
        expect(schema.safeParse(null).isOk, testCase.acceptsNull);
        expect(schema.safeEncode(null).isOk, testCase.acceptsNull);
        expect(nested.safeParse({'value': null}).isOk, testCase.acceptsNull);
        expect(nested.safeEncode({'value': null}).isOk, testCase.acceptsNull);
        expect(schema.parse(testCase.sample), testCase.sample);
        expect(schema.encode(testCase.sample), testCase.sample);
      });

      for (final draft7 in [false, true]) {
        test(
          '${draft7 ? 'Draft-7' : 'default'} export preserves null policy',
          () {
            final restored = Ack.fromJsonSchema(
              draft7 ? schema.toJsonSchemaDraft7() : schema.toJsonSchema(),
            );
            final restoredNested = Ack.fromJsonSchema(
              draft7 ? nested.toJsonSchemaDraft7() : nested.toJsonSchema(),
            );
            expect(restored.safeParse(null).isOk, testCase.acceptsNull);
            expect(
              restoredNested.safeParse({'value': null}).isOk,
              testCase.acceptsNull,
            );
            expect(restored.safeParse(testCase.sample).isOk, isTrue);
            expect(
              restoredNested.safeParse({'value': testCase.sample}).isOk,
              isTrue,
            );
          },
        );
      }
    });
  }

  test('a non-null restriction keeps imported source allOf assertions', () {
    final schema = _nullableImport()
        .codec<Object>(decode: (value) => value, encode: (value) => value)
        .nullable(value: false);
    for (final exported in [
      schema.toJsonSchema(),
      schema.toJsonSchemaDraft7(),
    ]) {
      final restored = Ack.fromJsonSchema(exported);
      expect(restored.safeParse('x').isFail, isTrue);
      expect(restored.safeParse(1).isFail, isTrue);
      expect(restored.safeParse('ok').isOk, isTrue);
    }
  });

  group('non-null restrictions add allOf only while null stays reachable', () {
    Object same(Object value) => value;
    final cases = <(String, AckSchema<Object, Object>, bool)>[
      (
        'a codec over a nullable primitive',
        Ack.string()
            .nullable()
            .codec<String>(decode: (value) => value, encode: (value) => value)
            .nullable(value: false),
        false,
      ),
      (
        'a boundary over a nullable object',
        Ack.preserveBoundary(_record.nullable()).nullable(value: false),
        false,
      ),
      (
        'a codec over a nested nullable union',
        _nullableUnion()
            .codec<Object>(decode: same, encode: same)
            .nullable(value: false),
        true,
      ),
      (
        'a codec over imported source nullability',
        _nullableImport()
            .codec<Object>(decode: same, encode: same)
            .nullable(value: false),
        true,
      ),
      (
        'a codec over a nullable lazy reference',
        Ack.lazy('NullableUnion', _nullableUnion)
            .nullable()
            .codec<Object>(decode: same, encode: same)
            .nullable(value: false),
        true,
      ),
    ];

    for (final (name, schema, needsAllOf) in cases) {
      test(name, () {
        for (final exported in [
          schema.toJsonSchema(),
          schema.toJsonSchemaDraft7(),
        ]) {
          expect(
            exported.containsKey('allOf'),
            needsAllOf,
            reason: '$exported',
          );
          expect(Ack.fromJsonSchema(exported).safeParse(null).isFail, isTrue);
        }
      });
    }
  });

  group('default null semantics', () {
    test('nullable defaults still substitute only on parse', () {
      final schema = Ack.string().nullable().withDefault('fallback');
      expect(schema.parse(null), 'fallback');
      expect(schema.encode(null), isNull);
      expect(
        Ack.fromJsonSchema(schema.toJsonSchema()).safeParse(null).isOk,
        isTrue,
      );
    });

    test('defaults over nullable unions retain effective null acceptance', () {
      final schema = _nullableUnion().withDefault('fallback');
      expect(schema.isNullable, isFalse);
      expect(schema.parse(null), 'fallback');
      expect(schema.encode(null), isNull);
      expect(
        Ack.fromJsonSchema(schema.toJsonSchema()).safeParse(null).isOk,
        isTrue,
      );
    });

    test(
      'a default outside a narrowed boundary still substitutes on parse',
      () {
        final schema = Ack.preserveBoundary(
          _record.nullable(),
        ).nullable(value: false).withDefault(_recordSample);
        expect(schema.parse(null), _recordSample);
        expect(schema.safeEncode(null).isFail, isTrue);
        expect(
          Ack.fromJsonSchema(schema.toJsonSchema()).safeParse(null).isFail,
          isTrue,
        );
      },
    );
  });
}
