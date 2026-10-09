import 'package:ack/ack.dart';

part 'schema_types_primitives.g.dart';

// Primitive schemas generate immutable value models while the schema remains
// available directly for parse() and safeParse().

/// Test primitive schema types with @Schemable

/// Test enums for enumValues schema
enum UserRole { admin, user, guest }

enum Status { active, inactive, pending }

// String schema
@Schemable()
final passwordSchema = Ack.string().minLength(8);

// Integer schema
@Schemable()
final ageSchema = Ack.integer().min(0).max(150);

// Double schema
@Schemable()
final priceSchema = Ack.double().min(0);

// Boolean schema
@Schemable()
final activeSchema = Ack.boolean();

// List schema
@Schemable()
final tagsSchema = Ack.list(Ack.string());

// List of integers
@Schemable()
final scoresSchema = Ack.list(Ack.integer());

// Literal schema
@Schemable(name: 'StatusLiteral')
final statusSchema = Ack.literal('active');

// String enum schema
@Schemable()
final roleSchema = Ack.enumString(['admin', 'user', 'guest']);

// EnumValues schemas
@Schemable(name: 'UserRoleModel')
final userRoleSchema = Ack.enumValues(UserRole.values);

@Schemable()
final statusEnumSchema = Ack.enumValues(Status.values);

// Method chaining tests for new schema types
@Schemable()
final optionalStatusSchema = Ack.literal('active').optional();

final nullableRoleSchema = Ack.enumString(['admin', 'user']).nullable();

@Schemable()
final defaultedEnumSchema = Ack.enumValues(
  UserRole.values,
).withDefault(UserRole.guest);

final optionalNullableLiteralSchema = Ack.literal(
  'pending',
).optional().nullable();

@Schemable()
final chainedEnumStringSchema = Ack.enumString([
  'read',
  'write',
  'execute',
]).withDefault('read');

// Test refine - this should work
@Schemable()
final refinedAgeSchema = Ack.integer()
    .min(0)
    .refine((age) => age < 150, message: 'Age must be less than 150');
