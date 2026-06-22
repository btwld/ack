import 'package:ack/ack.dart';
import 'package:standard_schema/utils.dart';
import 'package:test/test.dart';

enum _Role { admin, member }

void main() {
  group('Ack Standard Schema conformance', () {
    test('exposes the Standard Schema contract through package:ack', () async {
      final schema = Ack.string();

      expect(schema, isA<StandardSchemaWithJsonSchema<Object?, String?>>());
      expect(schema.standard.vendor, 'ack');
      expect(schema.standard.version, 1);

      final result = await Future.value(schema.standard.validate('Ada'));

      expect(result, isA<StandardSuccess<String?>>());
      expect((result as StandardSuccess<String?>).value, 'Ada');
    });

    test('maps nested Ack failures to flat Standard issues', () async {
      final schema = Ack.object({
        'user': Ack.object({'tags': Ack.list(Ack.string())}),
      });

      final result = await Future.value(
        schema.standard.validate({
          'user': {
            'tags': ['ok', 1],
          },
        }),
      );

      expect(result, isA<StandardFailure<JsonMap?>>());
      final failure = result as StandardFailure<JsonMap?>;

      expect(failure.issues, hasLength(1));
      expect(failure.issues.single.path, ['user', 'tags', 1]);
      expect(getDotPath(failure.issues.single), 'user.tags.1');
      expect(failure.issues.single.message, contains('Expected string'));
    });

    test('maps constraint failures to individual Standard issues', () async {
      final schema = Ack.string().minLength(3);

      final result = await Future.value(schema.standard.validate('a'));

      expect(result, isA<StandardFailure<String?>>());
      final failure = result as StandardFailure<String?>;

      expect(failure.issues, hasLength(1));
      expect(failure.issues.single.path, isEmpty);
      expect(failure.issues.single.message, contains('Minimum 3'));
    });

    test('fans out every failing constraint into its own issue', () async {
      final schema = Ack.string().minLength(5).matches(r'^\d+$');

      final result = await Future.value(schema.standard.validate('ab'));

      final failure = result as StandardFailure<String?>;
      expect(failure.issues, hasLength(2));
      expect(failure.issues.map((i) => i.path), everyElement(isEmpty));
      expect(
        failure.issues.map((i) => i.message),
        containsAll([contains('Minimum 5'), contains('match')]),
      );
    });

    test('fans out sibling object field failures into distinct paths', () async {
      final schema = Ack.object({'a': Ack.string(), 'b': Ack.integer()});

      final result = await Future.value(
        schema.standard.validate({'a': 1, 'b': 'x'}),
      );

      final failure = result as StandardFailure<JsonMap?>;
      expect(failure.issues, hasLength(2));
      expect(
        failure.issues.map((i) => i.path),
        containsAll([
          ['a'],
          ['b'],
        ]),
      );
    });

    test('fans out sibling list item failures into indexed paths', () async {
      final schema = Ack.list(Ack.string());

      final result = await Future.value(schema.standard.validate([1, 'ok', 2]));

      final failure = result as StandardFailure<List<String>?>;
      expect(failure.issues, hasLength(2));
      expect(
        failure.issues.map((i) => i.path),
        containsAll([
          [0],
          [2],
        ]),
      );
    });

    test('converts Draft-7 input JSON Schema through AckSchemaModel', () {
      final schema = Ack.object({
        'name': Ack.string(),
        'roles': Ack.list(Ack.enumValues(_Role.values)),
      });

      expect(
        schema.standard.jsonSchema.input(
          const StandardJsonSchemaOptions(target: JsonSchemaTarget.draft07),
        ),
        schema.toJsonSchema(),
      );
    });

    test('aliases input on the output side for non-codec transforms', () {
      // EnumSchema is String->enum (Boundary != Runtime) but not a codec, so
      // its output JSON Schema intentionally reuses the boundary schema.
      final schema = Ack.enumValues(_Role.values);
      const options = StandardJsonSchemaOptions(target: JsonSchemaTarget.draft07);

      expect(
        schema.standard.jsonSchema.output(options),
        schema.standard.jsonSchema.input(options),
      );
    });

    test('throws for unsupported JSON Schema targets', () {
      final schema = Ack.string();

      expect(
        () => schema.standard.jsonSchema.input(
          const StandardJsonSchemaOptions(target: JsonSchemaTarget.openapi30),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => schema.standard.jsonSchema.output(
          const StandardJsonSchemaOptions(target: JsonSchemaTarget.draft202012),
        ),
        throwsUnsupportedError,
      );
    });

    test('uses representable codec output schemas', () {
      final schema = Ack.codec<String, String, int>(
        input: Ack.string(),
        decode: int.parse,
        encode: (value) => value.toString(),
        output: Ack.integer(),
      );

      expect(
        schema.standard.jsonSchema.input(
          const StandardJsonSchemaOptions(target: JsonSchemaTarget.draft07),
        ),
        {'type': 'string', 'x-transformed': true},
      );
      expect(
        schema.standard.jsonSchema.output(
          const StandardJsonSchemaOptions(target: JsonSchemaTarget.draft07),
        ),
        {'type': 'integer'},
      );
    });

    test('throws for codec output schemas that are runtime-only', () {
      final schema = Ack.date();

      expect(
        schema.standard.jsonSchema.input(
          const StandardJsonSchemaOptions(target: JsonSchemaTarget.draft07),
        ),
        schema.toJsonSchema(),
      );
      expect(
        () => schema.standard.jsonSchema.output(
          const StandardJsonSchemaOptions(target: JsonSchemaTarget.draft07),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
