import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Tests for code snippets in docs/getting-started/quickstart-tutorial.mdx.
void main() {
  group('Docs /getting-started/quickstart-tutorial.mdx', () {
    AckSchema<Map<String, Object?>> buildUserSchema() {
      return Ack.object({
        'name': Ack.string().minLength(2),
        'age': Ack.integer().min(0).optional(),
      });
    }

    test('safeParse results match tutorial expectations', () {
      final userSchema = buildUserSchema();

      final validData = {'name': 'Alice', 'age': 30};
      final validDataNoAge = {'name': 'Bob'};
      final invalidDataShortName = {'name': 'X', 'age': 25};
      final invalidDataMissingName = {'age': 40};

      final result1 = userSchema.safeParse(validData);
      final result2 = userSchema.safeParse(validDataNoAge);
      final result3 = userSchema.safeParse(invalidDataShortName);
      final result4 = userSchema.safeParse(invalidDataMissingName);

      expect(result1.isOk, isTrue);
      expect(result1.getOrThrow(), equals(validData));

      expect(result2.isOk, isTrue);
      expect(result2.getOrThrow(), equals(validDataNoAge));

      expect(result3.isFail, isTrue);
      expect(result4.isFail, isTrue);
    });

    test('checkResult helper mirrors tutorial behaviour', () {
      final userSchema = buildUserSchema();

      Map<String, Object?> checkResult(
        SchemaResult<Map<String, Object?>> result,
        Map<String, Object?> originalData,
      ) {
        if (result.isOk) {
          final validatedData = result.getOrThrow()!;
          return {'status': 'OK', 'data': validatedData};
        } else {
          final error = result.getError();
          return {
            'status': 'FAILED',
            'errorName': error.name,
            'errorMessage': error.message,
            'originalData': originalData,
          };
        }
      }

      final valid = {'name': 'Alice', 'age': 30};
      final invalid = {'age': 40};

      final okSnapshot = checkResult(userSchema.safeParse(valid), valid);
      expect(okSnapshot['status'], equals('OK'));
      expect(okSnapshot['data'], equals(valid));

      final failSnapshot = checkResult(userSchema.safeParse(invalid), invalid);
      expect(failSnapshot['status'], equals('FAILED'));
      expect(failSnapshot['errorName'], isNotNull);
      expect(failSnapshot['errorMessage'], isA<String>());
      expect(failSnapshot['originalData'], equals(invalid));
    });
  });
}
