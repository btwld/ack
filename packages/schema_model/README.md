# schema_model

Standard Schema contracts for Dart validators and converters.

`schema_model` is a Dart port of the contract family described by
[standardschema.dev](https://standardschema.dev). It defines small
`StandardTyped`, `StandardSchema`, and `StandardJsonSchema` surfaces that
libraries can implement and consumers can call without depending on a
vendor-specific schema tree.

The package intentionally does not define a schema model, parser, renderer, or
warning system. Libraries keep those implementation details in their own
packages and expose this contract at their boundary.

## Implement a schema

```dart
import 'package:schema_model/schema_model.dart';

final class RequiredStringSchema implements StandardSchema<Object?, String> {
  const RequiredStringSchema();

  @override
  StandardSchemaProps<Object?, String> get standard => StandardSchemaProps(
    vendor: 'example',
    validate: (value, [options]) {
      if (value is String && value.isNotEmpty) {
        return StandardSuccess(value);
      }

      return const StandardFailure([
        StandardIssue(message: 'Expected a non-empty string'),
      ]);
    },
  );
}
```

## Expose JSON Schema conversion

```dart
import 'package:schema_model/schema_model.dart';

final class RequiredStringJsonSchema
    implements StandardJsonSchema<Object?, String> {
  const RequiredStringJsonSchema();

  @override
  StandardJsonSchemaProps<Object?, String> get standard =>
      StandardJsonSchemaProps(
        vendor: 'example',
        jsonSchema: StandardJsonSchemaConverter(
          input: (options) {
            if (options.target != JsonSchemaTarget.draft07) {
              throw UnsupportedError('Only Draft-7 is supported.');
            }

            return {'type': 'string'};
          },
          output: (options) => {'type': 'string'},
        ),
      );
}
```

Converters return plain JSON Schema maps (`Map<String, Object?>`). They may
throw when a schema cannot be represented for the requested target.

## Implement both traits

```dart
import 'package:schema_model/schema_model.dart';

final class RequiredStringSchemaWithJson
    implements StandardSchemaWithJsonSchema<Object?, String> {
  const RequiredStringSchemaWithJson();

  @override
  StandardSchemaWithJsonSchemaProps<Object?, String> get standard =>
      StandardSchemaWithJsonSchemaProps(
        vendor: 'example',
        validate: (value, [options]) {
          if (value is String && value.isNotEmpty) {
            return StandardSuccess(value);
          }

          return const StandardFailure([
            StandardIssue(message: 'Expected a non-empty string'),
          ]);
        },
        jsonSchema: StandardJsonSchemaConverter(
          input: (options) {
            if (options.target != JsonSchemaTarget.draft07) {
              throw UnsupportedError('Only Draft-7 is supported.');
            }

            return {'type': 'string'};
          },
          output: (options) => {'type': 'string'},
        ),
      );
}
```
