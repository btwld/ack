import 'package:ack/ack.dart';
import 'package:ack_example/schema_types_primitives.dart';
import 'package:test/test.dart';

/// Tests for primitive schemas.
///
/// Note: Extension types are NOT generated for primitive schemas (String, int,
/// double, bool, List, etc.). Instead, use the schema directly via `safeParse()`.
/// This is a design decision to reduce generated code - primitive schemas don't
/// need type wrappers since they just validate and return the same type.
void main() {
  group('Primitive Schemas (no extension types)', () {
    test('passwordSchema validates and returns String', () {
      final result = passwordSchema.safeParse('mySecurePassword123');

      expect(result.isOk, true);
      final password = result.getOrNull();
      expect(password, isA<String>());
      expect(password?.length, 19);
      expect(password?.toUpperCase(), 'MYSECUREPASSWORD123');
    });

    test('passwordSchema validates min length', () {
      final result = passwordSchema.safeParse('short');
      expect(result.isFail, true);
    });

    test('ageSchema validates and returns int', () {
      final result = ageSchema.safeParse(25);

      expect(result.isOk, true);
      final age = result.getOrNull();
      expect(age, isA<int>());
      expect(age, 25);
    });

    test('ageSchema validates range', () {
      expect(ageSchema.safeParse(-1).isFail, true);
      expect(ageSchema.safeParse(200).isFail, true);
    });

    test('priceSchema validates and returns double', () {
      final result = priceSchema.safeParse(19.99);

      expect(result.isOk, true);
      final price = result.getOrNull();
      expect(price, isA<double>());
      expect(price, closeTo(19.99, 0.01));
    });

    test('priceSchema validates min value', () {
      expect(priceSchema.safeParse(-1.0).isFail, true);
    });

    test('activeSchema validates and returns bool', () {
      final result = activeSchema.safeParse(true);

      expect(result.isOk, true);
      final active = result.getOrNull();
      expect(active, isA<bool>());
      expect(active, true);
    });

    test('tagsSchema validates and returns List<String>', () {
      final result = tagsSchema.safeParse(['dart', 'flutter', 'validation']);

      expect(result.isOk, true);
      final tags = result.getOrNull();
      expect(tags, isA<List>());
      expect(tags?.length, 3);
      expect(tags?[0], 'dart');
    });

    test('scoresSchema validates and returns List<int>', () {
      final result = scoresSchema.safeParse([10, 20, 30, 40]);

      expect(result.isOk, true);
      final scores = result.getOrNull();
      expect(scores, isA<List>());
      expect(scores?.length, 4);
    });

    test('Using parse() for valid input', () {
      final password = passwordSchema.parse('mySecurePassword123');
      expect(password, 'mySecurePassword123');
    });

    test('parse() throws AckException for invalid input', () {
      expect(() => ageSchema.parse(-5), throwsA(isA<AckException>()));
    });

    test('safeParse captures validation errors', () {
      final result = ageSchema.safeParse(200); // max(150)

      expect(result.isFail, true);
      expect(result.isOk, false);
      expect(result.getError(), isNotNull);
      expect(result.getOrNull(), isNull);
    });

    test('Error messages include constraint information', () {
      try {
        ageSchema.parse(-5); // min(0)
        fail('Should have thrown AckException');
      } catch (e) {
        expect(e, isA<AckException>());
        final message = e.toString();
        expect(message, contains('Validation failed'));
      }
    });

    test('List element types are strongly typed at runtime', () {
      final tags = tagsSchema.parse(['dart', 'flutter', 'validation'])!;

      // Type is preserved at runtime
      expect(tags, isA<List<String>>());

      // Can use String methods on elements
      final uppercaseTags = tags.map((t) => t.toUpperCase()).toList();
      expect(uppercaseTags, ['DART', 'FLUTTER', 'VALIDATION']);
    });
  });

  group('EnumValues Schema', () {
    test('userRoleSchema validates and returns enum value', () {
      final result = userRoleSchema.safeParse(UserRole.admin);

      expect(result.isOk, true);
      final role = result.getOrNull();
      expect(role, isA<UserRole>());
      expect(role, UserRole.admin);
    });

    test('statusEnumSchema validates and returns Status enum', () {
      final result = statusEnumSchema.safeParse(Status.active);

      expect(result.isOk, true);
      final status = result.getOrNull();
      expect(status, isA<Status>());
      expect(status, Status.active);
    });
  });

  group('EnumString Schema', () {
    test('roleSchema validates and returns string', () {
      final result = roleSchema.safeParse('admin');

      expect(result.isOk, true);
      final role = result.getOrNull();
      expect(role, 'admin');
    });

    test('roleSchema rejects invalid values', () {
      final result = roleSchema.safeParse('superuser');
      expect(result.isFail, true);
    });
  });

  group('Literal Schema', () {
    test('statusSchema validates and returns literal', () {
      final result = statusSchema.safeParse('active');

      expect(result.isOk, true);
      final status = result.getOrNull();
      expect(status, 'active');
    });

    test('statusSchema rejects non-literal values', () {
      final result = statusSchema.safeParse('inactive');
      expect(result.isFail, true);
    });
  });
}
