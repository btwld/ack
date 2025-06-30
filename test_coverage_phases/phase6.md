# Phase 6: Code Generation Enhancement 🏗️ (CRITICAL)

## Overview
This phase focuses on fixing critical bugs in the code generator and achieving feature parity with the core library. The generator currently has broken support for basic Dart types.

## Current Status
- Comprehensive test infrastructure exists in `/packages/ack_generator/`
- Golden tests, unit tests, and integration tests are well-structured
- CRITICAL ISSUES:
  - Enum fields cause "can only be applied to classes" error
  - Generic types generate broken `TSchema` instead of proper type
  - Map types generate generic object schema instead of map schema
  - Set types not supported at all

## Implementation Plan

### 6.1 Critical Bug Fixes (IMMEDIATE PRIORITY)

#### Fix: Generic type handling
```dart
// File: packages/ack_generator/lib/src/analyzers/field_analyzer.dart

// Current broken behavior:
// class Response<T> {
//   final T data; // Generates: TSchema instead of proper schema
// }

// Fix implementation:
class FieldAnalyzer {
  FieldInfo analyzeField(FieldElement field) {
    // ... existing code ...
    
    // Handle generic type parameters
    if (type is TypeParameterType) {
      return FieldInfo(
        name: field.name,
        type: type,
        isGeneric: true,
        genericBound: type.bound,
        // Add metadata for generic handling
        metadata: {
          'isTypeParameter': true,
          'parameterName': type.name,
          'bound': type.bound?.toString(),
        },
      );
    }
    
    // Handle parameterized types (List<T>, Map<K,V>, etc.)
    if (type is ParameterizedType && type.typeArguments.any((t) => t is TypeParameterType)) {
      return FieldInfo(
        name: field.name,
        type: type,
        isGenericContainer: true,
        typeArguments: type.typeArguments,
        metadata: {
          'containerType': type.element?.name,
          'typeArguments': type.typeArguments.map((t) => t.toString()).toList(),
        },
      );
    }
  }
}

// Test for generic fix:
test('should handle generic type parameters correctly', () {
  final code = '''
@Schema()
class Container<T> {
  final T value;
  final List<T> items;
  
  Container({required this.value, required this.items});
}

@Schema()
class StringContainer extends Container<String> {
  StringContainer({required String value, required List<String> items}) 
    : super(value: value, items: items);
}
''';
  
  final generated = await generateCode(code);
  
  // Should generate proper generic handling
  expect(generated, contains('AckSchema genericSchema<T>()'));
  expect(generated, contains('value: schemaForType<T>()'));
  expect(generated, contains('items: Ack.list(schemaForType<T>())'));
  
  // Concrete type should work
  expect(generated, contains('StringContainerSchema'));
  expect(generated, contains('value: Ack.string()'));
  expect(generated, contains('items: Ack.list(Ack.string())'));
});
```

#### Fix: Error messages for better debugging
```dart
// File: packages/ack_generator/lib/src/generator.dart

class AckGenerator extends GeneratorForAnnotation<Schema> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    try {
      if (element is! ClassElement) {
        throw InvalidGenerationSourceError(
          'The @Schema() annotation can only be applied to classes. '
          'Found: ${element.kind.name} "${element.name}"',
          element: element,
        );
      }
      
      // ... existing generation code ...
    } catch (e, stackTrace) {
      // Enhanced error reporting
      if (e is InvalidGenerationSourceError) {
        rethrow;
      }
      
      throw InvalidGenerationSourceError(
        'Failed to generate schema for ${element.name}: ${e.toString()}\n'
        'This might be due to:\n'
        '  - Unsupported type in a field\n'
        '  - Missing import statements\n'
        '  - Circular dependencies\n'
        'Stack trace:\n$stackTrace',
        element: element,
      );
    }
  }
}
```

### 6.2 Enum Support Implementation (CRITICAL PRIORITY)

