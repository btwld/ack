import 'package:ack_generator/src/models/constraint_info.dart';
import 'package:ack_generator/src/models/field_info.dart';
import 'package:analyzer/dart/element/element2.dart';
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

  @override
  final String? listElementSchemaRef;

  @override
  final String? nestedSchemaRef;

  final String typeName;
  final String? listItemTypeName;
  final String? mapKeyTypeName;
  final String? mapValueTypeName;

  MockFieldInfo({
    required this.name,
    required this.typeName,
    required this.isRequired,
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
    this.mapKeyTypeName,
    this.mapValueTypeName,
    this.listElementSchemaRef,
    this.nestedSchemaRef,
  }) : jsonKey = name;

  @override
  bool get isNestedSchema => !isPrimitive && !isList && !isMap;

  @override
  DartType get type => MockDartType(
    typeName,
    listItemTypeName,
    keyTypeName: mapKeyTypeName,
    valueTypeName: mapValueTypeName,
  );
}

// Mock DartType for testing
class MockDartType implements DartType {
  final String typeName;
  final String? itemTypeName;
  final String? keyTypeName;
  final String? valueTypeName;

  MockDartType(
    this.typeName,
    this.itemTypeName, {
    this.keyTypeName,
    this.valueTypeName,
  });

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
  @override
  bool get isDartCoreObject => typeName == 'Object';
  @override
  bool get isDartCoreSet => typeName.startsWith('Set<');

  @override
  Element2? get element3 => null; // Return null for mock types

  List<DartType> get typeArguments {
    // For Map types, return [keyType, valueType]
    if (keyTypeName != null && valueTypeName != null) {
      return [
        MockDartType(keyTypeName!, null),
        MockDartType(valueTypeName!, null),
      ];
    }
    // For List/Set types, return [itemType]
    if (itemTypeName != null) {
      return [MockDartType(itemTypeName!, null)];
    }
    return [];
  }

  @override
  String toString() => typeName;

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
    isPrimitive: false,
    isList: true,
    isMap: false,
    listItemTypeName: itemTypeName,
  );
}

FieldInfo createMapField(
  String name, {
  String keyType = 'String',
  String valueType = 'dynamic',
}) {
  return MockFieldInfo(
    name: name,
    typeName: 'Map<$keyType, $valueType>',
    isRequired: true,
    isNullable: false,
    constraints: [],
    isPrimitive: false,
    isList: false,
    isMap: true,
    mapKeyTypeName: keyType,
    mapValueTypeName: valueType,
  );
}
