import 'package:ack/ack.dart';
import 'package:ack/src/schemas/schema.dart' show AnyAckSchema;
import 'package:test/test.dart';

enum _Role { admin, member }

void main() {
  group('AckSchema.toSchemaModel()', () {
    test('builds primitive, object, and default metadata directly', () {
      final schema = Ack.object({
        'name': Ack.string().minLength(2).withDefault('Ada'),
        'role': Ack.enumValues(_Role.values).withDefault(_Role.admin),
      }).describe('User payload');

      final model = schema.toSchemaModel();

      expect(model, isA<ObjectSchemaModel>());
      final object = model as ObjectSchemaModel;
      expect(object.description, 'User payload');
      expect(object.properties!['name'], isA<StringSchemaModel>());
      expect((object.properties!['name']! as StringSchemaModel).minLength, 2);
      expect(object.properties!['name']!.defaultValue, 'Ada');
      expect((object.properties!['role']! as StringSchemaModel).enumValues, [
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

    test('rendered schema model JSON imports back to the same JSON', () {
      final model = Ack.object({
        'name': Ack.string().minLength(2),
        'tags': Ack.list(Ack.string()).optional(),
      }).toSchemaModel();
      final json = model.toJsonSchema();

      expect(SchemaModel.fromJsonSchema(json).toJsonSchema(), json);
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

      final model = schema.toSchemaModel() as ObjectSchemaModel;
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
          reason: '${schema.runtimeType} should render from SchemaModel',
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

      final model = schema.toSchemaModel() as AnyOfSchemaModel;
      final branch = model.schemas.single as ObjectSchemaModel;
      final discriminator = branch.properties!['type'] as StringSchemaModel;

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

        final model = schema.toSchemaModel() as AnyOfSchemaModel;
        final branch = model.schemas.single as ObjectSchemaModel;
        final discriminator = branch.properties!['type'] as StringSchemaModel;

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

      final model = schema.toSchemaModel() as AnyOfSchemaModel;
      final branch = model.schemas.single as ObjectSchemaModel;

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

        final model = schema.toSchemaModel() as AnyOfSchemaModel;
        final branch = model.schemas.single as ObjectSchemaModel;
        final discriminator = branch.properties!['type'] as StringSchemaModel;

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

    test('records Ack.any JSON export limitation as a warning', () {
      final model = Ack.any().toSchemaModel();

      expect(model, isA<AnyOfSchemaModel>());
      expect((model as AnyOfSchemaModel).schemas, isNotEmpty);
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

      expect((model as StringSchemaModel).minLength, isNull);
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
