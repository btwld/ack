import 'package:ack_generator/src/builders/schema_builder.dart';
import 'package:ack_generator/src/models/constraint_info.dart';
import 'package:ack_generator/src/models/field_info.dart';
import 'package:ack_generator/src/models/model_info.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaBuilder', () {
    late SchemaBuilder builder;

    setUp(() {
      builder = SchemaBuilder();
    });

    test('builds complete schema class', () {
      final model = ModelInfo(
        className: 'User',
        schemaClassName: 'UserSchema',
        description: 'User model for testing',
        fields: [
          _createField('id', 'String', isRequired: true),
          _createField('name', 'String', isRequired: true),
          _createField('email', 'String', isNullable: true),
        ],
        requiredFields: ['id', 'name'],
      );

      final result = builder.build(model);

      // Check class declaration
      expect(result, contains('class UserSchema extends SchemaModel'));

      // Check documentation
      expect(result, contains('/// Generated schema for User'));
      expect(result, contains('/// User model for testing'));

      // Check constructors
      expect(result, contains('const UserSchema()'));
      expect(result,
          contains('const UserSchema._valid(Map<String, Object?> data)'));

      // Check methods
      expect(result, contains('UserSchema parse(Object? input)'));
      expect(result, contains('UserSchema? tryParse(Object? input)'));
      expect(result,
          contains('UserSchema createValidated(Map<String, Object?> data)'));

      // Check definition field
      expect(result, contains('late final definition = Ack.object({'));
      expect(result, contains("'id': Ack.string"));
      expect(result, contains("'name': Ack.string"));
      expect(result, contains("'email': Ack.string.nullable()"));
      expect(result, contains("required: ['id', 'name']"));
    });

    test('generates property getters for primitive types', () {
      final model = ModelInfo(
        className: 'Product',
        schemaClassName: 'ProductSchema',
        fields: [
          _createField('name', 'String', isRequired: true),
          _createField('price', 'double', isRequired: true),
          _createField('inStock', 'bool', isRequired: true),
          _createField('description', 'String', isNullable: true),
        ],
        requiredFields: ['name', 'price', 'inStock'],
      );

      final result = builder.build(model);

      // Check primitive getters
      expect(result, contains("String get name => getValue<String>('name')"));
      expect(result, contains("double get price => getValue<double>('price')"));
      expect(result, contains("bool get inStock => getValue<bool>('inStock')"));
      expect(
          result,
          contains(
              "String? get description => getValueOrNull<String>('description')"));
    });

    test('generates property getters for lists', () {
      final model = ModelInfo(
        className: 'Post',
        schemaClassName: 'PostSchema',
        fields: [
          _createListField('tags', 'String', isRequired: true),
          _createListField('comments', 'String', isNullable: true),
        ],
        requiredFields: ['tags'],
      );

      final result = builder.build(model);

      expect(
          result,
          contains(
              "List<String> get tags => getValue<List>('tags').cast<String>()"));
      expect(
          result,
          contains(
              "List<String>? get comments => getValueOrNull<List>('comments')?.cast<String>()"));
    });

    test('generates property getters for nested schemas', () {
      final model = ModelInfo(
        className: 'Order',
        schemaClassName: 'OrderSchema',
        fields: [
          _createNestedField('customer', 'Customer', isRequired: true),
          _createNestedField('shippingAddress', 'Address', isNullable: true),
        ],
        requiredFields: ['customer'],
      );

      final result = builder.build(model);

      // Check nested schema getters
      expect(result, contains('CustomerSchema get customer'));
      expect(result, contains("getValue<Map<String, Object?>>('customer')"));
      expect(result, contains('CustomerSchema().parse(data)'));

      expect(result, contains('AddressSchema? get shippingAddress'));
      expect(result,
          contains("getValueOrNull<Map<String, Object?>>('shippingAddress')"));
      expect(result,
          contains('data != null ? AddressSchema().parse(data) : null'));
    });

    test('handles empty required fields', () {
      final model = ModelInfo(
        className: 'Config',
        schemaClassName: 'ConfigSchema',
        fields: [
          _createField('theme', 'String', isNullable: true),
          _createField('timeout', 'int', isNullable: true),
        ],
        requiredFields: [],
      );

      final result = builder.build(model);

      // Should not include required parameter when empty
      expect(result, contains('Ack.object({'));
      expect(result, isNot(contains('required:')));
    });

    test('formats output correctly', () {
      final model = ModelInfo(
        className: 'Simple',
        schemaClassName: 'SimpleSchema',
        fields: [
          _createField('value', 'String', isRequired: true),
        ],
        requiredFields: ['value'],
      );

      final result = builder.build(model);

      // Check formatting
      expect(result, contains('// GENERATED CODE - DO NOT MODIFY BY HAND'));
      expect(result.trim(), isNot(contains('  }'))); // No trailing spaces
      expect(result, isNot(contains('\t'))); // No tabs
    });
  });
}

// Helper functions
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
  bool isRequired = false,
  bool isNullable = false,
}) {
  return _MockFieldInfo(
    name: name,
    typeName: 'List<$itemTypeName>',
    isRequired: isRequired,
    isNullable: isNullable,
    constraints: [],
    isPrimitive: false,
    isList: true,
    isMap: false,
    listItemTypeName: itemTypeName,
  );
}

FieldInfo _createNestedField(
  String name,
  String typeName, {
  bool isRequired = false,
  bool isNullable = false,
}) {
  return _MockFieldInfo(
    name: name,
    typeName: typeName,
    isRequired: isRequired,
    isNullable: isNullable,
    constraints: [],
    isPrimitive: false,
    isList: false,
    isMap: false,
  );
}

// Mock implementation matching field_builder_test.dart
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
    this.defaultValue,
    required this.isPrimitive,
    required this.isList,
    required this.isMap,
    this.listItemTypeName,
  }) : jsonKey = name;

  @override
  bool get isNestedSchema => !isPrimitive && !isList && !isMap;

  @override
  DartType get type => _MockDartType(typeName, listItemTypeName);
}

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

  // Add missing core type getters
  bool get isDartCoreString => typeName == 'String';
  bool get isDartCoreInt => typeName == 'int';
  bool get isDartCoreDouble => typeName == 'double';
  bool get isDartCoreBool => typeName == 'bool';
  bool get isDartCoreNum => typeName == 'num';

  List<DartType> get typeArguments {
    if (itemTypeName != null) {
      return [_MockDartType(itemTypeName!, null)];
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
