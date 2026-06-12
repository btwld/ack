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

## Compatibility checks

In Dart, compatibility is nominal: a value is a Standard Schema when it
implements the shared interface from this package.

```dart
if (schema is StandardSchema<Object?, Object?>) {
  final result = await Future.value(schema.standard.validate(value));
}

if (schema is StandardJsonSchema<Object?, Object?>) {
  final json = schema.standard.jsonSchema.input(
    const StandardJsonSchemaOptions(target: JsonSchemaTarget.draft07),
  );
}
```

The JSON Schema maps returned by converters are owned by the implementing
library. Consumers should treat them as JSON Schema for the requested target,
not as canonical byte-for-byte output shared by every vendor.

## Dart mapping notes

This package intentionally maps the upstream TypeScript contract into Dart
idioms:

- `~standard` is exposed as the normal Dart getter `standard`.
- TypeScript's phantom `types` field is omitted because Dart generics carry
  input and output types.
- A missing issue path is represented as an empty list, which is also the root
  path.
- Path keys are permissive `Object` values. Utilities such as `getDotPath`
  render only string and number keys and return `null` for other keys.

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
The concrete JSON Schema output is owned by the implementing library; this
package only defines the converter contract.

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
