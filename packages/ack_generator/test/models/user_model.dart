import 'package:ack/ack.dart';

/// Annotate your model class with @AckModel
@Schema(
  description: 'A user model with validation',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class User {
  /// Email must be valid
  @IsEmail()
  final String email;

  /// Name cannot be empty
  @IsNotEmpty()
  final String name;

  /// Age is optional
  final int? age;

  /// Password must be at least 8 characters and is required
  @Required()
  @MinLength(8)
  final String? password;

  /// Address must be provided
  @Required()
  final Address address;

  /// Additional properties are stored here
  final Map<String, dynamic> metadata;

  /// Constructor parameters determine which fields are required
  User({
    required this.email,
    required this.name,
    this.age,
    this.password,
    required this.address,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  /// String representation of user
  @override
  String toString() {
    return 'User{email: $email, name: $name, age: $age, password: ${password != null ? "****" : "null"}, address: $address, metadata: $metadata}';
  }
}

/// Address model with its own validation
@Schema()
class Address {
  /// Street cannot be empty
  @IsNotEmpty()
  final String street;

  /// City cannot be empty
  @IsNotEmpty()
  final String city;

  /// Zip is optional
  @Nullable()
  final String? zip;

  /// Constructor determines required fields
  Address({
    required this.street,
    required this.city,
    this.zip,
  });

  /// String representation of address
  @override
  String toString() {
    return 'Address{street: $street, city: $city, zip: $zip}';
  }
}
