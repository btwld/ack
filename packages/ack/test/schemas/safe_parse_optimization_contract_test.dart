import 'package:ack/ack.dart';
import 'package:ack/src/schemas/schema.dart' show Refinement;
import 'package:test/test.dart';

final class _ProbeConstraint extends Constraint<String> with Validator<String> {
  final bool Function(String) check;

  const _ProbeConstraint(String name, this.check)
    : super(constraintKey: name, description: name);

  @override
  bool isValid(String value) => check(value);

  @override
  String buildMessage(String value) => '$constraintKey rejected $value';
}

final class _ObservedOk extends Ok<String> {
  final List<String> calls;

  const _ObservedOk(super.value, this.calls);

  @override
  R match<R>({
    required R Function(String? value) onOk,
    required R Function(SchemaError error) onFail,
  }) {
    calls.add('match:$value');
    return super.match(onOk: onOk, onFail: onFail);
  }
}

final class _ObservedResultSchema extends AckSchema<String, String> {
  final List<String> calls;

  const _ObservedResultSchema(
    this.calls, {
    super.isNullable,
    super.isOptional,
    super.description,
    super.constraints,
    super.refinements,
  });

  @override
  _ObservedResultSchema withRuntimeConfig({
    bool? isNullable,
    bool? isOptional,
    String? description,
    List<Constraint<String>>? constraints,
    List<Refinement<String>>? refinements,
  }) => _ObservedResultSchema(
    calls,
    isNullable: isNullable ?? this.isNullable,
    isOptional: isOptional ?? this.isOptional,
    description: description ?? this.description,
    constraints: constraints ?? this.constraints,
    refinements: refinements ?? this.refinements,
  );

  @override
  SchemaType get schemaType => SchemaType.string;

  @override
  SchemaResult<String> validateRuntimeWithContext(
    Object? value,
    SchemaContext context,
  ) {
    calls.add('validate:$value');
    return _ObservedOk(value as String, calls);
  }
}

void main() {
  test('object composition preserves public result dispatch', () {
    final calls = <String>[];
    final child = _ObservedResultSchema(calls);
    final schema = Ack.object({'first': child, 'second': child});

    expect(schema.safeParse({'second': 'b', 'first': 'a'}).getOrThrow(), {
      'first': 'a',
      'second': 'b',
    });
    expect(calls, ['validate:a', 'match:a', 'validate:b', 'match:b']);
  });

  test(
    'object visits and errors retain schema order across repeated parses',
    () {
      final calls = <String>[];
      final properties = {
        for (final key in ['a/b', 'c~d'])
          key: Ack.string().refine((value) {
            calls.add('$key:$value');
            return false;
          }),
      };
      final schema = Ack.object(properties);
      properties.clear();

      for (var i = 0; i < 2; i++) {
        final error =
            schema.safeParse({'c~d': 'second', 'a/b': 'first'}).getError()
                as SchemaNestedError;
        expect(error.errors.map((e) => e.path), ['#/a~1b', '#/c~0d']);
      }
      expect(calls, ['a/b:first', 'c~d:second', 'a/b:first', 'c~d:second']);
    },
  );

  group('safeParse constraint lifecycle', () {
    test('collects failures in order and skips refinements without replay', () {
      final calls = <String>[];
      final schema =
          StringSchema(
            constraints: [
              for (final name in ['first', 'middle', 'last'])
                _ProbeConstraint(name, (_) {
                  calls.add(name);
                  return name == 'middle';
                }),
            ],
          ).refine((_) {
            calls.add('refinement');
            return true;
          });

      final result = schema.safeParse('input', debugName: 'probe');

      expect(calls, ['first', 'middle', 'last']);
      final error = result.getError() as SchemaConstraintsError;
      expect(error.constraints.map((e) => e.constraintKey), ['first', 'last']);
      expect(error.name, 'probe');
      expect(error.value, 'input');
      expect(error.schema, same(schema));
      expect(error.constraints.first.context, {
        'inputValue': 'input',
        'stringValue': 'input',
      });
    });

    test('runs each passing constraint then each refinement once', () {
      final calls = <String>[];
      final schema =
          StringSchema(
            constraints: [
              _ProbeConstraint('constraint', (_) {
                calls.add('constraint');
                return true;
              }),
            ],
          ).refine((_) {
            calls.add('refinement');
            return true;
          });

      for (final input in ['first', 'second']) {
        expect(schema.safeParse(input).getOrThrow(), input);
      }
      expect(calls, ['constraint', 'refinement', 'constraint', 'refinement']);
    });

    test('a throwing constraint takes precedence over earlier violations', () {
      final calls = <String>[];
      const thrown = FormatException('constraint exception');
      final schema = StringSchema(
        constraints: [
          _ProbeConstraint('invalid', (_) {
            calls.add('invalid');
            return false;
          }),
          _ProbeConstraint('throws', (_) {
            calls.add('throws');
            throw thrown;
          }),
          _ProbeConstraint('unreached', (_) {
            calls.add('unreached');
            return true;
          }),
        ],
      );

      final result = schema.safeParse('input');

      expect(calls, ['invalid', 'throws']);
      final error = result.getError();
      expect(error, isA<SchemaValidationError>());
      expect(error.cause, same(thrown));
      expect(error.message, contains('Constraint "throws" threw:'));
      expect(error.stackTrace, isNotNull);
    });

    test('constraint Errors propagate unchanged', () {
      final thrown = StateError('programming defect');
      final schema = StringSchema(
        constraints: [_ProbeConstraint('throws', (_) => throw thrown)],
      );

      expect(() => schema.safeParse('input'), throwsA(same(thrown)));
    });

    test('success after failure does not reuse earlier diagnostics', () {
      final schema = StringSchema(
        constraints: [_ProbeConstraint('nonempty', (v) => v.isNotEmpty)],
      );
      final first = schema.safeParse('').getError() as SchemaConstraintsError;

      expect(schema.safeParse('valid').getOrThrow(), 'valid');
      final second = schema.safeParse('').getError() as SchemaConstraintsError;

      expect(first.constraints.single.message, 'nonempty rejected ');
      expect(
        second.constraints.single.message,
        first.constraints.single.message,
      );
      expect(second.constraints, isNot(same(first.constraints)));
    });
  });
}
