# schema_model

Vendor-neutral schema model and standard schema contracts for Dart.

`schema_model` has two layers:

- `SchemaModel`: a structured description tree that can render Draft-7 JSON
  Schema and import JSON Schema with `SchemaModel.fromJsonSchema`.
- `StandardSchema`: a small validation contract for libraries that want to
  expose `validate(value)` results and optional JSON Schema converters.

```dart
import 'package:schema_model/schema_model.dart';

final model = SchemaModel.fromJsonSchema({
  'type': 'object',
  'properties': {
    'name': {'type': 'string', 'minLength': 2},
  },
  'required': ['name'],
});

final jsonSchema = model.toJsonSchema();
```

Validator packages can implement `StandardSchema<Input, Output>` and expose
their contract through `standard`.
