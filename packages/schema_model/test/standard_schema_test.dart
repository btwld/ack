import 'dart:async';

import 'package:schema_model/schema_model.dart';
import 'package:test/test.dart';

Future<StandardResult<T>> _resolve<T>(
  FutureOr<StandardResult<T>> result,
) async {
  return result;
}

final class _FakeSchema implements StandardSchema<String, int> {
  const _FakeSchema({this.async = false, this.includeJsonSchema = true});

  final bool async;
  final bool includeJsonSchema;

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
    jsonSchema: includeJsonSchema
        ? StandardJsonSchemaConverter(
            input: (options) => {
              r'$schema': options.target,
              'type': 'string',
              if (options.libraryOptions case final options?)
                'x-options': options,
            },
            output: (options) => {'type': 'integer'},
          )
        : null,
  );
}

void main() {
  group('StandardSchema', () {
    test('carries vendor, version, and success or failure results', () async {
      const schema = _FakeSchema();

      expect(schema.standard.vendor, 'fake');
      expect(schema.standard.version, 1);

      final success = await _resolve(schema.standard.validate('ok'));
      final failure = await _resolve(schema.standard.validate('bad'));

      expect(success, isA<StandardSuccess<int>>());
      expect((success as StandardSuccess<int>).value, 1);
      expect(failure, isA<StandardFailure<int>>());
      expect((failure as StandardFailure<int>).issues.single.message, 'Not ok');
      expect(failure.issues.single.path, ['items', 1]);
    });

    test('allows async validation and validate options', () async {
      const schema = _FakeSchema(async: true);

      final result = await _resolve(
        schema.standard.validate(
          'ok',
          const StandardValidateOptions(libraryOptions: {'mode': 'strict'}),
        ),
      );

      expect(result, isA<StandardSuccess<int>>());
    });

    test('models optional JSON Schema converters', () {
      const withConverter = _FakeSchema();
      const withoutConverter = _FakeSchema(includeJsonSchema: false);

      expect(withoutConverter.standard.jsonSchema, isNull);
      expect(
        withConverter.standard.jsonSchema!.input(
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
        withConverter.standard.jsonSchema!.output(
          const StandardJsonSchemaOptions(target: JsonSchemaTarget.draft07),
        ),
        {'type': 'integer'},
      );
    });
  });
}
