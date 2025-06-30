# Phase 5: JSON Schema Generation Enhancement 📋

## Overview
This phase focuses on enhancing JSON schema generation support, particularly for object extension methods and transformation schemas which currently have minimal or missing JSON schema support.

## Current Status
- Excellent basic JSON schema coverage in `/packages/ack/test/schemas/comprehensive_json_schema_test.dart`
- Object extension methods (extend, merge, pick, omit) have NO JSON schema tests
- Transformation schemas only get minimal `x-transformed: true` property
- Advanced JSON schema features ($ref, definitions) not implemented

## Implementation Plan

### 5.1 Object Extension Methods (MISSING COMPLETELY)

#### Test: JSON schema generation for extended object schemas
```dart
test('should generate correct JSON schema for extended object schemas', () {
  final baseSchema = Ack.object({
    'id': Ack.string(),
    'name': Ack.string(),
  });
  
  final extendedSchema = baseSchema.extend({
    'email': Ack.string().email(),
    'age': Ack.int().min(0).max(120),
  });
  
  final jsonSchema = extendedSchema.toJson();
  
  expect(jsonSchema['type'], equals('object'));
  expect(jsonSchema['properties'].keys, containsAll(['id', 'name', 'email', 'age']));
  
  // Check email format
  expect(jsonSchema['properties']['email']['type'], equals('string'));
  expect(jsonSchema['properties']['email']['format'], equals('email'));
  
  // Check age constraints
  expect(jsonSchema['properties']['age']['type'], equals('integer'));
  expect(jsonSchema['properties']['age']['minimum'], equals(0));
  expect(jsonSchema['properties']['age']['maximum'], equals(120));
  
  // Required fields should include all non-optional fields
  expect(jsonSchema['required'], containsAll(['id', 'name', 'email', 'age']));
});
```

#### Test: JSON schema generation for picked object schemas
```dart
test('should generate correct JSON schema for picked object schemas', () {
  final originalSchema = Ack.object({
    'id': Ack.string(),
    'name': Ack.string(),
    'email': Ack.string().email(),
    'age': Ack.int(),
    'address': Ack.object({
      'street': Ack.string(),
      'city': Ack.string(),
      'zip': Ack.string(),
    }),
  }).requiredProperties(['id', 'name', 'email']);
  
  final pickedSchema = originalSchema.pick(['id', 'email', 'address']);
  
  final jsonSchema = pickedSchema.toJson();
  
  expect(jsonSchema['type'], equals('object'));
  expect(jsonSchema['properties'].keys, equals(['id', 'email', 'address']));
  expect(jsonSchema['properties'].keys, isNot(contains('name')));
  expect(jsonSchema['properties'].keys, isNot(contains('age')));
  
  // Required fields should be updated
  expect(jsonSchema['required'], containsAll(['id', 'email']));
  expect(jsonSchema['required'], isNot(contains('name'))); // Removed field
  
  // Nested object should be preserved
  expect(jsonSchema['properties']['address']['type'], equals('object'));
  expect(jsonSchema['properties']['address']['properties'].keys, 
    containsAll(['street', 'city', 'zip']));
});
```

#### Test: JSON schema generation for omitted object schemas
```dart
test('should generate correct JSON schema for omitted object schemas', () {
  final originalSchema = Ack.object({
    'id': Ack.string(),
    'name': Ack.string(),
    'password': Ack.string(),
    'email': Ack.string().email(),
    'secretKey': Ack.string(),
  }).requiredProperties(['id', 'name', 'password']);
  
  final omittedSchema = originalSchema.omit(['password', 'secretKey']);
  
  final jsonSchema = omittedSchema.toJson();
  
  expect(jsonSchema['type'], equals('object'));
  expect(jsonSchema['properties'].keys, equals(['id', 'name', 'email']));
  expect(jsonSchema['properties'].keys, isNot(contains('password')));
  expect(jsonSchema['properties'].keys, isNot(contains('secretKey')));
  
  // Required fields should be updated
  expect(jsonSchema['required'], containsAll(['id', 'name']));
  expect(jsonSchema['required'], isNot(contains('password'))); // Omitted required field
});
```

