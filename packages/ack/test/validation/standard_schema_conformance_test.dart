import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('StandardSchema conformance', () {
    test('AckSchema implements the standard schema contract', () {
      expect(Ack.string(), isA<StandardSchema<Object?, String?>>());
    });

    test(
      'standard validate maps successful nullable nulls without type errors',
      () {
        final result = Ack.string().nullable().standard.validate(null);

        expect(result, isA<StandardSuccess<String?>>());
        expect((result as StandardSuccess<String?>).value, isNull);
      },
    );

    test(
      'standard validate maps nested failures to flat issues with paths',
      () {
        final schema = Ack.object({
          'user': Ack.object({'tags': Ack.list(Ack.string().minLength(2))}),
        });

        final result = schema.standard.validate({
          'user': {
            'tags': ['ok', 'x'],
          },
        });

        expect(result, isA<StandardFailure<JsonMap?>>());
        final failure = result as StandardFailure<JsonMap?>;
        expect(failure.issues, hasLength(1));
        expect(failure.issues.single.path, ['user', 'tags', 1]);
      },
    );

    test('SchemaContext.pathSegments mirrors JSON pointer path semantics', () {
      final root = SchemaContext(name: 'root', schema: Ack.string(), value: {});
      final property = root.createChild(
        name: 'tags',
        schema: Ack.list(Ack.string()),
        value: const ['x'],
        pathSegment: 'tags',
      );
      final index = property.createChild(
        name: '1',
        schema: Ack.string(),
        value: 'x',
        pathSegment: '1',
      );
      final passThrough = index.createChild(
        name: 'anyOf',
        schema: Ack.string(),
        value: 'x',
        pathSegment: '',
      );

      expect(root.pathSegments, const []);
      expect(property.pathSegments, ['tags']);
      expect(index.pathSegments, ['tags', 1]);
      expect(passThrough.pathSegments, ['tags', 1]);
    });

    test('SchemaError.toStandardIssues flattens direct and nested errors', () {
      final direct = Ack.string().minLength(2).safeParse('x').getError();
      final nested = Ack.object({
        'name': Ack.string().minLength(2),
        'age': Ack.integer(),
      }).safeParse({'name': 'x', 'age': 'old'}).getError();

      expect(direct.toStandardIssues(), hasLength(1));
      expect(direct.toStandardIssues().single.path, const []);

      final issues = nested.toStandardIssues();
      expect(issues.map((issue) => issue.path), [
        ['name'],
        ['age'],
      ]);
    });

    test('standard JSON Schema converter delegates to Draft-7 rendering', () {
      final schema = Ack.string().minLength(2);
      final converter = schema.standard.jsonSchema!;
      const draft7 = StandardJsonSchemaOptions(
        target: JsonSchemaTarget.draft07,
      );

      expect(converter.input(draft7), schema.toJsonSchema());
      expect(converter.output(draft7), schema.toJsonSchema());
      expect(
        () => converter.input(
          const StandardJsonSchemaOptions(target: JsonSchemaTarget.openapi30),
        ),
        throwsUnsupportedError,
      );
    });

    test('standard output JSON Schema throws for codecs', () {
      final codec = Ack.string().transform<int>((value) => int.parse(value));
      final converter = codec.standard.jsonSchema!;

      expect(
        () => converter.output(
          const StandardJsonSchemaOptions(target: JsonSchemaTarget.draft07),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
