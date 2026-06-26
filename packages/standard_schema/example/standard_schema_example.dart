import 'dart:async';

import 'package:standard_schema/standard_schema.dart';
import 'package:standard_schema/utils.dart';

final class RequiredStringSchema implements StandardSchemaV1<Object?, String> {
  const RequiredStringSchema();

  @override
  StandardSchemaPropsV1<Object?, String> get standard => StandardSchemaPropsV1(
    vendor: 'example',
    validate: (value, [options]) {
      if (value is String && value.isNotEmpty) {
        return StandardSuccess(value);
      }

      return StandardFailure([
        StandardIssue(
          message: 'Expected a non-empty string',
          path: ['user', 'name'],
        ),
      ]);
    },
  );
}

final class StringToIntSchema implements StandardSchemaV1<Object?, int> {
  const StringToIntSchema();

  @override
  StandardSchemaPropsV1<Object?, int> get standard => StandardSchemaPropsV1(
    vendor: 'example',
    validate: (value, [options]) {
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return StandardSuccess(parsed);
        }
      }

      return StandardFailure([
        StandardIssue(message: 'Expected an integer string', path: ['age']),
      ]);
    },
  );
}

final class RequiredStringWithJsonSchema
    implements StandardSchemaWithJsonSchemaV1<Object?, String> {
  const RequiredStringWithJsonSchema();

  @override
  StandardSchemaWithJsonSchemaPropsV1<Object?, String> get standard =>
      StandardSchemaWithJsonSchemaPropsV1(
        vendor: 'example',
        validate: const RequiredStringSchema().standard.validate,
        jsonSchema: StandardJsonSchemaConverter(
          input: (options) => {
            r'$schema': options.target,
            'type': 'string',
            'minLength': 1,
          },
          output: (options) => {'type': 'string', 'minLength': 1},
        ),
      );
}

Future<void> main() async {
  await printResult(const RequiredStringSchema().standard.validate('Ada'));
  await printResult(const StringToIntSchema().standard.validate('42'));

  final schema = const RequiredStringWithJsonSchema();
  final inputJsonSchema = schema.standard.jsonSchema.input(
    const StandardJsonSchemaOptions(target: JsonSchemaTarget.draft07),
  );
  print(inputJsonSchema);

  await printResult(schema.standard.validate(''));
}

Future<void> printResult<T>(FutureOr<StandardResult<T>> result) async {
  final resolved = await Future.value(result);

  switch (resolved) {
    case StandardSuccess(value: final value):
      print('Valid: $value');
    case StandardFailure(issues: final issues):
      for (final issue in issues) {
        final path = getDotPath(issue) ?? '<root>';
        print('$path: ${issue.message}');
      }
  }
}
