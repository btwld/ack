# standard_schema

Standard Schema contracts for Dart validators and converters.

`standard_schema` is a Dart port of the contract family described by
[standardschema.dev](https://standardschema.dev). It ports the two official
interfaces — `StandardSchemaV1` and `StandardJSONSchemaV1` — as
`StandardSchema` and `StandardJsonSchema`, plus a Dart-only combined convenience
(`StandardSchemaWithJsonSchema`) for implementers that satisfy both with one
`standard` getter.

Libraries implement these small surfaces and consumers call them without
depending on a vendor-specific schema tree. The package does not define a JSON
schema model, parser, renderer, or warning system; those stay in vendor
packages (for example, Ack's `AckSchemaModel` in `package:ack`).

## Implement a schema

```dart
import 'package:standard_schema/standard_schema.dart';

final class RequiredStringSchema implements StandardSchema<Object?, String> {
  const RequiredStringSchema();

  @override
  StandardSchemaProps<Object?, String> get standard => StandardSchemaProps(
    vendor: 'example',
    validate: (value, [options]) {
      if (value is String && value.isNotEmpty) {
        return StandardSuccess(value);
      }

      return StandardFailure([
        StandardIssue(message: 'Expected a non-empty string'),
      ]);
    },
  );
}
```

## Expose JSON Schema conversion

```dart
import 'package:standard_schema/standard_schema.dart';

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

`StandardSchemaWithJsonSchema` is a Dart-only convenience — not a separate
upstream interface. It models the structural intersection of the two official
`~standard` Props when one getter must satisfy both traits.

```dart
import 'package:standard_schema/standard_schema.dart';

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

          return StandardFailure([
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

## Utilities

Optional helpers for consuming validation issues live in a separate, opt-in
library, mirroring upstream's `@standard-schema/utils` package. Import it
explicitly:

```dart
import 'package:standard_schema/utils.dart';
```

- `getDotPath(issue)` renders raw path keys and `StandardPathSegment(key: ...)`
  entries in dot notation (for example `user.tags.1`), or returns `null` when
  the issue has no path or contains a key that is not a string or number.
- `StandardSchemaError(issues)` wraps a failure's issues as a throwable whose
  `message` is the first issue's message.

```dart
final result = await Future.value(schema.standard.validate(value));

if (result is StandardFailure) {
  // Render each issue's path in dot notation:
  for (final issue in result.issues) {
    print('${getDotPath(issue) ?? '<root>'}: ${issue.message}');
  }

  // Or throw the whole failure as a single error:
  throw StandardSchemaError(result.issues);
}
```
