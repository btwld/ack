import 'package:ack/ack.dart';
import 'package:ack_example/schema_types_primitives.dart';
import 'package:test/test.dart';

/// Tests for enum, literal, and enumString schemas.
///
/// Note: Extension types are generated for non-nullable primitive schemas,
/// but these tests use the schema directly via `safeParse()` or `parse()`.
void main() {
  group('Literal Schema (via safeParse)', () {
    test('statusSchema validates literal value', () {
      final result = statusSchema.safeParse('active');

      expect(result.isOk, true);
      final status = result.getOrNull();
      expect(status, isA<String>());
      expect(status, equals('active'));
      expect(status?.length, 6);
    });

    test('statusSchema rejects non-literal values', () {
      expect(statusSchema.safeParse('inactive').isFail, true);
    });

    test('statusSchema works with parse()', () {
      final status = statusSchema.parse('active')!;
      expect(status, 'active');
      expect(status.toUpperCase(), 'ACTIVE');
    });

    test('parse() throws for invalid literal', () {
      expect(() => statusSchema.parse('invalid'), throwsA(isA<AckException>()));
    });
  });

  group('EnumString Schema (via safeParse)', () {
    test('roleSchema validates allowed values', () {
      final result = roleSchema.safeParse('admin');

      expect(result.isOk, true);
      final role = result.getOrNull();
      expect(role, isA<String>());
      expect(role, equals('admin'));
    });

    test('roleSchema validates all allowed values', () {
      expect(roleSchema.safeParse('admin').isOk, true);
      expect(roleSchema.safeParse('user').isOk, true);
      expect(roleSchema.safeParse('guest').isOk, true);
      expect(roleSchema.safeParse('superadmin').isFail, true);
    });

    test('roleSchema works with parse()', () {
      final role = roleSchema.parse('admin')!;

      expect(role.contains('adm'), true);
      expect(role.startsWith('ad'), true);
    });

    test('roleSchema in collections', () {
      final roles = <String>[
        roleSchema.parse('admin')!,
        roleSchema.parse('user')!,
        roleSchema.parse('guest')!,
      ];

      expect(roles, isA<List<String>>());
      expect(roles.length, 3);
      expect(roles.every((r) => r.isNotEmpty), true);
    });
  });

  group('EnumValues Schema (via safeParse)', () {
    test('userRoleSchema validates enum values', () {
      final result = userRoleSchema.safeParse(UserRole.admin);

      expect(result.isOk, true);
      final role = result.getOrNull();
      expect(role, isA<UserRole>());
      expect(role?.name, 'admin');
      expect(role?.index, 0);
    });

    test('userRoleSchema validates all enum values', () {
      expect(userRoleSchema.safeParse(UserRole.admin).isOk, true);
      expect(userRoleSchema.safeParse(UserRole.user).isOk, true);
      expect(userRoleSchema.safeParse(UserRole.guest).isOk, true);
    });

    test('userRoleSchema accepts string representation', () {
      // EnumSchema can parse from string name
      final result = userRoleSchema.safeParse('admin');
      expect(result.isOk, true);
      final role = result.getOrNull();
      expect(role, isA<UserRole>());
      expect(role?.name, 'admin');
    });

    test('userRoleSchema accepts index number', () {
      // EnumSchema can parse from index
      final result = userRoleSchema.safeParse(0);
      expect(result.isOk, true);
      final role = result.getOrNull();
      expect(role, UserRole.admin);
    });

    test('userRoleSchema supports pattern matching', () {
      final role = userRoleSchema.parse(UserRole.admin)!;

      final description = switch (role) {
        UserRole.admin => 'Administrator',
        UserRole.user => 'Regular User',
        UserRole.guest => 'Guest User',
      };

      expect(description, 'Administrator');
    });

    test('userRoleSchema comparison works', () {
      final role1 = userRoleSchema.parse(UserRole.admin);
      final role2 = userRoleSchema.parse('admin');
      final role3 = userRoleSchema.parse(0);

      expect(role1 == role2, true);
      expect(role1 == role3, true);
      expect(role1 == UserRole.admin, true);
    });

    test('Multiple enum types can coexist', () {
      final role = userRoleSchema.parse(UserRole.admin)!;
      final status = statusEnumSchema.parse(Status.active)!;

      expect(role, isA<UserRole>());
      expect(status, isA<Status>());
      expect(role.name, 'admin');
      expect(status.name, 'active');
    });

    test('statusEnumSchema works with all Status values', () {
      final active = statusEnumSchema.parse(Status.active);
      final inactive = statusEnumSchema.parse('inactive');
      final pending = statusEnumSchema.parse(2); // index

      expect(active, Status.active);
      expect(inactive, Status.inactive);
      expect(pending, Status.pending);
    });
  });

  group('Schema Chaining and Modifiers', () {
    test('optionalStatusSchema accepts value', () {
      final result = optionalStatusSchema.safeParse('active');
      expect(result.isOk, true);
      expect(result.getOrNull(), 'active');
    });

    // Note: .optional() is for object field contexts (field can be omitted).
    // It does NOT make standalone schemas accept null - use .nullable() for that.

    test('nullableRoleSchema accepts valid values', () {
      final result = nullableRoleSchema.safeParse('admin');
      expect(result.isOk, true);
      expect(result.getOrNull(), 'admin');
    });

    test('nullableRoleSchema accepts null', () {
      final result = nullableRoleSchema.safeParse(null);
      expect(result.isOk, true);
      expect(result.getOrNull(), isNull);
    });

    test('defaultedEnumSchema uses default when null', () {
      final result = defaultedEnumSchema.safeParse(null);
      expect(result.isOk, true);
      expect(result.getOrNull(), UserRole.guest);
    });

    test('defaultedEnumSchema accepts valid value', () {
      final result = defaultedEnumSchema.safeParse(UserRole.admin);
      expect(result.isOk, true);
      expect(result.getOrNull(), UserRole.admin);
    });

    test('optionalNullableLiteralSchema with chaining', () {
      final result = optionalNullableLiteralSchema.safeParse('pending');
      expect(result.isOk, true);
      expect(result.getOrNull(), 'pending');
    });

    test('chainedEnumStringSchema uses default', () {
      final result = chainedEnumStringSchema.safeParse(null);
      expect(result.isOk, true);
      expect(result.getOrNull(), 'read');
    });

    test('chainedEnumStringSchema accepts valid value', () {
      final result = chainedEnumStringSchema.safeParse('write');
      expect(result.isOk, true);
      expect(result.getOrNull(), 'write');
    });
  });

  group('Error Handling', () {
    test('safeParse error for invalid enum', () {
      final result = userRoleSchema.safeParse('invalid_role');

      expect(result.isFail, true);
      final error = result.getError();
      expect(error, isNotNull);
    });

    test('safeParse error for invalid literal', () {
      final result = statusSchema.safeParse('wrong');

      expect(result.isFail, true);
      final error = result.getError();
      expect(error, isNotNull);
    });

    test('safeParse error for invalid enumString', () {
      final result = roleSchema.safeParse('invalid');

      expect(result.isFail, true);
      final error = result.getError();
      expect(error, isNotNull);
    });

    test('parse() throws AckException for invalid', () {
      expect(() => userRoleSchema.parse('bad'), throwsA(isA<AckException>()));
      expect(() => statusSchema.parse('bad'), throwsA(isA<AckException>()));
      expect(() => roleSchema.parse('bad'), throwsA(isA<AckException>()));
    });
  });
}