#### Test: JSON schema generation for merged object schemas
```dart
test('should generate correct JSON schema for merged object schemas', () {
  final schema1 = Ack.object({
    'id': Ack.string(),
    'name': Ack.string(),
    'field1': Ack.int(),
  }).requiredProperties(['id', 'name']);
  
  final schema2 = Ack.object({
    'email': Ack.string().email(),
    'field1': Ack.string(), // Conflicting type
    'field2': Ack.bool(),
  }).requiredProperties(['email']);
  
  final mergedSchema = schema1.merge(schema2);
  
  final jsonSchema = mergedSchema.toJson();
  
  expect(jsonSchema['type'], equals('object'));
  expect(jsonSchema['properties'].keys, 
    containsAll(['id', 'name', 'email', 'field1', 'field2']));
  
  // field1 should use schema2's type (string)
  expect(jsonSchema['properties']['field1']['type'], equals('string'));
  
  // Required fields should be combined
  expect(jsonSchema['required'], containsAll(['id', 'name', 'email']));
  
  // Check other properties preserved
  expect(jsonSchema['properties']['email']['format'], equals('email'));
  expect(jsonSchema['properties']['field2']['type'], equals('boolean'));
});
```

#### Test: JSON schema generation for partial object schemas
```dart
test('should generate correct JSON schema for partial object schemas', () {
  final originalSchema = Ack.object({
    'id': Ack.string(),
    'name': Ack.string(),
    'email': Ack.string().email(),
    'age': Ack.int().optional(),
  }).requiredProperties(['id', 'name', 'email']);
  
  final partialSchema = originalSchema.partial();
  
  final jsonSchema = partialSchema.toJson();
  
  expect(jsonSchema['type'], equals('object'));
  expect(jsonSchema['properties'].keys, 
    containsAll(['id', 'name', 'email', 'age']));
  
  // No required fields in partial schema
  expect(jsonSchema['required'], anyOf([isEmpty, isNull]));
  
  // All properties should maintain their types and constraints
  expect(jsonSchema['properties']['email']['format'], equals('email'));
  expect(jsonSchema['properties']['age']['type'], equals('integer'));
});
```

#### Test: Proper handling of required fields in JSON schema after operations
```dart
test('should properly handle required fields through multiple operations', () {
  final schema = Ack.object({
    'a': Ack.string(),
    'b': Ack.string(),
    'c': Ack.string().optional(),
    'd': Ack.string(),
  }).requiredProperties(['a', 'b', 'd']);
  
  // Test pick maintains correct required fields
  final picked = schema.pick(['a', 'c', 'd']);
  final pickedJson = picked.toJson();
  expect(pickedJson['required'], containsAll(['a', 'd']));
  expect(pickedJson['required'], isNot(contains('b'))); // Not in picked
  expect(pickedJson['required'], isNot(contains('c'))); // Optional
  
  // Test extend adds to required fields
  final extended = schema.extend({
    'e': Ack.string(),
    'f': Ack.string().optional(),
  });
  final extendedJson = extended.toJson();
  expect(extendedJson['required'], containsAll(['a', 'b', 'd', 'e']));
  expect(extendedJson['required'], isNot(contains('f'))); // Optional
  
  // Test partial removes all required
  final partial = extended.partial();
  final partialJson = partial.toJson();
  expect(partialJson['required'], anyOf([isEmpty, isNull]));
  
  // Test complex chain
  final complex = schema
    .pick(['a', 'b', 'd'])
    .extend({'e': Ack.string()})
    .omit(['b'])
    .partial();
  final complexJson = complex.toJson();
  expect(complexJson['properties'].keys, containsAll(['a', 'd', 'e']));
  expect(complexJson['required'], anyOf([isEmpty, isNull]));
});
```

### 5.2 Transformation Schema Enhancement

#### Test: Enhanced transformation JSON schema with metadata
```dart
test('should generate enhanced JSON schema for transformations', () {
  final schema = Ack.string().transform<int>(
    (val) => val.length,
    inputSchema: Ack.string(),
    outputSchema: Ack.int().min(0),
    description: 'Transforms string to its length',
  );
  
  final jsonSchema = schema.toJson();
  
  // Should include transformation metadata
  expect(jsonSchema['x-transformed'], isTrue);
  expect(jsonSchema['x-transform-input'], equals({
    'type': 'string',
  }));
  expect(jsonSchema['x-transform-output'], equals({
    'type': 'integer',
    'minimum': 0,
  }));
  expect(jsonSchema['x-transform-description'], 
    equals('Transforms string to its length'));
  
  // Should use output schema as base
  expect(jsonSchema['type'], equals('integer'));
  expect(jsonSchema['minimum'], equals(0));
});
```

