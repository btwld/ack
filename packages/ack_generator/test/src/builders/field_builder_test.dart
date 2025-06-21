import 'package:test/test.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:ack_generator/src/builders/field_builder.dart';
import 'package:ack_generator/src/models/field_info.dart';
import 'package:ack_generator/src/models/constraint_info.dart';

void main() {
  group('FieldBuilder', () {
    late FieldBuilder builder;

    setUp(() {
      builder = FieldBuilder();
    });

    group('primitive schemas', () {
      test('builds string schema', () {
        final field = _createField('name', 'String', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.string'));
      });

      test('builds integer schema', () {
        final field = _createField('age', 'int', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.integer'));
      });

      test('builds double schema', () {
        final field = _createField('price', 'double', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.double'));
      });

      test('builds number schema', () {
        final field = _createField('value', 'num', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.number'));
      });

      test('builds boolean schema', () {
        final field = _createField('active', 'bool', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.boolean'));
      });
    });

    group('nullable fields', () {
      test('adds nullable to optional fields', () {
        final field = _createField('email', 'String', isNullable: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.string.nullable()'));
      });

      test('does not add nullable to required fields', () {
        final field = _createField('name', 'String', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.string'));
      });
    });

    group('constraints', () {
      test('applies email constraint', () {
        final field = _createField(
          'email',
          'String',
          isRequired: true,
          constraints: [ConstraintInfo(name: 'email', arguments: [])],
        );
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.string.email()'));
      });

      test('applies multiple constraints in order', () {
        final field = _createField(
          'password',
          'String',
          isRequired: true,
          constraints: [
            ConstraintInfo(name: 'notEmpty', arguments: []),
            ConstraintInfo(name: 'minLength', arguments: ['8']),
            ConstraintInfo(name: 'maxLength', arguments: ['100']),
          ],
        );
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.string.notEmpty().minLength(8).maxLength(100)'));
      });

      test('applies numeric constraints', () {
        final field = _createField(
          'age',
          'int',
          isRequired: true,
          constraints: [
            ConstraintInfo(name: 'positive', arguments: []),
            ConstraintInfo(name: 'max', arguments: ['150']),
          ],
        );
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.integer.positive().max(150)'));
      });
    });

    group('list schemas', () {
      test('builds list schema with primitive items', () {
        final field = _createListField('tags', 'String');
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.list(Ack.string)'));
      });

      test('builds list schema with nested schema items', () {
        final field = _createListField('users', 'User');
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.list(UserSchema().definition)'));
      });

      test('builds nullable list schema', () {
        final field = _createListField('tags', 'String', isNullable: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.list(Ack.string).nullable()'));
      });
    });

    group('nested schemas', () {
      test('builds nested schema reference', () {
        final field = _createField('address', 'Address', isRequired: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('AddressSchema().definition'));
      });

      test('builds nullable nested schema', () {
        final field = _createField('profile', 'Profile', isNullable: true);
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('ProfileSchema().definition.nullable()'));
      });
    });

    group('map schemas', () {
      test('builds generic map schema', () {
        final field = _createMapField('metadata');
        final schema = builder.buildFieldSchema(field);
        expect(schema, equals('Ack.object({}, additionalProperties: true)'));
      });
    });
  });
}

// Helper to create a mock FieldInfo
FieldInfo _createField(
  String name,
  String typeName, {
  bool isRequired = false,
  bool isNullable = false,
  List<ConstraintInfo> constraints = const [],
}) {
  return _MockFieldInfo(
    name: name,
    typeName: typeName,
    isRequired: isRequired,
    isNullable: isNullable,
    constraints: constraints,
    isPrimitive: ['String', 'int', 'double', 'num', 'bool'].contains(typeName),
    isList: false,
    isMap: false,
  );
}

FieldInfo _createListField(
  String name,
  String itemTypeName, {
  bool isNullable = false,
}) {
  return _MockFieldInfo(
    name: name,
    typeName: 'List<$itemTypeName>',
    isRequired: !isNullable,
    isNullable: isNullable,
    constraints: [],
    isPrimitive: false,
    isList: true,
    isMap: false,
    listItemTypeName: itemTypeName,
  );
}

FieldInfo _createMapField(String name) {
  return _MockFieldInfo(
    name: name,
    typeName: 'Map<String, dynamic>',
    isRequired: true,
    isNullable: false,
    constraints: [],
    isPrimitive: false,
    isList: false,
    isMap: true,
  );
}

// Mock implementation of FieldInfo for testing
class _MockFieldInfo implements FieldInfo {
  @override
  final String name;
  
  @override
  final String jsonKey;
  
  @override
  final bool isRequired;
  
  @override
  final bool isNullable;
  
  @override
  final List<ConstraintInfo> constraints;
  
  @override
  final String? defaultValue;
  
  @override
  final bool isPrimitive;
  
  @override
  final bool isList;
  
  @override
  final bool isMap;
  
  final String typeName;
  final String? listItemTypeName;
  
  _MockFieldInfo({
    required this.name,
    required this.typeName,
    required this.isRequired,
    required this.isNullable,
    required this.constraints,
    required this.isPrimitive,
    required this.isList,
    required this.isMap,
    this.listItemTypeName,
    this.defaultValue,
  }) : jsonKey = name;
  
  @override
  bool get isNestedSchema => !isPrimitive && !isList && !isMap;
  
  @override
  DartType get type => _MockDartType(typeName, listItemTypeName);
}

// Mock DartType for testing
class _MockDartType implements DartType {
  final String typeName;
  final String? itemTypeName;
  
  _MockDartType(this.typeName, this.itemTypeName);
  
  @override
  String getDisplayString({bool withNullability = true}) => typeName;
  
  @override
  bool get isDartCoreList => typeName.startsWith('List<');
  
  @override
  bool get isDartCoreMap => typeName.startsWith('Map<');
  
  List<DartType> get typeArguments {
    if (itemTypeName != null) {
      return [_MockDartType(itemTypeName!, null)];
    }
    return [];
  }
  
  // Other DartType methods would be implemented as needed
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
