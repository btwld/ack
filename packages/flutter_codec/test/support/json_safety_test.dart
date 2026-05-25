import 'package:flutter_test/flutter_test.dart';

import 'json_safety.dart';

void main() {
  group('jsonSafetyViolation accepts JSON values', () {
    for (final value in <Object?>[
      null,
      true,
      'text',
      1,
      1.5,
      [1, 'a', null],
      {
        'k': [1, true],
        'nested': {'x': 2.0},
      },
    ]) {
      test('$value', () {
        expect(jsonSafetyViolation(value), isNull);
        expectJsonSafe(value);
      });
    }
  });

  group('jsonSafetyViolation flags non-JSON content', () {
    test('reports the path of a leaked runtime object', () {
      final violation = jsonSafetyViolation({'color': Object()});
      expect(violation, r'$.color: non-JSON value of type Object');
    });

    test('rejects non-finite numbers', () {
      expect(jsonSafetyViolation(double.infinity), isNotNull);
      expect(jsonSafetyViolation(double.nan), isNotNull);
    });

    test('rejects non-string map keys', () {
      expect(jsonSafetyViolation({1: 'a'}), isNotNull);
    });

    test('expectJsonSafe fails when a runtime object leaks', () {
      expect(
        () => expectJsonSafe({'color': Object()}),
        throwsA(isA<TestFailure>()),
      );
    });
  });
}
