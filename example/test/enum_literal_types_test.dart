import 'package:ack/ack.dart';
import 'package:ack_example/schema_types_primitives.dart';
import 'package:test/test.dart';

void main() {
  group('Literal Schema Extension Types', () {
    test('StatusType wraps String with literal constraint', () {
      final status = StatusType.parse('active');

      expect(status, isA<String>());
      expect(status, equals('active'));
      expect(status.length, 6);
    });

    test('StatusType rejects non-literal values', () {
      expect(() => StatusType.parse('inactive'), throwsA(isA<AckException>()));
    });

    test('StatusType.safeParse returns correct result type', () {
      final validResult = StatusType.safeParse('active');
      expect(validResult.isOk, true);
      expect(validResult.getOrNull(), isA<StatusType>());
      expect(validResult.getOrNull(), equals('active'));

      final invalidResult = StatusType.safeParse('invalid');
      expect(invalidResult.isFail, true);
      expect(invalidResult.getError(), isNotNull);
    });

    test('StatusType works with String methods via implements', () {
      final status = StatusType.parse('active');

      expect(status.toUpperCase(), 'ACTIVE');
      expect(status.contains('act'), true);
      expect(status.startsWith('ac'), true);
      expect(status.endsWith('ive'), true);
    });
  });

  group('EnumString Schema Extension Types', () {
    test('RoleType wraps String with enum constraint', () {
      final role = RoleType.parse('admin');

      expect(role, isA<String>());
      expect(role, equals('admin'));
      expect(role.toUpperCase(), 'ADMIN');
    });

    test('RoleType validates against allowed values', () {
      expect(() => RoleType.parse('admin'), returnsNormally);
      expect(() => RoleType.parse('user'), returnsNormally);
      expect(() => RoleType.parse('guest'), returnsNormally);
      expect(() => RoleType.parse('superadmin'), throwsA(isA<AckException>()));
    });

    test('RoleType works with String methods', () {
      final role = RoleType.parse('admin');

      expect(role.contains('adm'), true);
      expect(role.startsWith('ad'), true);
      expect(role.split('m'), ['ad', 'in']);
      expect(role.replaceAll('a', 'A'), 'Admin');
    });

    test('RoleType.safeParse validates and returns typed result', () {
      final validResult = RoleType.safeParse('user');
      expect(validResult.isOk, true);
      expect(validResult.getOrNull(), isA<RoleType>());

      final invalidResult = RoleType.safeParse('invalid');
      expect(invalidResult.isFail, true);
    });

    test('RoleType can be used in collections', () {
      final roles = [
        RoleType.parse('admin'),
        RoleType.parse('user'),
        RoleType.parse('guest'),
      ];

      expect(roles, isA<List<RoleType>>());
      expect(roles.length, 3);
      // RoleType implements String, so all items have String methods
      expect(roles.every((r) => r.length > 0), true);
    });
  });

  group('EnumValues Schema Extension Types', () {
    test('UserRoleType wraps enum with type safety', () {
      final role = UserRoleType.parse(UserRole.admin);

      expect(role, isA<UserRole>());
      expect(role.name, 'admin');
      expect(role.index, 0);
    });

    test('UserRoleType validates all enum values', () {
      expect(() => UserRoleType.parse(UserRole.admin), returnsNormally);
      expect(() => UserRoleType.parse(UserRole.user), returnsNormally);
      expect(() => UserRoleType.parse(UserRole.guest), returnsNormally);
    });

    test('UserRoleType accepts string representation', () {
      // EnumSchema can parse from string name
      final role = UserRoleType.parse('admin');
      expect(role, isA<UserRole>());
      expect(role.name, 'admin');
      expect(role.index, 0);
    });

    test('UserRoleType accepts index number', () {
      // EnumSchema can parse from index
      final role = UserRoleType.parse(0);
      expect(role, UserRole.admin);
      expect(role.name, 'admin');
    });

    test('UserRoleType.safeParse returns correct type', () {
      final result = UserRoleType.safeParse(UserRole.user);
      expect(result.isOk, true);
      expect(result.getOrNull(), isA<UserRoleType>());
      expect(result.getOrNull(), UserRole.user);
    });

    test('UserRoleType supports pattern matching', () {
      final role = UserRoleType.parse(UserRole.admin);

      final description = switch (role) {
        UserRole.admin => 'Administrator',
        UserRole.user => 'Regular User',
        UserRole.guest => 'Guest User',
      };

      expect(description, 'Administrator');
    });

    test('UserRoleType can be compared', () {
      final role1 = UserRoleType.parse(UserRole.admin);
      final role2 = UserRoleType.parse('admin');
      final role3 = UserRoleType.parse(0);

      expect(role1 == role2, true);
      expect(role1 == role3, true);
      expect(role1 == UserRole.admin, true);
    });

    test('Multiple enum types can coexist', () {
      final role = UserRoleType.parse(UserRole.admin);
      final status = StatusEnumType.parse(Status.active);

      expect(role, isA<UserRole>());
      expect(status, isA<Status>());
      expect(role.name, 'admin');
      expect(status.name, 'active');
    });

    test('StatusEnumType works with all Status values', () {
      final active = StatusEnumType.parse(Status.active);
      final inactive = StatusEnumType.parse('inactive');
      final pending = StatusEnumType.parse(2); // index

      expect(active, Status.active);
      expect(inactive, Status.inactive);
      expect(pending, Status.pending);
    });
  });

  group('Edge Cases and Integration', () {
    test('Literal with .optional() works correctly', () {
      // OptionalStatusType should accept 'active' or omitted value
      final withValue = OptionalStatusType.parse('active');
      expect(withValue, equals('active'));
      expect(withValue.toUpperCase(), 'ACTIVE');
    });

    test('EnumString with .nullable() works correctly', () {
      // NullableRoleType should accept enum values
      final admin = NullableRoleType.parse('admin');
      expect(admin, equals('admin'));
      expect(admin.length, 5);

      // Note: Extension types can't directly represent nullable primitives
      // The nullable() modifier affects validation, not the extension type
      // This is expected behavior - extension types wrap non-nullable values
    });

    test('EnumValues with .withDefault() works correctly', () {
      // DefaultedEnumType should accept enum values
      final userRole = DefaultedEnumType.parse(UserRole.user);
      expect(userRole, equals(UserRole.user));
      expect(userRole.name, 'user');
      expect(userRole.index, 1);

      // Should use default when value is missing/null
      final defaultResult = DefaultedEnumType.safeParse(null);
      expect(defaultResult.isOk, true);
      expect(defaultResult.getOrNull(), equals(UserRole.guest));
    });

    test('Literal with .optional().nullable() double chaining works', () {
      final pending = OptionalNullableLiteralType.parse('pending');
      expect(pending, equals('pending'));
      expect(pending.contains('pend'), true);
    });

    test('EnumString with .withDefault() chaining works', () {
      final permission = ChainedEnumStringType.parse('write');
      expect(permission, equals('write'));
      expect(permission.startsWith('w'), true);

      // Should use default value
      final defaultPerm = ChainedEnumStringType.safeParse(null);
      expect(defaultPerm.isOk, true);
      expect(defaultPerm.getOrNull(), equals('read'));
    });

    test('Literal in collections preserves type', () {
      final statuses = [StatusType.parse('active'), StatusType.parse('active')];

      expect(statuses, isA<List<StatusType>>());
      expect(statuses.every((s) => s == 'active'), true);
    });

    test('EnumString comparison works', () {
      final role1 = RoleType.parse('admin');
      final role2 = RoleType.parse('admin');
      final role3 = RoleType.parse('user');

      expect(role1 == role2, true);
      expect(role1 == role3, false);
      expect(role1 == 'admin', true);
    });

    test('EnumValues comparison works', () {
      final role1 = UserRoleType.parse(UserRole.admin);
      final role2 = UserRoleType.parse(UserRole.admin);
      final role3 = UserRoleType.parse(UserRole.user);

      expect(role1 == role2, true);
      expect(role1 == role3, false);
    });

    test('EnumValues can be used in switch expressions', () {
      final role = UserRoleType.parse(UserRole.user);

      final permissions = switch (role) {
        UserRole.admin => ['read', 'write', 'delete'],
        UserRole.user => ['read', 'write'],
        UserRole.guest => ['read'],
      };

      expect(permissions, ['read', 'write']);
    });

    test('EnumValues index and name accessors work', () {
      final role = UserRoleType.parse(UserRole.guest);

      expect(role.index, 2);
      expect(role.name, 'guest');
      expect(role.toString(), 'UserRole.guest');
    });

    test('Type transparency allows enum methods', () {
      final status = StatusEnumType.parse(Status.pending);

      // All enum methods should work
      expect(status.name, 'pending');
      expect(status.index, 2);
      expect(Status.values.contains(status), true);
    });

    test('SafeParse error handling for enums', () {
      final result = UserRoleType.safeParse('invalid_role');

      expect(result.isFail, true);
      final error = result.getError();
      expect(error, isNotNull);
    });

    test('SafeParse error handling for literals', () {
      final result = StatusType.safeParse('wrong');

      expect(result.isFail, true);
      final error = result.getError();
      expect(error, isNotNull);
    });

    test('SafeParse error handling for enumString', () {
      final result = RoleType.safeParse('invalid');

      expect(result.isFail, true);
      final error = result.getError();
      expect(error, isNotNull);
    });
  });
}
