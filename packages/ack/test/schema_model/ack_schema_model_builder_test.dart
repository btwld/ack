import 'package:ack/ack.dart';
import 'package:ack/src/constraints/comparison_constraint.dart';
import 'package:ack/src/schemas/schema.dart' show AnyAckSchema;
import 'package:test/test.dart';

enum _Role { admin, member }

/// A codec whose runtime values are seconds, not the milliseconds
/// [DurationConstraint] renders into JSON Schema keywords.
CodecSchema<int, Duration> _secondsCodec() => Ack.integer().codec<Duration>(
  decode: (value) => Duration(seconds: value),
  encode: (value) => value.inSeconds,
);

/// A codec whose encode changes the boundary string's length, so a runtime
/// `minLength` does not describe the encoded value.
CodecSchema<String, String> _prefixCodec() => Ack.string().codec<String>(
  decode: (value) => value,
  encode: (value) => 'ID:$value',
);

/// Every value the exported schema associates with [keyword], at any depth.
List<Object?> _keywordValues(Object? exported, String keyword) {
  final found = <Object?>[];
  void walk(Object? node) {
    if (node is Map) {
      for (final entry in node.entries) {
        if (entry.key == keyword) found.add(entry.value);
        walk(entry.value);
      }
    } else if (node is List) {
      node.forEach(walk);
    }
  }

  walk(exported);

  return found;
}

