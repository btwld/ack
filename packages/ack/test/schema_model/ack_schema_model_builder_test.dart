import 'package:ack/ack.dart';
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
      expect(object.required, ['name', 'role']);
      expect(object.propertyOrdering, ['name', 'role']);
    });

    test('renders model defaults into JSON Schema output', () {
      final model = Ack.string().withDefault('draft').toSchemaModel();

      expect(model.toJsonSchema(), {'type': 'string', 'default': 'draft'});
    });

    test('renders direct JSON Schema through the schema model', () {
      void expectDirectMatchesModel(AckSchema<Object> schema) {
        expect(
          schema.toJsonSchema(),
          equals(schema.toSchemaModel().toJsonSchema()),
          reason: '${schema.runtimeType} should render from AckSchemaModel',
        );
      }

      expectDirectMatchesModel(Ack.string().email().nullable());
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

      final model = schema.toSchemaModel() as AckOneOfSchemaModel;
      final branch = model.schemas.single as AckObjectSchemaModel;
      final discriminator = branch.properties!['type'] as AckStringSchemaModel;

      expect(model.discriminator!.propertyName, 'type');
      expect(discriminator.constValue, 'cat');
      expect(branch.required, ['type', 'name']);
      expect(branch.propertyOrdering, ['type', 'name']);
      expect(model.toJsonSchema()['oneOf'], isNotNull);
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

        final model = schema.toSchemaModel() as AckOneOfSchemaModel;
        final branch = model.schemas.single as AckObjectSchemaModel;
        final discriminator =
            branch.properties!['type'] as AckStringSchemaModel;

        expect(model.discriminator!.propertyName, 'type');
        expect(discriminator.constValue, 'cat');
        expect(branch.required, ['type', 'name']);
        expect(model.toJsonSchema()['oneOf'], isNotNull);
      },
    );

    test('puts injected discriminator first in branch model ordering', () {
      final schema = Ack.discriminated<Map<String, Object?>>(
        discriminatorKey: 'type',
        schemas: {
          'cat': Ack.object({'name': Ack.string(), 'type': Ack.literal('cat')}),
        },
      );

      final model = schema.toSchemaModel() as AckOneOfSchemaModel;
      final branch = model.schemas.single as AckObjectSchemaModel;

      expect(branch.properties!.keys, ['type', 'name']);
      expect(branch.required, ['type', 'name']);
      expect(branch.propertyOrdering, ['type', 'name']);
    });

    test('rejects incompatible discriminator without executing transforms', () {
      var transformCalled = false;
      final schema = Ack.discriminated<Map<String, Object?>>(
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
      );

      expect(schema.toSchemaModel, throwsArgumentError);
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

        final model = schema.toSchemaModel() as AckOneOfSchemaModel;
        final branch = model.schemas.single as AckObjectSchemaModel;
        final discriminator =
            branch.properties!['type'] as AckStringSchemaModel;

        expect(discriminator.constValue, 'cat');
        expect(branch.extensions['x-transformed'], isTrue);
        expect(branch.required, ['type', 'name']);
      },
    );

    test('exports date constraints using date-only bounds', () {
      final schema = Ack.date()
          .min(DateTime(2026, 1, 1))
          .max(DateTime(2026, 12, 31));

      expect(schema.toSchemaModel().toJsonSchema(), {
        'type': 'string',
        'format': 'date',
        'formatMinimum': '2026-01-01',
        'formatMaximum': '2026-12-31',
        'x-transformed': true,
      });
    });

    test('records Ack.any JSON export limitation as a warning', () {
      final model = Ack.any().toSchemaModel();

      expect(model, isA<AckAnyOfSchemaModel>());
      expect((model as AckAnyOfSchemaModel).schemas, isNotEmpty);
      expect(model.warnings, hasLength(1));
      expect(model.warnings.single.message, contains('JSON-compatible values'));
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
