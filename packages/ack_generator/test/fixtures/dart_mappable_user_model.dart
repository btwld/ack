import 'package:ack/ack.dart';

part 'dart_mappable_user_model.g.dart';

/// Example model demonstrating dart_mappable integration with Ack
/// This shows how case style transformations work seamlessly between
/// dart_mappable serialization and Ack schema validation
@MappableClass(caseStyle: CaseStyle.snakeCase)
@Schema(
  description: 'A user model with dart_mappable snake_case integration',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class DartMappableUser with DartMappableUserMappable {
  /// User's first name - will be transformed to 'first_name'
  @IsNotEmpty()
  final String firstName;

  /// User's last name - will be transformed to 'last_name'
  @IsNotEmpty()
  final String lastName;

  /// User's email with custom field key override
  @MappableField(key: 'email_address')
  @IsEmail()
  final String email;

  /// User's age - will be transformed to 'user_age'
  @Min(0)
  @Max(120)
  final int? userAge;

  /// User's phone number - will be transformed to 'phone_number'
  @Pattern(r'^\+?[\d\s\-\(\)]+$')
  final String? phoneNumber;

  /// User's preferences - will be transformed to 'user_preferences'
  final Map<String, dynamic>? userPreferences;

  /// Additional metadata for extra properties
  final Map<String, dynamic> metadata;

  const DartMappableUser({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.userAge,
    this.phoneNumber,
    this.userPreferences,
    this.metadata = const {},
  });
}

/// Address model with camelCase (no transformation)
@MappableClass(caseStyle: CaseStyle.camelCase)
@Schema(description: 'Address with camelCase field names')
class DartMappableAddress with DartMappableAddressMappable {
  /// Street address - remains 'streetAddress'
  @IsNotEmpty()
  final String streetAddress;

  /// City name - remains 'cityName'
  @IsNotEmpty()
  final String cityName;

  /// Postal code with custom key
  @MappableField(key: 'zipCode')
  @Pattern(r'^\d{5}(-\d{4})?$')
  final String? postalCode;

  /// Country code - remains 'countryCode'
  @MinLength(2)
  @MaxLength(3)
  final String countryCode;

  const DartMappableAddress({
    required this.streetAddress,
    required this.cityName,
    this.postalCode,
    required this.countryCode,
  });
}

/// Mock dart_mappable classes for testing
/// These simulate the actual dart_mappable annotations and mixins

class CaseStyle {
  static const snakeCase = CaseStyle._('snakeCase');
  static const camelCase = CaseStyle._('camelCase');
  static const pascalCase = CaseStyle._('pascalCase');
  static const paramCase = CaseStyle._('paramCase');
  static const constantCase = CaseStyle._('constantCase');
  
  final String name;
  const CaseStyle._(this.name);
}

class MappableClass {
  final CaseStyle caseStyle;
  const MappableClass({required this.caseStyle});
}

class MappableField {
  final String key;
  const MappableField({required this.key});
}

// Mock mixins for testing
mixin DartMappableUserMappable {
  Map<String, dynamic> toMap() => {
    'first_name': (this as DartMappableUser).firstName,
    'last_name': (this as DartMappableUser).lastName,
    'email_address': (this as DartMappableUser).email,
    if ((this as DartMappableUser).userAge != null) 
      'user_age': (this as DartMappableUser).userAge,
    if ((this as DartMappableUser).phoneNumber != null) 
      'phone_number': (this as DartMappableUser).phoneNumber,
    if ((this as DartMappableUser).userPreferences != null) 
      'user_preferences': (this as DartMappableUser).userPreferences,
    ...(this as DartMappableUser).metadata,
  };
}

mixin DartMappableAddressMappable {
  Map<String, dynamic> toMap() => {
    'streetAddress': (this as DartMappableAddress).streetAddress,
    'cityName': (this as DartMappableAddress).cityName,
    if ((this as DartMappableAddress).postalCode != null) 
      'zipCode': (this as DartMappableAddress).postalCode,
    'countryCode': (this as DartMappableAddress).countryCode,
  };
}
