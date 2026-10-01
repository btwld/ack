import 'package:ack/ack.dart';
import 'package:ack/annotations.dart';

part 'schema_types_primitives.ack.dart';
part 'schema_types_primitives.ack.g.dart';

// Primitive schemas generate immutable value models while the schema remains
// available directly for parse() and safeParse().

/// Test primitive schema types with @AckInfer

/// Test enums for enumValues schema
enum UserRole { admin, user, guest }

enum Status { active, inactive, pending }

// String schema
@AckInfer()
final passwordSchema = Ack.string().minLength(8);

// Integer schema
@AckInfer()
final ageSchema = Ack.integer().min(0).max(150);

// Double schema
@AckInfer()
final priceSchema = Ack.double().min(0);

// Boolean schema
@AckInfer()
final activeSchema = Ack.boolean();

// List schema
@AckInfer()
final tagsSchema = Ack.list(Ack.string());

// List of integers
@AckInfer()
final scoresSchema = Ack.list(Ack.integer());

// Literal schema
@AckInfer(name: 'StatusLiteral')
final statusSchema = Ack.literal('active');

// String enum schema
@AckInfer()
final roleSchema = Ack.enumString(['admin', 'user', 'guest']);

// EnumValues schemas
@AckInfer(name: 'UserRoleModel')
final userRoleSchema = Ack.enumValues(UserRole.values);

@AckInfer()
final statusEnumSchema = Ack.enumValues(Status.values);

// Method chaining tests for new schema types
@AckInfer()
final optionalStatusSchema = Ack.literal('active').optional();

final nullableRoleSchema = Ack.enumString(['admin', 'user']).nullable();

@AckInfer()
final defaultedEnumSchema = Ack.enumValues(
  UserRole.values,
).withDefault(UserRole.guest);

final optionalNullableLiteralSchema = Ack.literal(
  'pending',
).optional().nullable();

@AckInfer()
final chainedEnumStringSchema = Ack.enumString([
  'read',
  'write',
  'execute',
]).withDefault('read');

// Test refine - this should work
@AckInfer()
final refinedAgeSchema = Ack.integer()
    .min(0)
    .refine((age) => age < 150, message: 'Age must be less than 150');