#### Test: Transformation metadata for complex types
```dart
test('should handle complex transformation metadata', () {
  final schema = Ack.object({
    'firstName': Ack.string(),
    'lastName': Ack.string(),
  }).transform<String>(
    (obj) => '${obj['firstName']} ${obj['lastName']}',
    inputSchema: Ack.object({
      'firstName': Ack.string(),
      'lastName': Ack.string(),
    }),
    outputSchema: Ack.string().minLength(1),
    description: 'Combines first and last name',
  );
  
  final jsonSchema = schema.toJson();
  
  expect(jsonSchema['x-transformed'], isTrue);
  expect(jsonSchema['x-transform-input']['type'], equals('object'));
  expect(jsonSchema['x-transform-input']['properties'].keys, 
    containsAll(['firstName', 'lastName']));
  expect(jsonSchema['x-transform-output']['type'], equals('string'));
  expect(jsonSchema['x-transform-output']['minLength'], equals(1));
});
```

#### Test: Round-trip compatibility documentation
```dart
test('should document round-trip compatibility in JSON schema', () {
  // Reversible transformation
  final reversibleSchema = Ack.string().transform<List<String>>(
    (val) => val.split(','),
    inputSchema: Ack.string(),
    outputSchema: Ack.list(Ack.string()),
    description: 'CSV to array',
    reversible: true,
    reverseTransform: (arr) => arr.join(','),
  );
  
  final reversibleJson = reversibleSchema.toJson();
  
  expect(reversibleJson['x-transform-reversible'], isTrue);
  expect(reversibleJson['x-transform-reverse-description'], isNotNull);
  
  // Non-reversible transformation
  final nonReversibleSchema = Ack.string().transform<int>(
    (val) => val.length,
    inputSchema: Ack.string(),
    outputSchema: Ack.int(),
    description: 'String length (lossy)',
    reversible: false,
  );
  
  final nonReversibleJson = nonReversibleSchema.toJson();
  
  expect(nonReversibleJson['x-transform-reversible'], isFalse);
  expect(nonReversibleJson['x-transform-warning'], 
    contains('lossy transformation'));
});
```

#### Test: Document limitations of transformation in JSON schema
```dart
test('should document transformation limitations in JSON schema', () {
  final schema = Ack.string().transform<dynamic>(
    (val) => DateTime.parse(val),
    inputSchema: Ack.string().datetime(),
    outputSchema: Ack.any(),
    description: 'Parse ISO date string to Date object',
    limitations: [
      'Output is platform-specific Date object',
      'JSON serialization will convert back to string',
      'Timezone information may be lost',
    ],
  );
  
  final jsonSchema = schema.toJson();
  
  expect(jsonSchema['x-transform-limitations'], isA<List>());
  expect(jsonSchema['x-transform-limitations'], hasLength(3));
  expect(jsonSchema['x-transform-limitations'][0], 
    contains('platform-specific'));
  
  // Should warn about any type
  expect(jsonSchema['x-transform-output-warning'], 
    contains('any type'));
});
```

### 5.3 Advanced JSON Schema Features (Lower Priority)

#### Test: $ref generation for recursive schemas
```dart
test('should generate $ref for recursive schemas', () {
  // Define a recursive node structure
  late final ObjectSchema nodeSchema;
  
  nodeSchema = Ack.object({
    'value': Ack.string(),
    'children': Ack.list(Ack.lazy(() => nodeSchema)).optional(),
  });
  
  final jsonSchema = nodeSchema.toJson(
    options: JsonSchemaOptions(
      useReferences: true,
      definitionsPath: '#/definitions',
    ),
  );
  
  expect(jsonSchema['\$defs'], isNotNull);
  expect(jsonSchema['\$defs']['Node'], isNotNull);
  
  // Children should use $ref
  expect(jsonSchema['properties']['children']['items']['\$ref'], 
    equals('#/definitions/Node'));
});
```

