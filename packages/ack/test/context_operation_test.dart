import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaContext.operation', () {
    final schema = Ack.string();

    test('defaults to SchemaOperation.parse', () {
      final ctx = SchemaContext(name: 'root', schema: schema, value: 'hi');
      expect(ctx.operation, equals(SchemaOperation.parse));
    });

    test('can be set explicitly via constructor', () {
      final ctx = SchemaContext(
        name: 'root',
        schema: schema,
        value: 'hi',
        operation: SchemaOperation.encode,
      );
      expect(ctx.operation, equals(SchemaOperation.encode));
    });

    test('child inherits operation from parent', () {
      final parent = SchemaContext(
        name: 'root',
        schema: schema,
        value: {'a': 1},
        operation: SchemaOperation.encode,
      );

      final child = parent.createChild(
        name: 'a',
        schema: schema,
        value: 1,
        pathSegment: 'a',
      );

      expect(child.operation, equals(SchemaOperation.encode));
    });

    test('child can override operation explicitly', () {
      final parent = SchemaContext(
        name: 'root',
        schema: schema,
        value: 'hi',
      );

      final child = parent.createChild(
        name: 'inner',
        schema: schema,
        value: 'hi',
        operation: SchemaOperation.encode,
      );

      expect(parent.operation, equals(SchemaOperation.parse));
      expect(child.operation, equals(SchemaOperation.encode));
    });

    test('withOperation returns a context with the new operation', () {
      final ctx = SchemaContext(name: 'root', schema: schema, value: 'hi');
      final encoded = ctx.withOperation(SchemaOperation.encode);

      expect(encoded.operation, equals(SchemaOperation.encode));
      expect(encoded.name, equals(ctx.name));
      expect(encoded.schema, same(ctx.schema));
      expect(encoded.value, equals(ctx.value));
      expect(encoded.parent, isNull);
      expect(encoded.path, equals('#'));
      // Original is unchanged.
      expect(ctx.operation, equals(SchemaOperation.parse));
    });

    test('withOperation preserves parent and path segment', () {
      final parent = SchemaContext(name: 'root', schema: schema, value: null);
      final child = parent.createChild(
        name: 'field',
        schema: schema,
        value: 1,
        pathSegment: 'field',
      );

      final encoded = child.withOperation(SchemaOperation.encode);

      expect(encoded.path, equals('#/field'));
      expect(encoded.parent, same(parent));
      expect(encoded.operation, equals(SchemaOperation.encode));
    });

    test('toString includes the operation', () {
      final parseCtx = SchemaContext(name: 'root', schema: schema, value: 'hi');
      final encodeCtx = parseCtx.withOperation(SchemaOperation.encode);

      expect(parseCtx.toString(), contains('parse'));
      expect(encodeCtx.toString(), contains('encode'));
    });
  });
}
