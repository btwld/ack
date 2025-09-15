import 'package:ack_generator/builder.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'test_utils/test_assets.dart';

void main() {
  group('Annotation Combination Edge Cases', () {
    group('AckModel Complex Combinations', () {
      test('should handle model + additionalProperties + custom schema name',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/complex_combo.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(
  model: true,
  schemaName: 'FlexibleUserSchema',
  description: 'A flexible user model with additional properties',
  additionalProperties: true,
  additionalPropertiesField: 'metadata'
)
class FlexibleUser {
  final String name;
  final int age;
  final Map<String, dynamic> metadata;
  
  FlexibleUser({
    required this.name,
    required this.age,
    required this.metadata,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/complex_combo.g.dart': decodedMatches(allOf([
              // Custom schema name
              contains('final flexibleUserSchema = Ack.object({'),
              contains('/// Generated schema for FlexibleUser'),
              contains('/// A flexible user model with additional properties'),

              // Additional properties
              contains('}, additionalProperties: true)'),

              // SchemaModel generation
              contains(
                  'class FlexibleUserSchemaModel extends SchemaModel<FlexibleUser>'),
              contains('extractAdditionalProperties(map, {'),
              contains("'name', 'age'"),
            ])),
          },
        );
      });

      test('should handle discriminated types with model generation', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/discriminated_with_model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(
  discriminatedKey: 'type',
  model: true,
  description: 'Base notification class'
)
abstract class Notification {
  String get type;
  final String message;
  Notification({required this.message});
}

@AckModel(
  discriminatedValue: 'email',
  model: true,
  description: 'Email notification'
)
class EmailNotification extends Notification {
  @override
  String get type => 'email';
  
  final String recipient;
  
  EmailNotification({
    required super.message,
    required this.recipient,
  });
}

@AckModel(
  discriminatedValue: 'sms',
  model: true,
  description: 'SMS notification'
)
class SmsNotification extends Notification {
  @override
  String get type => 'sms';
  
  final String phoneNumber;
  
  SmsNotification({
    required super.message,
    required this.phoneNumber,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/discriminated_with_model.g.dart':
                decodedMatches(allOf([
              // Discriminated schema
              contains('final notificationSchema = Ack.discriminated('),
              contains("discriminatorKey: 'type'"),

              // Individual schemas
              contains('final emailNotificationSchema = Ack.object({'),
              contains('final smsNotificationSchema = Ack.object({'),

              // SchemaModel classes
              contains(
                  'class NotificationSchemaModel extends SchemaModel<Notification>'),
              contains(
                  'class EmailNotificationSchemaModel extends SchemaModel<EmailNotification>'),
              contains(
                  'class SmsNotificationSchemaModel extends SchemaModel<SmsNotification>'),

              // Switch logic in base class
              contains("final type = map['type'] as String;"),
              contains('return switch (type) {'),
              contains(
                  "'email' => EmailNotificationSchemaModel().createFromMap(map)"),
              contains(
                  "'sms' => SmsNotificationSchemaModel().createFromMap(map)"),
            ])),
          },
        );
      });
    });

    group('Field and Model Annotation Combinations', () {
      test('should handle AckField with AckModel additionalProperties',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/field_with_additional.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(
  model: true,
  additionalProperties: true,
  additionalPropertiesField: 'extras'
)
class FieldWithAdditionalProps {
  @AckField(jsonKey: 'user_name', required: true)
  final String name;
  
  @AckField(jsonKey: 'user_email', constraints: ['email'])
  final String email;
  
  final Map<String, dynamic> extras;
  
  FieldWithAdditionalProps({
    required this.name,
    required this.email,
    required this.extras,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/field_with_additional.g.dart': decodedMatches(allOf([
              // Schema with custom keys
              contains("'user_name': Ack.string()"),
              contains("'user_email': Ack.string()"),
              contains('}, additionalProperties: true)'),

              // SchemaModel with additional properties extraction
              contains('extractAdditionalProperties(map, {'),
              contains("'user_name', 'user_email'"),
              contains('name: map[\'user_name\'] as String'),
              contains('email: map[\'user_email\'] as String'),
            ])),
          },
        );
      });

      test('should handle nested models with AckField annotations', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/nested_with_fields.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(model: true)
class Address {
  @AckField(jsonKey: 'street_address')
  final String street;
  
  @AckField(jsonKey: 'city_name')
  final String city;
  
  @AckField(jsonKey: 'postal_code')
  final String? postalCode;
  
  Address({
    required this.street,
    required this.city,
    this.postalCode,
  });
}

@AckModel(model: true, description: 'User with address information')
class UserWithAddress {
  @AckField(jsonKey: 'full_name', constraints: ['notEmpty'])
  final String name;
  
  @AckField(jsonKey: 'home_address')
  final Address homeAddress;
  
  @AckField(jsonKey: 'work_address')
  final Address? workAddress;
  
  UserWithAddress({
    required this.name,
    required this.homeAddress,
    this.workAddress,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/nested_with_fields.g.dart': decodedMatches(allOf([
              // Address schema with custom keys
              contains("'street_address': Ack.string()"),
              contains("'city_name': Ack.string()"),
              contains("'postal_code': Ack.string().optional().nullable()"),

              // User schema with nested references
              contains("'full_name': Ack.string()"),
              contains("'home_address': addressSchema"),
              contains("'work_address': addressSchema.optional().nullable()"),

              // SchemaModel createFromMap with custom keys
              contains('street: map[\'street_address\'] as String'),
              contains('city: map[\'city_name\'] as String'),
              contains('postalCode: map[\'postal_code\'] as String?'),
              contains('name: map[\'full_name\'] as String'),
              contains('homeAddress: AddressSchemaModel().createFromMap('),
              contains('map[\'home_address\'] as Map<String, dynamic>'),
            ])),
          },
        );
      });
    });

    group('Error Cases and Validation', () {
      test('should handle contradictory AckField settings gracefully',
          () async {
        final builder = ackGenerator(BuilderOptions.empty);

        // This should succeed despite the logical contradiction
        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/contradictory.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class ContradictoryModel {
  @AckField(required: true)  // Marked required but type is nullable
  final String? contradictoryField;
  
  ContradictoryModel({this.contradictoryField});
}
''',
          },
          outputs: {
            'test_pkg|lib/contradictory.g.dart': decodedMatches(allOf([
              contains('final contradictoryModelSchema = Ack.object({'),
              contains("'contradictoryField': Ack.string().nullable()"),
            ])),
          },
        );
      });

      test('should handle very long annotation values', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/long_values.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

@AckModel(
  schemaName: 'VeryLongSchemaNameThatExceedsNormalLengthExpectationsAndTestsEdgeCasesForNameGeneration',
  description: 'This is a very long description that tests how the generator handles extremely verbose documentation strings that might span multiple lines and contain various special characters and formatting requirements'
)
class LongValuesModel {
  @AckField(
    jsonKey: 'extremely_long_json_key_name_that_tests_limits',
    description: 'This field has an extremely long description that tests the generators ability to handle verbose field documentation',
    constraints: ['minLength(1)', 'maxLength(1000)', 'pattern(^[a-zA-Z0-9\\s\\.,!?-]*)', 'custom(very, long, constraint, list)']
  )
  final String longField;
  
  LongValuesModel({required this.longField});
}
''',
          },
          outputs: {
            'test_pkg|lib/long_values.g.dart': decodedMatches(allOf([
              contains(
                  'final veryLongSchemaNameThatExceedsNormalLengthExpectationsAndTestsEdgeCasesForNameGeneration'),
              contains('Ack.object({'),
              contains("'extremely_long_json_key_name_that_tests_limits'"),
              contains('/// This is a very long description'),
            ])),
          },
        );
      });
    });

    group('Real-World Scenarios', () {
      test('should handle realistic API model with all features', () async {
        final builder = ackGenerator(BuilderOptions.empty);

        await testBuilder(
          builder,
          {
            ...allAssets,
            'test_pkg|lib/api_model.dart': '''
import 'package:ack_annotations/ack_annotations.dart';

enum UserRole { admin, user, guest }
enum SubscriptionStatus { active, inactive, pending, cancelled }

@AckModel(
  model: true,
  schemaName: 'ApiUserSchema',
  description: 'Complete user model for API responses',
  additionalProperties: true,
  additionalPropertiesField: 'customFields'
)
class ApiUser {
  @AckField(jsonKey: 'user_id', description: 'Unique user identifier')
  final String id;
  
  @AckField(
    jsonKey: 'email_address',
    description: 'User email address',
    constraints: ['email', 'notEmpty'],
    required: true
  )
  final String email;
  
  @AckField(
    jsonKey: 'display_name',
    description: 'User display name',
    constraints: ['minLength(1)', 'maxLength(100)']
  )
  final String? displayName;
  
  @AckField(jsonKey: 'user_role')
  final UserRole role;
  
  @AckField(jsonKey: 'subscription_status')
  final SubscriptionStatus? subscriptionStatus;
  
  @AckField(jsonKey: 'profile_tags')
  final List<String> tags;
  
  @AckField(jsonKey: 'user_preferences')
  final Map<String, String> preferences;
  
  final Map<String, dynamic> customFields;
  
  ApiUser({
    required this.id,
    required this.email,
    this.displayName,
    required this.role,
    this.subscriptionStatus,
    required this.tags,
    required this.preferences,
    required this.customFields,
  });
}
''',
          },
          outputs: {
            'test_pkg|lib/api_model.g.dart': decodedMatches(allOf([
              // Custom schema name
              contains('final apiUserSchema = Ack.object({'),
              contains('/// Complete user model for API responses'),

              // All field types with custom keys
              contains("'user_id': Ack.string()"),
              contains("'email_address': Ack.string()"),
              contains("'display_name': Ack.string()"),
              contains('.minLength(1)'),
              contains('.maxLength(100)'),
              contains('.optional()'),
              contains('.nullable()'),
              contains(
                  "'user_role': Ack.string().enumString(['admin', 'user', 'guest'])"),
              contains("'subscription_status': Ack.string()"),
              contains(
                  ".enumString(['active', 'inactive', 'pending', 'cancelled'])"),
              contains('.optional()'),
              contains('.nullable()'),
              contains("'profile_tags': Ack.list(Ack.string())"),
              contains(
                  "'user_preferences': Ack.object({}, additionalProperties: true)"),

              // Additional properties
              contains('}, additionalProperties: true)'),

              // SchemaModel with all features
              contains('class ApiUserSchemaModel extends SchemaModel<ApiUser>'),
              contains('extractAdditionalProperties(map, {'),
              contains("'user_id'"),
              contains("'email_address'"),
              contains("'display_name'"),
              contains("'user_role'"),
              contains("'subscription_status'"),
              contains("'profile_tags'"),
              contains("'user_preferences'"),
            ])),
          },
        );
      });
    });
  });
}
