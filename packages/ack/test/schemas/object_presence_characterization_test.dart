import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

Map<String, Object?> _error(SchemaError error) => {
  ...error.toMap(),
  'type': error.runtimeType.toString(),
  if (error is SchemaNestedError)
    'nestedErrors': [for (final child in error.errors) _error(child)],
};

Object _result(SchemaResult<Object> result) => result.isOk
    ? {'ok': result.getOrNull()}
    : {'error': _error(result.getError())};

void main() {
  test('frozen presence and unknown-property matrix preserves both loops', () {
    final properties = <String, AckSchema<Object, Object>>{
      'nullable': Ack.string().nullable(),
      'optional': Ack.string().optional(),
      'defaulted': Ack.string().withDefault('fallback'),
      'nullableDefault': Ack.string().nullable().withDefault('fallback'),
    };
    final records = <Object>[];
    for (final property in properties.entries) {
      for (final nested in [false, true]) {
        for (final presence in ['missing', 'null', 'value']) {
          final outcomes = <String, Object?>{};
          for (final allowExtra in [false, true]) {
            final inner = Ack.object({
              'field': property.value,
            }, additionalProperties: allowExtra);
            final schema = nested ? Ack.object({'child': inner}) : inner;
            final map = <String, Object?>{
              'extra': 7,
              if (presence != 'missing')
                'field': presence == 'null' ? null : 'valid',
            };
            final Map<String, Object?> input = nested ? {'child': map} : map;
            // Exercise the runtime loop independently of parse and encode.
            // ignore: invalid_use_of_protected_member
            final runtime = schema.validateRuntimeWithContext(
              input,
              SchemaContext(name: 'matrix', schema: schema, value: input),
            );
            outcomes['$allowExtra'] = [
              _result(schema.safeParse(input, debugName: 'matrix')),
              _result(runtime),
              _result(schema.safeEncode(input, debugName: 'matrix')),
            ];
          }
          records.add({
            'property': property.key,
            'nested': nested,
            'presence': presence,
            'outcomes': outcomes,
          });
        }
      }
    }
    final fixture = File('test/fixtures/object_presence_matrix.jsonl');
    if (Platform.environment['ACK_UPDATE_PRESENCE'] == '1') {
      fixture.writeAsStringSync('${records.map(jsonEncode).join('\n')}\n');
    }
    expect(records, fixture.readAsLinesSync().map(jsonDecode).toList());
  });

  test('additional-property errors retain order and pointer escaping', () {
    final schema = Ack.object({});
    final input = {'a/b': 1, 'c~d': 2};
    for (final result in [schema.safeParse(input), schema.safeEncode(input)]) {
      final error = result.getError() as SchemaNestedError;
      expect(error.errors.map((e) => e.context.path), ['#/a~1b', '#/c~0d']);
    }
  });
}
