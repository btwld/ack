import 'dart:async';

import 'package:schema_model/schema_model.dart';
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
      return const StandardFailure<int>([
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
            : const StandardFailure([StandardIssue(message: 'Not ok')]),
        jsonSchema: StandardJsonSchemaConverter(
          input: (options) => {'type': 'string'},
          output: (options) => {'type': 'integer'},
        ),
      );
}

void main() {
  group('StandardSchema', () {
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
  });
}
