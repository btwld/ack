import 'package:test/test.dart';

import '../lib/schema_types_edge_cases.dart';

void main() {
  group('Edge case schema examples', () {
    test('typed list extraction keeps element types', () {
      final product = ProductType.parse({
        'name': 'Widget',
        'tags': ['sale', 'featured'],
        'scores': [1, 2, 3],
        'flags': [true, false, true],
      });

      expect(product.tags, everyElement(isA<String>()));
      expect(product.scores, everyElement(isA<int>()));
      expect(product.flags, everyElement(isA<bool>()));
    });

    test('nested schema references produce typed nested wrappers', () {
      final employee = EmployeeType.parse({
        'name': 'Leo',
        'employeeId': 'EMP-1',
        'homeAddress': {
          'street': '123 Main St',
          'city': 'Miami',
          'zipCode': '33101',
          'country': 'USA',
        },
        'workAddress': {
          'street': '200 Market St',
          'city': 'New York',
          'zipCode': '10001',
          'country': 'USA',
        },
      });

      expect(employee.homeAddress, isA<AddressType>());
      expect(employee.homeAddress.city, 'Miami');
      expect(employee.workAddress.street, '200 Market St');
    });

    test('optional and nullable fields are surfaced as nullable getters', () {
      final modifier = ModifierType.parse({
        'requiredField': 'value',
        'nullableField': null,
        'nullableOptional': null,
      });

      expect(modifier.requiredField, 'value');
      expect(modifier.optionalField, isNull);
      expect(modifier.nullableField, isNull);
      expect(modifier.optionalNullable, isNull);
      expect(modifier.nullableOptional, isNull);
    });

    test('empty and minimal schemas still parse', () {
      final empty = EmptyType.parse({});
      final minimal = MinimalType.parse({'id': 'abc-123'});

      expect(empty, isEmpty);
      expect(minimal.id, 'abc-123');
    });

    test('naming variations generate the expected type wrappers', () {
      final named = NamedItemType.parse({'name': 'named'});
      final itemValue = ItemType.parse({'id': 'item-1'});
      final custom = MyCustomSchema123Type.parse({'value': 'custom'});

      expect(named.name, 'named');
      expect(itemValue.id, 'item-1');
      expect(custom.value, 'custom');
    });
  });
}
