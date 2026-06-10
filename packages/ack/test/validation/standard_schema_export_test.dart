import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('standard_schema re-export via ack.dart', () {
    test(
      'AckSchema.standard contract types are reachable without direct import',
      () {
        final schema = Ack.string();

        expect(schema, isA<StandardSchemaWithJsonSchema<Object?, String?>>());

        final success = schema.standard.validate('ok');
        expect(success, isA<StandardSuccess<String?>>());
        expect((success as StandardSuccess<String?>).value, 'ok');

        final failure = schema.standard.validate(1);
        expect(failure, isA<StandardFailure<String?>>());
        expect((failure as StandardFailure<String?>).issues, [
          isA<StandardIssue>(),
        ]);

        final jsonSchema = schema.standard.jsonSchema.input(
          const StandardJsonSchemaOptions(target: JsonSchemaTarget.draft07),
        );
        expect(jsonSchema, isA<Map<String, Object?>>());
      },
    );
  });
}
