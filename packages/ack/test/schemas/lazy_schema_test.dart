import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  test('parses and encodes a recursive object graph', () {
    late final ObjectSchema categorySchema;
    categorySchema = Ack.object({
      'name': Ack.string(),
      'children': Ack.list(
        Ack.lazy<JsonMap, JsonMap>('Category', () => categorySchema),
      ),
    });

    final json = <String, Object?>{
      'name': 'root',
      'children': [
        {
          'name': 'first',
          'children': [
            {'name': 'leaf', 'children': <Object?>[]},
          ],
        },
      ],
    };

    final parsed = categorySchema.parse(json);
    expect(parsed, equals(json));

    final encoded = categorySchema.encode(parsed);
    expect(encoded, equals(json));
    expect(categorySchema.encode(categorySchema.parse(json)), equals(json));
  });

  test('throws a clear error when exporting recursive schemas', () {
    late final ObjectSchema categorySchema;
    categorySchema = Ack.object({
      'name': Ack.string(),
      'children': Ack.list(
        Ack.lazy<JsonMap, JsonMap>('Category', () => categorySchema),
      ),
    });

    const message =
        'JSON Schema export of recursive schemas (Ack.lazy) is not supported';

    expect(
      categorySchema.toSchemaModel,
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains(message),
        ),
      ),
    );
    expect(
      categorySchema.toJsonSchema,
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains(message),
        ),
      ),
    );
  });

  test('memoizes the builder result', () {
    var calls = 0;
    late final ObjectSchema categorySchema;
    final lazy = Ack.lazy<JsonMap, JsonMap>('Category', () {
      calls++;
      return categorySchema;
    });
    categorySchema = Ack.object({
      'name': Ack.string(),
      'children': Ack.list(lazy),
    });

    final json = <String, Object?>{
      'name': 'root',
      'children': [
        {'name': 'leaf', 'children': <Object?>[]},
      ],
    };

    final parsed = categorySchema.parse(json);
    expect(parsed, equals(json));
    expect(categorySchema.encode(parsed), equals(json));
    expect(calls, 1);
  });

  test('uses closure identity for equality', () {
    final target = Ack.object({'name': Ack.string()});
    final first = Ack.lazy<JsonMap, JsonMap>('Category', () => target);
    final second = Ack.lazy<JsonMap, JsonMap>('Category', () => target);

    expect(first, equals(first));
    expect(first, isNot(equals(second)));
  });
}
