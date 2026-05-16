import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

final class _Cat {
  _Cat(this.name);
  final String name;
}

void main() {
  group('1. Null-policy hooks (no public safeEncode override needed)', () {
    test('AnyOf with nullable branch accepts null on encode via base wrapper',
        () {
      final schema = Ack.anyOf([Ack.string().nullable(), Ack.integer()]);
      final result = schema.safeEncode(null);
      expect(result.isOk, true);
      expect(result.getOrNull(), isNull);
    });

    test('AnyOf without nullable branch rejects null on encode', () {
      final schema = Ack.anyOf([Ack.string(), Ack.integer()]);
      final result = schema.safeEncode(null);
      expect(result.isFail, true);
    });

    test('Primitive schemas inherit isNullable-based encode null policy', () {
      final nullable = Ack.string().nullable();
      final nonNullable = Ack.string();
      expect(nullable.safeEncode(null).isOk, true);
      expect(nonNullable.safeEncode(null).isFail, true);
    });
  });

  group('2. JSON-safe default filtering', () {
    test('DefaultSchema omits non-JSON-safe defaults', () {
      // InstanceSchema<DateTime> identity-encodes a DateTime as itself,
      // which is NOT JSON-safe. The default must NOT be emitted.
      final schema = Ack.instance<DateTime>().withDefault(DateTime(2026, 1));
      final json = schema.toJsonSchema();
      expect(json.containsKey('default'), false);
    });

    test('DefaultSchema emits JSON-safe primitive defaults', () {
      final schema = Ack.string().withDefault('x');
      final json = schema.toJsonSchema();
      expect(json['default'], 'x');
    });

    test('DefaultSchema emits JSON-safe nested map default', () {
      final schema = Ack.object({
        'name': Ack.string(),
      }).withDefault({'name': 'guest'});
      final json = schema.toJsonSchema();
      expect(json['default'], {'name': 'guest'});
    });

    test('DefaultSchema emits codec-encoded default (date) cleanly', () {
      final schema = Ack.date().withDefault(DateTime(2026, 1, 1));
      final json = schema.toJsonSchema();
      // The codec encodes DateTime → 'YYYY-MM-DD', which is JSON-safe.
      expect(json['default'], '2026-01-01');
    });

    test('DefaultSchema default survives a jsonEncode round-trip', () {
      final schema = Ack.object({
        'name': Ack.string(),
      }).withDefault({'name': 'guest'});
      final json = schema.toJsonSchema();
      // Should not throw.
      final encoded = jsonEncode(json);
      expect(encoded.contains('"default":{"name":"guest"}'), true);
    });
  });

  group('3. Ack.any() JSON Schema does not accept null', () {
    test('non-nullable Ack.any() emits explicit non-null branches', () {
      final json = Ack.any().toJsonSchema();
      expect(json['anyOf'], isA<List>());
      final branches = (json['anyOf'] as List).cast<Map>();
      final types = branches
          .where((b) => b['type'] != null)
          .map((b) => b['type'])
          .toList();
      expect(types, containsAll([
        'string',
        'number',
        'integer',
        'boolean',
        'object',
        'array',
      ]));
      // No null branch.
      expect(types.contains('null'), false);
    });

    test('nullable Ack.any() adds null branch', () {
      final json = Ack.any().nullable().toJsonSchema();
      expect(json['anyOf'], isA<List>());
      final branches = (json['anyOf'] as List).cast<Map>();
      final types = branches.map((b) => b['type']).toList();
      expect(types.contains('null'), true);
    });
  });

  group('4. Discriminated branch reject conflicting discriminator', () {
    test('encode fails when a branch emits a conflicting discriminator',
        () {
      final schema = Ack.discriminated<_Cat>(
        discriminatorKey: 'kind',
        schemas: {
          'cat': Ack.object({
            // Branch encoder emits 'wrong-kind', which conflicts with 'cat'.
            'kind': Ack.literal('wrong-kind'),
            'name': Ack.string(),
          }).model<_Cat>(
            decode: (data) => _Cat(data['name'] as String),
            encode: (cat) => {
              'kind': 'wrong-kind',
              'name': cat.name,
            },
          ),
        },
      );
      final result = schema.safeEncode(_Cat('Mittens'));
      expect(result.isFail, true);
    });

    test('encode succeeds when branch omits discriminator (auto-added)', () {
      final schema = Ack.discriminated<_Cat>(
        discriminatorKey: 'kind',
        schemas: {
          'cat': Ack.object({
            'name': Ack.string(),
          }).model<_Cat>(
            decode: (data) => _Cat(data['name'] as String),
            encode: (cat) => {'name': cat.name},
          ),
        },
      );
      final encoded = schema.encode(_Cat('Mittens'));
      expect(encoded, {'kind': 'cat', 'name': 'Mittens'});
    });

    test('encode succeeds when branch emits a matching discriminator', () {
      final schema = Ack.discriminated<_Cat>(
        discriminatorKey: 'kind',
        schemas: {
          'cat': Ack.object({
            'kind': Ack.literal('cat'),
            'name': Ack.string(),
          }).model<_Cat>(
            decode: (data) => _Cat(data['name'] as String),
            encode: (cat) => {
              'kind': 'cat',
              'name': cat.name,
            },
          ),
        },
      );
      final encoded = schema.encode(_Cat('Mittens'));
      expect(encoded, {'kind': 'cat', 'name': 'Mittens'});
    });
  });

  group('5. Optional-null encode omission (parse/encode asymmetry)', () {
    test('encode omits optional + non-nullable null property', () {
      final schema = Ack.object({
        'name': Ack.string(),
        'nickname': Ack.string().optional(),
      });
      final encoded = schema.encode({
        'name': 'Cat',
        'nickname': null,
      });
      expect(encoded, {'name': 'Cat'});
    });

    test('encode keeps optional + nullable explicit null property', () {
      final schema = Ack.object({
        'name': Ack.string(),
        'nickname': Ack.string().optional().nullable(),
      });
      final encoded = schema.encode({
        'name': 'Cat',
        'nickname': null,
      });
      expect(encoded, {'name': 'Cat', 'nickname': null});
    });

    test('parse still rejects optional + non-nullable explicit null', () {
      final schema = Ack.object({
        'name': Ack.string(),
        'nickname': Ack.string().optional(),
      });
      final result = schema.safeParse({
        'name': 'Cat',
        'nickname': null,
      });
      expect(result.isFail, true);
    });
  });
}
