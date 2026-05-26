import 'package:flutter_codec/src/json_readers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('readValue', () {
    test('reads required typed fields', () {
      final map = {'value': 'text'};

      expect(readValue<String>(map, 'value'), 'text');
    });
  });

  group('readNullableValue', () {
    test('returns null for missing or explicit null fields', () {
      final map = {'explicitNull': null};

      expect(readNullableValue<String>(map, 'missing'), isNull);
      expect(readNullableValue<String>(map, 'explicitNull'), isNull);
    });

    test('reads present typed fields', () {
      final map = {'value': 'text'};

      expect(readNullableValue<String>(map, 'value'), 'text');
    });
  });

  group('readDouble', () {
    test('reads numeric fields as doubles', () {
      final map = {'integer': 2, 'double': 2.5};

      expect(readDouble(map, 'integer'), 2.0);
      expect(readDouble(map, 'double'), 2.5);
    });
  });

  group('readNullableDouble', () {
    test('returns null for missing or explicit null fields', () {
      final map = {'explicitNull': null};

      expect(readNullableDouble(map, 'missing'), isNull);
      expect(readNullableDouble(map, 'explicitNull'), isNull);
    });

    test('reads present numeric fields as doubles', () {
      final map = {'integer': 3, 'double': 3.5};

      expect(readNullableDouble(map, 'integer'), 3.0);
      expect(readNullableDouble(map, 'double'), 3.5);
    });
  });

  group('readList', () {
    test('reads typed list fields', () {
      final map = {
        'values': ['a', 'b'],
      };

      expect(readList<String>(map, 'values'), ['a', 'b']);
    });
  });

  group('readNullableList', () {
    test('returns null for missing or explicit null fields', () {
      final map = {'explicitNull': null};

      expect(readNullableList<String>(map, 'missing'), isNull);
      expect(readNullableList<String>(map, 'explicitNull'), isNull);
    });

    test('reads typed list fields', () {
      final map = {
        'values': ['a', 'b'],
      };

      expect(readNullableList<String>(map, 'values'), ['a', 'b']);
    });
  });

  group('readNullableDoubleList', () {
    test('returns null for missing or explicit null fields', () {
      final map = {'explicitNull': null};

      expect(readNullableDoubleList(map, 'missing'), isNull);
      expect(readNullableDoubleList(map, 'explicitNull'), isNull);
    });

    test('reads numeric list fields as doubles', () {
      final map = {
        'values': [1, 2.5],
      };

      expect(readNullableDoubleList(map, 'values'), [1.0, 2.5]);
    });
  });
}