#### Implementation: Enum field detection and generation
```dart
// File: packages/ack_generator/lib/src/analyzers/field_analyzer.dart

extension on DartType {
  bool get isEnum {
    final element = this.element;
    return element is ClassElement && element.isEnum;
  }
  
  List<String> get enumValues {
    if (!isEnum) return [];
    final element = this.element as ClassElement;
    return element.fields
        .where((f) => f.isEnumConstant)
        .map((f) => f.name)
        .toList();
  }
}

// File: packages/ack_generator/lib/src/builders/field_builder.dart

class FieldBuilder {
  String buildFieldSchema(FieldInfo field) {
    final type = field.type;
    
    if (type.isEnum) {
      final values = type.enumValues;
      final enumName = type.element!.name;
      
      // Generate enum schema
      return '''
Ack.string().enum([
  ${values.map((v) => '$enumName.$v.name').join(', ')}
])''';
    }
    
    // ... existing type handling ...
  }
}

// Test cases:
test('should generate schema for string enums', () {
  final code = '''
enum Status { active, inactive, pending }

@Schema()
class User {
  final String name;
  final Status status;
  
  User({required this.name, required this.status});
}
''';
  
  final generated = await generateCode(code);
  
  expect(generated, contains("status: Ack.string().enum(['active', 'inactive', 'pending'])"));
});

test('should generate schema for int enums', () {
  final code = '''
enum Priority {
  low(1),
  medium(2),
  high(3);
  
  final int value;
  const Priority(this.value);
}

@Schema()
class Task {
  final String title;
  final Priority priority;
  
  Task({required this.title, required this.priority});
}
''';
  
  final generated = await generateCode(code);
  
  expect(generated, contains("priority: Ack.int().enum([1, 2, 3])"));
});

test('should handle nullable enum fields', () {
  final code = '''
enum Category { personal, work, other }

@Schema()
class Note {
  final String content;
  final Category? category;
  
  Note({required this.content, this.category});
}
''';
  
  final generated = await generateCode(code);
  
  expect(generated, contains("category: Ack.string().enum(['personal', 'work', 'other']).nullable()"));
});
```

### 6.3 Missing Type Support (HIGH PRIORITY)

#### Add: Map schema generation support
```dart
// File: packages/ack_generator/lib/src/builders/field_builder.dart

String _buildMapSchema(ParameterizedType type) {
  if (type.typeArguments.length != 2) {
    throw InvalidGenerationSourceError(
      'Map must have exactly 2 type arguments',
    );
  }
  
  final keyType = type.typeArguments[0];
  final valueType = type.typeArguments[1];
  
  // Maps in Dart must have String keys for JSON
  if (!keyType.isDartCoreString) {
    throw InvalidGenerationSourceError(
      'Map keys must be String for JSON serialization. Found: $keyType',
    );
  }
  
  final valueSchema = _buildSchemaForType(valueType);
  
  return 'Ack.map($valueSchema)';
}

// Test cases:
test('should generate schema for Map types', () {
  final code = '''
@Schema()
class Config {
  final Map<String, dynamic> settings;
  final Map<String, int> counts;
  final Map<String, List<String>> groupedData;
  
  Config({
    required this.settings,
    required this.counts,
    required this.groupedData,
  });
}
''';
  
  final generated = await generateCode(code);
  
  expect(generated, contains('settings: Ack.map(Ack.any())'));
  expect(generated, contains('counts: Ack.map(Ack.int())'));
  expect(generated, contains('groupedData: Ack.map(Ack.list(Ack.string()))'));
});
```

