import 'dart:async';

import 'package:standard_schema/standard_schema.dart';
import 'package:test/test.dart';

Future<StandardResult<T>> _resolve<T>(
  FutureOr<StandardResult<T>> result,
) async {
  return result;
}

final class _ValidationOnlySchema implements StandardSchema<String, int> {
  const _ValidationOnlySchema({this.async = false});

  final bool async;

  @override
  StandardSchemaProps<String, int> get standard => StandardSchemaProps(
    vendor: 'fake',
    validate: (value, [options]) {
      if (value == 'ok') {
        final result = const StandardSuccess(1);
        return async ? Future<StandardResult<int>>.value(result) : result;
      }
      return StandardFailure<int>([
        StandardIssue(message: 'Not ok', path: ['items', 1]),
      ]);
    },
  );
}

final class _JsonSchemaOnlySchema implements StandardJsonSchema<String, int> {
  const _JsonSchemaOnlySchema();

  @override
  StandardJsonSchemaProps<String, int> get standard => StandardJsonSchemaProps(
    vendor: 'fake-json',
    jsonSchema: StandardJsonSchemaConverter(
      input: (options) => {
        r'$schema': options.target,
        'type': 'string',
        if (options.libraryOptions case final options?) 'x-options': options,
      },
      output: (options) => {'type': 'integer'},
    ),
  );
}

final class _CombinedSchema
    implements StandardSchemaWithJsonSchema<String, int> {
  const _CombinedSchema();

  @override
  StandardSchemaWithJsonSchemaProps<String, int> get standard =>
      StandardSchemaWithJsonSchemaProps(
        vendor: 'fake-combined',
        validate: (value, [options]) => value == 'ok'
            ? const StandardSuccess(1)
            : StandardFailure([StandardIssue(message: 'Not ok')]),
        jsonSchema: StandardJsonSchemaConverter(
          input: (options) => {'type': 'string'},
          output: (options) => {'type': 'integer'},
        ),
      );
}

void main() {
  group('StandardSchema', () {
    test(
      'does not accept constructor overrides for the fixed spec version',
      () {
        StandardResult<int> validate(
          Object? value, [
          StandardValidateOptions? _,
        ]) {
          return const StandardSuccess(1);
        }

        Map<String, Object?> convert(StandardJsonSchemaOptions _) => {};

        expect(
          () => Function.apply(StandardTypedProps<Object?, int>.new, const [], {
            #vendor: 'fake',
            #version: 2,
          }),
          throwsNoSuchMethodError,
        );
        expect(
          () => Function.apply(
            StandardSchemaProps<Object?, int>.new,
            const [],
            {#vendor: 'fake', #validate: validate, #version: 2},
          ),
          throwsNoSuchMethodError,
        );
        expect(
          () => Function.apply(
            StandardJsonSchemaProps<Object?, int>.new,
            const [],
            {
              #vendor: 'fake',
              #jsonSchema: StandardJsonSchemaConverter(
                input: convert,
                output: convert,
              ),
              #version: 2,
            },
          ),
          throwsNoSuchMethodError,
        );
        expect(
          () => Function.apply(
            StandardSchemaWithJsonSchemaProps<Object?, int>.new,
            const [],
            {
              #vendor: 'fake',
              #validate: validate,
              #jsonSchema: StandardJsonSchemaConverter(
                input: convert,
                output: convert,
              ),
              #version: 2,
            },
          ),
          throwsNoSuchMethodError,
        );
      },
    );

    test('carries vendor, version, and success or failure results', () async {
      const schema = _ValidationOnlySchema();

      expect(schema.standard.vendor, 'fake');
      expect(schema.standard.version, 1);
      expect(schema, isNot(isA<StandardJsonSchema<String, int>>()));

      final success = await _resolve(schema.standard.validate('ok'));
      final failure = await _resolve(schema.standard.validate('bad'));

      expect(success, isA<StandardSuccess<int>>());
      expect((success as StandardSuccess<int>).value, 1);
      expect(failure, isA<StandardFailure<int>>());
      expect((failure as StandardFailure<int>).issues.single.message, 'Not ok');
      expect(failure.issues.single.path, ['items', 1]);
    });

    test('allows async validation and validate options', () async {
      const schema = _ValidationOnlySchema(async: true);

      final result = await _resolve(
        schema.standard.validate(
          'ok',
          const StandardValidateOptions(libraryOptions: {'mode': 'strict'}),
        ),
      );

      expect(result, isA<StandardSuccess<int>>());
    });

    test('models JSON Schema converters as a separate trait', () {
      const schema = _JsonSchemaOnlySchema();

      expect(schema.standard.vendor, 'fake-json');
      expect(schema.standard.version, 1);
      expect(schema, isNot(isA<StandardSchema<String, int>>()));
      expect(
        schema.standard.jsonSchema.input(
          const StandardJsonSchemaOptions(
            target: JsonSchemaTarget.draft07,
            libraryOptions: {'dialect': 'draft7'},
          ),
        ),
        {
          r'$schema': JsonSchemaTarget.draft07,
          'type': 'string',
          'x-options': {'dialect': 'draft7'},
        },
      );
      expect(
        schema.standard.jsonSchema.output(
          const StandardJsonSchemaOptions(target: JsonSchemaTarget.draft07),
        ),
        {'type': 'integer'},
      );
    });

    test(
      'allows a schema to implement validation and JSON Schema together',
      () {
        const schema = _CombinedSchema();

        expect(schema, isA<StandardSchema<String, int>>());
        expect(schema, isA<StandardJsonSchema<String, int>>());
        expect(schema.standard.vendor, 'fake-combined');
        expect(schema.standard.validate('ok'), isA<StandardSuccess<int>>());
        expect(
          schema.standard.jsonSchema.input(
            const StandardJsonSchemaOptions(target: JsonSchemaTarget.draft07),
          ),
          {'type': 'string'},
        );
      },
    );

    test('stores validation failure issues as an unmodifiable snapshot', () {
      final issues = [StandardIssue(message: 'first')];
      final failure = StandardFailure<int>(issues);

      issues.add(StandardIssue(message: 'second'));

      expect(failure.issues, hasLength(1));
      expect(failure.issues.single.message, 'first');
      expect(
        () => failure.issues.add(StandardIssue(message: 'third')),
        throwsUnsupportedError,
      );
    });

    test('stores issue paths as unmodifiable snapshots', () {
      final path = <Object>['user'];
      final issue = StandardIssue(message: 'Required', path: path);

      path.add('email');

      expect(issue.path, ['user']);
      expect(() => issue.path.add('name'), throwsUnsupportedError);
    });

    test('supports README-style async validation consumption', () async {
      final schema = StandardSchemaProps<Object?, int>(
        vendor: 'fake',
        validate: (value, [options]) async {
          return StandardFailure<int>([
            StandardIssue(message: 'Not ok', path: ['value']),
          ]);
        },
      );

      final result = await Future.value(schema.validate('bad'));

      expect(result, isA<StandardFailure<int>>());
      expect((result as StandardFailure<int>).issues.single.message, 'Not ok');
    });
  });
}
