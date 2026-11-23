import 'package:ack/ack.dart';
import 'package:ack_mcp_dart/ack_mcp_dart.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  test('Station-shaped search contract is preserved exactly', () {
    final schema = searchSchema();
    final expected = {
      'type': 'object',
      'properties': {
        'query': {
          'type': 'string',
          'minLength': 1,
          'description': 'Search query',
        },
        'limit': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 100,
          'default': 5,
        },
      },
      'required': ['query'],
      'additionalProperties': false,
    };
    expect(schema.toMcpToolInputSchema().toJson(), expected);
    expect(schema.toMcpToolInputSchema().toJson(), schema.toJsonSchema());
  });

  for (final fixture in schemaFixtures()) {
    group(fixture.name, () {
      test('round trips every keyword and stays within the dialect subset', () {
        final json = fixture.schema.toJsonSchema();
        expect(fixture.schema.toMcpToolInputSchema().toJson(), json);
        checkKeywords(json);
      });
      test('MCP and ACK agree on acceptance', () {
        final mcp = fixture.schema.toMcpToolInputSchema();
        for (final args in fixture.valid) {
          expect(() => mcp.validate(args), returnsNormally, reason: '$args');
          expect(fixture.schema.safeParse(args).isOk, isTrue, reason: '$args');
        }
        for (final args in fixture.invalid) {
          expect(
            () => mcp.validate(args),
            throwsA(isA<JsonSchemaValidationException>()),
            reason: '$args',
          );
          expect(
            fixture.schema.safeParse(args).isFail,
            isTrue,
            reason: '$args',
          );
        }
      });
    });
  }

  for (final (schema, shape) in <(AckSchema<Object, Object>, String)>[
    (Ack.object({}).nullable(), 'anyOf'),
    (discriminatedSchema, 'anyOf'),
    (Ack.string(), 'string'),
    (Ack.list(Ack.string()), 'array'),
  ]) {
    test('rejects $shape root with an actionable message', () {
      expect(
        schema.toMcpToolInputSchema,
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains(shape),
          ),
        ),
      );
    });
  }
}

// Property/definition names and literal defaults are data, not schema keywords.
void checkKeywords(Map<String, Object?> schema) {
  const allowed = {
    'type',
    'properties',
    'required',
    'additionalProperties',
    'minimum',
    'maximum',
    'exclusiveMinimum',
    'exclusiveMaximum',
    'multipleOf',
    'minLength',
    'maxLength',
    'pattern',
    'format',
    'enum',
    'const',
    'items',
    'minItems',
    'maxItems',
    'uniqueItems',
    'anyOf',
    'oneOf',
    'allOf',
    r'$ref',
    'definitions',
    'title',
    'description',
    'default',
  };
  for (final MapEntry(:key, :value) in schema.entries) {
    expect(
      allowed.contains(key) || key.startsWith('x-'),
      isTrue,
      reason: 'New keyword $key: revisit the README dialect guarantee',
    );
    if (key == 'properties' || key == 'definitions') {
      for (final child in (value! as Map<String, Object?>).values) {
        checkKeywords(child! as Map<String, Object?>);
      }
    } else if (key == 'anyOf' || key == 'oneOf' || key == 'allOf') {
      for (final child in value! as List<Object?>) {
        checkKeywords(child! as Map<String, Object?>);
      }
    } else if ((key == 'items' || key == 'additionalProperties') &&
        value is Map<String, Object?>) {
      checkKeywords(value);
    }
  }
}
