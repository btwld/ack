import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

// This file demonstrates how AnyOf could work with sealed classes
// Note: Code generation for AnyOf is not yet implemented
// part 'anyof_example.g.dart';

/// Example 1: Simple AnyOf with sealed class
/// Represents a value that can be either a string ID or numeric ID
sealed class UserId {
  const UserId();
}

class StringUserId extends UserId {
  final String value;
  const StringUserId(this.value);
}

class NumericUserId extends UserId {
  final int value;
  const NumericUserId(this.value);
}

/// Example 2: API Response that can return different types
@AckModel(
  description: 'API response with different possible payloads',
  model: true,
)
class ApiResponse {
  final String status;
  final ResponseData data;  // This would be the AnyOf field
  
  ApiResponse({
    required this.status,
    required this.data,
  });
}

// Sealed class for different response types
sealed class ResponseData {
  const ResponseData();
}

@AckModel(model: true)
class UserResponse extends ResponseData {
  final String id;
  final String name;
  final String email;
  
  const UserResponse({
    required this.id,
    required this.name,
    required this.email,
  });
}

@AckModel(model: true)
class ErrorResponse extends ResponseData {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  
  const ErrorResponse({
    required this.code,
    required this.message,
    this.details,
  });
}

@AckModel(model: true)
class ListResponse extends ResponseData {
  final List<String> items;
  final int total;
  final int page;
  
  const ListResponse({
    required this.items,
    required this.total,
    required this.page,
  });
}

/// Example 3: Settings value that can be different types
@AckModel(
  description: 'Configuration setting with flexible value type',
  model: true,
)
class Setting {
  final String key;
  final SettingValue value;  // AnyOf: string, number, boolean, object
  
  Setting({
    required this.key,
    required this.value,
  });
}

sealed class SettingValue {
  const SettingValue();
}

class StringSetting extends SettingValue {
  final String value;
  const StringSetting(this.value);
}

class NumberSetting extends SettingValue {
  final double value;
  const NumberSetting(this.value);
}

class BooleanSetting extends SettingValue {
  final bool value;
  const BooleanSetting(this.value);
}

class ObjectSetting extends SettingValue {
  final Map<String, dynamic> value;
  const ObjectSetting(this.value);
}

// Manual implementation to show how it could work
void main() {
  print('🎯 AnyOf with Sealed Classes Example\n');

  // Example 1: Manual AnyOf schema for UserId
  final userIdSchema = Ack.anyOf([
    Ack.string(),
    Ack.integer(),
  ]);

  print('1️⃣ Simple UserId AnyOf:');
  
  // Valid string ID
  try {
    final stringId = userIdSchema.parse('user_123');
    print('   ✅ String ID valid: $stringId');
  } catch (e) {
    print('   ❌ Error: $e');
  }

  // Valid numeric ID
  try {
    final numericId = userIdSchema.parse(456789);
    print('   ✅ Numeric ID valid: $numericId');
  } catch (e) {
    print('   ❌ Error: $e');
  }

  // Invalid ID (wrong type)
  try {
    userIdSchema.parse(true);
  } catch (e) {
    print('   ❌ Boolean ID rejected (as expected)');
  }

  // Example 2: Complex nested AnyOf
  print('\n2️⃣ API Response with AnyOf data:');
  
  // For now, we'd need to manually create the schema
  // In the future, the generator could do this automatically
  final responseDataSchema = Ack.anyOf([
    Ack.object({
      'id': Ack.string(),
      'name': Ack.string(),
      'email': Ack.string(),
    }),
    Ack.object({
      'code': Ack.string(),
      'message': Ack.string(),
      'details': Ack.object({}, additionalProperties: true).optional().nullable(),
    }),
    Ack.object({
      'items': Ack.list(Ack.string()),
      'total': Ack.integer(),
      'page': Ack.integer(),
    }),
  ]);

  final apiResponseSchema = Ack.object({
    'status': Ack.string(),
    'data': responseDataSchema,
  });

  // Test different response types
  final successResponse = {
    'status': 'success',
    'data': {
      'id': 'user_123',
      'name': 'John Doe',
      'email': 'john@example.com',
    },
  };

  final errorResponse = {
    'status': 'error',
    'data': {
      'code': 'AUTH_FAILED',
      'message': 'Invalid credentials',
      'details': {'attempts': 3},
    },
  };

  final listResponse = {
    'status': 'success',
    'data': {
      'items': ['item1', 'item2', 'item3'],
      'total': 50,
      'page': 1,
    },
  };

  for (final response in [successResponse, errorResponse, listResponse]) {
    try {
      final result = apiResponseSchema.parse(response);
      print('   ✅ Valid response: ${response['status']} - ${(result as Map<String, dynamic>)['data']}');
    } catch (e) {
      print('   ❌ Invalid response: $e');
    }
  }

  print('\n💡 How AnyOf could work with code generation:');
  print('   1. Detect sealed class hierarchies');
  print('   2. Generate AnyOf schema with each subclass schema');
  print('   3. In createFromMap, use discriminator or type checking');
  print('   4. Return appropriate subclass instance');
  
  print('\n🚀 Proposed annotation:');
  print('   @AnyOf() on sealed class fields');
  print('   @Discriminator("type") for explicit discriminator fields');
  print('   Automatic detection of sealed class patterns');
}