#### Add: Set schema generation support
```dart
// File: packages/ack_generator/lib/src/builders/field_builder.dart

String _buildSetSchema(ParameterizedType type) {
  if (type.typeArguments.isEmpty) {
    return 'Ack.set(Ack.any())';
  }
  
  final elementType = type.typeArguments[0];
  final elementSchema = _buildSchemaForType(elementType);
  
  // Sets are serialized as arrays with unique constraint
  return 'Ack.list($elementSchema).unique()';
}

// Test cases:
test('should generate schema for Set types', () {
  final code = '''
@Schema()
class UniqueData {
  final Set<String> tags;
  final Set<int> ids;
  final Set<dynamic> mixed;
  
  UniqueData({
    required this.tags,
    required this.ids,
    required this.mixed,
  });
}
''';
  
  final generated = await generateCode(code);
  
  expect(generated, contains('tags: Ack.list(Ack.string()).unique()'));
  expect(generated, contains('ids: Ack.list(Ack.int()).unique()'));
  expect(generated, contains('mixed: Ack.list(Ack.any()).unique()'));
});
```

#### Test: Complex collection types
```dart
test('should handle complex nested collection types', () {
  final code = '''
@Schema()
class ComplexModel {
  final List<List<String>> matrix;
  final Map<String, List<int>> grouped;
  final Set<String> unique;
  final Map<String, Map<String, dynamic>> nested;
  final List<Map<String, Set<int>>> superComplex;
  
  ComplexModel({
    required this.matrix,
    required this.grouped,
    required this.unique,
    required this.nested,
    required this.superComplex,
  });
}
''';
  
  final generated = await generateCode(code);
  
  expect(generated, contains('matrix: Ack.list(Ack.list(Ack.string()))'));
  expect(generated, contains('grouped: Ack.map(Ack.list(Ack.int()))'));
  expect(generated, contains('unique: Ack.list(Ack.string()).unique()'));
  expect(generated, contains('nested: Ack.map(Ack.map(Ack.any()))'));
  expect(generated, contains('superComplex: Ack.list(Ack.map(Ack.list(Ack.int()).unique()))'));
});
```

### 6.4 Advanced Features

#### Test: Generation for sealed classes
```dart
test('should generate discriminated union for sealed classes', () {
  final code = '''
sealed class Result {}

class Success extends Result {
  final String data;
  Success(this.data);
}

class Error extends Result {
  final String message;
  final int code;
  Error(this.message, this.code);
}

@Schema()
class Response {
  final Result result;
  Response(this.result);
}
''';
  
  final generated = await generateCode(code);
  
  expect(generated, contains('Ack.discriminated'));
  expect(generated, contains("discriminatorKey: 'type'"));
  expect(generated, contains("'Success': Ack.object"));
  expect(generated, contains("'Error': Ack.object"));
});
```

#### Add: Discriminated union generation support
```dart
// Implementation for discriminated unions
class DiscriminatedUnionBuilder {
  String buildDiscriminatedUnion(ClassElement sealed) {
    final subclasses = _findDirectSubclasses(sealed);
    
    if (subclasses.isEmpty) {
      throw InvalidGenerationSourceError(
        'Sealed class ${sealed.name} has no subclasses',
      );
    }
    
    final discriminatorKey = 'type'; // Could be configurable
    final schemas = <String, String>{};
    
    for (final subclass in subclasses) {
      final schema = ObjectSchemaBuilder().build(subclass);
      schemas[subclass.name] = schema;
    }
    
    return '''
Ack.discriminated(
  discriminatorKey: '$discriminatorKey',
  schemas: {
    ${schemas.entries.map((e) => "'${e.key}': ${e.value}").join(',\n    ')}
  },
)''';
  }
}
```

#### Test: Generation with custom validators
```dart
test('should support custom validators in generated code', () {
  final code = '''
@Schema()
class User {
  @SchemaField(
    validator: r'(value) => value.length >= 3 ? null : "Too short"',
  )
  final String username;
  
  @SchemaField(
    pattern: r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
    message: 'Invalid email format',
  )
  final String email;
  
  User({required this.username, required this.email});
}
''';
  
  final generated = await generateCode(code);
  
  expect(generated, contains('.refine((value) => value.length >= 3 ? null : "Too short")'));
  expect(generated, contains('.pattern(RegExp(r\'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\$\'))'));
});
```

