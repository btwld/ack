import 'package:ack/ack.dart';
import 'package:ack/src/schemas/schema.dart' show AnyAckSchema;
import 'package:test/test.dart';

enum _Status { active, disabled }

void main() {
  group('canonical factory invariants', () {
    test('object schemas snapshot caller-owned property maps', () {
      final properties = {'name': Ack.string()};
      final schema = Ack.object(properties);

      properties.clear();

      expect(schema.safeParse({'name': 'Ada'}).isOk, isTrue);
      expect(schema.safeParse({}).isFail, isTrue);
      expect(schema.toJsonSchema()['properties'], contains('name'));
    });

    test('union and enum schemas snapshot caller-owned lists', () {
      final branches = <AnyAckSchema>[Ack.string(), Ack.integer()];
      final union = Ack.anyOf(branches);
      final values = [_Status.active, _Status.disabled];
      final enumSchema = Ack.enumValues(values);

      branches.clear();
      values.clear();

      expect(union.safeParse('value').isOk, isTrue);
      expect(enumSchema.safeParse('active').isOk, isTrue);
    });

    test('rejects empty unions and empty or duplicate enums', () {
      expect(() => Ack.anyOf([]), throwsArgumentError);
      expect(() => Ack.enumValues(<_Status>[]), throwsArgumentError);
      expect(
        () => Ack.enumValues([_Status.active, _Status.active]),
        throwsArgumentError,
      );
      expect(() => Ack.enumString([]), throwsArgumentError);
      expect(() => Ack.enumString(['same', 'same']), throwsArgumentError);
    });

    test('rejects invalid JSON Schema constraint arguments', () {
      expect(() => Ack.string().minLength(-1), throwsArgumentError);
      expect(() => Ack.string().maxLength(-1), throwsArgumentError);
      expect(() => Ack.string().length(-1), throwsArgumentError);
      expect(() => Ack.list(Ack.string()).minItems(-1), throwsArgumentError);
      expect(() => Ack.list(Ack.string()).maxItems(-1), throwsArgumentError);
      expect(() => Ack.double().min(double.infinity), throwsArgumentError);
      expect(() => Ack.double().max(double.nan), throwsArgumentError);
    });
  });

  group('portable schema semantics', () {
    test('preserves intersecting constraints with duplicate keywords', () {
      final schema = Ack.string().minLength(10).minLength(5);

      expect(schema.safeParse('1234567').isFail, isTrue);
      expect(schema.toJsonSchema(), {
        'type': 'string',
        'minLength': 10,
        'allOf': [
          {'minLength': 5},
        ],
      });
    });

    test('keeps intersecting constraints inside nullable branches', () {
      final schema = Ack.string().nullable().minLength(10).minLength(5);

      expect(schema.toJsonSchema(), {
        'anyOf': [
          {
            'type': 'string',
            'minLength': 10,
            'allOf': [
              {'minLength': 5},
            ],
          },
          {'type': 'null'},
        ],
      });
    });

    test('preserves constraints across codec layers', () {
      final outerConstraint = Ack.string().minLength(5).constraints.single;
      final schema = Ack.string()
          .minLength(10)
          .transform((value) => value)
          .withConstraint(outerConstraint);

      expect(schema.safeParse('1234567').isFail, isTrue);
      // The inner schema's `minLength` describes the boundary and still
      // exports. The outer one is a runtime constraint on a codec that does
      // not claim its mapping preserves keywords, so it is enforced locally
      // and reported as omitted rather than published.
      final model = schema.toSchemaModel();
      expect(model.toJsonSchema(), {
        'type': 'string',
        'minLength': 10,
        'x-transformed': true,
      });
      expect(model.warnings.map((warning) => warning.code), [
        'codec_runtime_constraint_not_exported',
      ]);
    });

    test('exports exact list lengths as item-count constraints', () {
      final schema = Ack.list(Ack.string()).exactLength(2);

      expect(schema.safeParse(['one']).isFail, isTrue);
      expect(schema.toJsonSchema(), {
        'type': 'array',
        'items': {'type': 'string'},
        'minItems': 2,
        'maxItems': 2,
      });
    });
  });

  group('callback failure handling', () {
    test('preserves nested context when a constraint throws an Exception', () {
      final schema = Ack.object({
        'name': Ack.string().constrain(const _ThrowingConstraint()),
      });

      final result = schema.safeParse({'name': 'Ada'});

      expect(result.isFail, isTrue);
      final nested = result.getError() as SchemaNestedError;
      final error = nested.errors.single;
      expect(error, isA<SchemaValidationError>());
      expect(error.path, '#/name');
      expect(error.cause, isA<FormatException>());
    });

    test('rethrows Error instances from constraints', () {
      final schema = Ack.object({
        'name': Ack.string().constrain(const _ThrowingErrorConstraint()),
      });

      expect(
        () => schema.safeParse({'name': 'Ada'}),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('behavioral equality', () {
    test('deep set comparison consumes each matching element once', () {
      final repeated = {
        <int>[1],
        <int>[1],
      };
      final distinct = {
        <int>[1],
        <int>[2],
      };

      expect(deepEquals(repeated, distinct), isFalse);
      expect(deepEquals(distinct, repeated), isFalse);
    });

    test('different codec callbacks produce unequal schemas', () {
      int length(String value) => value.length;
      int constant(String _) => 1;

      final first = Ack.string().transform(length);
      final second = Ack.string().transform(constant);

      expect(first, isNot(equals(second)));
    });

    test('different constraint messages produce unequal schemas', () {
      final constraint = Ack.string().minLength(2).constraints.single;
      final first = Ack.string().constrain(constraint, message: 'first');
      final second = Ack.string().constrain(constraint, message: 'second');

      expect(first, isNot(equals(second)));
    });
  });
}

final class _ThrowingConstraint extends Constraint<String>
    with Validator<String> {
  const _ThrowingConstraint()
    : super(
        constraintKey: 'throwing_test_constraint',
        description: 'Throws for test coverage.',
      );

  @override
  bool isValid(String value) => throw FormatException('constraint exploded');

  @override
  String buildMessage(String value) => 'unreachable';
}

final class _ThrowingErrorConstraint extends Constraint<String>
    with Validator<String> {
  const _ThrowingErrorConstraint()
    : super(
        constraintKey: 'throwing_error_test_constraint',
        description: 'Throws an Error for test coverage.',
      );

  @override
  bool isValid(String value) => throw StateError('constraint exploded');

  @override
  String buildMessage(String value) => 'unreachable';
}
