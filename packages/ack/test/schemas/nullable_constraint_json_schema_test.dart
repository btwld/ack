import 'package:ack/ack.dart';
import 'package:ack/src/constraints/comparison_constraint.dart';
import 'package:ack/src/constraints/constraint.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

/// Test-only constraint that adds a custom JSON Schema keyword.
///
/// Used to verify that constraints are properly merged in JSON Schema output
/// for AnyOfSchema, which uses `AckSchema<Object>` and has no natural
/// JsonSchemaSpec constraints.
class _TestJsonSchemaConstraint extends Constraint<Object>
    with Validator<Object>, JsonSchemaSpec<Object> {
  const _TestJsonSchemaConstraint()
      : super(
          constraintKey: 'test_marker',
          description: 'Test constraint for JSON Schema merging verification',
        );

  @override
  @protected
  bool isValid(Object value) => true; // Always passes

  @override
  @protected
  String buildMessage(Object value) => 'Test constraint failed';

  @override
  Map<String, Object?> toJsonSchema() => {'x-test-marker': true};
}

void main() {
  group('Nullable Schema Constraint JSON Schema Merging', () {
    group('DiscriminatedObjectSchema', () {
      test('non-nullable merges constraints in JSON Schema', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'a': Ack.object({'type': Ack.literal('a')}),
            'b': Ack.object({'type': Ack.literal('b')}),
          },
        ).withConstraint(ComparisonConstraint.objectMinProperties(1));

        final jsonSchema = schema.toJsonSchema();

        // Non-nullable: constraints merged at top level
        expect(jsonSchema['minProperties'], equals(1));
        expect(jsonSchema['anyOf'], isA<List>());
      });

      test('nullable merges constraints in inner JSON Schema', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'a': Ack.object({'type': Ack.literal('a')}),
            'b': Ack.object({'type': Ack.literal('b')}),
          },
        ).nullable().withConstraint(ComparisonConstraint.objectMinProperties(1));

        final jsonSchema = schema.toJsonSchema();

        // Structure: { anyOf: [ {anyOf: [...], minProperties: 1}, {type: 'null'} ] }
        expect(jsonSchema['anyOf'], isA<List>());
        final anyOfList = jsonSchema['anyOf'] as List;
        expect(anyOfList.length, equals(2));

        // Inner schema should have minProperties merged
        final innerSchema = anyOfList[0] as Map<String, Object?>;
        expect(
          innerSchema['minProperties'],
          equals(1),
          reason: 'Constraint should be merged into inner schema when nullable',
        );

        // Second element is null type
        expect(anyOfList[1], equals({'type': 'null'}));
      });

      test('nullable with multiple constraints merges all', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'a': Ack.object({'type': Ack.literal('a')}),
            'b': Ack.object({'type': Ack.literal('b')}),
          },
        )
            .nullable()
            .withConstraint(ComparisonConstraint.objectMinProperties(1))
            .withConstraint(ComparisonConstraint.objectMaxProperties(10));

        final jsonSchema = schema.toJsonSchema();
        final anyOfList = jsonSchema['anyOf'] as List;
        final innerSchema = anyOfList[0] as Map<String, Object?>;

        expect(innerSchema['minProperties'], equals(1));
        expect(innerSchema['maxProperties'], equals(10));
      });
    });

    group('AnyOfSchema', () {
      test('non-nullable merges constraints in JSON Schema', () {
        final schema = Ack.anyOf([
          Ack.string(),
          Ack.integer(),
        ]).withConstraint(const _TestJsonSchemaConstraint());

        final jsonSchema = schema.toJsonSchema();

        // Non-nullable: constraints merged at top level
        expect(jsonSchema['x-test-marker'], isTrue);
        expect(jsonSchema['anyOf'], isA<List>());
      });

      test('nullable merges constraints in inner JSON Schema', () {
        final schema = Ack.anyOf([
          Ack.string(),
          Ack.integer(),
        ]).nullable().withConstraint(const _TestJsonSchemaConstraint());

        final jsonSchema = schema.toJsonSchema();

        // Structure: { anyOf: [ {anyOf: [...], x-test-marker: true}, {type: 'null'} ] }
        expect(jsonSchema['anyOf'], isA<List>());
        final anyOfList = jsonSchema['anyOf'] as List;
        expect(anyOfList.length, equals(2));

        // Inner schema should have test marker merged
        final innerSchema = anyOfList[0] as Map<String, Object?>;
        expect(
          innerSchema['x-test-marker'],
          isTrue,
          reason: 'Constraint should be merged into inner schema when nullable',
        );

        // Second element is null type
        expect(anyOfList[1], equals({'type': 'null'}));
      });
    });
  });
}
