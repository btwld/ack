# Migration Guide

## What's Changing
ACK now generates pure JSON Schema draft-7, removing OpenAPI mixins.

## Impact on Users

### No Code Changes Required
Your ACK schema definitions remain the same:
```dart
// This doesn't change
final schema = Ack.object({
  'email': Ack.string.email().nullable(),
});
```

### Output Format Changes
The generated JSON Schema format changes:
- Nullable fields: `["string", "null"]` instead of `"nullable": true`
- Includes `"$schema"` declaration
- Discriminated unions use `if/then/else`

## For Different Use Cases

### 1. JSON Schema Validators ✅
Works out of the box with AJV, JSON Schema Validator, etc.

### 2. OpenAI 
May need to strip unsupported format keywords:
```dart
// Future feature (not in this PR):
final schema = mySchema.toJsonSchema(openAiCompatMode: true);
```

### 3. Gemini
- Use Gemini 2.5+ (supports JSON Schema)
- Or convert to OpenAPI format externally

### 4. Claude
Wrap schema in tool definition:
```dart
final schema = mySchema.toJsonSchema();
final tool = {
  "name": "extract",
  "input_schema": schema
};
```

## Breaking Changes
1. Generated schemas have different structure
2. OpenAPI properties (`nullable`, `discriminator`) removed
3. Type arrays for nullable values

## Need Old Format?
```dart
// Disable schema version
final converter = JsonSchemaConverter(
  schema: mySchema,
  includeSchemaVersion: false,
);
```

## Timeline
- Update your schema validators to support draft-7
- Test with the new format
- Report any issues
