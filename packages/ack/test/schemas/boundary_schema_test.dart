import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

enum Status { active, archived }

const _instant = '2026-08-27T12:00:00Z';

/// A codec whose output object fills a default, so its runtime validation is
/// stricter under parse than under encode.
final _defaultFillingCodec = Ack.codec<String, String, Map<String, Object?>>(
  input: Ack.string(),
  decode: (_) => <String, Object?>{},
  encode: (_) => 'x',
  output: Ack.object({'n': Ack.integer().withDefault(1)}),
);

/// Wire views over every JSON-object root kind, with one valid wire value.
final _roots =
    <({String name, AckSchema<JsonMap, Object> schema, String json})>[
      (
        name: 'object',
        schema: Ack.object({
          'when': Ack.datetime(),
          'tags': Ack.list(Ack.string()),
        }),
        json: '{"when": "$_instant", "tags": ["a"]}',
      ),
      (
        name: 'map',
        schema: Ack.map(Ack.datetime()),
        json: '{"a": "$_instant"}',
      ),
      (
        name: 'discriminated',
        schema: Ack.discriminated(
          discriminatorKey: 'kind',
          schemas: {
            'stamp': Ack.object({
              'kind': Ack.literal('stamp'),
              'when': Ack.datetime(),
            }),
          },
        ),
        json: '{"kind": "stamp", "when": "$_instant"}',
      ),
      (
        name: 'lazy',
        schema: Ack.lazy('Stamp', () => Ack.object({'when': Ack.datetime()})),
        json: '{"when": "$_instant"}',
      ),
    ];