#### Support: Complex generic scenarios
```dart
test('should handle complex generic scenarios', () {
  final code = '''
@Schema()
class Paginated<T> {
  final List<T> items;
  final int total;
  final int page;
  
  Paginated({
    required this.items,
    required this.total,
    required this.page,
  });
}

@Schema()
class UserList extends Paginated<User> {
  UserList({
    required List<User> items,
    required int total,
    required int page,
  }) : super(items: items, total: total, page: page);
}

@Schema()
class User {
  final String name;
  User({required this.name});
}
''';
  
  final generated = await generateCode(code);
  
  // Should generate reusable generic schema
  expect(generated, contains('AckSchema paginatedSchema<T>(AckSchema itemSchema)'));
  expect(generated, contains('items: Ack.list(itemSchema)'));
  
  // Should use generic schema for concrete type
  expect(generated, contains('UserListSchema'));
  expect(generated, contains('paginatedSchema<User>(UserSchema())'));
});
```

### 6.5 Error Recovery and UX

#### Test: Generator with malformed annotations
```dart
test('should provide helpful errors for malformed annotations', () {
  final code = '''
@Schema(unknownParam: true)
class Model {
  final String field;
  Model({required this.field});
}
''';
  
  expect(
    () => generateCode(code),
    throwsA(isA<InvalidGenerationSourceError>()
      .having(
        (e) => e.message,
        'message',
        contains('Unknown parameter "unknownParam"'),
      )),
  );
});
```

#### Test: Generator with invalid constraint combinations
```dart
test('should detect invalid constraint combinations', () {
  final code = '''
@Schema()
class Model {
  @SchemaField(
    min: 10,
    max: 5, // Invalid: min > max
  )
  final int value;
  
  Model({required this.value});
}
''';
  
  expect(
    () => generateCode(code),
    throwsA(isA<InvalidGenerationSourceError>()
      .having(
        (e) => e.message,
        'message',
        contains('min (10) cannot be greater than max (5)'),
      )),
  );
});
```

#### Provide: Helpful error messages for common mistakes
```dart
// Enhanced error messages
class ErrorMessages {
  static String unsupportedType(DartType type) => '''
Unsupported type: $type

Ack generator currently supports:
- Basic types: String, int, double, bool, DateTime
- Collections: List<T>, Set<T>, Map<String, T>
- Enums
- Classes with @Schema annotation
- Nullable types (T?)

If you need support for this type, consider:
1. Creating a custom transformer
2. Using a supported type instead
3. Opening an issue at: https://github.com/acme/ack/issues
''';
  
  static String circularDependency(List<String> cycle) => '''
Circular dependency detected: ${cycle.join(' -> ')}

To fix this:
1. Use Ack.lazy(() => Schema()) for one of the references
2. Restructure your models to avoid circular dependencies
3. Consider using a discriminated union pattern
''';
}
```

#### Add: Better diagnostics for unsupported types
```dart
test('should provide clear diagnostics for unsupported types', () {
  final code = '''
import 'dart:typed_data';

@Schema()
class Model {
  final Uint8List bytes; // Unsupported type
  final Duration time; // Unsupported type
  
  Model({required this.bytes, required this.time});
}
''';
  
  final errors = await collectGeneratorErrors(code);
  
  expect(errors, hasLength(2));
  expect(errors[0].message, contains('Uint8List'));
  expect(errors[0].message, contains('consider using List<int>'));
  expect(errors[1].message, contains('Duration'));
  expect(errors[1].message, contains('consider using int (milliseconds)'));
});
```

## Validation Checklist

- [ ] Generic type handling fixed
- [ ] Error messages improved
- [ ] Enum support fully implemented
- [ ] Map type generation working
- [ ] Set type generation working
- [ ] Complex collection types supported
- [ ] Sealed class support added
- [ ] Custom validators working
- [ ] Error recovery improved
- [ ] All golden tests updated
- [ ] Integration tests passing
- [ ] Real models can be generated

## Success Metrics

- Zero errors for common Dart patterns
- All basic Dart types supported
- Generated code compiles and runs
- Feature parity with core library
- Clear error messages for unsupported scenarios
- Examples work out of the box