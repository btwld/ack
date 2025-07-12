import 'package:ack_generator/src/models/constraint_info.dart';
import 'package:ack_generator/src/models/field_info.dart';
import 'package:analyzer/dart/element/type.dart';

// Mock implementation of FieldInfo for testing
class MockFieldInfo implements FieldInfo {
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
  final String? description;

  @override
  final bool isPrimitive;

  @override
  final bool isList;

  @override
  final bool isSet;

  @override
  final bool isGeneric;

  @override
  final bool isEnum;

  @override
  final List<String> enumValues;

  @override
  final bool isMap;

  final String typeName;
  final String? listItemTypeName;

  MockFieldInfo({
    required this.name,
    required this.typeName,
    required this.isRequired,
    required this.defaultValue,
    required this.isNullable,
    required this.constraints,
    required this.isPrimitive,
    required this.isList,
    required this.isMap,
    this.description,
    this.isSet = false,
    this.isGeneric = false,
    this.isEnum = false,
    this.enumValues = const [],
    this.listItemTypeName,
  }) : jsonKey = name;

  @override
  bool get isNestedSchema => !isPrimitive && !isList && !isMap;

  @override
  DartType get type => MockDartType(typeName, listItemTypeName);
}

// Mock DartType for testing
class MockDartType implements DartType {
  final String typeName;
  final String? itemTypeName;

  MockDartType(this.typeName, this.itemTypeName);

  @override
  String getDisplayString({bool withNullability = true}) => typeName;

  @override
  bool get isDartCoreList => typeName.startsWith('List<');

  @override
  bool get isDartCoreMap => typeName.startsWith('Map<');

  @override
  bool get isDartCoreString => typeName == 'String';
  @override
  bool get isDartCoreInt => typeName == 'int';
  @override
  bool get isDartCoreDouble => typeName == 'double';
  @override
  bool get isDartCoreBool => typeName == 'bool';
  @override
  bool get isDartCoreNum => typeName == 'num';

  List<DartType> get typeArguments {
    if (itemTypeName != null) {
      return [MockDartType(itemTypeName!, null)];
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Helper to create a mock FieldInfo
FieldInfo createField(
  String name,
  String typeName, {
  bool isRequired = false,
  bool isNullable = false,
  List<ConstraintInfo> constraints = const [],
}) {
  return MockFieldInfo(
    name: name,
    typeName: typeName,
    defaultValue: null,
    isRequired: isRequired,
    isNullable: isNullable,
    constraints: constraints,
    isPrimitive: ['String', 'int', 'double', 'num', 'bool'].contains(typeName),
    isList: false,
    isMap: false,
  );
}

FieldInfo createListField(
  String name,
  String itemTypeName, {
  bool isNullable = false,
}) {
  return MockFieldInfo(
    name: name,
    typeName: 'List<$itemTypeName>',
    isRequired: !isNullable,
    isNullable: isNullable,
    constraints: [],
    defaultValue: null,
    isPrimitive: false,
    isList: true,
    isMap: false,
    listItemTypeName: itemTypeName,
  );
}

FieldInfo createMapField(String name) {
  return MockFieldInfo(
    name: name,
    defaultValue: null,
    typeName: 'Map<String, dynamic>',
    isRequired: true,
    isNullable: false,
    constraints: [],
    isPrimitive: false,
    isList: false,
    isMap: true,
  );
}