void main() {
  group('BoundarySchema', () {
    final typedSchema = Ack.object({
      'createdAt': Ack.datetime(),
      'statuses': Ack.list(Ack.enumValues(Status.values)),
    });
    final wireSchema = Ack.preserveBoundary(typedSchema);

    Map<String, Object?> wireValue() => {
      'createdAt': _instant,
      'statuses': ['active'],
    };

    test('validates codecs without retaining decoded values', () {
      final result = wireSchema.parse(wireValue());

      expect(result, wireValue());
      expect(result!['createdAt'], isA<String>());
      expect(result['statuses'], ['active']);
    });

    test('rejects invalid boundary values', () {
      final result = wireSchema.safeParse({
        'createdAt': 'not-a-date',
        'statuses': ['unknown'],
      });

      expect(result.isFail, isTrue);
    });

    test('exports the wrapped boundary contract', () {
      expect(wireSchema.toJsonSchema(), typedSchema.toJsonSchema());
    });

    test('returns the same schema when it already wraps a wire view', () {
      expect(Ack.preserveBoundary(wireSchema), same(wireSchema));
    });

    group('detached results', () {
      void expectDetached(
        Map<String, Object?> Function(Map<String, Object?> input) operation,
      ) {
        final input = wireValue();
        final result = operation(input);
        input['createdAt'] = 'not-a-date';
        (input['statuses']! as List).add('archived');

        expect(result, wireValue());
        expect(() => result['createdAt'] = 'x', throwsUnsupportedError);
        expect(
          () => (result['statuses']! as List).add('archived'),
          throwsUnsupportedError,
        );
      }

      test('parse returns an unmodifiable copy of the input', () {
        expectDetached((input) => wireSchema.parse(input)!);
      });

      test('encode returns an unmodifiable copy of the input', () {
        expectDetached((input) => wireSchema.encode(input)!);
      });

      test('runtime validation returns an unmodifiable copy', () {
        late Map<String, Object?> decoded;
        final codec = Ack.codec<String, String, Map<String, Object?>>(
          input: Ack.string(),
          decode: (_) => decoded = wireValue(),
          encode: jsonEncode,
          output: wireSchema,
        );

        final result = codec.parse('ignored')!;
        decoded.clear();

        expect(result, wireValue());
        expect(() => result['createdAt'] = 'x', throwsUnsupportedError);
      });
    });

    group('container independence', () {
      for (final root in _roots) {
        test('${root.name} roots accept every JSON map container alike', () {
          final wire = Ack.preserveBoundary(root.schema);
          final decoded = jsonDecode(root.json) as Map<String, dynamic>;
          final inputs = <Object>[
            Map<String, Object?>.of(decoded),
            decoded,
            Map<dynamic, dynamic>.of(decoded),
          ];

          for (final input in inputs) {
            final result = wire.safeParse(input);
            expect(result.isOk, isTrue, reason: '${input.runtimeType}');
            expect(result.getOrNull(), decoded);
            expect(wire.safeEncode(decoded).getOrNull(), decoded);
          }
          final invalid = jsonDecode(root.json.replaceAll(_instant, 'bad'));
          expect(wire.safeParse(invalid).isFail, isTrue);
          expect(wire.safeEncode(invalid as JsonMap).isFail, isTrue);
        });

        test('${root.name} roots export the wrapped schema', () {
          expect(
            Ack.preserveBoundary(root.schema).toJsonSchema(),
            root.schema.toJsonSchema(),
          );
        });
      }
    });

    group('no encoders', () {
      test('nested codec strings are returned unchanged', () {
        final wire = Ack.preserveBoundary(
          Ack.object({'times': Ack.list(Ack.datetime())}),
        );
        final input = jsonDecode('{"times": ["$_instant"]}');

        expect(wire.parse(input), {
          'times': [_instant],
        });
        expect(wire.encode(input as JsonMap), {
          'times': [_instant],
        });
      });

      test('map values keep their wire representation', () {
        final wire = Ack.preserveBoundary(Ack.map(Ack.datetime()));
        final input = jsonDecode('{"a": "$_instant"}');

        expect(wire.parse(input), {'a': _instant});
      });

      test('one-way transforms do not change acceptance', () {
        int toInt(String? value) => int.parse(value!);
        final wires = [
          Ack.preserveBoundary(Ack.map(Ack.string().transform<int>(toInt))),
          Ack.preserveBoundary(
            Ack.object({'a': Ack.list(Ack.string().transform<int>(toInt))}),
          ),
        ];
        final inputs = [jsonDecode('{"a": "1"}'), jsonDecode('{"a": ["1"]}')];

        for (final (index, wire) in wires.indexed) {
          final input = inputs[index] as JsonMap;
          expect(wire.parse(input), input);
          expect(wire.encode(input), input);
        }
      });

      test('defaults of the wrapped object are not injected', () {
        final wire = Ack.preserveBoundary(
          Ack.object({'n': Ack.integer().withDefault(1)}),
        );

        expect(wire.parse(<String, Object?>{}), isEmpty);
        expect(wire.encode(<String, Object?>{}), isEmpty);
      });
    });

    group('invariants', () {
      final values = <Object?>[
        wireValue(),
        {'createdAt': 'not-a-date', 'statuses': <Object?>[]},
        {
          'createdAt': _instant,
          'statuses': ['unknown'],
        },
        {'statuses': <Object?>[]},
        {...wireValue(), 'extra': true},
        'not a map',
        <Object?>[],
      ];

      test('parse agrees with the wrapped schema and keeps the input', () {
        for (final value in values) {
          final wire = wireSchema.safeParse(value);
          expect(
            wire.isOk,
            typedSchema.safeParse(value).isOk,
            reason: '$value',
          );
          if (wire.isOk) expect(wire.getOrNull(), value);
        }
      });

      test('parse and encode accept the same values', () {
        final holder = Ack.object({'wire': wireSchema});
        for (final value in values.whereType<JsonMap>()) {
          final parsed = wireSchema.safeParse(value).isOk;
          expect(wireSchema.safeEncode(value).isOk, parsed, reason: '$value');
          expect(holder.safeParse({'wire': value}).isOk, parsed);
          expect(holder.safeEncode({'wire': value}).isOk, parsed);
        }
      });

      test('encode does not accept what parse rejects', () {
        final typed = Ack.object({'p': _defaultFillingCodec});
        final wire = Ack.preserveBoundary(typed);
        final holder = Ack.object({'wire': wire});
        const value = {'p': 'x'};

        expect(typed.safeParse(value).isFail, isTrue);
        expect(wire.safeParse(value).isFail, isTrue);
        expect(wire.safeEncode(value).isFail, isTrue);
        expect(holder.safeParse({'wire': value}).isFail, isTrue);
        expect(holder.safeEncode({'wire': value}).isFail, isTrue);
      });

      test('encode reports parse-side errors at the wrapper path', () {
        final holder = Ack.object({'wire': wireSchema});
        final invalid = {...wireValue(), 'createdAt': 'not-a-date'};

        final parseError = holder.safeParse({'wire': invalid}).getError();
        final encodeError = holder.safeEncode({'wire': invalid}).getError();

        for (final error in [parseError, encodeError]) {
          final nested = (error as SchemaNestedError).errors.single;
          expect(nested, isA<SchemaNestedError>());
          expect(nested.path, '#/wire');
          expect(
            (nested as SchemaNestedError).errors.single.path,
            '#/wire/createdAt',
          );
        }
      });

      test('encoding a parsed value returns the same JSON', () {
        final parsed = wireSchema.parse(wireValue());

        expect(wireSchema.encode(parsed), wireValue());
      });

      for (final (name, wire) in [
        ('a non-null wrapper', Ack.preserveBoundary(typedSchema)),
        ('a widened wrapper', Ack.preserveBoundary(typedSchema).nullable()),
        ('a nullable inner', Ack.preserveBoundary(typedSchema.nullable())),
        (
          'a narrowed nullable inner',
          Ack.preserveBoundary(typedSchema.nullable()).nullable(value: false),
        ),
      ]) {
        test('$name agrees on null in every operation and export', () {
          final acceptsNull = wire.safeParse(null).isOk;

          expect(wire.safeEncode(null).isOk, acceptsNull);
          expect(
            Ack.object({'k': wire}).safeParse({'k': null}).isOk,
            acceptsNull,
          );
          expect(
            Ack.object({'k': wire}).safeEncode({'k': null}).isOk,
            acceptsNull,
          );
          expect(
            Ack.fromJsonSchema(wire.toJsonSchema()).safeParse(null).isOk,
            acceptsNull,
          );
        });
      }
    });

    group('defaults', () {
      final inner = Ack.object({'k': Ack.string()});

      test('a default inside the wrapper does not apply at the root', () {
        final wire = Ack.preserveBoundary(inner.withDefault({'k': 'x'}));

        expect(wire.isNullable, isFalse);
        expect(wire.safeParse(null).isFail, isTrue);
        expect(wire.safeEncode(null).isFail, isTrue);
        expect(wire.toJsonSchema(), containsPair('default', {'k': 'x'}));
      });

      test('a default inside the wrapper keeps a property required', () {
        final holder = Ack.object({
          'p': Ack.preserveBoundary(inner.withDefault({'k': 'x'})),
        });

        expect(holder.safeParse(<String, Object?>{}).isFail, isTrue);
        expect(holder.safeParse({'p': null}).isFail, isTrue);
        expect(holder.safeEncode(<String, Object?>{}).isFail, isTrue);
        expect(holder.toJsonSchema()['required'], ['p']);
      });

      test('a default outside the wrapper applies', () {
        final holder = Ack.object({
          'p': Ack.preserveBoundary(inner).withDefault({'k': 'x'}),
        });

        expect(holder.parse(<String, Object?>{}), {
          'p': {'k': 'x'},
        });
        expect(holder.toJsonSchema()['required'], isNull);
      });
    });
  });
}
