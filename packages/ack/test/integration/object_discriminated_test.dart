import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Object Extensions with Discriminated Unions', () {
    test('should extend discriminated union schemas', () {
      final baseUserSchema = Ack.object({
        'id': Ack.string(),
        'name': Ack.string(),
      });
      
      final userTypeSchema = Ack.discriminated(
        discriminatorKey: 'role',
        schemas: {
          'admin': baseUserSchema.extend({
            'role': Ack.literal('admin'),
            'permissions': Ack.list(Ack.string()),
          }),
          'customer': baseUserSchema.extend({
            'role': Ack.literal('customer'),
            'subscription': Ack.enumString(['free', 'pro', 'enterprise']),
          }),
        },
      );
      
      // Add common fields to all variants
      final enhancedSchema = userTypeSchema.transform<Map<String, Object?>>((user) {
        return {
          ...user!,
          'lastActive': DateTime.now().toIso8601String(),
          'apiVersion': 'v2',
        };
      });
      
      final admin = enhancedSchema.parse({
        'id': '1',
        'name': 'Admin User',
        'role': 'admin',
        'permissions': ['read', 'write', 'delete'],
      });
      
      expect(admin!['role'], equals('admin'));
      expect(admin['apiVersion'], equals('v2'));
      expect(admin.containsKey('lastActive'), isTrue);
    });
  });
}