void main() {
  group('AckSchema.toSchemaModel()', () {
    test('builds primitive, object, and default metadata directly', () {
      final schema = Ack.object({
        'name': Ack.string().minLength(2).withDefault('Ada'),
        'role': Ack.enumValues(_Role.values).withDefault(_Role.admin),
      }).describe('User payload');

      final model = schema.toSchemaModel();

      expect(model, isA<AckObjectSchemaModel>());
      final object = model as AckObjectSchemaModel;
      expect(object.description, 'User payload');
      expect(object.properties!['name'], isA<AckStringSchemaModel>());
      expect(
        (object.properties!['name']! as AckStringSchemaModel).minLength,
        2,
      );
      expect(object.properties!['name']!.defaultValue, 'Ada');
      expect((object.properties!['role']! as AckStringSchemaModel).enumValues, [
        'admin',
        'member',
      ]);
      expect(object.properties!['role']!.defaultValue, 'admin');
      expect(object.required, isNull);
      expect(object.propertyOrdering, ['name', 'role']);
    });

    test('renders model defaults into JSON Schema output', () {
      final model = Ack.string().withDefault('draft').toSchemaModel();

      expect(model.toJsonSchema(), {'type': 'string', 'default': 'draft'});
    });

    test('omits defaults that cannot be encoded through wrapped schema', () {
      final transformed = Ack.string()
          .transform<int>((value) => int.parse(value))
          .withDefault(7);
      final constrained = Ack.integer().min(10).withDefault(5);
      final invalidEnum = Ack.enumValues([
        _Role.admin,
      ]).withDefault(_Role.member);

      expect(transformed.toJsonSchema(), isNot(contains('default')));
      expect(constrained.toJsonSchema(), isNot(contains('default')));
      expect(invalidEnum.toJsonSchema(), isNot(contains('default')));
    });

    test('records warning when default cannot be exported', () {
      final model = Ack.instance<DateTime>()
          .withDefault(DateTime(2026, 1, 1))
          .toSchemaModel();
      final defaultWarnings = model.warnings
          .where((warning) => warning.code == 'default_not_export_safe')
          .toList(growable: false);

      expect(model.toJsonSchema(), isNot(contains('default')));
      expect(defaultWarnings, hasLength(1));
    });

    test('object required fields follow parse-valid defaults', () {
      final schema = Ack.object({
        'createdAt': Ack.instance<DateTime>().withDefault(DateTime(2026, 1, 1)),
        'age': Ack.integer().min(10).withDefault(5),
      });

      final model = schema.toSchemaModel() as AckObjectSchemaModel;
      final json = model.toJsonSchema();
      final properties = json['properties'] as Map<Object?, Object?>;

      expect(model.required, ['age']);
      expect(json['required'], ['age']);
      expect(
        properties['createdAt'] as Map<Object?, Object?>,
        isNot(contains('default')),
      );
      expect(
        properties['age'] as Map<Object?, Object?>,
        isNot(contains('default')),
      );
    });

    test('renders direct JSON Schema through the schema model', () {
      void expectDirectMatchesModel(AnyAckSchema schema) {
        expect(
          schema.toJsonSchema(),
          equals(schema.toSchemaModel().toJsonSchema()),
          reason: '${schema.runtimeType} should render from AckSchemaModel',
        );
      }

      expectDirectMatchesModel(Ack.string().email().nullable());
      expectDirectMatchesModel(Ack.integer().min(1).max(10));
      expectDirectMatchesModel(Ack.double().positive().multipleOf(0.5));
      expectDirectMatchesModel(Ack.boolean().withDefault(true));
      expectDirectMatchesModel(Ack.enumValues(_Role.values).nullable());
      expectDirectMatchesModel(Ack.list(Ack.string()).minItems(1).unique());
      expectDirectMatchesModel(
        Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().optional(),
        }, additionalProperties: true),
      );
      expectDirectMatchesModel(Ack.any());
      expectDirectMatchesModel(Ack.map(Ack.integer().min(0)).nullable());
      expectDirectMatchesModel(Ack.map(Ack.any().nullable()));
      expectDirectMatchesModel(
        Ack.anyOf([Ack.string(), Ack.integer()]).nullable(),
      );
      expectDirectMatchesModel(
        Ack.string().transform<int>((value) => value.length),
      );
      expectDirectMatchesModel(Ack.date().min(DateTime(2026, 1, 1)));
      expectDirectMatchesModel(
        Ack.discriminated<Map<String, Object?>>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({'name': Ack.string()}),
            'dog': Ack.object({'good': Ack.boolean()}),
          },
        ).nullable(),
      );
    });

    test('uses existing composition models for imported JSON Schema', () {
      final schema = Ack.fromJsonSchema({'type': 'string', 'minLength': 2});

      final model = schema.toSchemaModel();

      expect(model, isA<AckAllOfSchemaModel>());
      final allOf = model as AckAllOfSchemaModel;
      expect(allOf.schemas, hasLength(1));
      expect(allOf.schemas.single, isA<AckRefSchemaModel>());
      expect(model.toJsonSchema(), schema.toJsonSchema());
    });

    test('rejects an imported definition reused as a lazy target', () {
      final imported = Ack.fromJsonSchema(true).nullable(value: false);
      final schema = Ack.object({
        'a': imported,
        'b': Ack.lazy('_ack_import_0_0', () => imported),
      });

      expect(
        schema.toJsonSchema,
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('collides with an imported definition'),
          ),
        ),
      );
    });

    test('rejects an import generated name occupied by an earlier lazy', () {
      final imported = Ack.fromJsonSchema(true);
      final schema = Ack.object({
        'a': Ack.lazy('_ack_import_0_0', Ack.string),
        'b': imported,
      });

      expect(
        schema.toJsonSchema,
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Imported definition collides with'),
          ),
        ),
      );
    });

    test('rejects nullable list item schemas at construction', () {
      expect(
        () => Ack.list(Ack.string().nullable()),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('does not support nullable item schemas'),
          ),
        ),
      );
    });

    test('injects omitted discriminator literals in model builds', () {
      final schema = Ack.discriminated<Map<String, Object?>>(
        discriminatorKey: 'type',
        schemas: {
          'cat': Ack.object({'name': Ack.string()}),
        },
      );

      final model = schema.toSchemaModel() as AckAnyOfSchemaModel;
      final branch = model.schemas.single as AckObjectSchemaModel;
      final discriminator = branch.properties!['type'] as AckStringSchemaModel;

      expect(model.discriminator!.propertyName, 'type');
      expect(discriminator.constValue, 'cat');
      expect(branch.required, ['type', 'name']);
      expect(branch.propertyOrdering, ['type', 'name']);
      expect(model.toJsonSchema()['anyOf'], isNotNull);
      expect(model.toJsonSchema(), isNot(contains('discriminator')));
      expect(branch.toJsonSchema(), isNot(contains('propertyOrdering')));
    });

    test(
      'replaces compatible authored discriminator with exact branch literal',
      () {
        final schema = Ack.discriminated<Map<String, Object?>>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({
              'type': Ack.enumString(['cat', 'kitty']),
              'name': Ack.string(),
            }),
          },
        );

        final model = schema.toSchemaModel() as AckAnyOfSchemaModel;
        final branch = model.schemas.single as AckObjectSchemaModel;
        final discriminator =
            branch.properties!['type'] as AckStringSchemaModel;

        expect(model.discriminator!.propertyName, 'type');
        expect(discriminator.constValue, 'cat');
        expect(branch.required, ['type', 'name']);
        expect(model.toJsonSchema()['anyOf'], isNotNull);
      },
    );

    test('puts injected discriminator first in branch model ordering', () {
      final schema = Ack.discriminated<Map<String, Object?>>(
        discriminatorKey: 'type',
        schemas: {
          'cat': Ack.object({'name': Ack.string(), 'type': Ack.literal('cat')}),
        },
      );

      final model = schema.toSchemaModel() as AckAnyOfSchemaModel;
      final branch = model.schemas.single as AckObjectSchemaModel;

      expect(branch.properties!.keys, ['type', 'name']);
      expect(branch.required, ['type', 'name']);
      expect(branch.propertyOrdering, ['type', 'name']);
    });

    test('rejects incompatible discriminator without executing transforms', () {
      var transformCalled = false;
      expect(
        () => Ack.discriminated<Map<String, Object?>>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({
              'type': Ack.string().transform<String>((value) {
                transformCalled = true;
                return value;
              }),
              'name': Ack.string(),
            }),
          },
        ),
        throwsArgumentError,
      );
      expect(transformCalled, isFalse);
    });

    test(
      'exports transformed object-backed branches through effectiveBranch',
      () {
        final schema = Ack.discriminated<Object>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({
              'name': Ack.string(),
            }).transform<Object>((map) => map),
          },
        );

        final model = schema.toSchemaModel() as AckAnyOfSchemaModel;
        final branch = model.schemas.single as AckObjectSchemaModel;
        final discriminator =
            branch.properties!['type'] as AckStringSchemaModel;

        expect(discriminator.constValue, 'cat');
        expect(branch.extensions['x-transformed'], isTrue);
        expect(branch.required, ['type', 'name']);
      },
    );

    test('records date constraints as non-Draft-7 warnings', () {
      final schema = Ack.date()
          .min(DateTime(2026, 1, 1))
          .max(DateTime(2026, 12, 31));
      final model = schema.toSchemaModel();

      expect(model.toJsonSchema(), {
        'type': 'string',
        'format': 'date',
        'x-transformed': true,
      });
      expect(
        model.warnings.map((warning) => warning.code),
        everyElement('datetime_constraint_not_draft7'),
      );
      expect(model.warnings, hasLength(2));
    });

    test('omits a codec runtime constraint that the wire cannot express', () {
      final schema = _secondsCodec().min(const Duration(seconds: 5));
      final model = schema.toSchemaModel();
      final exported = model.toJsonSchema();

      expect(_keywordValues(exported, 'minimum'), isEmpty);
      expect(model.warnings, hasLength(1));
      expect(
        model.warnings.single.code,
        'codec_runtime_constraint_not_exported',
      );
      expect(model.warnings.single.context['constraints'], ['duration_min']);
    });

    test('an omitted codec constraint is still enforced at runtime', () {
      final schema = _secondsCodec().min(const Duration(seconds: 5));

      expect(schema.safeEncode(const Duration(seconds: 4)).isFail, isTrue);
      expect(schema.safeEncode(const Duration(seconds: 5)).isOk, isTrue);
      expect(schema.safeEncode(const Duration(seconds: 5)).getOrNull(), 5);
    });

    test('a length-changing codec exports no runtime minLength', () {
      final schema = _prefixCodec().withConstraints([
        ComparisonConstraint.stringMinLength(5),
      ]);
      final model = schema.toSchemaModel();

      expect(_keywordValues(model.toJsonSchema(), 'minLength'), isEmpty);
      expect(model.warnings.map((warning) => warning.code), [
        'codec_runtime_constraint_not_exported',
      ]);
      expect(model.warnings.single.context['constraints'], [
        'string_min_length',
      ]);
      expect(schema.safeEncode('ab').isFail, isTrue);
      expect(schema.safeEncode('abcde').getOrNull(), 'ID:abcde');
    });

    test('input-side constraints still export through a codec', () {
      final schema = Ack.string()
          .minLength(1)
          .transform((value) => value.trim());
      final model = schema.toSchemaModel();

      expect(model.toJsonSchema(), {
        'type': 'string',
        'minLength': 1,
        'x-transformed': true,
      });
      expect(model.warnings, isEmpty);
    });

    test('output-schema constraints remain un-exported and un-warned', () {
      final schema = Ack.integer().codec<Duration>(
        output: Ack.instance<Duration>().refine(
          (value) => value.inSeconds >= 5,
          message: 'at least five seconds',
        ),
        decode: (value) => Duration(seconds: value),
        encode: (value) => value.inSeconds,
      );
      final model = schema.toSchemaModel();

      expect(model.toJsonSchema(), {'type': 'integer', 'x-transformed': true});
      expect(model.warnings, isEmpty);
    });

    test('datetime constraints keep their own warning on any codec', () {
      final builtIn = Ack.datetime().min(DateTime.utc(2026)).toSchemaModel();
      final custom = Ack.string()
          .codec<DateTime>(
            decode: DateTime.parse,
            encode: (value) => value.toIso8601String(),
          )
          .min(DateTime.utc(2026))
          .toSchemaModel();

      for (final model in [builtIn, custom]) {
        expect(model.warnings.map((warning) => warning.code), [
          'datetime_constraint_not_draft7',
        ]);
      }
    });

    test('default and boundary wrappers export unchanged', () {
      final withDefault = Ack.string()
          .minLength(2)
          .withDefault('ack')
          .toSchemaModel();
      final boundary = Ack.preserveBoundary(
        Ack.string().minLength(2),
      ).toSchemaModel();

      expect(withDefault.toJsonSchema(), {
        'type': 'string',
        'minLength': 2,
        'default': 'ack',
      });
      expect(boundary.toJsonSchema(), {'type': 'string', 'minLength': 2});
      expect(withDefault.warnings, isEmpty);
      expect(boundary.warnings, isEmpty);
    });

    test('nesting does not change codec constraint projection', () {
      final constrained = _secondsCodec().min(const Duration(seconds: 5));

      final property = Ack.object({'t': constrained}).toSchemaModel();
      final item = Ack.list(constrained).toSchemaModel();
      final defaulted = constrained
          .withDefault(const Duration(seconds: 30))
          .toSchemaModel();

      for (final model in [property, item, defaulted]) {
        expect(_keywordValues(model.toJsonSchema(), 'minimum'), isEmpty);
      }
      expect(
        Ack.object({
          't': Ack.duration().min(const Duration(seconds: 5)),
        }).toSchemaModel().toJsonSchema(),
        containsPair(
          'properties',
          containsPair('t', containsPair('minimum', 5000)),
        ),
      );
    });

    test('records Ack.any JSON export limitation as a warning', () {
      final model = Ack.any().toSchemaModel();

      expect(model, isA<AckAnyOfSchemaModel>());
      expect((model as AckAnyOfSchemaModel).schemas, isNotEmpty);
      expect(model.warnings, hasLength(1));
      expect(model.warnings.single.message, contains('JSON-safe values'));
    });

    test('applies constraints to all model-producing schema kinds', () {
      final boolean = Ack.boolean().withConstraint(
        const _TestSchemaModelConstraint<bool>(),
      );
      final anyOf = Ack.anyOf([
        Ack.string(),
        Ack.integer(),
      ]).withConstraint(const _TestSchemaModelConstraint<Object>());

      expect(boolean.toSchemaModel().extensions['x-test-marker'], isTrue);
      expect(anyOf.toSchemaModel().extensions['x-test-marker'], isTrue);
    });

    test('preserves custom JSON Schema keywords in extensions', () {
      final model = Ack.string()
          .withConstraint(const _TestSchemaModelConstraint<String>())
          .toSchemaModel();

      expect(model.extensions, {'x-test-marker': true});
      expect(model.toJsonSchema()['x-test-marker'], isTrue);
    });

    test('preserves malformed integer keywords instead of truncating', () {
      final model = Ack.string()
          .withConstraint(
            const _TestJsonSchemaKeywordConstraint<String>({'minLength': 1.5}),
          )
          .toSchemaModel();

      expect((model as AckStringSchemaModel).minLength, isNull);
      expect(model.extensions, {'minLength': 1.5});
      expect(model.toJsonSchema()['minLength'], 1.5);
    });
  });
}

final class _TestSchemaModelConstraint<T extends Object> extends Constraint<T>
    with Validator<T>, JsonSchemaSpec<T> {
  const _TestSchemaModelConstraint()
    : super(
        constraintKey: 'test_schema_model_marker',
        description: 'Adds a test-only JSON Schema marker.',
      );

  @override
  bool isValid(T value) => true;

  @override
  String buildMessage(T value) => 'ok';

  @override
  Map<String, Object?> toJsonSchema() => {'x-test-marker': true};
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