#### Test: Conditional schema generation (if/then/else)
```dart
test('should generate conditional schemas', () {
  final schema = Ack.object({
    'type': Ack.string().enum(['individual', 'company']),
    'name': Ack.string(),
    'companyNumber': Ack.when(
      (obj) => obj['type'] == 'company',
      then: Ack.string(),
      else: Ack.forbidden(),
    ),
    'dateOfBirth': Ack.when(
      (obj) => obj['type'] == 'individual',
      then: Ack.string().datetime(),
      else: Ack.forbidden(),
    ),
  });
  
  final jsonSchema = schema.toJson();
  
  expect(jsonSchema['if'], isNotNull);
  expect(jsonSchema['then'], isNotNull);
  expect(jsonSchema['else'], isNotNull);
  
  // Check conditional structure
  expect(jsonSchema['if']['properties']['type']['const'], equals('company'));
  expect(jsonSchema['then']['required'], contains('companyNumber'));
  expect(jsonSchema['else']['required'], contains('dateOfBirth'));
});
```

#### Test: Pattern properties and propertyNames
```dart
test('should generate pattern properties', () {
  final schema = Ack.object({
    'id': Ack.string(),
  }).patternProperties({
    r'^data_': Ack.any(), // Properties starting with data_
    r'_id$': Ack.string(), // Properties ending with _id
  }).propertyNames(
    Ack.string().pattern(r'^[a-zA-Z_][a-zA-Z0-9_]*$'),
  );
  
  final jsonSchema = schema.toJson();
  
  expect(jsonSchema['patternProperties'], isNotNull);
  expect(jsonSchema['patternProperties']['^data_']['type'], equals('any'));
  expect(jsonSchema['patternProperties']['_id\$']['type'], equals('string'));
  
  expect(jsonSchema['propertyNames'], isNotNull);
  expect(jsonSchema['propertyNames']['pattern'], 
    equals('^[a-zA-Z_][a-zA-Z0-9_]*\$'));
});
```

#### Test: Schema definitions/components ($defs)
```dart
test('should generate schema definitions', () {
  final addressSchema = Ack.object({
    'street': Ack.string(),
    'city': Ack.string(),
    'zip': Ack.string(),
  }).withId('#address');
  
  final userSchema = Ack.object({
    'name': Ack.string(),
    'billingAddress': addressSchema,
    'shippingAddress': addressSchema,
  });
  
  final jsonSchema = userSchema.toJson(
    options: JsonSchemaOptions(
      extractDefinitions: true,
    ),
  );
  
  expect(jsonSchema['\$defs'], isNotNull);
  expect(jsonSchema['\$defs']['address'], isNotNull);
  
  // Both addresses should reference the definition
  expect(jsonSchema['properties']['billingAddress']['\$ref'], 
    equals('#/\$defs/address'));
  expect(jsonSchema['properties']['shippingAddress']['\$ref'], 
    equals('#/\$defs/address'));
});
```

#### Test: allOf composition for schema inheritance
```dart
test('should generate allOf for schema inheritance', () {
  final basePersonSchema = Ack.object({
    'name': Ack.string(),
    'age': Ack.int(),
  });
  
  final employeeSchema = Ack.allOf([
    basePersonSchema,
    Ack.object({
      'employeeId': Ack.string(),
      'department': Ack.string(),
    }),
  ]);
  
  final jsonSchema = employeeSchema.toJson();
  
  expect(jsonSchema['allOf'], isNotNull);
  expect(jsonSchema['allOf'], hasLength(2));
  
  // First should be base person
  expect(jsonSchema['allOf'][0]['properties'].keys, 
    containsAll(['name', 'age']));
  
  // Second should be employee fields
  expect(jsonSchema['allOf'][1]['properties'].keys, 
    containsAll(['employeeId', 'department']));
});
```

## Validation Checklist

- [ ] Object extension JSON schema tests implemented
- [ ] All extension methods generate correct schemas
- [ ] Required fields properly handled after operations
- [ ] Transformation metadata enhanced
- [ ] Round-trip compatibility documented
- [ ] Limitations clearly stated
- [ ] Advanced features implemented (lower priority)
- [ ] Tests added to `comprehensive_json_schema_test.dart`
- [ ] All tests passing
- [ ] No regressions

## Success Metrics

- 15+ new JSON schema tests added
- All object methods generate valid JSON schemas
- Transformation metadata is comprehensive
- Feature parity between runtime and JSON schema
- Clear documentation of limitations