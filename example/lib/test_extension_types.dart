import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'test_extension_types.g.dart';

/// Simple model to test basic extension type generation
@AckModel()
class SimpleUser {
  final String name;
  final int age;
  final String? email;

  SimpleUser({required this.name, required this.age, this.email});
}

/// Model with nested types to test dependency ordering
@AckModel()
class Address {
  final String street;
  final String city;
  final String country;

  Address({required this.street, required this.city, required this.country});
}

@AckModel()
class UserWithAddress {
  final String name;
  final Address address;
  final Address? billingAddress;

  UserWithAddress({
    required this.name,
    required this.address,
    this.billingAddress,
  });
}

/// Model with collections to test list handling
@AckModel()
class BlogPost {
  final String title;
  final String content;
  final List<String> tags;
  final List<Address> locations;

  BlogPost({
    required this.title,
    required this.content,
    required this.tags,
    required this.locations,
  });
}
