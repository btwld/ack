import 'package:ack/ack.dart';
import 'package:ack/src/context.dart';
import 'package:ack/src/helpers.dart';
import 'package:test/test.dart';

class _MockSchemaContext extends SchemaContext {
  _MockSchemaContext()
      : super(name: 'test', schema: ObjectSchema({}), value: null);
}

class _MockConstraint extends Constraint {
  const _MockConstraint()
      : super(constraintKey: 'test_constraint', description: 'Test constraint');
}

void main() {
  group('SchemaError', () {
    group('SchemaConstraintsError', () {
      final constraintError1 = ConstraintError(
        message: 'Custom constraint',
        constraint: _MockConstraint(),
      );

      final constraintError2 = ConstraintError(
        message: 'Custom constraint 2',
        constraint: _MockConstraint(),
      );

      test('single constraint error', () {
        final error = SchemaConstraintsError(
          constraints: [constraintError1],
          context: _MockSchemaContext(),
        );

        expect(error.constraints.length, 1);
        expect(error.constraints.first, constraintError1);
      });

      test('multiple constraint errors', () {
        final error = SchemaConstraintsError(
          constraints: [constraintError1, constraintError2],
          context: _MockSchemaContext(),
        );

        expect(error.constraints.length, 2);
        expect(error.constraints, [constraintError1, constraintError2]);
      });
    });

    test('toString() returns formatted string', () {
      final error = NonNullableConstraint();
      expect(
        error.toString(),
        contains('$NonNullableConstraint'),
      );
      expect(
        error.toString(),
        contains('non_nullable'),
      );
    });
  });

  group('Schema Error Messages', () {
    test('Simple string validation error messages', () {
      final schema = Ack.string.minLength(5).maxLength(10);

      var result = schema.validate('abc');
      expect(result.isFail, isTrue);
      var error = result.getError() as SchemaConstraintsError;
      expect(error.constraints.first.message,
          equals('Too short, min 5 characters'));

      result = schema.validate('abcdefghijk');
      expect(result.isFail, isTrue);
      error = result.getError() as SchemaConstraintsError;
      expect(error.constraints.first.message,
          equals('Too long, max 10 characters'));
    });

    test('Enum validation error messages', () {
      final constraint = StringEnumConstraint(['red', 'green', 'blue']);
      final schema = Ack.string.constrain(constraint);

      var result = schema.validate('yellow');
      expect(result.isFail, isTrue);
      var error = result.getError() as SchemaConstraintsError;

      expect(error.constraints.length, 1);
      expect(error.constraints.first.message,
          equals('Allowed: "red", "green", "blue"'));
    });

    test('Date validation error messages', () {
      final constraint = StringDateConstraint();
      final schema = Ack.string.constrain(constraint);

      var result = schema.validate('2023-13-45');
      expect(result.isFail, isTrue);
      var error = result.getError() as SchemaConstraintsError;
      expect(error.constraints.first.message,
          equals('Invalid date. YYYY-MM-DD required. Ex: 2017-07-21'));
    });

    test('List validation error messages', () {
      final minItems = ListMinItemsConstraint(2);
      final maxItems = ListMaxItemsConstraint(4);
      final uniqueItems = ListUniqueItemsConstraint();
      final schema = Ack.list(Ack.string)
          .constrain(minItems)
          .constrain(maxItems)
          .constrain(uniqueItems);

      // Test too few items
      var result = schema.validate(['a']);
      expect(result.isFail, isTrue);
      var error = result.getError() as SchemaConstraintsError;
      expect(error.constraints.first.message,
          equals('Too few items, min 2. Got 1'));

      // Test too many items
      result = schema.validate(['a', 'b', 'c', 'd', 'e']);
      expect(result.isFail, isTrue);
      error = result.getError() as SchemaConstraintsError;
      expect(error.constraints.first.message,
          equals('Too many items, max 4. Got 5'));

      // Test duplicate items
      result = schema.validate(['a', 'b', 'a']);
      expect(result.isFail, isTrue);
      error = result.getError() as SchemaConstraintsError;
      expect(error.constraints.first.message,
          equals('Must be unique. Duplicates found: "a"'));
    });
  });

  final userSchema = Ack.object({
    'name': Ack.string.minLength(5).maxLength(10),
    'age': Ack.int.min(18).max(100),
    'email': Ack.string.isEmail(),
    'phone': Ack.string.isNotEmpty(),
  }, required: [
    'name',
    'email'
  ]);

  final addressSchema = Ack.object({
    'street': Ack.string,
    'city': Ack.string,
    'zip': Ack.int,
  });

  final userWithAddressSchema = userSchema.extend({
    'address': addressSchema,
  });

  test('SchemaError', () {
    final result =
        userWithAddressSchema.validate(debugName: 'userWithAddress', {
      'age': 'car',
      'name': 'Leo',
      'email': 'john.doe@example.com',
      'phone': '1234567890',
      'address': {
        'street': '123 Main St',
        'city': 'Anytown',
        'zip': 'here',
      },
    });

    print(prettyJson(composeSchemaErrorMap(result.getError())));
  });
}
