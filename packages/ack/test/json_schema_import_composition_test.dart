import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  test('repeated identified imports preserve occurrence overrides', () {
    final shared = Ack.fromJsonSchema({
      r'$id': 'https://example.test/shared',
      'type': 'string',
    });
    final composed = Ack.object({
      'optionalNull': shared.nullable().describe('Nullable occurrence'),
      'requiredString': shared.describe('String occurrence'),
    });
    final restored = Ack.fromJsonSchema(composed.toJsonSchema());
    expect(
      restored.safeParse({'optionalNull': null, 'requiredString': 'ok'}).isOk,
      isTrue,
    );
    expect(
      restored.safeParse({'optionalNull': 'ok', 'requiredString': null}).isFail,
      isTrue,
    );
  });

  test('distinct imports share external resources and assertion dialects', () {
    final documents = {
      Uri.parse('https://example.test/email'): {
        r'$id': 'https://example.test/email',
        'type': 'string',
        'format': 'email',
      },
    };
    final composed = Ack.object({
      for (final key in ['first', 'second'])
        key: Ack.fromJsonSchema(
          {
            r'$id': 'https://example.test/$key',
            r'$ref': 'https://example.test/email',
          },
          documents: documents,
          assertFormats: true,
        ),
    });
    final restored = Ack.fromJsonSchema(composed.toJsonSchema());
    expect(
      restored.safeParse({
        'first': 'a@example.test',
        'second': 'b@example.test',
      }).isOk,
      isTrue,
    );
    expect(
      restored.safeParse({'first': 'a@example.test', 'second': 'bad'}).isFail,
      isTrue,
    );
  });

  test('nested resource pointers survive resource deduplication', () {
    final nested = {
      r'$id': 'https://example.test/nested',
      r'$defs': {
        'value': {'type': 'string'},
        'never': false,
      },
    };
    for (final target in ['value', 'never']) {
      final composed = Ack.object({
        for (final key in ['first', 'second'])
          key: Ack.fromJsonSchema({
            r'$id': 'https://example.test/$key',
            r'$defs': {'shared': nested},
            r'$ref': '#/\$defs/shared/\$defs/$target',
          }),
      });
      final restored = Ack.fromJsonSchema(composed.toJsonSchema());
      expect(
        restored.safeParse({'first': 'ok', 'second': 'ok'}).isOk,
        target == 'value',
      );
      expect(restored.safeParse({'first': 'ok', 'second': 1}).isFail, isTrue);
    }
  });

  test('referenced resources in nonstandard containers can be composed', () {
    final composed = Ack.object({
      for (final key in ['first', 'second'])
        key: Ack.fromJsonSchema({
          r'$id': 'https://example.test/$key',
          'catalog': {
            'shared': {r'$id': 'https://example.test/shared', 'type': 'string'},
          },
          r'$ref': '#/catalog/shared',
        }),
    });
    final restored = Ack.fromJsonSchema(composed.toJsonSchema());
    expect(restored.safeParse({'first': 'ok', 'second': 'ok'}).isOk, isTrue);
    expect(restored.safeParse({'first': 'ok', 'second': 1}).isFail, isTrue);
  });

  test('constraints and non-null overrides stay local to each occurrence', () {
    final shared = Ack.fromJsonSchema({r'$id': 'urn:anything'});
    final composed = Ack.object({
      'string': shared.constrain(const _OnlyStrings()),
      'any': shared,
      'nonNull': shared.nullable(value: false),
    });
    final restored = Ack.fromJsonSchema(composed.toJsonSchema());
    for (final value in [
      {'string': 'ok', 'any': 1, 'nonNull': false},
      {'string': null, 'any': null, 'nonNull': 'ok'},
      {'string': 1, 'any': 'ok', 'nonNull': 'ok'},
      {'string': 'ok', 'any': 'ok', 'nonNull': null},
    ]) {
      expect(restored.safeParse(value).isOk, composed.safeParse(value).isOk);
    }
  });

  test('shared recursive resources retain dynamic reference scope', () {
    final tree = Ack.fromJsonSchema({
      r'$id': 'https://example.test/tree',
      r'$dynamicAnchor': 'node',
      'type': 'object',
      'properties': {
        'value': {'type': 'string'},
        'child': {r'$dynamicRef': '#node'},
      },
      'required': ['value'],
    });
    final schema = Ack.object({'first': tree, 'second': tree});
    final restored = Ack.fromJsonSchema(schema.toJsonSchema());
    for (final child in <Object?>[
      {'value': 'ok'},
      {'value': 42},
      null,
    ]) {
      final data = {
        'first': {'value': 'ok'},
        'second': {'value': 'ok', 'child': child},
      };
      expect(restored.safeParse(data).isOk, schema.safeParse(data).isOk);
    }
  });

  test('conflicting resource identifiers fail explicitly during export', () {
    final composed = Ack.object({
      'first': Ack.fromJsonSchema({r'$id': 'urn:shared', 'type': 'string'}),
      'second': Ack.fromJsonSchema({r'$id': 'urn:shared', 'type': 'number'}),
    });
    expect(() => composed.toJsonSchema(), throwsArgumentError);
  });

  test('identifier-shaped instance data is not deduplicated', () {
    final value = {r'$id': 'urn:instance', 'type': 'string'};
    final composed = Ack.object({
      'first': Ack.fromJsonSchema({'const': value}),
      'second': Ack.fromJsonSchema({'const': value}),
    });
    final restored = Ack.fromJsonSchema(composed.toJsonSchema());
    expect(restored.safeParse({'first': value, 'second': value}).isOk, isTrue);
  });
}

final class _OnlyStrings extends Constraint<Object>
    with Validator<Object>, JsonSchemaSpec<Object> {
  const _OnlyStrings()
    : super(constraintKey: 'only_strings', description: 'Expected a string.');

  @override
  bool isValid(Object value) => value is String;

  @override
  String buildMessage(Object value) => description;

  @override
  Map<String, Object?> toJsonSchema() => {'type': 'string'};
}
