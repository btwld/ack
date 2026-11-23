import 'package:ack_example/schema_types_edge_cases.dart';
import 'package:test/test.dart';

void main() {
  group('Edge case schema examples', () {
    test('typed list extraction keeps element types', () {
      final product = Product.parse({
        'name': 'Widget',
        'tags': ['sale', 'featured'],
        'scores': [1, 2, 3],
        'flags': [true, false, true],
      });

      expect(product.tags, everyElement(isA<String>()));
      expect(product.scores, everyElement(isA<int>()));
      expect(product.flags, everyElement(isA<bool>()));
    });

    test('nested schema references produce typed nested models', () {
      final employee = Employee.parse({
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

      expect(employee.homeAddress, isA<Address>());
      expect(employee.homeAddress.city, 'Miami');
      expect(employee.workAddress.street, '200 Market St');
    });

    test('optional and nullable fields are surfaced as nullable getters', () {
      final modifier = Modifier.parse({
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

    test('required nullable encodes null and optional null is omitted', () {
      final modifier = Modifier(requiredField: 'value', nullableField: null);
      final json = modifier.toJson();

      expect(json.containsKey('nullableField'), isTrue);
      expect(json['nullableField'], isNull);
      expect(json.containsKey('optionalField'), isFalse);
      expect(json.containsKey('optionalNullable'), isFalse);
      expect(json.containsKey('nullableOptional'), isFalse);
    });

    test('empty and minimal schemas still parse', () {
      final empty = Empty.parse({});
      final minimal = Minimal.parse({'id': 'abc-123'});

      expect(empty.toJson(), isEmpty);
      expect(minimal.id, 'abc-123');
    });

    test('naming variations generate the expected model classes', () {
      final named = NamedItem.parse({'name': 'named'});
      final itemValue = Item.parse({'id': 'item-1'});
      final custom = MyCustomSchema123.parse({'value': 'custom'});

      expect(named.name, 'named');
      expect(itemValue.id, 'item-1');
      expect(custom.value, 'custom');
    });
  });
}
